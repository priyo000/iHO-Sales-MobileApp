import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/product_repository.dart';
import '../../data/models/product_model.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/paginated_state.dart';

final productControllerProvider =
    AsyncNotifierProvider<ProductController, PaginatedState<Product>>(
      ProductController.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PROVIDERS — Reactive SSOT (Preferred)
// These providers watch Drift table streams and auto-update UI on changes.
// Use these for new StreamBuilder-based UI code.
// ─────────────────────────────────────────────────────────────────────────────

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  return repo.watchAllProducts().asyncMap(
    (list) => _enrichWithUnits(list, db),
  );
});

final productSearchStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, query) {
      final repo = ref.watch(productRepositoryProvider);
      final db = ref.watch(appDatabaseProvider);
      return repo
          .watchSearchProducts(query)
          .asyncMap((list) => _enrichWithUnits(list, db));
    });

final productsByCategoryStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, kategoriId) {
      final repo = ref.watch(productRepositoryProvider);
      final db = ref.watch(appDatabaseProvider);
      return repo
          .watchProductsByCategory(kategoriId)
          .asyncMap((list) => _enrichWithUnits(list, db));
    });

final productsByCategoryAndSearchStreamProvider =
    StreamProvider.family<List<Product>, ({String kategoriId, String query})>((ref, params) {
      final repo = ref.watch(productRepositoryProvider);
      final db = ref.watch(appDatabaseProvider);
      return repo
          .watchProductsByCategoryAndSearch(
            kategoriId: params.kategoriId,
            query: params.query,
          )
          .asyncMap((list) => _enrichWithUnits(list, db));
    });

/// Watch all categories - for category chips
final categoriesStreamProvider = StreamProvider<List<CategoriesTableData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllCategories();
});

Future<List<Product>> _enrichWithUnits(List<ProductsTableData> rows, AppDatabase db) async {
  // Batch-load all units in one query, then group by productId in-memory
  final allUnits = await db.getAllProductUnits();
  final unitsByProduct = <String, List<ProductUnit>>{};
  for (final u in allUnits) {
    (unitsByProduct[u.productId] ??= []).add(ProductUnit(
      id: u.id,
      nama: u.nama,
      konversi: u.konversi,
      hargaJual: u.hargaJual,
      isBase: u.isBase,
    ));
  }

  return rows.map((row) => Product(
    id: row.id.toString(),
    namaProduk: row.namaProduk,
    kodeBarang: row.kodeBarang ?? '',
    sku: row.sku ?? '',
    satuan: row.satuan ?? 'pcs',
    hargaJual: row.hargaJual ?? 0,
    stokTersedia: row.stokTersedia,
    gambarUrl: row.gambarUrl,
    idKategori: row.kategoriId?.toString(),
    kategori: row.kategori,
    units: unitsByProduct[row.id] ?? [],
  )).toList();
}

class ProductController extends AsyncNotifier<PaginatedState<Product>> {
  static const int _perPage = 20;
  bool _isSyncing = false;

  @override
  FutureOr<PaginatedState<Product>> build() async {
    log('[ProductController] 🚀 build() called');
    // SSOT: Instant Load dari Cache + Revalidate Silent
    return await _fetchData(page: 1, reset: true);
  }

  Future<void> _revalidateSilent() async {
    if (_isSyncing) return;
    _isSyncing = true;
    log('[ProductController] 🔄 Starting background revalidation');

    try {
      final repository = ref.read(productRepositoryProvider);

      // Sinkronisasi data ke SQLite secara FULL (per_page=-1)
      await repository.syncProductsFromApi();
      log('[ProductController] ✅ Background sync complete');

      // Jika user masih di halaman 1, kita update UI dengan data segar
      // Ambil data langsung dari repository tanpa memicu revalidasi lagi (break loop)
      if (state.asData?.value.currentPage == 1) {
        final products = await repository.getProducts(
          page: 1,
          perPage: _perPage,
        );
        state = AsyncData(PaginatedState<Product>(
          items: products,
          currentPage: 1,
          lastPage: 1,
          isLoadingMore: false,
          isRefreshing: false,
        ));
      }
    } catch (e) {
      log('[ProductController] ❌ Background revalidation failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _revalidateFull() async {
    if (_isSyncing) return;
    _isSyncing = true;
    log('[ProductController] 🔄 Starting full revalidation');

    try {
      final repository = ref.read(productRepositoryProvider);
      await repository.syncProductsFromApi();
      final fresh = await _fetchData(page: 1, reset: true, triggerSync: false);
      state = AsyncData(fresh);
    } catch (e) {
      log('[ProductController] ❌ Full revalidation failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<PaginatedState<Product>> _fetchData({
    required int page,
    required bool reset,
    bool triggerSync = true,
  }) async {
    final repository = ref.read(productRepositoryProvider);

    // 1. Ambil dari Cache Lokal (Instant UX)
    final products = await repository.getProducts(
      page: page,
      perPage: _perPage,
    );

    // 2. Jika halaman 1 dan bukan dipicu oleh sync itu sendiri, jalankan revalidasi
    if (reset && page == 1 && triggerSync) {
      _revalidateSilent();
    }

    final existingItems = reset
        ? <Product>[]
        : (state.asData?.value.items ?? []);

    return PaginatedState<Product>(
      items: reset ? products : [...existingItems, ...products],
      currentPage: 1,
      lastPage: 1,
      isLoadingMore: false,
      isRefreshing: false,
    );
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(productRepositoryProvider);
    await repo.syncProductsFromApi(forceRefresh: true);
    await _revalidateFull();
  }

  /// Load More (infinity scroll)
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final pg = await _fetchData(page: current.currentPage + 1, reset: false);
      state = AsyncData(pg);
    } catch (e) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }
}
