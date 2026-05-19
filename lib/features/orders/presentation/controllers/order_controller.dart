import 'dart:async';
import 'dart:math' show Random;
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/db/app_database.dart';
import '../../data/order_repository.dart';
import '../../data/models/promo_model.dart';
import 'cart_controller.dart';
import 'promo_controller.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/controllers/order_history_controller.dart';
import '../../data/models/product_model.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../pages/order_detail_page.dart';
import 'package:sales_tracker_mobile/features/notifications/presentation/controllers/notifications_controller.dart';

final orderControllerProvider = AsyncNotifierProvider<OrderController, void>(
  OrderController.new,
);

/// Watch today's orders for a pelanggan from local Drift (SSOT).
/// Used by checkout page to detect if any order exists for current visit,
/// regardless of online/offline state.
final todayOrdersByPelangganProvider =
    StreamProvider.autoDispose.family<int, String>((ref, pelangganId) {
  final dao = ref.watch(orderDaoProvider);
  return dao.watchOrdersByPelanggan(pelangganId).map((orders) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + const Duration(days: 1).inMilliseconds;
    return orders.where((o) {
      final ts = o.tanggalTransaksi;
      final notCancelled = !o.status.toUpperCase().contains('CANCEL') &&
          !o.status.toUpperCase().contains('BATAL');
      return notCancelled && ts >= startOfDay && ts < endOfDay;
    }).length;
  });
});

class OrderController extends AsyncNotifier<void> {
  String? _normalizeCustomerId(dynamic pelangganId) {
    if (pelangganId == null) return null;
    final normalized = pelangganId.toString().trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') return null;
    return normalized;
  }

  @override
  FutureOr<void> build() {
    return null;
  }

  Future<dynamic> submitOrder({
    dynamic kunjunganId,
    dynamic pelangganId,
    Map<String, dynamic>? pelangganData,
    String? notes,
    String? clientRef,
  }) async {
    final cartState = ref.read(cartControllerProvider);
    final cartItems = cartState.items;
    if (cartItems.isEmpty) {
      throw 'Keranjang kosong. Tambahkan produk terlebih dahulu.';
    }

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(orderRepositoryProvider);
      final promoSelection = ref.read(promoSelectionProvider);

      final promosApplied = promoSelection.buildPromosPayload();
      final hadiahPayload = promoSelection.buildHadiahPayload();

      final stableClientRef = clientRef ??
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(0xFFFFFF).toRadixString(16)}';
      final result = await repository.createOrder(
        kunjunganId: kunjunganId,
        pelangganId: pelangganId,
        pelangganData: pelangganData,
        items: cartItems,
        notes: notes,
        promosApplied: promosApplied.isNotEmpty ? promosApplied : null,
        hadiahDitebus: hadiahPayload.isNotEmpty ? hadiahPayload : null,
        clientRef: stableClientRef,
      );

      // Clear cart dan reset promo selection SETELAH cache invalidations
      // untuk mencegah race condition (cart kosong sebelum cache update selesai)
      final isOffline = result['is_offline'] == true;

      ref.invalidate(scheduleControllerProvider);
      ref.invalidate(notificationsControllerProvider);
      ref.invalidate(orderHistoryControllerProvider);

      if (!isOffline) {
        // Hanya refresh ini saat online — keduanya akan hit server
      } else {
        // Offline: cukup refresh schedule dari cache lokal
      }

