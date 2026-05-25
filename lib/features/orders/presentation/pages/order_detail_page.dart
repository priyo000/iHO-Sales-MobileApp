import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/order_status.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../widgets/order_detail_action_bar.dart';
import '../widgets/order_detail_header.dart';
import '../widgets/order_detail_items_list.dart';
import '../widgets/order_detail_notes_card.dart';
import '../widgets/order_detail_timeline.dart';

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
    final AsyncValue<Map<String, dynamic>> orderStreamAsync =
        localOrderId != null
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

    final pelanggan = displayOrder['pelanggan'] is Map
        ? Map<String, dynamic>.from(displayOrder['pelanggan'] as Map)
        : <String, dynamic>{};
    final items = (displayOrder['items'] as List?) ?? [];
    final promos = (displayOrder['promos'] as List?) ?? [];
    final total =
        double.tryParse(displayOrder['total_tagihan'].toString()) ?? 0.0;
    final diskonTotal =
        double.tryParse(displayOrder['diskon_total']?.toString() ?? '0') ?? 0.0;

    DateTime? date;
    final tanggalTx = displayOrder['tanggal_transaksi'];
    if (tanggalTx is int) {
      date = DateTime.fromMillisecondsSinceEpoch(tanggalTx);
    } else if (tanggalTx is String) {
      date = DateTime.tryParse(tanggalTx)?.toLocal();
    }
    final status = (displayOrder['status'] ?? OrderStatus.pending.code)
        .toString()
        .toUpperCase();

    final regularItems = items.where((i) => i['is_hadiah'] != true).toList();
    final hadiahNotaPromos = promos
        .where((p) => p['jenis'] == 'hadiah_nota')
        .toList();
    final subtotalItems = regularItems.fold<double>(0, (s, i) {
      return s +
          (double.tryParse(i['harga_satuan']?.toString() ?? '0') ?? 0) *
              (i['jumlah'] as int? ?? 0);
    });
    final totalHadiah = promos.fold<double>(0, (s, p) {
      if (p['jenis'] == 'hadiah' || p['jenis'] == 'hadiah_nota') {
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
                  (double.tryParse(i['harga_satuan']?.toString() ?? '0') ?? 0) *
                      (i['jumlah'] as int? ?? 0),
            );
      }
      return s;
    });

    return AppScaffold(
      safeAreaTop: false,
      safeAreaBottom: false,
      body: CustomScrollView(
        slivers: [
          OrderDetailHeader(
            displayOrder: displayOrder,
            pelanggan: pelanggan,
            status: status,
            total: total,
            itemCount: regularItems.length,
            date: date,
            currencyFormat: currencyFormat,
            dateFormat: dateFormat,
            onRefresh: serverOrderId != null
                ? () => ref.invalidate(orderDetailProvider(serverOrderId))
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderDetailItemsList(
                    items: items,
                    regularItems: regularItems,
                    promos: promos,
                    hadiahNotaPromos: hadiahNotaPromos,
                    subtotalItems: subtotalItems,
                    diskonTotal: diskonTotal,
                    total: total,
                    totalHadiah: totalHadiah,
                    currencyFormat: currencyFormat,
                    isLoading: orderDetailAsync.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (displayOrder['catatan'] != null &&
                      displayOrder['catatan'].toString().isNotEmpty) ...[
                    OrderDetailNotesCard(
                      notes: displayOrder['catatan'].toString(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  OrderDetailTimeline(
                    order: displayOrder,
                    dateFormat: dateFormat,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomBar: status == OrderStatus.pending.code
          ? OrderDetailActionBar(
              displayOrder: displayOrder,
              serverOrderId: serverOrderId,
              localRef: localRef,
              canMutateOrder: canMutateOrder,
              hasPendingActions: hasPendingActions,
            )
          : null,
    );
  }
}
