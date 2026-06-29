import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/last_sync_service.dart';
import 'models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final lastSync = ref.watch(lastSyncServiceProvider);
  return ProductRepository(db, dio, connectivity, lastSync);
});

// ─────────────────────────────────────────────────────────────────────────────
// ProductRepository — Full SSOT with Reactive Streams
//
// Principles:
// 1. UI reads from LOCAL Drift tables (instant, offline-capable)
// 2. Sync downloads from API → saves to Drift tables
// 3. Streams auto-update UI when data changes
// 4. Search/filter uses SQL WHERE, not in-memory filter
// ─────────────────────────────────────────────────────────────────────────────

class ProductRepository {
  final AppDatabase _db;
  final DioClient _dio;
  final ConnectivityService _connectivity;
  final LastSyncService _lastSync;

  ProductRepository(this._db, this._dio, this._connectivity, this._lastSync);

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE STREAMS — For Real-Time UI Updates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all products - auto-updates when table changes
  Stream<List<ProductsTableData>> watchAllProducts() {
    return _db.watchAllProducts();
  }

  /// Watch products by category
  Stream<List<ProductsTableData>> watchProductsByCategory(String kategoriId) {
    return _db.watchProductsByCategory(kategoriId);
  }

  /// Watch products with search - instant SQL filtering, no loading state
  Stream<List<ProductsTableData>> watchSearchProducts(String query) {
    if (query.isEmpty) {
      return _db.watchAllProducts();
    }
    return _db.watchSearchProducts(query);
  }

  /// Watch products by status
  Stream<List<ProductsTableData>> watchProductsByStatus(String status) {
    return _db.watchProductsByStatus(status);
  }

