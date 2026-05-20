import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customer_repository.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/paginated_state.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/last_sync_service.dart';

// userLocationProvider has moved to lib/core/providers/location_provider.dart.
// Re-exported here so existing callers that import this file keep working.
export '../../../../core/providers/location_provider.dart' show userLocationProvider;

// ─── Search & Filter Notifiers ────────────────────────────────────────────────

class CustomerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final customerSearchProvider = NotifierProvider<CustomerSearchNotifier, String>(
  CustomerSearchNotifier.new,
);

class CustomerStatusNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setStatus(String status) => state = status;
}

final customerStatusFilterProvider =
    NotifierProvider<CustomerStatusNotifier, String>(
      CustomerStatusNotifier.new,
    );

class RevalidatingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final customerRevalidatingProvider =
    NotifierProvider<RevalidatingNotifier, bool>(RevalidatingNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PROVIDERS — Reactive SSOT (Preferred)
// These return Stream<List<CustomersTableData>> for use with StreamBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Watch all customers as `Stream<List<CustomersTableData>>`
final allCustomersStreamProvider = Provider<Stream<List<CustomersTableData>>>((
  ref,
) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchAllCustomers();
});

/// Watch customers by status - status: 'All', 'Active', 'Pending', 'Prospect'
/// Also triggers a background sync if the local DB is empty (first launch or
/// after schema migration drops tables). This ensures data appears even if
/// PreloadService hasn't completed yet or failed silently.
final customersByStatusStreamProvider =
    Provider.family<Stream<List<CustomersTableData>>, String>((ref, status) {
      final repo = ref.watch(customerRepositoryProvider);
      final db = ref.watch(appDatabaseProvider);
      final statusKey = status == 'All'
          ? 'active,pending'
          : status.toLowerCase();

      // Fallback: if Drift has zero customers, trigger sync in background.
      // This covers cases where PreloadService failed or was skipped.
      db.getAllLocalCustomers().then((all) {
        if (all.isEmpty) {
          repo.syncCustomersToDrift();
        }
      });

      return repo.watchCustomersByStatus(statusKey);
    });

/// Watch customers with search query - instant SQL filtering
/// Only shows ACTIVE + PENDING customers (same as default list filter)
final customerSearchStreamProvider =
    Provider.family<Stream<List<CustomersTableData>>, String>((ref, query) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchSearchCustomersWithStatus(query, ['active', 'pending']);
    });

// ─── Controller ───────────────────────────────────────────────────────────────

final customerControllerProvider =
    AsyncNotifierProvider<
      CustomerController,
      PaginatedState<Map<String, dynamic>>
    >(CustomerController.new);