      ref.read(cartControllerProvider.notifier).clear();
      ref.read(promoSelectionProvider.notifier).reset();

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      dev.log('[OrderController][SUBMIT][ERROR] submitOrder gagal: $e');
      debugPrint('[OrderController][SUBMIT][ERROR] submitOrder gagal: $e');
      dev.log('[OrderController][SUBMIT][ERROR][STACK] $st');
      debugPrint('[OrderController][SUBMIT][ERROR][STACK] $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updatePendingOrder({
    required String localRef,
    String? notes,
  }) async {
    final cartState = ref.read(cartControllerProvider);
    final cartItems = cartState.items;
    if (cartItems.isEmpty) {
      state = AsyncValue.error(
        'Keranjang kosong. Tambahkan produk terlebih dahulu.',
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncValue.loading();
    try {
      final repository = ref.read(orderRepositoryProvider);
      final promoSelection = ref.read(promoSelectionProvider);

      final promosApplied = promoSelection.buildPromosPayload();
      final hadiahPayload = promoSelection.buildHadiahPayload();

      final ok = await repository.updatePendingOrder(
        localRef: localRef,
        items: cartItems,
        notes: notes,
        promosApplied: promosApplied.isNotEmpty ? promosApplied : null,
        hadiahDitebus: hadiahPayload.isNotEmpty ? hadiahPayload : null,
      );

      if (!ok) {
        state = AsyncValue.error(
          'Order pending tidak ditemukan atau sudah tersinkron.',
          StackTrace.current,
        );
        return false;
      }

      final optimisticItems = cartItems
          .map(
            (item) => {
              'id_produk': item.product.id,
              'jumlah': item.quantity,
              'harga_satuan': item.price,
              'total_harga': item.price * item.quantity,
              'is_hadiah': false,
              'produk': item.product.toJson(),
            },
          )
          .toList();

      final optimisticPromos = promosApplied
          .map(
            (p) => {
              'id': null,
              'id_pesanan': null,
              'id_promo_campaign': p['id_campaign'],
              'nama_promo': p['nama_promo'],
              'jenis': p['jenis'],
              'id_produk': p['id_produk'],
              'diskon_amount': p['diskon_amount'] ?? 0,
            },
          )
          .toList();

      final diskonTotal = promoSelection.totalDiskon;
      final totalHadiah = promoSelection.totalHadiah;
      final grandTotal =
          (cartItems.fold<double>(0, (s, i) => s + i.totalPrice) +
                  totalHadiah -
                  diskonTotal)
              .clamp(0, double.infinity);

      await repository.applyOptimisticPendingOrderPatch(
        localRef: localRef,
        patch: {
          'items': optimisticItems,
          'promos': optimisticPromos,
          'catatan': notes,
          'diskon_total': diskonTotal,
          'total_tagihan': grandTotal,
          'status': 'PENDING',
        },
      );

      ref.read(orderHistoryControllerProvider.notifier).refresh();
      ref.read(cartControllerProvider.notifier).clear();
      ref.read(promoSelectionProvider.notifier).reset();

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      dev.log('[OrderController][SUBMIT][ERROR] submitOrder gagal: $e');
      debugPrint('[OrderController][SUBMIT][ERROR] submitOrder gagal: $e');
      dev.log('[OrderController][SUBMIT][ERROR][STACK] $st');
      debugPrint('[OrderController][SUBMIT][ERROR][STACK] $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateOrder({
    required String orderId,
    required String localOrderId,
    String? notes,
  }) async {
    final cartState = ref.read(cartControllerProvider);
    final cartItems = cartState.items;
    if (cartItems.isEmpty) {
      state = AsyncValue.error(
        'Keranjang kosong. Tambahkan produk terlebih dahulu.',
        StackTrace.current,
      );
      return false;
    }

    try {
      final repository = ref.read(orderRepositoryProvider);
      final promoSelection = ref.read(promoSelectionProvider);

      final promosApplied = promoSelection.buildPromosPayload();
      final hadiahPayload = promoSelection.buildHadiahPayload();

      await repository.updateOrder(
        orderId: orderId,
        localOrderId: localOrderId,
        items: cartItems,
        notes: notes,
        promosApplied: promosApplied.isNotEmpty ? promosApplied : null,
        hadiahDitebus: hadiahPayload.isNotEmpty ? hadiahPayload : null,
      );

      ref.read(cartControllerProvider.notifier).clear();
      ref.read(promoSelectionProvider.notifier).reset();
      return true;
    } catch (e, st) {
      dev.log('[OrderController][UPDATE][ERROR] updateOrder gagal: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelPendingOrder(String localRef) async {
    try {
      final repository = ref.read(orderRepositoryProvider);
      final ok = await repository.cancelPendingOrder(localRef);
      if (!ok) {
        state = AsyncValue.error(
          'Order pending tidak ditemukan atau sudah tersinkron.',
          StackTrace.current,
        );
        return false;
      }
      return true;
    } catch (e, st) {
      dev.log('[OrderController][CANCEL][ERROR] cancelPendingOrder gagal: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final repository = ref.read(orderRepositoryProvider);
      await repository.updateOrderStatus(orderId, 'CANCELLED');
      return true;
    } catch (e, st) {
      dev.log('[OrderController][CANCEL][ERROR] cancelOrder gagal: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> prepareEdit(Map<String, dynamic> orderData) async {
    final items = orderData['items'] as List? ?? [];
    final promos = orderData['promos'] as List? ?? [];
    final cartNotifier = ref.read(cartControllerProvider.notifier);
    final promoNotifier = ref.read(promoSelectionProvider.notifier);

    final targetCustomerId = _normalizeCustomerId(orderData['id_pelanggan']);

    cartNotifier.clear();
    cartNotifier.initForCustomer(targetCustomerId);
    promoNotifier.reset();

    // Items disimpan di Drift hanya dengan id_produk (tanpa produk object).
    // Kalau orderData datang dari routeOrder (stream belum emit), 'produk' null.
    // Lookup product dari Drift sebagai fallback agar cart tetap terisi.
    final needsLookup = items.any((item) =>
        item['is_hadiah'] != true && item['produk'] == null);
    final productMap = <String, ProductsTableData>{};
    final unitsMap = <String, List<ProductUnitsTableData>>{};
    if (needsLookup) {
      final db = ref.read(appDatabaseProvider);
      final allProducts = await db.getAllProducts();
      for (final p in allProducts) {
        productMap[p.id] = p;
      }
      final allUnits = await db.getAllProductUnits();
      for (final u in allUnits) {
        unitsMap.putIfAbsent(u.productId, () => []).add(u);
      }
    }

    // Load item biasa ke cart (skip hadiah)
    for (final item in items) {
      if (item['is_hadiah'] == true) continue;
      var productData = item['produk'] as Map<String, dynamic>?;
      if (productData == null) {
        final id = item['id_produk']?.toString();
        final p = id != null && id.isNotEmpty ? productMap[id] : null;
        if (p == null) continue;
        productData = {
          'id': p.id,
          'nama_produk': p.namaProduk,
          'kategori': p.kategori,
          'satuan': item['satuan'] ?? p.satuan ?? 'pcs',
          'harga_jual': p.hargaJual,
          'gambar_url': p.gambarUrl,
          'kode_barang': p.kodeBarang,
          'sku': p.sku,
          'satuan_list': (unitsMap[p.id] ?? const <ProductUnitsTableData>[])
              .map((u) => {
                    'id': u.id,
                    'nama': u.nama,
                    'konversi': u.konversi,
                    'harga_jual': u.hargaJual,
                    'is_base': u.isBase,
                  })
              .toList(),
        };
      }
      final product = Product.fromJson(productData);
      final qty = item['jumlah'] as int? ?? 0;
      final price = double.tryParse(item['harga_satuan'].toString()) ?? 0.0;

      // Restore unit selection from order item
      final unitId = item['id_satuan']?.toString();
      final unitName = item['satuan']?.toString();
      ProductUnit? selectedUnit;
      if (unitId != null && product.units.isNotEmpty) {
        selectedUnit = product.units.where((u) => u.id == unitId).firstOrNull;
      }
      selectedUnit ??= unitName != null
          ? product.units.where((u) => u.nama == unitName).firstOrNull
          : null;

      cartNotifier.addItem(product, qty, selectedUnit: selectedUnit);
      if (price > 0) {
        cartNotifier.updatePrice(product.id, price);
      }
    }

    // Restore promo per produk dari pesanan_promo
    for (final promo in promos) {
      final jenis = promo['jenis'] as String? ?? '';
      final idProduk = promo['id_produk']?.toString();
      final idCampaign = promo['id_promo_campaign']?.toString() ?? '';
      final namaPromo = promo['nama_promo'] as String? ?? '';
      final diskonAmount =
          double.tryParse(promo['diskon_amount']?.toString() ?? '0') ?? 0.0;

      if (jenis == 'hadiah_nota' || idProduk == null || idProduk.isEmpty) {
        // Hadiah by nota — restore ke hadiahNota
        final hadiahItem = items
            .where(
              (i) =>
                  i['is_hadiah'] == true &&
                  i['id_promo_campaign']?.toString() == idCampaign,
            )
            .firstOrNull;
        if (hadiahItem != null) {
          promoNotifier.toggleHadiahNota(
            HadiahNotaApplied(
              idCampaign: idCampaign,
              namaPromo: namaPromo,
              idProdukHadiah:
                  hadiahItem['id_produk']?.toString() ?? '',
              namaProdukHadiah: hadiahItem['produk']?['nama_produk'] as String?,
              qty: hadiahItem['jumlah'] as int? ?? 1,
              hargaTebus:
                  double.tryParse(
                    hadiahItem['harga_satuan']?.toString() ?? '0',
                  ) ??
                  0,
            ),
          );
        }
      } else if (jenis == 'hadiah') {
        // Hadiah by produk — restore ke promoPerProduk
        final hadiahItem = items
            .where(
              (i) =>
                  i['is_hadiah'] == true &&
                  i['id_promo_campaign']?.toString() == idCampaign,
            )
            .firstOrNull;
        promoNotifier.selectPromoForProduct(
          ItemPromoApplied(
            idCampaign: idCampaign,
            namaPromo: namaPromo,
            jenis: jenis,
            idProduk: idProduk,
            diskonAmount: diskonAmount,
            idProdukHadiah: hadiahItem?['id_produk']?.toString(),
            namaProdukHadiah: hadiahItem?['produk']?['nama_produk'] as String?,
            qtyHadiah: hadiahItem?['jumlah'] as int?,
            hargaTebus:
                double.tryParse(
                  hadiahItem?['harga_satuan']?.toString() ?? '0',
                ) ??
                0,
          ),
        );
      } else {
        // Diskon (aturan_harga / grosir)
        promoNotifier.selectPromoForProduct(
          ItemPromoApplied(
            idCampaign: idCampaign,
            namaPromo: namaPromo,
            jenis: jenis,
            idProduk: idProduk,
            diskonAmount: diskonAmount,
          ),
        );
      }
    }
  }
}