  /// Watch products by category + search combined
  Stream<List<ProductsTableData>> watchProductsByCategoryAndSearch({
    required String kategoriId,
    required String query,
  }) {
    if (query.isEmpty) {
      return _db.watchProductsByCategory(kategoriId);
    }
    return _db.watchProductsByCategoryAndSearch(
      kategoriId: kategoriId,
      query: query,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC — Download from API, Save to Local Drift Table
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync products from server to local Drift table
  /// After sync completes, all stream watchers auto-update
  Future<void> syncProductsFromApi({bool forceRefresh = false}) async {
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) {
      log('[Product SSOT] ❌ Offline, cannot sync');
      return;
    }

    try {
      log('[Product SSOT] 🔄 Starting sync to Drift... (forceRefresh=$forceRefresh)');
      final queryParams = <String, dynamic>{
        'per_page': -1, // Get all
      };

      // Delta sync: only fetch changed since last sync.
      // A force refresh must NOT send `since` — it needs a full snapshot so
      // deleted units/products can be reconciled against current server state.
      if (!forceRefresh) {
        final lastModified = await _lastSync.getLastModified(
          SyncResource.products,
        );
        if (lastModified != null) {
          queryParams['since'] = lastModified;
        }
      }

      log('[Product SSOT] 📡 Calling API: ${ApiConstants.produk} with params: $queryParams');
      // Use extended timeout for bulk download (per_page=-1 can be slow
      // for large product catalogs — default 15s may cause receive timeout).
      final response = await _dio.get(
        ApiConstants.produk,
        queryParameters: queryParams,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      log('[Product SSOT] 📥 Raw response type: ${response.runtimeType}');
      log('[Product SSOT] 📥 Raw response keys: ${response is Map ? response.keys.toList() : 'N/A'}');

      if (response == null) {
        log('[Product SSOT] ❌ Response is null');
        return;
      }

      // Handle different API response structures
      // New backend returns: { data: { produk: [...], kategori: [...] } }
      // Old backend returned: { data: [...] } or just [...]
      List<dynamic> dataList;
      List<dynamic> kategoriList = [];
      if (response is List) {
        dataList = response;
        log('[Product SSOT] 📦 Response is a List with ${dataList.length} items');
      } else if (response is Map) {
        final data = response['data'];
        if (data is Map) {
          // New backend: { data: { produk: [...], kategori: [...] } }
          dataList = (data['produk'] as List?) ?? [];
          kategoriList = (data['kategori'] as List?) ?? [];
          log('[Product SSOT] 📦 Response[data][produk]: ${dataList.length} items, kategori: ${kategoriList.length}');
        } else if (data is List) {
          dataList = data;
          log('[Product SSOT] 📦 Response[data] is a List with ${dataList.length} items');
        } else {
          final fallback = response['products'] ?? response['items'] ?? response['produk'];
          if (fallback is List) {
            dataList = fallback;
          } else {
            dataList = [];
            log('[Product SSOT] ❌ Response[data] is not a List or Map: ${data.runtimeType}');
          }
        }
      } else {
        dataList = [];
        log('[Product SSOT] ❌ Unknown response type: ${response.runtimeType}');
      }

      if (dataList.isEmpty) {
        log('[Product SSOT] ❌ No data to save, aborting');
        return;
      }

      // Log first item to verify structure
      if (dataList.isNotEmpty) {
        log('[Product SSOT] 📝 First item keys: ${(dataList.first as Map).keys.toList()}');
      }

      // Save to Drift table - triggers stream update!
      final productsToSave = dataList.map((json) => Map<String, dynamic>.from(json as Map)).toList();
      await _db.saveProducts(productsToSave);

      // Save product units to product_units_table
      final allUnits = <ProductUnitsTableCompanion>[];
      for (final p in productsToSave) {
        final satuanList = p['satuan_list'] as List?;
        if (satuanList != null) {
          for (final u in satuanList) {
            if (u is Map) {
              allUnits.add(ProductUnitsTableCompanion(
                id: Value(u['id'].toString()),
                productId: Value(p['id'].toString()),
                nama: Value(u['nama']?.toString() ?? ''),
                konversi: Value((u['konversi'] as num?)?.toDouble() ?? 1.0),
                hargaJual: Value((u['harga_jual'] as num?)?.toDouble()),
                isBase: Value(u['is_base'] == true),
              ));
            }
          }
        }
      }
      if (allUnits.isNotEmpty) {
        await _db.saveProductUnits(allUnits);
        log('[Product SSOT] ✅ Saved ${allUnits.length} product units');
      }

      // Reconcile units per product so stale units deleted on the server do
      // not linger locally. Only safe when the response is a full snapshot
      // (forceRefresh / no `since`); a delta response may legitimately omit
      // unchanged products, so we must not delete their units.
      final isFullSnapshot = !queryParams.containsKey('since');
      if (isFullSnapshot) {
        final serverUnitIds = allUnits.map((u) => u.id.value).toSet();
        final productIdsInResponse =
            productsToSave.map((p) => p['id'].toString()).toList();
        for (final productId in productIdsInResponse) {
          await _db.deleteUnitsForProductExcept(productId, serverUnitIds);
        }
      }

      // Save categories to categories_table for ProductCatalogPage chips.
      // Priority: use kategoriList from backend response if available,
      // otherwise extract from product objects.
      final categoriesMap = <String, String>{};

      if (kategoriList.isNotEmpty) {
        for (final cat in kategoriList) {
          if (cat is Map && cat['id'] != null && cat['nama_kategori'] != null) {
            categoriesMap[cat['id'].toString()] = cat['nama_kategori'] as String;
          }
        }
      } else {
        for (final p in productsToSave) {
          final kategoriObj = p['kategori'];
          if (kategoriObj is Map && kategoriObj['id'] != null && kategoriObj['nama_kategori'] != null) {
            categoriesMap[kategoriObj['id'].toString()] = kategoriObj['nama_kategori'] as String;
          } else if (p['id_kategori'] != null && p['nama_kategori'] != null) {
            categoriesMap[p['id_kategori'].toString()] = p['nama_kategori'] as String;
          }
        }
      }

      if (categoriesMap.isNotEmpty) {
        final categoriesToSave = categoriesMap.entries
            .map((e) => {'id': e.key, 'nama_kategori': e.value})
            .toList();
        await _db.saveCategories(categoriesToSave);
        log('[Product SSOT] ✅ Saved ${categoriesToSave.length} categories to categories_table');
      }
    } on DioException catch (e) {
      log('[Product SSOT] ❌ DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        log('[Product SSOT] ❌ Response data: ${e.response?.data}');
      }
    } catch (e, st) {
      log('[Product SSOT] ❌ Sync error: $e');
      log('[Product SSOT] ❌ Stack trace: $st');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY COMPATIBILITY — For code not yet migrated to streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get products with pagination (legacy method, prefer streams)
  Future<List<Product>> getProducts({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    if (search != null && search.isNotEmpty) {
      final results = await _db.searchProducts(search);
      return Future.wait(results.map((row) async {
        final units = await _db.getUnitsForProduct(row.id);
        return _productFromRow(row, units: units);
      }));
    }

    final allProducts = await _db.getAllProducts();
    return Future.wait(allProducts.map((row) async {
      final units = await _db.getUnitsForProduct(row.id);
      return _productFromRow(row, units: units);
    }));
  }

  /// Get single product by ID
  Future<Product?> getProduct(String id) async {
    final row = await _db.getProduct(id);
    if (row == null) return null;
    final units = await _db.getUnitsForProduct(id);
    return _productFromRow(row, units: units);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Product _productFromRow(ProductsTableData row, {List<ProductUnitsTableData>? units}) {
    final productUnits = units
        ?.map((u) => ProductUnit(
              id: u.id,
              nama: u.nama,
              konversi: u.konversi,
              hargaJual: u.hargaJual,
              isBase: u.isBase,
            ))
        .toList() ?? [];

    return Product(
      id: row.id.toString(),
      namaProduk: row.namaProduk,
      kodeBarang: row.kodeBarang ?? '',
      sku: row.sku ?? '',
      satuan: row.satuan ?? 'pcs',
      hargaJual: row.hargaJual ?? 0,
      stokTersedia: row.stokTersedia,
      gambarUrl: row.gambarUrl,
      idKategori: row.kategoriId?.toString(),
      units: productUnits,
    );
  }
}