class CustomerController
    extends AsyncNotifier<PaginatedState<Map<String, dynamic>>> {
  static const int _perPage = 20;

  @override
  Future<PaginatedState<Map<String, dynamic>>> build() async {
    final search = ref.watch(customerSearchProvider);
    final status = ref.watch(customerStatusFilterProvider);

    // SSOT: Auto refresh local data (from Drift) when sync count changes.
    // Only re-fetch from local DB — do NOT trigger network sync here.
    ref.listen(pendingSyncCountProvider, (previous, next) {
      if (previous is AsyncData && next is AsyncData &&
          (previous as AsyncData).value != (next as AsyncData).value &&
          !state.isLoading) {
        _refetchLocal();
      }
    });

    return await _fetchData(
      page: 1,
      search: search,
      status: status,
      reset: true,
    );
  }

  Future<PaginatedState<Map<String, dynamic>>> _fetchData({
    required int page,
    required String search,
    required String status,
    required bool reset,
  }) async {
    final repo = ref.read(customerRepositoryProvider);
    final statusKey = status == 'All' ? 'active,pending' : status.toLowerCase();

    // 1. Ambil data dari Cache Lokal SEKETIKA (Instant UX)
    // getCustomers() returns a Map with 'data' key containing List<CustomersTableData> converted to List<Map>
    final cachedResponse = await repo.getCustomers(
      search: search.isEmpty ? null : search,
      status: statusKey,
      page: page,
      perPage: _perPage,
    );

    // cachedResponse is {'data': [...List of customer maps...], 'current_page': 1, 'last_page': N}
    final dataList = cachedResponse is Map ? cachedResponse['data'] as List? ?? [] : [];
    final currentPage = cachedResponse is Map ? (cachedResponse['current_page'] as int?) ?? 1 : 1;
    final totalItems = dataList.length;
    final lastPage = totalItems == 0 ? 1 : (totalItems / _perPage).ceil();

    final existingItems = reset ? [] : (state.asData?.value.items ?? []);

    return PaginatedState<Map<String, dynamic>>(
      items: reset ? dataList.cast<Map<String, dynamic>>() : [...existingItems, ...dataList.cast<Map<String, dynamic>>()],
      currentPage: currentPage,
      lastPage: lastPage,
      isLoadingMore: false,
      isRefreshing: false,
    );
  }

  Future<void> revalidateSilent(String search, String statusKey) async {
    try {
      ref.read(customerRevalidatingProvider.notifier).set(true);
      final repo = ref.read(customerRepositoryProvider);

      // Sinkronisasi data ke SQLite secara FULL (per_page=-1)
      await repo.syncCustomersFromApi(
        search: search.isEmpty ? null : search,
        status: statusKey,
      );

      // Setelah tersinkronisasi, ambil lagi data page 1 terupdate
      final response = await repo.getCustomers(
        search: search.isEmpty ? null : search,
        status: statusKey,
        page: 1,
        perPage: _perPage,
      );

      // response is {'data': [...], 'current_page': 1, 'last_page': N}
      final parsed = response is Map ? response['data'] as List? ?? [] : [];
      final parsedPage = response is Map ? (response['current_page'] as int?) ?? 1 : 1;
      final totalItems = parsed.length;
      final parsedLastPage = totalItems == 0 ? 1 : (totalItems / _perPage).ceil();

      // Update state secara cerdas: hanya jika masih di halaman 1 dan kueri sama
      final currentSearch = ref.read(customerSearchProvider);
      final currentStatus = ref.read(customerStatusFilterProvider);
      final currentStatusKey = currentStatus == 'All'
          ? 'active,pending'
          : currentStatus.toLowerCase();

      if (state.asData?.value.currentPage == 1 &&
          currentSearch == search &&
          currentStatusKey == statusKey) {
        state = AsyncData(
          PaginatedState<Map<String, dynamic>>(
            items: parsed.cast<Map<String, dynamic>>(),
            currentPage: parsedPage,
            lastPage: parsedLastPage,
            isLoadingMore: false,
            isRefreshing: false,
          ),
        );
      }
    } catch (_) {
    } finally {
      ref.read(customerRevalidatingProvider.notifier).set(false);
    }
  }

  // ── Load More (infinity scroll) ─────────────────────────────────────────────

  /// Re-fetch from local Drift DB only (no network call).
  /// Used when sync count changes to reflect newly synced data in UI.
  Future<void> _refetchLocal() async {
    try {
      final search = ref.read(customerSearchProvider);
      final status = ref.read(customerStatusFilterProvider);
      final fresh = await _fetchData(
        page: 1,
        search: search,
        status: status,
        reset: true,
      );
      state = AsyncData(fresh);
    } catch (_) {}
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final search = ref.read(customerSearchProvider);
      final status = ref.read(customerStatusFilterProvider);

      // Cukup baca halaman selanjutnya dari SQLite cache yang secara offline mendayagunakan full pagination lokal!

      final pg = await _fetchData(
        page: current.currentPage + 1,
        search: search,
        status: status,
        reset: false,
      );
      state = AsyncData(pg);
    } catch (e, st) {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false, error: e.toString()),
        );
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<Map<String, dynamic>> updateCustomer({
    required String id,
    String? namaToko,
    String? namaPemilik,
    String? noHpPribadi,
    String? alamatUsaha,
    double? latitude,
    double? longitude,
    String? kotaUsaha,
    String? kecamatanUsaha,
    String? provinsiUsaha,
  }) async {
    final repo = ref.read(customerRepositoryProvider);
    return await repo.updateCustomer(
      id: id,
      namaToko: namaToko,
      namaPemilik: namaPemilik,
      noHpPribadi: noHpPribadi,
      alamatUsaha: alamatUsaha,
      latitude: latitude,
      longitude: longitude,
      kotaUsaha: kotaUsaha,
      kecamatanUsaha: kecamatanUsaha,
      provinsiUsaha: provinsiUsaha,
    );
  }

  Future<Map<String, dynamic>> updateCustomerPhoto({
    required String id,
    required File photo,
  }) async {
    final repo = ref.read(customerRepositoryProvider);
    return await repo.updateCustomerPhoto(id: id, photo: photo);
  }

  Future<void> refresh() async {
    final repo = ref.read(customerRepositoryProvider);
    final status = ref.read(customerStatusFilterProvider);
    final statusKey = status == 'All' ? 'active,pending' : status.toLowerCase();
    await repo.syncCustomersFromApi(
      status: statusKey,
      perPage: -1,
      forceRefresh: true,
    );
    ref.invalidateSelf();
    await future;
  }
}

// ── Detail & Sync Support ────────────────────────────────────────────────────

/// SSOT Stream provider for a single customer by ID.
/// Uses watchAllCustomers() and filters in memory for instant updates.
/// This replaces the old FutureProvider pattern with a reactive stream.
final customerDetailStreamProvider =
    StreamProvider.family<CustomersTableData?, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchAllCustomers().map((customers) {
        return customers
            .where((c) => c.serverId == id || c.id == id)
            .firstOrNull;
      });
    });

/// Provider detail pelanggan spesifik yang reaktif terhadap update di list/sync.
///
/// DEPRECATED: Use customerDetailStreamProvider instead.
/// This FutureProvider is kept for backward compatibility with existing code
/// that hasn't migrated to stream-based patterns.
@Deprecated('Use customerDetailStreamProvider for reactive SSOT updates')
final customerDetailProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, int>((ref, id) async {
      // 1. Listen ke list provider agar jika list di-refresh (misal: SWR), detail juga ikut update
      ref.watch(customerControllerProvider);

      final repo = ref.read(customerRepositoryProvider);
      return await repo.getCustomer(id);
    });

/// Memaksa sinkronisasi satu pelanggan ke server (untuk Pull to Refresh detail)
final customerSyncProvider = FutureProvider.family.autoDispose<void, int>((
  ref,
  id,
) async {
  final repo = ref.read(customerRepositoryProvider);
  final isOnline = await ref.read(connectivityServiceProvider).checkNow();
  if (!isOnline) throw 'Anda sedang offline';

  // Kita fetch dari server dan simpan ke cache
  await repo.getCustomer(id); // getCustomer sudah handle cache save internalnya
  ref.invalidate(customerDetailProvider(id));
});

// ── Freshness Indicator Provider ─────────────────────────────────────────────

/// SSOT: Get last sync time for customers from LastSyncService
final customerUpdateTimeProvider = FutureProvider.autoDispose<DateTime?>((
  ref,
) async {
  // Watch controller to force re-evaluation when data changes/refreshes
  ref.watch(customerControllerProvider);
  final lastSync = ref.read(lastSyncServiceProvider);
  return await lastSync.getLastSync(SyncResource.customers);
});
