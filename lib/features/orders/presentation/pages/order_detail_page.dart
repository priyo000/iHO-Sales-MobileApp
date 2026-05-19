import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/widgets/store_image.dart';
import '../controllers/order_controller.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/order_summary_section.dart';
import '../widgets/hadiah_nota_info_section.dart';

String? parseServerOrderId(dynamic rawId) {
  if (rawId == null) return null;
  final str = rawId.toString().trim();
  if (str.isEmpty || str == 'null') return null;
  return str;
}

bool hasMeaningfulOrderData(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) return false;
  if (data['id'] != null) return true;
  if (data['no_pesanan'] != null) return true;
  if (data['pelanggan'] is Map && (data['pelanggan'] as Map).isNotEmpty) {
    return true;
  }
  if (data['items'] is List && (data['items'] as List).isNotEmpty) return true;
  return false;
}

Map<String, dynamic> resolveOrderForDisplay({
  required Map<String, dynamic> routeOrder,
  Map<String, dynamic>? fetchedOrder,
}) {
  if (hasMeaningfulOrderData(fetchedOrder)) return fetchedOrder!;
  return routeOrder;
}

// SSOT: Watch order from Drift stream (single source of truth)
// Returns enriched Map (with product names) instead of raw OrdersTableData
final orderDetailStreamProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, orderId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchOrder(orderId).asyncMap((data) async {
        if (data == null) return <String, dynamic>{};
        final map = ordersTableDataToMap(data);
        final items = map['items'] as List?;
        if (items != null && items.isNotEmpty) {
          map['items'] = await enrichItemsWithProducts(items, db);
        }
        return map;
      });
    });

/// Enriches order items with product data from local Drift SSOT.
/// - Regular items: looks up by `id_produk`
/// - Hadiah items: looks up by `id_produk_hadiah`
/// This enables order detail to display product names/images without an API call.
Future<List<Map<String, dynamic>>> enrichItemsWithProducts(
  List items,
  AppDatabase db,
) async {
  if (items.isEmpty) return [];

  // Batch lookup all products at once (single DB call)
  final allProducts = await db.getAllProducts();
  final productMap = <String, ProductsTableData>{};
  for (final p in allProducts) {
    productMap[p.id] = p;
  }

  // Enrich each item with product data
  return items.map((item) {
    // Hadiah items use id_produk_hadiah instead of id_produk
    final id =
        item['id_produk']?.toString() ??
        item['id_produk_hadiah']?.toString();

    final product = (id != null && id.isNotEmpty) ? productMap[id] : null;
    if (product == null) return Map<String, dynamic>.from(item);

    return {
      ...Map<String, dynamic>.from(item),
      'produk': {
        'id': product.id,
        'nama_produk': product.namaProduk,
        'kategori': product.kategori,
        'satuan': item['satuan'] ?? product.satuan ?? 'pcs',
        'harga_jual': product.hargaJual,
        'gambar_url': product.gambarUrl,
        'kode_barang': product.kodeBarang,
        'sku': product.sku,
      },
    };
  }).toList();
}

/// Helper to convert OrdersTableData to display Map
Map<String, dynamic> ordersTableDataToMap(OrdersTableData? data) {
  if (data == null) return {};
  return {
    'id': data.id,
    'server_id': data.serverId,
    'no_pesanan':
        data.noPesanan ?? data.id, // Server-assigned or local fallback
    'id_kunjungan': data.kunjunganId,
    'id_pelanggan': data.pelangganId,
    'status': data.status,
    'items': data.itemsJson.isNotEmpty ? jsonDecode(data.itemsJson) : [],
    'catatan': data.notes,
    'promos': data.promosJson?.isNotEmpty == true
        ? jsonDecode(data.promosJson!)
        : [],
    'total_tagihan': data.totalTagihan,
    'local_ref': data.clientRef ?? data.id,
    'is_offline': data.isLocal == 1,
    'tanggal_transaksi':
        data.tanggalTransaksi, // epoch ms — UI parses as int or String
  };
}

final orderDetailProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, orderId) async {
      final db = ref.read(appDatabaseProvider);
      final data = await db.getOrder(orderId);
      final map = ordersTableDataToMap(data);

      final items = map['items'] as List?;
      if (items != null && items.isNotEmpty) {
        final enrichedItems = await enrichItemsWithProducts(
          items.cast<Map<String, dynamic>>(),
          db,
        );
        map['items'] = enrichedItems;
      }

      return map;
    });

