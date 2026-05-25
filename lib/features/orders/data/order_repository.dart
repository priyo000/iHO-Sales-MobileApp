import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/order_status.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/mutation_queue_service.dart';
import '../../../../core/services/last_sync_service.dart';
import '../../../../core/providers/database_providers.dart';
import 'models/cart_item_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    ref.watch(appDatabaseProvider),
    ref.read(dioClientProvider),
    ref.read(connectivityServiceProvider),
    ref.read(syncServiceProvider),
    ref.read(mutationQueueServiceProvider),
    ref.read(lastSyncServiceProvider),
  );
});

final ordersByKunjunganProvider =
    StreamProvider.family<List<OrdersTableData>, String>((ref, kunjunganId) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByKunjungan(kunjunganId);
});

final ordersByPelangganProvider =
    StreamProvider.autoDispose.family<List<OrdersTableData>, String>(
        (ref, pelangganId) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByPelanggan(pelangganId);
});

/// Resolve orders for a specific visit — Drift-only stream (offline-first, SSOT).
///
/// Strategy:
/// 1. Primary match: `orders.kunjunganId` cocok dengan `visit.id` (clientRef)
///    atau `visit.serverId` (UUID setelah sync).
/// 2. Fallback match: `orders.tanggalTransaksi` jatuh dalam window
///    [waktuCheckIn, waktuCheckOut] dari visit ini.
///
/// Fallback diperlukan karena `orders.kunjunganId` tidak selalu di-rewrite
/// saat sync menghasilkan ref mapping baru — orders lama mungkin masih
/// menyimpan clientRef sementara visit sudah punya serverId, atau sebaliknya.
final ordersForVisitProvider = StreamProvider.autoDispose
    .family<List<OrdersTableData>, VisitsTableData>((ref, visit) {
  final pelangganId = visit.pelangganId;
  if (pelangganId == null || pelangganId.isEmpty) {
    return Stream.value(const []);
  }
  final repo = ref.watch(orderRepositoryProvider);
  return repo.watchOrdersByPelanggan(pelangganId).map((orders) {
    final candidates = <String>{
      visit.id,
      if (visit.serverId != null && visit.serverId!.isNotEmpty) visit.serverId!,
    };
    final byKunjungan = orders
        .where((o) =>
            o.kunjunganId != null && candidates.contains(o.kunjunganId))
        .toList();
    if (byKunjungan.isNotEmpty) return byKunjungan;

    final checkIn = DateTime.tryParse(visit.waktuCheckIn ?? '')?.toLocal();
    final checkOut = DateTime.tryParse(visit.waktuCheckOut ?? '')?.toLocal();
    if (checkIn == null || checkOut == null) return const <OrdersTableData>[];
    return orders.where((o) {
      final created =
          DateTime.fromMillisecondsSinceEpoch(o.tanggalTransaksi);
      return !created.isBefore(checkIn) && !created.isAfter(checkOut);
    }).toList();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// OrderRepository — SSOT Pattern (Phase 2)
//
// READ:  From Drift streams (instant, offline-first) — NEW
// WRITE: Via MutationQueueService (writes to Drift first, queues sync) — EXISTING
//
// This ensures:
// - UI can read from local Drift (instant) via stream providers
// - Writes are queued for server sync
// - No direct server calls in read path
// ─────────────────────────────────────────────────────────────────────────────

class OrderRepository {
  final AppDatabase _db;
  final DioClient _dioClient;
  final ConnectivityService _connectivity;
  final SyncService _sync;
  final MutationQueueService _mutations;
  final LastSyncService _lastSync;

  OrderRepository(
    this._db,
    this._dioClient,
    this._connectivity,
    this._sync,
    this._mutations,
    this._lastSync,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // READ — Stream from Drift (SSOT instant read) — NEW
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all orders - reactive stream for order list pages
  Stream<List<OrdersTableData>> watchAllOrders() {
    return _db.watchAllOrders();
  }

  /// Watch pending orders (offline-created, not yet synced)
  Stream<List<OrdersTableData>> watchPendingOrders() {
    return _db.watchPendingOrders();
  }

  /// Watch orders by status (e.g., 'PENDING', 'APPROVED', 'REJECTED')
  Stream<List<OrdersTableData>> watchOrdersByStatus(String status) {
    return _db.watchOrdersByStatus(status);
  }

  /// Watch orders by pelanggan
  Stream<List<OrdersTableData>> watchOrdersByPelanggan(String pelangganId) {
    return _db.watchOrdersByPelanggan(pelangganId);
  }

  /// Watch orders by kunjungan (visit)
  Stream<List<OrdersTableData>> watchOrdersByKunjungan(String kunjunganId) {
    return _db.watchOrdersByKunjungan(kunjunganId);
  }

  /// Watch single order by ID
  Stream<OrdersTableData?> watchOrder(String id) {
    return _db.watchOrder(id);
  }

  /// Get all orders (non-reactive) - for initial load
  Future<List<OrdersTableData>> getAllOrders() async {
    return _db.getAllOrders();
  }

  /// Get order by ID (non-reactive)
  Future<OrdersTableData?> getOrder(String id) async {
    return _db.getOrder(id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE — Via MutationQueueService (Drift first, then sync) — EXISTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Buat order — write to local SSOT first, auto-sync to server.
  Future<Map<String, dynamic>> createOrder({
    dynamic kunjunganId,
    dynamic pelangganId,
    Map<String, dynamic>?
    pelangganData, // NEW: Simpan data pelanggan untuk display langsung
    required List<CartItem> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
    String? clientRef,
  }) async {
    final itemMaps = items
        .map(
          (item) => {
            'id_produk': item.product.id,
            'jumlah': item.quantity,
            'harga_satuan': item.price,
            if (item.selectedUnitId != null) 'id_satuan': item.selectedUnitId,
          },
        )
        .toList();

    return _mutations.mutateCreateOrder(
      kunjunganId: kunjunganId,
      pelangganId: pelangganId,
      pelangganData: pelangganData, // NEW: Pass ke mutation queue
      items: itemMaps,
      notes: notes,
      promosApplied: promosApplied,
      hadiahDitebus: hadiahDitebus,
      clientRef: clientRef,
    );
  }

  Future<void> syncOrdersFromApi({
    String? since,
    String? search,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final isOnline = await _connectivity.checkNow();
    debugPrint(
      '[OrderRepo] syncOrdersFromApi called - isOnline=$isOnline, since=$since',
    );
    if (!isOnline) {
      debugPrint('[OrderRepo] ❌ Offline, skipping sync');
      return;
    }

    try {
      // Untuk sinkronisasi SSOT, kita ambil FULL data pada hit pertama (page 1)
      final bool isFullSync = page == 1 && (search == null || search.isEmpty);

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': isFullSync ? '-1' : perPage.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status != 'All') {
        queryParams['status'] = status.toUpperCase();
      }

      // Delta sync: attach ?since= for partial sync after first load
      // When since is explicitly provided (preload 30 days), use it directly.
      // Otherwise use delta sync based on lastModified.
      if (since != null) {
        queryParams['since'] = since;
      } else if (!isFullSync) {
        final lastModified = await _lastSync.getLastModified(
          SyncResource.orders,
        );
        if (lastModified != null) {
          queryParams['since'] = lastModified;
        }
      }

      final uri = Uri.parse(
        ApiConstants.syncPesanan,
      ).replace(queryParameters: queryParams);
      debugPrint('[OrderRepo] 🌐 API call: $uri');

      final result = await _dioClient.get(
        uri.toString(),
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      debugPrint(
        '[OrderRepo] 📥 API response received: ${result is Map ? "Map with ${(result['data'] as List?)?.length ?? 0} items" : result.runtimeType}',
      );

      if (result is Map && result['data'] is List) {
        final dataList = result['data'] as List;
        debugPrint(
          '[OrderRepo] 📦 Processing ${dataList.length} orders from API',
        );
        if (dataList.isNotEmpty) {
          // Build set of localOrderIds with pending mutations to skip overwrite.
          // SSOT guard: jangan overwrite optimistic local state dengan server data
          // yang masih stale (server belum proses mutation kita).
          final pendingUpdates = await _sync.getPendingByType('update_order');
          final pendingStatusUpdates =
              await _sync.getPendingByType('update_order_status');
          final pendingLocalIds = <String>{
            for (final p in pendingUpdates)
              if ((p['payload'] as Map)['_local_order_id'] != null)
                (p['payload'] as Map)['_local_order_id'].toString(),
            for (final p in pendingStatusUpdates)
              if ((p['payload'] as Map)['_local_order_id'] != null)
                (p['payload'] as Map)['_local_order_id'].toString(),
          };

          // Batch-load all orders once to avoid N+1 lookups inside the loop.
          // Build lookup maps for O(1) access by clientRef / serverId / noPesanan.
          final allOrders = await _db.getAllOrders();
          final byClientRef = <String, OrdersTableData>{};
          final byServerId = <String, OrdersTableData>{};
          final byNoPesanan = <String, OrdersTableData>{};
          for (final o in allOrders) {
            if (o.clientRef != null) byClientRef[o.clientRef!] = o;
            if (o.serverId != null) byServerId[o.serverId!] = o;
            if (o.noPesanan != null) byNoPesanan[o.noPesanan!] = o;
          }

          int savedCount = 0;
          for (final item in dataList) {
            final serverId = item['id']?.toString();
            final noPesanan = item['no_pesanan']?.toString();
            final clientRef = item['client_ref']?.toString();
            final existingOrder = clientRef != null
                ? byClientRef[clientRef]
                : null;
            final existingByServerId = serverId != null
                ? byServerId[serverId]
                : null;
            final existingByNoPesanan = noPesanan != null
                ? byNoPesanan[noPesanan]
                : null;
            final orderId =
                existingOrder?.id ??
                existingByServerId?.id ??
                existingByNoPesanan?.id ??
                clientRef ??
                item['id'].toString();

            if (pendingLocalIds.contains(orderId)) {
              debugPrint(
                '[OrderRepo] ⏭️ Skip overwrite: $orderId has pending mutation',
              );
              continue;
            }

            final status = item['status'] ?? OrderStatus.pending.code;
            debugPrint(
              '[OrderRepo] 💾 Saving order: id=$orderId, no_pesanan=$noPesanan, status=$status',
            );
            // Parse tanggal_transaksi from API (ISO string) → epoch ms
            int? tanggalTransaksi;
            final tanggalStr = item['tanggal_transaksi']?.toString();
            if (tanggalStr != null && tanggalStr.isNotEmpty) {
              tanggalTransaksi = DateTime.tryParse(
                tanggalStr,
              )?.millisecondsSinceEpoch;
            }
            await _db.saveOrder(
              id: orderId,
              kunjunganId: (item['kunjungan_id'] ?? item['id_kunjungan'])?.toString(),
              pelangganId: (item['pelanggan_id'] ?? item['id_pelanggan'])?.toString(),
              status: status,
              itemsJson: jsonEncode(item['items'] ?? []),
              notes: item['catatan'] ?? item['notes'],
              promosJson: item['promos_applied'] != null
                  ? jsonEncode(item['promos_applied'])
                  : null,
              totalTagihan:
                  double.tryParse(item['total_tagihan']?.toString() ?? '0') ??
                  0.0,
              serverId: serverId,
              clientRef: clientRef,
              noPesanan: noPesanan,
              tanggalTransaksi: tanggalTransaksi,
            );
            await _db.deleteDuplicateOrdersForCanonical(
              canonicalId: orderId,
              serverId: serverId,
              noPesanan: noPesanan,
              clientRef: clientRef,
            );
            savedCount++;
          }
          debugPrint('[OrderRepo] ✅ Synced $savedCount orders to Drift');

          // Mark delta sync timestamp so next sync only fetches changes
          await _lastSync.setLastSync(
            SyncResource.orders,
            lastModified: DateTime.now(),
          );
        } else {
          debugPrint('[OrderRepo] ⚠️ API returned empty data list');
        }
      } else {
        debugPrint(
          '[OrderRepo] ⚠️ Unexpected response format: ${result?.runtimeType}',
        );
      }
    } catch (e, st) {
      debugPrint('[OrderRepo] ❌ Sync failed: $e');
      debugPrint('[OrderRepo] ❌ Stack trace: $st');
    }
  }

  /// Update order — 100% offline-first via MutationQueueService
  Future<void> updateOrder({
    required String orderId,
    required String localOrderId,
    required List<CartItem> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  }) async {
    final itemMaps = items
        .map(
          (item) => {
            'id_produk': item.product.id,
            'jumlah': item.quantity,
            'harga_satuan': item.price,
            if (item.selectedUnitId != null) 'id_satuan': item.selectedUnitId,
          },
        )
        .toList();

    await _mutations.mutateUpdateOrder(
      orderId: orderId,
      localOrderId: localOrderId,
      items: itemMaps,
      notes: notes,
      promosApplied: promosApplied,
      hadiahDitebus: hadiahDitebus,
    );
  }

  /// Update order status — 100% offline-first via MutationQueueService
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _mutations.mutateUpdateOrderStatus(orderId: orderId, status: status);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY METHODS — Still used by order_controller for optimistic updates
  // These need to work with existing cache structure
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> updatePendingOrder({
    required String localRef,
    required List<CartItem> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  }) async {
    final itemMaps = items
        .map(
          (item) => {
            'id_produk': item.product.id,
            'jumlah': item.quantity,
            'harga_satuan': item.price,
            if (item.selectedUnitId != null) 'id_satuan': item.selectedUnitId,
          },
        )
        .toList();

    // 1. Find the order in Drift (localRef = clientRef from UI)
    final existing =
        await _db.getOrder(localRef) ?? await _db.getOrderByClientRef(localRef);
    if (existing == null) return false;

    // 2. Update local Drift record (SSOT — instant UI update)
    final double totalTagihan = _calcOrderTotal(
      itemMaps,
      promosApplied,
      hadiahDitebus,
    );
    await _db.saveOrder(
      id: existing.id,
      kunjunganId: existing.kunjunganId,
      pelangganId: existing.pelangganId,
      status: existing.status,
      itemsJson: jsonEncode(itemMaps),
      notes: notes,
      promosJson: promosApplied != null ? jsonEncode(promosApplied) : null,
      totalTagihan: totalTagihan,
      serverId: existing.serverId,
      clientRef: existing.clientRef,
      noPesanan: existing.noPesanan,
    );

    // 3. Update payload in sync queue (so server gets updated data)
    // Find the create_order item in queue by matching client_ref
    final pendingItems = await _sync.getPendingByType('create_order');
    for (final item in pendingItems) {
      final payload = item['payload'] as Map<String, dynamic>? ?? {};
      if (payload['client_ref'] == existing.clientRef ||
          item['local_ref'] == localRef) {
        // Update the payload with new items/notes/promos
        final updatedPayload = Map<String, dynamic>.from(payload);
        updatedPayload['items'] = itemMaps;
        if (notes != null) {
          updatedPayload['catatan'] = notes;
        } else {
          updatedPayload.remove('catatan');
        }
        if (promosApplied?.isNotEmpty == true) {
          updatedPayload['promos_applied'] = promosApplied;
        } else {
          updatedPayload.remove('promos_applied');
        }
        if (hadiahDitebus?.isNotEmpty == true) {
          updatedPayload['hadiah_ditebus'] = hadiahDitebus;
        } else {
          updatedPayload.remove('hadiah_ditebus');
        }
        await _sync.updatePendingPayload(
          item['local_ref'] as String,
          updatedPayload,
        );
        break;
      }
    }

    return true;
  }

  Future<void> applyOptimisticPendingOrderPatch({
    required String localRef,
    required Map<String, dynamic> patch,
  }) async {
    // For optimistic patches, we update the Drift record directly
    // The actual sync will overwrite this when it completes
    // This is now a no-op since we write directly to Drift
    log(
      '[OrderRepo] applyOptimisticPendingOrderPatch for $localRef - patches: ${patch.keys.toList()}',
    );
  }

  Future<void> applyOptimisticOrderPatch({
    required String orderId,
    required Map<String, dynamic> patch,
  }) async {
    final allOrders = await _db.getAllOrders();
    final existing =
        allOrders.where((o) => o.serverId == orderId).firstOrNull ??
        await _db.getOrder(orderId);
    if (existing != null) {
      await _db.saveOrder(
        id: existing.id,
        kunjunganId: existing.kunjunganId,
        pelangganId: existing.pelangganId,
        status: patch['status'] ?? existing.status,
        itemsJson: patch['items'] != null
            ? jsonEncode(patch['items'])
            : existing.itemsJson,
        notes: patch['catatan'] ?? existing.notes,
        promosJson: patch['promos'] != null
            ? jsonEncode(patch['promos'])
            : existing.promosJson,
        totalTagihan: (patch['total_tagihan'] ?? existing.totalTagihan)
            .toDouble(),
        serverId: existing.serverId,
        clientRef: existing.clientRef,
        noPesanan: existing.noPesanan,
      );
    }
  }

  Future<bool> cancelPendingOrder(String localRef) async {
    // 1. Find the order in Drift (localRef here is clientRef from UI)
    final existing =
        await _db.getOrder(localRef) ?? await _db.getOrderByClientRef(localRef);
    if (existing == null) return false;

    // 2. Update status to CANCELLED in Drift (SSOT) — preserve all existing fields
    await _db.saveOrder(
      id: existing.id,
      kunjunganId: existing.kunjunganId,
      pelangganId: existing.pelangganId,
      status: 'CANCELLED',
      itemsJson: existing.itemsJson,
      notes: existing.notes,
      promosJson: existing.promosJson,
      totalTagihan: existing.totalTagihan,
      serverId: existing.serverId,
      clientRef: existing.clientRef,
      noPesanan: existing.noPesanan,
    );

    // 3. Remove from sync queue so it won't be sent to server
    // The sync queue item has a different localRef than the order ID,
    // so we search by client_ref in the payload.
    final pendingItems = await _sync.getPendingByType('create_order');
    for (final item in pendingItems) {
      final payload = item['payload'] as Map<String, dynamic>? ?? {};
      if (payload['client_ref'] == existing.clientRef ||
          item['local_ref'] == localRef) {
        await _sync.removePendingItem(item['local_ref'] as String);
        break;
      }
    }

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  double _calcOrderTotal(
    List<Map<String, dynamic>> items,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  ) {
    double total = 0;
    for (final item in items) {
      final jumlah = (item['jumlah'] ?? 0).toDouble();
      final harga = (item['harga_satuan'] ?? item['harga'] ?? 0).toDouble();
      total += jumlah * harga;
    }
    if (promosApplied != null) {
      for (final promo in promosApplied) {
        final diskon = (promo['diskon_amount'] ?? 0).toDouble();
        total -= diskon;
      }
    }
    return total.clamp(0, double.infinity);
  }
}