class OrderDetailPage extends ConsumerWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverOrderId =
        parseServerOrderId(order['server_id']) ??
        parseServerOrderId(order['id']);
    final localOrderId = (order['id'] ?? order['local_ref'])?.toString();
    final AsyncValue<Map<String, dynamic>> orderStreamAsync = localOrderId != null
        ? ref.watch(orderDetailStreamProvider(localOrderId))
        : const AsyncValue<Map<String, dynamic>>.data({});
    final AsyncValue<Map<String, dynamic>?> orderDetailAsync =
        serverOrderId != null
        ? ref.watch(orderDetailProvider(serverOrderId))
        : const AsyncValue<Map<String, dynamic>?>.data(null);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    final displayOrder = resolveOrderForDisplay(
      routeOrder: order,
      fetchedOrder: orderStreamAsync.value?.isNotEmpty == true
          ? orderStreamAsync.value
          : orderDetailAsync.value,
    );
    final routePelanggan = order['pelanggan'] is Map
        ? Map<String, dynamic>.from(order['pelanggan'] as Map)
        : <String, dynamic>{};
    if ((displayOrder['pelanggan'] is! Map ||
            (displayOrder['pelanggan'] as Map).isEmpty) &&
        routePelanggan.isNotEmpty) {
      displayOrder['pelanggan'] = routePelanggan;
    }
    final canMutateServerOrder = serverOrderId != null;
    final localRef = displayOrder['local_ref']?.toString();
    final canMutatePendingOrder = localRef != null && localRef.isNotEmpty;
    final canMutateOrder = canMutateServerOrder || canMutatePendingOrder;
    final hasPendingActions =
        (displayOrder['is_offline'] == true) || serverOrderId == null;

    final pelanggan = displayOrder['pelanggan'] ?? {};
    final items = (displayOrder['items'] as List?) ?? [];
    final promos = (displayOrder['promos'] as List?) ?? [];
    final total =
        double.tryParse(displayOrder['total_tagihan'].toString()) ?? 0.0;
    final diskonTotal =
        double.tryParse(displayOrder['diskon_total']?.toString() ?? '0') ?? 0.0;
    // Parse tanggal_transaksi: epoch ms (int) from Drift, or ISO string fallback
    DateTime? date;
    final tanggalTx = displayOrder['tanggal_transaksi'];
    if (tanggalTx is int) {
      date = DateTime.fromMillisecondsSinceEpoch(tanggalTx);
    } else if (tanggalTx is String) {
      date = DateTime.tryParse(tanggalTx)?.toLocal();
    }
    final status = (displayOrder['status'] ?? 'PENDING')
        .toString()
        .toUpperCase();

    Color getStatusColor(String s) {
      switch (s) {
        case 'SUKSES':
        case 'SUCCESS':
          return Colors.green;
        case 'PROSES':
        case 'PROCESS':
          return Colors.blue;
        case 'PENDING':
          return Colors.orange;
        case 'BATAL':
        case 'CANCELED':
        case 'CANCELLED':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    final regularItems = items.where((i) => i['is_hadiah'] != true).toList();
    final hadiahNotaPromos = promos
        .where((p) => p['jenis'] == 'hadiah_nota')
        .toList();
    final subtotalItems = regularItems.fold<double>(0, (s, i) {
      return s +
          (double.tryParse(i['harga_satuan']?.toString() ?? '0') ?? 0) *
              (i['jumlah'] as int? ?? 0);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (serverOrderId != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  tooltip: 'Refresh Detail',
                  onPressed: () =>
                      ref.invalidate(orderDetailProvider(serverOrderId)),
                ),
            ],
            title: Text(
              displayOrder['no_pesanan'] ?? 'Detail Pesanan',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    bottom: 60,
                    child: Container(
                      color: Colors.grey[300],
                      child: StoreImage(
                        url: pelanggan['foto_toko_url'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        fallbackIcon: status == 'PROSPECT'
                            ? Icons.store_outlined
                            : Icons.store,
                        fallbackIconSize: 64,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    bottom: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOKO PELANGGAN',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pelanggan['nama_toko'] ??
                              pelanggan['nama_pelanggan'] ??
                              pelanggan['nama'] ??
                              '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Text(
                                date != null ? dateFormat.format(date) : '-',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(total),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'PRODUK',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${regularItems.length} item',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (orderDetailAsync.isLoading && items.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (items.isEmpty)
                    const Text('Tidak ada item.')
                  else ...[
                    ...regularItems.map<Widget>((item) {
                      final itemPromo = promos
                          .where(
                            (p) =>
                                p['jenis'] != 'hadiah_nota' &&
                                p['id_produk'] != null &&
                                p['id_produk'].toString() ==
                                    item['id_produk'].toString(),
                          )
                          .firstOrNull;
                      final hadiahItem = itemPromo != null
                          ? items
                                .where(
                                  (i) =>
                                      i['is_hadiah'] == true &&
                                      i['id_promo_campaign'].toString() ==
                                          itemPromo['id_promo_campaign']
                                              .toString(),
                                )
                                .firstOrNull
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OrderItemTile(
                          item: item,
                          fmt: currencyFormat,
                          promoApplied: itemPromo,
                          hadiahItem: hadiahItem,
                        ),
                      );
                    }),

                    // Hadiah per nota
                    if (hadiahNotaPromos.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      HadiahNotaInfoSection(
                        hadiahNotaPromos: hadiahNotaPromos,
                        items: items,
                        currencyFormat: currencyFormat,
                      ),
                      const SizedBox(height: 4),
                    ],

                    const SizedBox(height: 8),

                    // Ringkasan perhitungan
                    OrderSummarySection(
                      subtotal: subtotalItems,
                      diskonTotal: diskonTotal,
                      totalHadiah: promos.fold<double>(0, (s, p) {
                        if (p['jenis'] == 'hadiah' ||
                            p['jenis'] == 'hadiah_nota') {
                          final hadiahItems = items.where(
                            (i) =>
                                i['is_hadiah'] == true &&
                                i['id_promo_campaign'].toString() ==
                                    p['id_promo_campaign'].toString(),
                          );
                          return s +
                              hadiahItems.fold<double>(
                                0,
                                (ss, i) =>
                                    ss +
                                    (double.tryParse(
                                              i['harga_satuan']?.toString() ??
                                                  '0',
                                            ) ??
                                            0) *
                                        (i['jumlah'] as int? ?? 0),
                              );
                        }
                        return s;
                      }),
                      grandTotal: total,
                      fmt: currencyFormat,
                    ),
                  ],

                  const SizedBox(height: 16),

                  if (displayOrder['catatan'] != null &&
                      displayOrder['catatan'].toString().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes, color: Colors.grey, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Catatan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              displayOrder['catatan'].toString(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTimeline(context, displayOrder, dateFormat),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      persistentFooterButtons: status == 'PENDING' && hasPendingActions
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Perubahan akan disimpan ke antrean offline dan diterapkan saat sinkronisasi berhasil.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ]
          : null,
      bottomNavigationBar: status == 'PENDING'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canMutateOrder
                          ? () => _showCancelDialog(
                              context,
                              ref,
                              serverOrderId,
                              localRef,
                            )
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batalkan Pesanan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canMutateOrder
                          ? () async {
                              await ref
                                  .read(orderControllerProvider.notifier)
                                  .prepareEdit(displayOrder);
                              if (!context.mounted) return;
                              context.push(
                                '/order-review',
                                extra: {
                                  'orderId': serverOrderId,
                                  'localRef': localRef,
                                  'isEdit': true,
                                  'initialNotes': displayOrder['catatan'],
                                  'pelangganId': displayOrder['id_pelanggan'],
                                  'pelangganData': displayOrder['pelanggan'],
                                  'kunjunganId': displayOrder['id_kunjungan'],
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Edit Pesanan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    String? orderId,
    String? localRef,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Batalkan Pesanan"),
          content: const Text(
            "Yakin ingin membatalkan pesanan ini? Tindakan ini tidak bisa dibatalkan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(orderControllerProvider).isLoading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final notifier = ref.read(
                            orderControllerProvider.notifier,
                          );
                          final success = orderId != null
                              ? await notifier.cancelOrder(orderId)
                              : (localRef != null && localRef.isNotEmpty
                                    ? await notifier.cancelPendingOrder(
                                        localRef,
                                      )
                                    : false);
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text("Pesanan berhasil dibatalkan"),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Ya, Batalkan",
                          style: TextStyle(color: Colors.red),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    Map<String, dynamic> order,
    DateFormat format,
  ) {
    List<Map<String, dynamic>> stages = [
      {
        "label": "Order Dibuat",
        "time": order["tanggal_transaksi"],
        "icon": Icons.add_shopping_cart,
      },
      {"label": "Diproses", "time": order["waktu_proses"], "icon": Icons.sync},
      {
        "label": "Dikirim",
        "time": order["waktu_kirim"],
        "icon": Icons.local_shipping,
      },
      {
        "label": "Selesai",
        "time": order["waktu_selesai"],
        "icon": Icons.check_circle,
      },
    ];
    if (order["waktu_batal"] != null) {
      stages.add({
        "label": "Dibatalkan",
        "time": order["waktu_batal"],
        "icon": Icons.cancel,
        "color": Colors.red,
      });
    }
    stages = stages.where((s) => s["time"] != null).toList();
    if (stages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Riwayat Status",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...stages.map((stage) {
            final idx = stages.indexOf(stage);
            final isLast = idx == stages.length - 1;
            final rawTime = stage["time"];
            DateTime? dt;
            if (rawTime is int) {
              dt = DateTime.fromMillisecondsSinceEpoch(rawTime);
            } else if (rawTime is String) {
              dt = DateTime.tryParse(rawTime)?.toLocal();
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            (stage["color"] as Color?) ??
                            AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stage["icon"] as IconData,
                        size: 14,
                        color: (stage["color"] as Color?) ?? AppTheme.primary,
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 20, color: Colors.grey[200]),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage["label"] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dt != null ? format.format(dt) : "-",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// Extracted widgets are now in:
// - ../widgets/order_item_tile.dart (OrderItemTile)
// - ../widgets/order_summary_section.dart (OrderSummarySection)
// - ../widgets/hadiah_nota_info_section.dart (HadiahNotaInfoSection)
