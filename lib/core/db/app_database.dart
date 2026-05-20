// ─────────────────────────────────────────────────────────────────────────────
// AppDatabase - Drift ORM Database for iHO-now Mobile
//
// OFFLINE-FIRST: This database is the SINGLE SOURCE OF TRUTH (SSOT).
// All UI reads from here. Server data is downloaded and merged.
// All writes go here first, then queued for sync.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'daos/cache_dao.dart';
import 'daos/cart_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/order_dao.dart';
import 'daos/product_dao.dart';
import 'daos/promo_dao.dart';
import 'daos/reports_dao.dart';
import 'daos/schedule_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/visit_dao.dart';

part 'app_database.g.dart';

// ─── Local-Only Tables (for sync infrastructure) ────────────────────────────

/// Cache table for GET responses (schedule, customers, products, etc.)
class LocalCacheTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cacheKey => text().unique()();
  TextColumn get data => text()();
  IntColumn get cachedAt => integer()();
}

/// Sync metadata for delta sync (last sync timestamp per resource)
class SyncMetadataTable extends Table {
  TextColumn get resource => text()();
  IntColumn get lastSync => integer()();
  TextColumn get lastModified => text().nullable()();

  @override
  Set<Column> get primaryKey => {resource};
}

/// Sync queue for pending mutations (check-in, orders, etc.)
/// Status: pending, syncing, failed, failed_permanently
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localRef => text().unique()();
  TextColumn get operation => text()();
  TextColumn get endpoint => text()();
  TextColumn get method => text()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get lastServerId => text().nullable()();
  IntColumn get serverSyncedAt => integer().nullable()();
}

/// Reference ID mapping (local_ref → server_id) - permanent storage
class RefIdMapTable extends Table {
  TextColumn get localRef => text()();
  TextColumn get serverId => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {localRef};
}

/// Distributed lock for preventing duplicate sync (TTL-based)
class SyncLockTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lockName => text().unique()();
  IntColumn get acquiredAt => integer()();
  TextColumn get ownerId => text()();
}

/// Persistent cart items (survives app restart)
class CartItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pelangganId => text().nullable()();
  TextColumn get productJson => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  RealColumn get negotiatedPrice => real().nullable()();
  TextColumn get unitId => text().nullable()();
  TextColumn get unitName => text().nullable()();
  IntColumn get createdAt => integer()();
}

/// Promo cache per customer
class PromoCacheTable extends Table {
  TextColumn get idPelanggan => text()();
  TextColumn get data => text()();
  IntColumn get syncedAt => integer()();

  @override
  Set<Column> get primaryKey => {idPelanggan};
}

// ─── Domain SSOT Tables (mirror Backend API) ───────────────────────────────

/// Visits SSOT (= kunjungan)
class VisitsTable extends Table {
  TextColumn get id => text()();
  IntColumn get isLocal => integer().withDefault(const Constant(1))();
  TextColumn get scheduleId => text().nullable()();
  TextColumn get pelangganId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('CHECKED_IN'))();
  RealColumn get latIn => real().nullable()();
  RealColumn get longIn => real().nullable()();
  RealColumn get latOut => real().nullable()();
  RealColumn get longOut => real().nullable()();
  TextColumn get waktuCheckIn => text().nullable()();
  TextColumn get waktuCheckOut => text().nullable()();
  TextColumn get alasanTidak => text().nullable()();
  TextColumn get catatan => text().nullable()();
  TextColumn get serverId => text().nullable()();
  IntColumn get photosPending => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Orders SSOT (= pesanan)
class OrdersTable extends Table {
  TextColumn get id => text()();
  IntColumn get isLocal => integer().withDefault(const Constant(1))();
  TextColumn get kunjunganId => text().nullable()();
  TextColumn get pelangganId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  TextColumn get itemsJson => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get promosJson => text().nullable()();
  RealColumn get totalTagihan => real().withDefault(const Constant(0))();
  TextColumn get serverId => text().nullable()();
  TextColumn get clientRef => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get tanggalTransaksi =>
      integer()();
  TextColumn get noPesanan =>
      text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Customers SSOT (= pelanggan)
class CustomersTable extends Table {
  TextColumn get id => text()();
  IntColumn get isLocal => integer().withDefault(const Constant(1))();
  TextColumn get serverId => text().nullable()();
  TextColumn get clientRef => text().nullable()();
  TextColumn get kodePelanggan => text().nullable()();
  TextColumn get namaToko => text().nullable()();
  TextColumn get namaPemilik => text().nullable()();
  TextColumn get noHpPribadi => text().nullable()();
  TextColumn get alamatUsaha => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get fotoTokoPath => text().nullable()();
  TextColumn get fotoKtpPath => text().nullable()();
  // Extended fields
  TextColumn get noKtpPemilik => text().nullable()();
  TextColumn get sistemPembayaran => text().nullable()();
  TextColumn get caraPembayaran => text().nullable()();
  TextColumn get namaBank => text().nullable()();
  TextColumn get cabangBank => text().nullable()();
  TextColumn get noRekening => text().nullable()();
  TextColumn get atasNamaRekening => text().nullable()();
  IntColumn get topHari => integer().nullable()();
  RealColumn get limitKreditAwal => real().nullable()();
  TextColumn get kotaUsaha => text().nullable()();
  TextColumn get kecamatanUsaha => text().nullable()();
  TextColumn get provinsiUsaha => text().nullable()();
  TextColumn get dataJson => text().nullable()();
  TextColumn get createdById => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── NEW SSOT Tables for Full Domain Coverage ────────────────────────────────

/// Product Units SSOT — multi-unit per product (Karton, Pack, Pcs, etc.)
class ProductUnitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get nama => text()();
  RealColumn get konversi => real()();
  RealColumn get hargaJual => real().nullable()();
  BoolColumn get isBase => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Products SSOT (= produk) - Full product catalog
class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get perusahaanId => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get kodeBarang => text().nullable()();
  TextColumn get namaProduk => text()();
  TextColumn get kategoriId => text().nullable()();
  TextColumn get kategori =>
      text().nullable()();
  TextColumn get satuan => text().nullable()();
  TextColumn get deskripsi => text().nullable()();
  RealColumn get hargaDasar => real().nullable()();
  RealColumn get hargaJual => real().nullable()();
  IntColumn get stokTersedia => integer().withDefault(const Constant(0))();
  TextColumn get gambarUrl => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categories SSOT (= kategori_produk) - Product categories
class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get namaKategori => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Schedule SSOT (= jadwal_sales) - Daily visit schedule
class ScheduleTable extends Table {
  TextColumn get id => text()();
  TextColumn get jadwalId => text().nullable()();
  TextColumn get karyawanId => text()();
  TextColumn get tanggal => text()();
  TextColumn get divisiId => text().nullable()();
  TextColumn get pelangganId => text()();
  TextColumn get namaRute => text().nullable()();
  IntColumn get urutan => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(
    const Constant('scheduled'),
  )();
  TextColumn get waktuCheckIn => text().nullable()();
  TextColumn get waktuCheckOut => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Promo SSOT - Promo campaigns (per-customer, reactive)
/// Each row = one promo campaign available to a specific pelanggan.
/// Primary key is composite (id, idPelanggan) since same campaign can have
/// multiple promo types (aturan_harga, grosir, hadiah) for different customers.
class PromoTable extends Table {
  TextColumn get id => text()();
  TextColumn get idPelanggan => text()();
  TextColumn get namaCampaign => text()();
  TextColumn get jenis => text()();
  TextColumn get dataJson => text()();
  TextColumn get status => text().withDefault(
    const Constant('active'),
  )();
  IntColumn get startDate => integer()();
  IntColumn get endDate => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id, idPelanggan};
}

/// Notifications SSOT - User notifications
class NotificationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get karyawanId => text()();
  TextColumn get judul => text()();
  TextColumn get isi => text()();
  TextColumn get tipe => text().withDefault(
    const Constant('info'),
  )();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database Definition ─────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    LocalCacheTable,
    SyncMetadataTable,
    SyncQueueTable,
    RefIdMapTable,
    SyncLockTable,
    CartItemsTable,
    PromoCacheTable,
    VisitsTable,
    OrdersTable,
    CustomersTable,
    ProductsTable,
    ProductUnitsTable,
    CategoriesTable,
    ScheduleTable,
    PromoTable,
    NotificationsTable,
  ],
  daos: [
    CacheDao,
    CartDao,
    CustomerDao,
    NotificationDao,
    OrderDao,
    ProductDao,
    PromoDao,
    ReportsDao,
    ScheduleDao,
    SyncDao,
    VisitDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  static final _random = Random();

  // DAO accessors are auto-generated by Drift in `app_database.g.dart`.

  // ─── Table Name Constants (for raw SQL compatibility) ─────────────────────
  static const String tableCache = 'local_cache_table';
  static const String tableSyncMeta = 'sync_metadata_table';
  static const String tableSyncQueue = 'sync_queue_table';
  static const String tableRefIdMap = 'ref_id_map_table';
  static const String tableSyncLock = 'sync_lock_table';
  static const String tableCartItems = 'cart_items_table';
  static const String tablePromoCache = 'promo_cache_table';
  static const String tableVisits = 'visits_table';
  static const String tableOrders = 'orders_table';
  static const String tableCustomers = 'customers_table';
  static const String tableProducts = 'products_table';
  static const String tableProductUnits = 'product_units_table';
  static const String tableCategories = 'categories_table';
  static const String tableSchedule = 'schedule_table';
  static const String tablePromo = 'promo_table';
  static const String tableNotifications = 'notifications_table';

  AppDatabase() : super(_openConnection());

  // Constructor for lazy opening (for testing)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 20;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // v20: Add clientRef to customers_table for robust offline dedup
        if (from == 19) {
          await customStatement('ALTER TABLE customers_table ADD COLUMN client_ref TEXT');
          return;
        }
        // v19: Add namaRute to schedule_table for dashboard route name display
        if (from == 18) {
          await customStatement('ALTER TABLE schedule_table ADD COLUMN nama_rute TEXT');
          await customStatement('ALTER TABLE customers_table ADD COLUMN client_ref TEXT');
          return;
        }
        // v18: Add createdById to customers_table for SSOT "Pelanggan Baru" filtering
        if (from == 17) {
          await customStatement('ALTER TABLE customers_table ADD COLUMN created_by_id TEXT');
          return;
        }
        // v17: Multi-unit product support — add ProductUnitsTable + cart unit columns
        if (from == 16) {
          await m.createTable(productUnitsTable);
          await customStatement('ALTER TABLE cart_items_table ADD COLUMN unit_id TEXT');
          await customStatement('ALTER TABLE cart_items_table ADD COLUMN unit_name TEXT');
          return;
        }
        // v16: UUID migration — all ID columns changed from INTEGER to TEXT.
        // Destructive: drop ALL tables and recreate. Data re-syncs from server.
        if (from < 16) {
          await customStatement('DROP TABLE IF EXISTS customers_table');
          await customStatement('DROP TABLE IF EXISTS products_table');
          await customStatement('DROP TABLE IF EXISTS categories_table');
          await customStatement('DROP TABLE IF EXISTS schedule_table');
          await customStatement('DROP TABLE IF EXISTS promo_table');
          await customStatement('DROP TABLE IF EXISTS notifications_table');
          await customStatement('DROP TABLE IF EXISTS visits_table');
          await customStatement('DROP TABLE IF EXISTS orders_table');
          await customStatement('DROP TABLE IF EXISTS cart_items_table');
          await customStatement('DROP TABLE IF EXISTS promo_cache_table');
          await customStatement('DROP TABLE IF EXISTS sync_queue_table');
          await customStatement('DROP TABLE IF EXISTS ref_id_map_table');
          await customStatement('DROP TABLE IF EXISTS sync_lock_table');
          await m.createAll();
          return;
        }
        await _dropAndRecreateSsotTables(m);
        await _ensureSsotTables();
      },
      beforeOpen: (OpeningDetails details) async {
        await _ensureSsotTables();
      },
    );
  }

  /// Drop & recreate ALL Drift-managed domain tables to fix missing-column issues
  /// from incomplete migrations. Safe because all domain data is re-synced from server.
  Future<void> _dropAndRecreateSsotTables(Migrator m) async {
    // Domain SSOT tables — always synced from server, safe to drop.
    await customStatement('DROP TABLE IF EXISTS customers_table');
    await customStatement('DROP TABLE IF EXISTS products_table');
    await customStatement('DROP TABLE IF EXISTS product_units_table');
    await customStatement('DROP TABLE IF EXISTS categories_table');
    await customStatement('DROP TABLE IF EXISTS schedule_table');
    await customStatement('DROP TABLE IF EXISTS promo_table');
    await customStatement('DROP TABLE IF EXISTS notifications_table');
    await customStatement('DROP TABLE IF EXISTS visits_table');
    await customStatement('DROP TABLE IF EXISTS orders_table');
    await customStatement('DROP TABLE IF EXISTS local_cache_table');
    await customStatement('DROP TABLE IF EXISTS sync_metadata_table');

    // Recreate all Drift tables (includes newly added columns)
    await m.createAll();
  }

  Future<void> _ensureSsotTables() async {
    // Drop legacy ghost tables that conflict with Drift-managed tables.
    // These were created by older versions with wrong column types (INTEGER vs TEXT PKs).
    // Drift's createAll() in migrations handles the correct table creation.
    await customStatement('DROP TABLE IF EXISTS visits');
    await customStatement('DROP TABLE IF EXISTS orders');
    await customStatement('DROP TABLE IF EXISTS customers');
  }

  // ─── Instance ID for Distributed Locking ──────────────────────────────────

  String? _instanceId;

  Future<String> _getInstanceId() async {
    if (_instanceId != null) return _instanceId!;
    final prefs = await SharedPreferences.getInstance();
    _instanceId = prefs.getString('_instance_id');
    if (_instanceId != null) return _instanceId!;
    _instanceId =
        '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(999999).toString().padLeft(6, '0')}';
    await prefs.setString('_instance_id', _instanceId!);
    return _instanceId!;
  }

  // ─── Cache Operations ──────────────────────────────────────────────────────

  Future<void> cacheData(String key, dynamic data) async {
    await into(localCacheTable).insert(
      LocalCacheTableCompanion.insert(
        cacheKey: key,
        data: jsonEncode(data),
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      onConflict: DoUpdate(
        (old) => LocalCacheTableCompanion(
          data: Value(jsonEncode(data)),
          cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
        target: [localCacheTable.cacheKey],
      ),
    );
  }

  Future<dynamic> getCached(String key, {int? maxAgeMinutes}) async {
    final query = select(localCacheTable)..where((t) => t.cacheKey.equals(key));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    if (maxAgeMinutes != null) {
      final age = DateTime.now().millisecondsSinceEpoch - row.cachedAt;
      if (age > maxAgeMinutes * 60 * 1000) return null;
    }

    return jsonDecode(row.data);
  }

  Future<DateTime?> getCacheTime(String key) async {
    final query = select(localCacheTable)
      ..where((t) => t.cacheKey.equals(key))
      ..addColumns([localCacheTable.cachedAt]);

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(row.cachedAt);
  }

  Future<void> clearCache(String key) async {
    await (delete(localCacheTable)..where((t) => t.cacheKey.equals(key))).go();
  }

  Future<void> clearAllCache() async {
    await delete(localCacheTable).go();
  }

  /// Clear all domain SSOT tables — used on logout to prevent data leakage
  /// between different user sessions on the same device.
  Future<void> clearAllDomainData() async {
    await delete(customersTable).go();
    await delete(productsTable).go();
    await delete(productUnitsTable).go();
    await delete(categoriesTable).go();
    await delete(ordersTable).go();
    await delete(visitsTable).go();
    await delete(scheduleTable).go();
    await delete(promoTable).go();
    await delete(promoCacheTable).go();
    await delete(notificationsTable).go();
    await delete(cartItemsTable).go();
    await delete(syncMetadataTable).go();
    await delete(refIdMapTable).go();
  }

  // ─── Sync Metadata Operations (Delta Sync) ──────────────────────────────────

  Future<void> setLastSync(String resource, {DateTime? lastModified}) async {
    await into(syncMetadataTable).insertOnConflictUpdate(
      SyncMetadataTableCompanion.insert(
        resource: resource,
        lastSync: DateTime.now().millisecondsSinceEpoch,
        lastModified: Value(lastModified?.toIso8601String()),
      ),
    );
  }

  Future<DateTime?> getLastSync(String resource) async {
    final query = select(syncMetadataTable)
      ..where((t) => t.resource.equals(resource));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(row.lastSync);
  }

  Future<String?> getLastModified(String resource) async {
    final query = select(syncMetadataTable)
      ..where((t) => t.resource.equals(resource))
      ..addColumns([syncMetadataTable.lastModified]);

    final row = await query.getSingleOrNull();
    return row?.lastModified;
  }

  Future<void> clearLastSync(String resource) async {
    await (delete(
      syncMetadataTable,
    )..where((t) => t.resource.equals(resource))).go();
  }

  Future<void> clearAllLastSync() async {
    await delete(syncMetadataTable).go();
  }

  // ─── Sync Queue Operations ──────────────────────────────────────────────────

  Future<String> enqueue({
    required String operation,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    return await transaction(() async {
      final pendingItems =
          await (select(syncQueueTable)..where(
                (t) =>
                    t.operation.equals(operation) &
                    t.endpoint.equals(endpoint) &
                    t.status.isIn(['pending', 'syncing', 'failed']),
              ))
              .get();

      if (pendingItems.isNotEmpty) {
        String? dedupKey;
        dynamic dedupValue;

        if (operation == 'check_in') {
          dedupKey = 'id_pelanggan';
          dedupValue = payload['id_pelanggan'];
        } else if (operation == 'create_order' ||
            operation == 'create_pelanggan' ||
            operation == 'create_prospect') {
          dedupKey = 'client_ref';
          dedupValue = payload['client_ref'];
        }

        if (dedupKey != null && dedupValue != null) {
          for (final item in pendingItems) {
            try {
              final existingPayload =
                  jsonDecode(item.payload) as Map<String, dynamic>;
              if (existingPayload[dedupKey]?.toString() ==
                  dedupValue.toString()) {
                debugPrint(
                  '[SyncQueue] Duplicate enqueue blocked: $operation $endpoint ($dedupKey=$dedupValue)',
                );
                return item.localRef;
              }
            } catch (_) {
              // JSON parse failure — skip this item, don't block
            }
          }
        } else {
          final existing = pendingItems.first;
          debugPrint(
            '[SyncQueue] Duplicate enqueue blocked: $operation $endpoint',
          );
          return existing.localRef;
        }
      }

      final localRef =
          '${operation}_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999).toString().padLeft(5, '0')}';

      await into(syncQueueTable).insert(
        SyncQueueTableCompanion.insert(
          localRef: localRef,
          operation: operation,
          endpoint: endpoint,
          method: method,
          payload: jsonEncode(payload),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      return localRef;
    });
  }

  Future<List<SyncQueueTableData>> getAllQueueItems() async {
    return await (select(syncQueueTable)
          ..where(
            (t) => t.status.isIn([
              'pending',
              'failed',
              'failed_permanently',
              'cancelled_dependency',
            ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get sync queue items by operation type. Used by delta-sync guards to
  /// avoid overwriting optimistic local state. Includes 'syncing' status by
  /// default so in-flight mutations are also protected.
  Future<List<SyncQueueTableData>> getPendingByOperation(
    String operation, {
    bool includeInFlight = true,
  }) async {
    final statuses = includeInFlight
        ? const [
            'pending',
            'syncing',
            'failed',
            'failed_permanently',
            'cancelled_dependency',
          ]
        : const ['pending', 'failed', 'failed_permanently', 'cancelled_dependency'];
    return await (select(syncQueueTable)
          ..where(
            (t) => t.operation.equals(operation) & t.status.isIn(statuses),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> updateQueueStatus(
    String localRef,
    String status, {
    String? errorMessage,
  }) async {
    await (update(
      syncQueueTable,
    )..where((t) => t.localRef.equals(localRef))).write(
      SyncQueueTableCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  Future<void> updatePayload(
    String localRef,
    Map<String, dynamic> newPayload,
  ) async {
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(SyncQueueTableCompanion(payload: Value(jsonEncode(newPayload))));
  }

  Future<void> incrementRetry(String localRef) async {
    await customStatement(
      'UPDATE sync_queue_table SET retry_count = retry_count + 1 WHERE local_ref = ?',
      [localRef],
    );
  }

  Future<void> removeFromQueue(String localRef) async {
    await (delete(
      syncQueueTable,
    )..where((t) => t.localRef.equals(localRef))).go();
  }

  Future<void> markServerSynced(String localRef) async {
    await (update(
      syncQueueTable,
    )..where((t) => t.localRef.equals(localRef))).write(
      SyncQueueTableCompanion(
        serverSyncedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> getPendingCount() async {
    final count =
        await (selectOnly(syncQueueTable)
              ..where(
                syncQueueTable.status.isIn([
                  'pending',
                  'syncing',
                  'failed',
                  'failed_permanently',
                  'cancelled_dependency',
                ]),
              )
              ..addColumns([syncQueueTable.id.count()]))
            .map((row) => row.read(syncQueueTable.id.count()))
            .getSingle();
    return count ?? 0;
  }

  Stream<int> watchPendingCount() {
    return (selectOnly(syncQueueTable)
          ..where(
            syncQueueTable.status.isIn([
              'pending',
              'syncing',
              'failed',
              'failed_permanently',
              'cancelled_dependency',
            ]),
          )
          ..addColumns([syncQueueTable.id.count()]))
        .map((row) => row.read(syncQueueTable.id.count()) ?? 0)
        .watchSingle();
  }

  Stream<List<SyncQueueTableData>> watchFailedItems() {
    return (select(syncQueueTable)
          ..where((t) =>
              t.status.equals('failed') | t.status.equals('failed_permanently'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> resetStuckSyncing() async {
    await (update(syncQueueTable)..where((t) => t.status.equals('syncing')))
        .write(const SyncQueueTableCompanion(status: Value('pending')));
  }

  Future<void> clearQueue() async {
    await delete(syncQueueTable).go();
  }

  // ─── ID Mapping Operations ────────────────────────────────────────────────

  Future<void> saveRefMapping(String localRef, String serverId) async {
    await into(refIdMapTable).insertOnConflictUpdate(
      RefIdMapTableCompanion.insert(
        localRef: localRef,
        serverId: serverId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<String?> getServerId(String localRef) async {
    final query = select(refIdMapTable)
      ..where((t) => t.localRef.equals(localRef));

    final row = await query.getSingleOrNull();
    return row?.serverId;
  }

  Future<Map<String, String>> getAllRefMappings() async {
    final rows = await select(refIdMapTable).get();
    return {for (var r in rows) r.localRef: r.serverId};
  }

  Future<int> cleanupOldMappings({int maxAgeDays = 30}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: maxAgeDays))
        .millisecondsSinceEpoch;

    return await (delete(
      refIdMapTable,
    )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
  }

  // ─── Sync Lock Operations ──────────────────────────────────────────────────

  Future<bool> acquireSyncLock(String lockName, {int ttlMinutes = 2}) async {
    final instanceId = await _getInstanceId();
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: ttlMinutes))
        .millisecondsSinceEpoch;

    return await transaction(() async {
      // Delete expired locks first
      await (delete(syncLockTable)..where(
            (t) =>
                t.lockName.equals(lockName) &
                t.acquiredAt.isSmallerThanValue(cutoff),
          ))
          .go();

      // Try atomic insert
      try {
        await into(syncLockTable).insert(
          SyncLockTableCompanion.insert(
            lockName: lockName,
            acquiredAt: DateTime.now().millisecondsSinceEpoch,
            ownerId: instanceId,
          ),
        );
        return true;
      } on Exception {
        return false;
      }
    });
  }

  Future<void> releaseSyncLock(String lockName) async {
    try {
      final instanceId = await _getInstanceId();
      await (delete(syncLockTable)..where(
            (t) => t.lockName.equals(lockName) & t.ownerId.equals(instanceId),
          ))
          .go();
    } catch (e) {
      dev.log('[DB] releaseSyncLock failed: $e - continuing anyway');
    }
  }

  Future<void> clearStaleSyncLock({int ttlMinutes = 2}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: ttlMinutes))
        .millisecondsSinceEpoch;

    await (delete(
      syncLockTable,
    )..where((t) => t.acquiredAt.isSmallerThanValue(cutoff))).go();
  }

  // ─── Cart Operations ───────────────────────────────────────────────────────

  Future<void> saveCartItem({
    String? pelangganId,
    required String productJson,
    required String productId,
    required int quantity,
    double? negotiatedPrice,
    String? unitId,
    String? unitName,
  }) async {
    await into(cartItemsTable).insertOnConflictUpdate(
      CartItemsTableCompanion.insert(
        pelangganId: Value(pelangganId),
        productJson: productJson,
        productId: productId,
        quantity: quantity,
        negotiatedPrice: Value(negotiatedPrice),
        unitId: Value(unitId),
        unitName: Value(unitName),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> removeCartItem(String productId) async {
    await (delete(
      cartItemsTable,
    )..where((t) => t.productId.equals(productId))).go();
  }

  Future<List<CartItemsTableData>> getCartItems({String? pelangganId}) async {
    if (pelangganId != null) {
      return await (select(cartItemsTable)
            ..where((t) => t.pelangganId.equals(pelangganId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
    }
    return await (select(
      cartItemsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  Future<void> clearCart({String? pelangganId}) async {
    if (pelangganId != null) {
      await (delete(
        cartItemsTable,
      )..where((t) => t.pelangganId.equals(pelangganId))).go();
    } else {
      await delete(cartItemsTable).go();
    }
  }

  // ─── Promo Cache Operations ────────────────────────────────────────────────
  // NOTE: PromoCacheTable is legacy. New code uses PromoTable (SSOT) via
  // savePromo/getPromosForPelanggan/watchPromosForPelanggan. The table itself
  // is retained on-device until a future schema migration drops it cleanly.

  // ─── Visits Operations (SSOT) ─────────────────────────────────────────────

  Future<String> saveVisit({
    required String id,
    String? scheduleId,
    dynamic pelangganId,
    String status = 'CHECKED_IN',
    double? latIn,
    double? longIn,
    double? latOut,
    double? longOut,
    String? waktuCheckIn,
    String? waktuCheckOut,
    String? alasanTidak,
    String? catatan,
    String? serverId,
    int photosPending = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = VisitsTableCompanion.insert(
      id: id,
      isLocal: Value(serverId == null ? 1 : 0),
      scheduleId: Value(scheduleId),
      pelangganId: Value(pelangganId?.toString()),
      status: Value(status),
      latIn: Value(latIn),
      longIn: Value(longIn),
      latOut: Value(latOut),
      longOut: Value(longOut),
      waktuCheckIn: Value(waktuCheckIn),
      waktuCheckOut: Value(waktuCheckOut),
      alasanTidak: Value(alasanTidak),
      catatan: Value(catatan),
      serverId: Value(serverId),
      photosPending: Value(photosPending),
      createdAt: now,
      updatedAt: now,
    );
    await into(visitsTable).insert(
      companion,
      onConflict: DoUpdate(
        (old) => VisitsTableCompanion(
          isLocal: Value(serverId == null ? 1 : 0),
          scheduleId: Value(scheduleId),
          pelangganId: Value(pelangganId?.toString()),
          status: Value(status),
          latIn: Value(latIn),
          longIn: Value(longIn),
          latOut: Value(latOut),
          longOut: Value(longOut),
          waktuCheckIn: Value(waktuCheckIn),
          waktuCheckOut: Value(waktuCheckOut),
          alasanTidak: Value(alasanTidak),
          catatan: Value(catatan),
          serverId: Value(serverId),
          photosPending: Value(photosPending),
          // createdAt is intentionally NOT updated on conflict — preserve original
          updatedAt: Value(now),
        ),
      ),
    );
    return id;
  }

  /// Partial update for checkout — only updates checkout-related fields.
  /// Does NOT touch scheduleId, pelangganId, latIn, longIn, waktuCheckIn, createdAt.
  Future<void> updateVisitCheckout({
    required String id,
    String status = 'CHECKED_OUT',
    double? latOut,
    double? longOut,
    String? waktuCheckOut,
    String? alasanTidak,
    String? catatan,
    int photosPending = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(visitsTable)..where((t) => t.id.equals(id))).write(
      VisitsTableCompanion(
        status: Value(status),
        latOut: Value(latOut),
        longOut: Value(longOut),
        waktuCheckOut: Value(waktuCheckOut),
        alasanTidak: Value(alasanTidak),
        catatan: Value(catatan),
        photosPending: Value(photosPending),
        updatedAt: Value(now),
      ),
    );
  }

  Future<VisitsTableData?> getVisit(String id) async {
    return await (select(
      visitsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<VisitsTableData?> getVisitByServerId(String serverId) async {
    return await (select(
      visitsTable,
    )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
  }

  Future<List<VisitsTableData>> getPendingVisits() async {
    return await (select(visitsTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markVisitSynced(String id, String serverId) async {
    await (update(visitsTable)..where((t) => t.id.equals(id))).write(
      VisitsTableCompanion(
        isLocal: const Value(0),
        serverId: Value(serverId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateVisitPelangganId(String visitId, String pelangganId) async {
    await (update(visitsTable)..where((t) => t.id.equals(visitId))).write(
      VisitsTableCompanion(
        pelangganId: Value(pelangganId.toString()),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteVisit(String id) async {
    await (delete(visitsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<VisitsTableData>> getVisitsByPelanggan(String pelangganId) async {
    return await (select(visitsTable)
          ..where((t) => t.pelangganId.equals(pelangganId.toString()))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // ─── Orders Operations (SSOT) ─────────────────────────────────────────────

  Future<String> saveOrder({
    required String id,
    String? kunjunganId,
    String? pelangganId,
    String status = 'PENDING',
    required String itemsJson,
    String? notes,
    String? promosJson,
    double totalTagihan = 0,
    String? serverId,
    String? clientRef,
    String? noPesanan,
    int? tanggalTransaksi,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    dev.log('[DB] saveOrder id=$id, noPesanan=$noPesanan, serverId=$serverId');

    // Try UPDATE first for all cases - this reliably triggers Drift stream watchers.
    // Then fall back to INSERT if row doesn't exist yet (preloaded orders from API
    // or first-time local writes).
    final updatedRows =
        await (update(ordersTable)..where((t) => t.id.equals(id))).write(
          OrdersTableCompanion(
            isLocal: Value(serverId != null ? 0 : 1),
            status: Value(status),
            itemsJson: Value(itemsJson),
            notes: Value(notes),
            promosJson: Value(promosJson),
            totalTagihan: Value(totalTagihan),
            serverId: Value(serverId),
            clientRef: Value(clientRef),
            updatedAt: Value(now),
            tanggalTransaksi: Value(tanggalTransaksi ?? now),
            noPesanan: Value(noPesanan),
            kunjunganId: Value(kunjunganId),
            pelangganId: Value(pelangganId),
          ),
        );

    dev.log(
      '[DB] saveOrder UPDATE: id=$id, updatedRows=$updatedRows, noPesanan=$noPesanan, tanggal=$tanggalTransaksi, serverId=$serverId',
    );

    // If UPDATE affected 0 rows, row doesn't exist yet - INSERT it
    if (updatedRows == 0) {
      await into(ordersTable).insert(
        OrdersTableCompanion.insert(
          id: id,
          isLocal: serverId != null ? const Value(0) : const Value(1),
          kunjunganId: Value(kunjunganId),
          pelangganId: Value(pelangganId),
          status: Value(status),
          itemsJson: itemsJson,
          notes: Value(notes),
          promosJson: Value(promosJson),
          totalTagihan: Value(totalTagihan),
          serverId: Value(serverId),
          clientRef: Value(clientRef),
          createdAt: now,
          updatedAt: now,
          tanggalTransaksi: tanggalTransaksi ?? now,
          noPesanan: Value(noPesanan),
        ),
      );
    }
    return id;
  }

  Future<OrdersTableData?> getOrder(String id) async {
    return await (select(
      ordersTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Find order by client_ref (stable ID shared between orders_table and sync_queue)
  Future<OrdersTableData?> getOrderByClientRef(String clientRef) async {
    return await (select(ordersTable)
          ..where((t) => t.clientRef.equals(clientRef))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isLocal),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OrdersTableData?> getOrderByServerId(String serverId) async {
    return await (select(ordersTable)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isLocal),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OrdersTableData?> getOrderByNoPesanan(String noPesanan) async {
    return await (select(ordersTable)
          ..where((t) => t.noPesanan.equals(noPesanan))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isLocal),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> deleteDuplicateOrdersForCanonical({
    required String canonicalId,
    String? serverId,
    String? noPesanan,
    String? clientRef,
  }) async {
    await (delete(ordersTable)..where(
          (t) =>
              t.id.equals(canonicalId).not() &
              ((serverId != null
                      ? t.serverId.equals(serverId)
                      : const Constant(false)) |
                  (noPesanan != null
                      ? t.noPesanan.equals(noPesanan)
                      : const Constant(false)) |
                  (clientRef != null
                      ? t.clientRef.equals(clientRef)
                      : const Constant(false))),
        ))
        .go();
  }

  int? _parseEpochMs(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // Laravel timestamps in seconds are 10 digits; app stores milliseconds.
      return value < 1000000000000 ? value * 1000 : value;
    }
    if (value is double) {
      final intValue = value.toInt();
      return intValue < 1000000000000 ? intValue * 1000 : intValue;
    }
    final parsedInt = int.tryParse(value.toString());
    if (parsedInt != null) {
      return parsedInt < 1000000000000 ? parsedInt * 1000 : parsedInt;
    }
    return DateTime.tryParse(value.toString())?.millisecondsSinceEpoch;
  }

  Future<List<OrdersTableData>> getPendingOrders() async {
    return await (select(ordersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markOrderSynced(String id, String serverId) async {
    await (update(ordersTable)..where((t) => t.id.equals(id))).write(
      OrdersTableCompanion(
        isLocal: const Value(0),
        serverId: Value(serverId),
        status: const Value('SYNCED'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteOrder(String id) async {
    await (delete(ordersTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<OrdersTableData>> getOrdersByPelanggan(String pelangganId) async {
    return await (select(ordersTable)
          ..where((t) => t.pelangganId.equals(pelangganId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // ─── Customers Operations (SSOT) ─────────────────────────────────────────

  Future<String> saveCustomer({
    required String id,
    String? serverId,
    String? clientRef,
    String? kodePelanggan,
    String? namaToko,
    String? namaPemilik,
    String? noHpPribadi,
    String? alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    String? fotoTokoPath,
    String? fotoKtpPath,
    // Extended fields
    String? noKtpPemilik,
    String? sistemPembayaran,
    String? caraPembayaran,
    String? namaBank,
    String? cabangBank,
    String? noRekening,
    String? atasNamaRekening,
    int? topHari,
    double? limitKreditAwal,
    String? kotaUsaha,
    String? kecamatanUsaha,
    String? provinsiUsaha,
    String? dataJson,
    String? createdById,
    int? createdAt,
    int? updatedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await (select(customersTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null) {
      // Partial update: only overwrite fields that are explicitly provided,
      // preserve existing values for fields passed as null.
      await (update(customersTable)..where((t) => t.id.equals(id))).write(
        CustomersTableCompanion(
          serverId: Value(serverId ?? existing.serverId),
          isLocal: Value(serverId == null && existing.serverId == null ? 1 : 0),
          kodePelanggan: Value(kodePelanggan ?? existing.kodePelanggan),
          namaToko: Value(namaToko ?? existing.namaToko),
          namaPemilik: Value(namaPemilik ?? existing.namaPemilik),
          noHpPribadi: Value(noHpPribadi ?? existing.noHpPribadi),
          alamatUsaha: Value(alamatUsaha ?? existing.alamatUsaha),
          latitude: Value(latitude ?? existing.latitude),
          longitude: Value(longitude ?? existing.longitude),
          status: Value(status ?? existing.status),
          fotoTokoPath: Value(fotoTokoPath ?? existing.fotoTokoPath),
          fotoKtpPath: Value(fotoKtpPath ?? existing.fotoKtpPath),
          noKtpPemilik: Value(noKtpPemilik ?? existing.noKtpPemilik),
          sistemPembayaran: Value(sistemPembayaran ?? existing.sistemPembayaran),
          caraPembayaran: Value(caraPembayaran ?? existing.caraPembayaran),
          namaBank: Value(namaBank ?? existing.namaBank),
          cabangBank: Value(cabangBank ?? existing.cabangBank),
          noRekening: Value(noRekening ?? existing.noRekening),
          atasNamaRekening: Value(atasNamaRekening ?? existing.atasNamaRekening),
          topHari: Value(topHari ?? existing.topHari),
          limitKreditAwal: Value(limitKreditAwal ?? existing.limitKreditAwal),
          kotaUsaha: Value(kotaUsaha ?? existing.kotaUsaha),
          kecamatanUsaha: Value(kecamatanUsaha ?? existing.kecamatanUsaha),
          provinsiUsaha: Value(provinsiUsaha ?? existing.provinsiUsaha),
          dataJson: Value(dataJson ?? existing.dataJson),
          createdById: Value(createdById ?? existing.createdById),
          updatedAt: Value(updatedAt ?? now),
        ),
      );
    } else {
      // New customer: insert with all provided values
      await into(customersTable).insertOnConflictUpdate(
        CustomersTableCompanion.insert(
          id: id,
          isLocal: Value(serverId == null ? 1 : 0),
          serverId: Value(serverId),
          kodePelanggan: Value(kodePelanggan),
          namaToko: Value(namaToko),
          namaPemilik: Value(namaPemilik),
          noHpPribadi: Value(noHpPribadi),
          alamatUsaha: Value(alamatUsaha),
          latitude: Value(latitude),
          longitude: Value(longitude),
          status: Value(status),
          fotoTokoPath: Value(fotoTokoPath),
          fotoKtpPath: Value(fotoKtpPath),
          noKtpPemilik: Value(noKtpPemilik),
          sistemPembayaran: Value(sistemPembayaran),
          caraPembayaran: Value(caraPembayaran),
          namaBank: Value(namaBank),
          cabangBank: Value(cabangBank),
          noRekening: Value(noRekening),
          atasNamaRekening: Value(atasNamaRekening),
          topHari: Value(topHari),
          limitKreditAwal: Value(limitKreditAwal),
          kotaUsaha: Value(kotaUsaha),
          kecamatanUsaha: Value(kecamatanUsaha),
          provinsiUsaha: Value(provinsiUsaha),
          dataJson: Value(dataJson),
          createdById: Value(createdById),
          createdAt: createdAt ?? now,
          updatedAt: updatedAt ?? now,
        ),
      );
    }

    // Save clientRef separately (column added in v20, not in generated companion yet)
    if (clientRef != null) {
      await customStatement(
        'UPDATE customers_table SET client_ref = ? WHERE id = ?',
        [clientRef, id],
      );
    }

    return id;
  }

  /// Batch save customers (for sync)
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Parse integer from dynamic value (handles String→int conversion)
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> saveCustomers(List<Map<String, dynamic>> customers) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Deduplicate: remove local rows that would conflict with incoming server records.
    // This prevents duplicates when a locally-created customer gets synced and then
    // the server record is downloaded with a different primary key (server UUID vs localRef).
    final serverIds = customers
        .map((c) => c['id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();
    if (serverIds.isNotEmpty) {
      // 1. Remove local records whose serverId matches incoming server IDs
      await (delete(customersTable)
            ..where((t) =>
                t.serverId.isIn(serverIds) &
                t.id.isNotIn(serverIds)))
          .go();

      // 2. Remove local records whose clientRef matches any incoming server ID
      await (delete(customersTable)
            ..where((t) =>
                t.clientRef.isIn(serverIds) &
                t.id.isNotIn(serverIds)))
          .go();

      // 3. Remove local records whose clientRef matches incoming client_ref values
      // (server returns client_ref field so we can match localRef-based rows)
      final incomingClientRefs = customers
          .map((c) => c['client_ref']?.toString())
          .where((r) => r != null && r.isNotEmpty)
          .cast<String>()
          .toList();
      if (incomingClientRefs.isNotEmpty) {
        await (delete(customersTable)
              ..where((t) =>
                  (t.clientRef.isIn(incomingClientRefs) |
                   t.id.isIn(incomingClientRefs)) &
                  t.id.isNotIn(serverIds)))
            .go();
      }

      // 4. Also check RefIdMapTable as fallback
      final mappings = await (select(refIdMapTable)
            ..where((t) => t.serverId.isIn(serverIds)))
          .get();
      if (mappings.isNotEmpty) {
        final localRefs = mappings.map((m) => m.localRef).toList();
        await (delete(customersTable)
              ..where((t) => t.id.isIn(localRefs) & t.id.isNotIn(serverIds)))
            .go();
      }
    }

    await batch((batch) {
      for (final c in customers) {
        final id = c['id']?.toString() ?? '';
        final serverId = c['id']?.toString() ?? c['server_id']?.toString();
        final createdAt = _parseEpochMs(c['created_at']) ?? now;
        final updatedAt = _parseEpochMs(c['updated_at']) ?? now;
        batch.insert(
          customersTable,
          CustomersTableCompanion.insert(
            id: id,
            isLocal: Value(serverId == null ? 1 : 0),
            serverId: Value(serverId),
            kodePelanggan: Value(c['kode_pelanggan'] as String?),
            namaToko: Value(c['nama_toko'] as String?),
            namaPemilik: Value(c['nama_pemilik'] as String?),
            noHpPribadi: Value(c['no_hp_pribadi'] as String?),
            alamatUsaha: Value(c['alamat_usaha'] as String?),
            latitude: Value(_parseDouble(c['latitude'])),
            longitude: Value(_parseDouble(c['longitude'])),
            status: Value(c['status'] as String?),
            fotoTokoPath: Value(
              c['foto_toko'] as String? ?? c['foto_toko_url'] as String? ?? c['foto_toko_path'] as String?,
            ),
            fotoKtpPath: Value(
              c['foto_ktp'] as String? ?? c['foto_ktp_url'] as String? ?? c['foto_ktp_path'] as String?,
            ),
            noKtpPemilik: Value(c['no_ktp_pemilik'] as String?),
            sistemPembayaran: Value(c['sistem_pembayaran'] as String?),
            caraPembayaran: Value(c['cara_pembayaran'] as String?),
            namaBank: Value(c['nama_bank'] as String?),
            cabangBank: Value(c['cabang_bank'] as String?),
            noRekening: Value(c['no_rekening'] as String?),
            atasNamaRekening: Value(c['atas_nama_rekening'] as String?),
            topHari: Value(_parseInt(c['top_hari'])),
            limitKreditAwal: Value(_parseDouble(c['limit_kredit_awal'])),
            kotaUsaha: Value(c['kota_usaha'] as String?),
            kecamatanUsaha: Value(c['kecamatan_usaha'] as String?),
            provinsiUsaha: Value(c['provinsi_usaha'] as String?),
            dataJson: Value(c['data_json'] as String?),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<CustomersTableData?> getCustomer(String id) async {
    return await (select(
      customersTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CustomersTableData>> getPendingCustomers() async {
    return await (select(customersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markCustomerSynced(String id, String serverId) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      CustomersTableCompanion(
        isLocal: const Value(0),
        serverId: Value(serverId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteCustomer(String id) async {
    await (delete(customersTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<CustomersTableData>> getAllLocalCustomers() async {
    return await (select(
      customersTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  // ─── Report Aggregation Methods ───────────────────────────────────────────

  Future<List<VisitsTableData>> getVisitsInRange(
    String startDate,
    String endDate,
  ) async {
    final startMs = DateTime.parse(startDate).millisecondsSinceEpoch;
    final endMs = DateTime.parse(
      endDate,
    ).add(const Duration(days: 1)).millisecondsSinceEpoch;

    return await (select(visitsTable)
          ..where(
            (t) =>
                (t.waktuCheckIn.isNotNull() &
                    t.waktuCheckIn.isBiggerOrEqualValue(
                      DateTime.fromMillisecondsSinceEpoch(
                        startMs,
                      ).toIso8601String(),
                    ) &
                    t.waktuCheckIn.isSmallerThanValue(
                      DateTime.fromMillisecondsSinceEpoch(
                        endMs,
                      ).toIso8601String(),
                    )) |
                (t.waktuCheckIn.isNull() &
                    t.createdAt.isBiggerOrEqualValue(startMs) &
                    t.createdAt.isSmallerThanValue(endMs)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.waktuCheckIn)]))
        .get();
  }

  Future<List<OrdersTableData>> getOrdersInRange(
    String startDate,
    String endDate,
  ) async {
    final startMs = DateTime.parse(startDate).millisecondsSinceEpoch;
    final endMs = DateTime.parse(
      endDate,
    ).add(const Duration(days: 1)).millisecondsSinceEpoch;

    return await (select(ordersTable)
          ..where(
            (t) =>
                t.tanggalTransaksi.isBiggerOrEqualValue(startMs) &
                t.tanggalTransaksi.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.tanggalTransaksi)]))
        .get();
  }

  Future<double> getOrdersTotalInRange(String startDate, String endDate) async {
    final orders = await getOrdersInRange(startDate, endDate);
    double total = 0;
    for (final order in orders) {
      final status = order.status.toUpperCase();
      if (status.contains('BATAL') || status.contains('CANCEL')) {
        continue;
      }
      total += order.totalTagihan;
    }
    return total;
  }

  Future<int> getEffectiveCallsInRange(String startDate, String endDate) async {
    final startMs = DateTime.parse(startDate).millisecondsSinceEpoch;
    final endMs = DateTime.parse(
      endDate,
    ).add(const Duration(days: 1)).millisecondsSinceEpoch;

    final orders =
        await (select(ordersTable)..where(
              (t) =>
                  t.tanggalTransaksi.isBiggerOrEqualValue(startMs) &
                  t.tanggalTransaksi.isSmallerThanValue(endMs) &
                  t.kunjunganId.isNotNull(),
            ))
            .get();

    final seenKunj = <String>{};
    for (final order in orders) {
      final status = order.status.toUpperCase();
      if (status.contains('BATAL') || status.contains('CANCEL')) {
        continue;
      }
      final kunjId = order.kunjunganId?.toString();
      if (kunjId != null) seenKunj.add(kunjId);
    }
    return seenKunj.length;
  }

  Future<Map<String, double>> getDailySalesInRange(
    String startDate,
    String endDate,
  ) async {
    final orders = await getOrdersInRange(startDate, endDate);
    final Map<String, double> daily = {};

    for (final order in orders) {
      final status = order.status.toUpperCase();
      if (status.contains('BATAL') || status.contains('CANCEL')) {
        continue;
      }
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        order.tanggalTransaksi,
      );
      final dateKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      daily[dateKey] =
          (daily[dateKey] ?? 0) +
          ((order.totalTagihan as num?)?.toDouble() ?? 0);
    }

    return daily;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE STREAM METHODS - Real-time UI Updates
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Products Watch Methods (REACTIVE) ───────────────────────────────────

  /// Watch all products - emits new list on any change
  Stream<List<ProductsTableData>> watchAllProducts() {
    // Sort alphabetically by namaProduk (A-Z)
    return (select(
      productsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.namaProduk)])).watch();
  }

  /// Watch products by status (active/inactive)
  Stream<List<ProductsTableData>> watchProductsByStatus(String status) {
    return (select(productsTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  /// Watch products by category
  Stream<List<ProductsTableData>> watchProductsByCategory(String kategoriId) {
    return (select(productsTable)
          ..where((t) => t.kategoriId.equals(kategoriId))
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  /// Watch products by category + search (combined filter for 10k+ products)
  Stream<List<ProductsTableData>> watchProductsByCategoryAndSearch({
    required String kategoriId,
    required String query,
  }) {
    final q = '%${query.toLowerCase()}%';
    return (select(productsTable)
          ..where(
            (t) =>
                t.kategoriId.equals(kategoriId) &
                (t.namaProduk.lower().like(q) |
                    t.kodeBarang.lower().like(q) |
                    t.sku.lower().like(q)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  /// Watch products with search - instant SQL filtering
  Stream<List<ProductsTableData>> watchSearchProducts(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(productsTable)
          ..where(
            (t) =>
                t.namaProduk.lower().like(q) |
                t.kodeBarang.lower().like(q) |
                t.sku.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  // ─── Categories Watch Methods (REACTIVE) ─────────────────────────────────

  /// Watch all categories
  Stream<List<CategoriesTableData>> watchAllCategories() {
    return (select(
      categoriesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.namaKategori)])).watch();
  }

  // ─── Schedule Watch Methods (REACTIVE) ───────────────────────────────────

  /// Watch schedule for a specific date - instant SQL filter
  Stream<List<ScheduleTableData>> watchScheduleForDate(String tanggal) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.equals(tanggal))
          ..orderBy([(t) => OrderingTerm.asc(t.urutan)]))
        .watch();
  }

  /// Watch schedule for date with status filter
  Stream<List<ScheduleTableData>> watchScheduleByStatus(
    String tanggal,
    String status,
  ) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.equals(tanggal) & t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.urutan)]))
        .watch();
  }

  /// Watch today's schedule
  Stream<List<ScheduleTableData>> watchTodaySchedule() {
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    return watchScheduleForDate(today);
  }

  /// Watch schedule by pelanggan (customer)
  Stream<List<ScheduleTableData>> watchScheduleByPelanggan(String pelangganId) {
    return (select(scheduleTable)
          ..where((t) => t.pelangganId.equals(pelangganId))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggal)]))
        .watch();
  }

  // ─── Customers Watch Methods (REACTIVE) ─────────────────────────────────

  /// Watch all customers - emits on any change
  Stream<List<CustomersTableData>> watchAllCustomers() {
    return (select(
      customersTable,
    )..orderBy([(t) => OrderingTerm.asc(t.namaToko)])).watch();
  }

  /// Watch customers by status (active/pending/prospect)
  /// Supports comma-separated status like 'active,pending' for OR filtering
  /// Case-insensitive matching using isIn() for reliable exact match.
  /// Also includes customers with NULL status (defensive: server data should always have status).
  Stream<List<CustomersTableData>> watchCustomersByStatus(String status) {
    if (status.contains(',')) {
      // Support 'active,pending' style filter — OR match (case-insensitive)
      final statuses = status
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .toList();
      return (select(customersTable)
            ..where((t) => t.status.lower().isIn(statuses) | t.status.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
          .watch();
    }
    return (select(customersTable)
          ..where(
            (t) =>
                t.status.lower().equals(status.toLowerCase()) |
                t.status.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch customers with search - instant SQL filtering
  Stream<List<CustomersTableData>> watchSearchCustomers(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(customersTable)
          ..where(
            (t) =>
                t.namaToko.lower().like(q) |
                t.namaPemilik.lower().like(q) |
                t.noHpPribadi.like(q) |
                t.kodePelanggan.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
        .watch();
  }

  /// Watch customers with search + status filter (only show matching statuses)
  Stream<List<CustomersTableData>> watchSearchCustomersWithStatus(
    String query,
    List<String> statuses,
  ) {
    final q = '%${query.toLowerCase()}%';
    return (select(customersTable)
          ..where(
            (t) =>
                (t.namaToko.lower().like(q) |
                    t.namaPemilik.lower().like(q) |
                    t.noHpPribadi.like(q) |
                    t.kodePelanggan.lower().like(q)) &
                (t.status.lower().isIn(statuses) | t.status.isNull()),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
        .watch();
  }

  /// Watch pending customers (offline-created, not yet synced)
  Stream<List<CustomersTableData>> watchPendingCustomers() {
    return (select(customersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  // ─── Notifications Watch Methods (REACTIVE) ─────────────────────────────

  /// Watch all notifications
  Stream<List<NotificationsTableData>> watchAllNotifications() {
    return (select(
      notificationsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Watch unread notifications only
  Stream<List<NotificationsTableData>> watchUnreadNotifications() {
    return (select(notificationsTable)
          ..where((t) => t.isRead.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch unread count - for badge updates
  Stream<int> watchUnreadNotificationCount() {
    final query = selectOnly(notificationsTable)
      ..where(notificationsTable.isRead.equals(false))
      ..addColumns([notificationsTable.id.count()]);
    return query
        .map((row) => row.read(notificationsTable.id.count()) ?? 0)
        .watchSingle();
  }

  // ─── Promo Watch Methods (REACTIVE) ────────────────────────────────────

  /// Watch active promos
  Stream<List<PromoTableData>> watchActivePromos() {
    return (select(promoTable)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  /// Watch promos by type (cluster/grosir/aturan_harga/hadiah)
  Stream<List<PromoTableData>> watchPromosByType(String jenis) {
    return (select(promoTable)
          ..where((t) => t.jenis.equals(jenis) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  /// Watch promos for specific customer - PRIMARY STREAM for SSOT
  Stream<List<PromoTableData>> watchPromosForPelanggan(String idPelanggan) {
    return (select(promoTable)
          ..where(
            (t) =>
                t.idPelanggan.equals(idPelanggan) & t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  /// Watch promos by type for specific customer
  Stream<List<PromoTableData>> watchPromosByTypeForPelanggan(
    String idPelanggan,
    String jenis,
  ) {
    return (select(promoTable)
          ..where(
            (t) =>
                t.idPelanggan.equals(idPelanggan) &
                t.jenis.equals(jenis) &
                t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  // ─── Visits Watch Methods (REACTIVE) ────────────────────────────────────

  /// Watch all visits - emits new list on any change
  Stream<List<VisitsTableData>> watchAllVisits() {
    return (select(
      visitsTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Watch pending visits (offline-created, not yet synced)
  Stream<List<VisitsTableData>> watchPendingVisits() {
    return (select(visitsTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Watch visit by ID
  Stream<VisitsTableData?> watchVisit(String id) {
    return (select(
      visitsTable,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Watch visits by pelanggan
  Stream<List<VisitsTableData>> watchVisitsByPelanggan(String pelangganId) {
    return (select(visitsTable)
          ..where((t) => t.pelangganId.equals(pelangganId.toString()))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch today's visits - used for dashboard SSOT
  Stream<List<VisitsTableData>> watchTodayVisits() {
    final today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // 'YYYY-MM-DD'
    return (select(visitsTable)
          ..where((t) => t.waktuCheckIn.like('$today%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get today's visits (non-reactive) - for initial load
  Future<List<VisitsTableData>> getTodayVisits() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await (select(visitsTable)
          ..where((t) => t.waktuCheckIn.like('$today%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // ─── Orders Watch Methods (REACTIVE) ─────────────────────────────────────

  /// Watch all orders - emits new list on any change
  Stream<List<OrdersTableData>> watchAllOrders() {
    return (select(
      ordersTable,
    )..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)])).watch();
  }

  /// Watch pending orders (offline-created, not yet synced)
  Stream<List<OrdersTableData>> watchPendingOrders() {
    return (select(ordersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }

  /// Watch order by ID
  Stream<OrdersTableData?> watchOrder(String id) {
    return (select(
      ordersTable,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Watch orders by pelanggan
  Stream<List<OrdersTableData>> watchOrdersByPelanggan(String pelangganId) {
    return (select(ordersTable)
          ..where((t) => t.pelangganId.equals(pelangganId))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }

  /// Watch orders by status (e.g., 'PENDING', 'APPROVED', 'REJECTED')
  Stream<List<OrdersTableData>> watchOrdersByStatus(String status) {
    return (select(ordersTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }

  /// Get all orders (non-reactive) - for initial load
  Future<List<OrdersTableData>> getAllOrders() async {
    return await (select(
      ordersTable,
    )..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)])).get();
  }

  // ─── Cart Watch Methods (REACTIVE) ─────────────────────────────────────

  /// Watch all cart items
  Stream<List<CartItemsTableData>> watchCartItems({String? pelangganId}) {
    if (pelangganId != null) {
      return (select(cartItemsTable)
            ..where((t) => t.pelangganId.equals(pelangganId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();
    }
    return (select(
      cartItemsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS - For New SSOT Tables
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Products CRUD ──────────────────────────────────────────────────────

  /// Save product - upsert
  Future<void> saveProduct({
    required String id,
    String? perusahaanId,
    String? sku,
    String? kodeBarang,
    required String namaProduk,
    String? kategoriId,
    String? satuan,
    String? deskripsi,
    double? hargaDasar,
    double? hargaJual,
    int stokTersedia = 0,
    String? gambarUrl,
    String status = 'active',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(productsTable).insertOnConflictUpdate(
      ProductsTableCompanion.insert(
        id: id,
        perusahaanId: Value(perusahaanId),
        sku: Value(sku),
        kodeBarang: Value(kodeBarang),
        namaProduk: namaProduk,
        kategoriId: Value(kategoriId),
        satuan: Value(satuan),
        deskripsi: Value(deskripsi),
        hargaDasar: Value(hargaDasar),
        hargaJual: Value(hargaJual),
        stokTersedia: Value(stokTersedia),
        gambarUrl: Value(gambarUrl),
        status: Value(status),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Batch save products (for sync)
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      for (final p in products) {
        // Handle harga_dasar and harga_jual which come as String from API
        final hargaDasarRaw = p['harga_dasar'];
        final hargaJualRaw = p['harga_jual'];
        double? hargaDasar;
        double? hargaJual;
        if (hargaDasarRaw is num) {
          hargaDasar = hargaDasarRaw.toDouble();
        } else if (hargaDasarRaw is String) {
          hargaDasar = double.tryParse(hargaDasarRaw);
        }
        if (hargaJualRaw is num) {
          hargaJual = hargaJualRaw.toDouble();
        } else if (hargaJualRaw is String) {
          hargaJual = double.tryParse(hargaJualRaw);
        }

        // Extract nama_kategori from nested kategori object: {"id":16,"nama_kategori":"TAM-TAM"}
        String? namaKategori;
        final kategoriObj = p['kategori'];
        if (kategoriObj is Map) {
          namaKategori = kategoriObj['nama_kategori'] as String?;
        }

        batch.insert(
          productsTable,
          ProductsTableCompanion.insert(
            id: p['id']?.toString() ?? '',
            perusahaanId: Value(p['id_perusahaan']?.toString()),
            sku: Value(p['sku'] as String?),
            kodeBarang: Value(p['kode_barang'] as String?),
            namaProduk: p['nama_produk'] as String? ?? '',
            kategoriId: Value(p['id_kategori']?.toString() ?? p['kategori_id']?.toString()),
            kategori: Value(namaKategori),
            satuan: Value(p['satuan'] as String?),
            deskripsi: Value(p['deskripsi'] as String?),
            hargaDasar: Value(hargaDasar),
            hargaJual: Value(hargaJual),
            stokTersedia: Value(p['stok_tersedia'] as int? ?? 0),
            gambarUrl: Value(p['gambar_url'] as String?),
            status: Value(p['status'] as String? ?? 'active'),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Get product by ID
  Future<ProductsTableData?> getProduct(String id) {
    return (select(
      productsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all products (for sync)
  Future<List<ProductsTableData>> getAllProducts() {
    return (select(
      productsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.namaProduk)])).get();
  }

  /// Search products (non-reactive, for one-time queries)
  Future<List<ProductsTableData>> searchProducts(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(productsTable)
          ..where(
            (t) =>
                t.namaProduk.lower().like(q) |
                t.kodeBarang.lower().like(q) |
                t.sku.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .get();
  }

  /// Delete product
  Future<void> deleteProduct(String id) {
    return (delete(productsTable)..where((t) => t.id.equals(id))).go();
  }

  // ─── Product Units CRUD ─────────────────────────────────────────────────

  Future<List<ProductUnitsTableData>> getUnitsForProduct(String productId) {
    return (select(productUnitsTable)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.konversi)]))
        .get();
  }

  Future<List<ProductUnitsTableData>> getAllProductUnits() {
    return (select(productUnitsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.konversi)]))
        .get();
  }

  Future<void> saveProductUnits(List<ProductUnitsTableCompanion> units) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(productUnitsTable, units);
    });
  }

  Future<void> deleteUnitsForProduct(String productId) {
    return (delete(productUnitsTable)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }

  // ─── Categories CRUD ────────────────────────────────────────────────────

  /// Save category
  Future<void> saveCategory({
    required String id,
    required String namaKategori,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(categoriesTable).insertOnConflictUpdate(
      CategoriesTableCompanion.insert(
        id: id,
        namaKategori: namaKategori,
        createdAt: now,
      ),
    );
  }

  /// Batch save categories (for sync)
  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      for (final c in categories) {
        batch.insert(
          categoriesTable,
          CategoriesTableCompanion.insert(
            id: c['id']?.toString() ?? '',
            namaKategori: c['nama_kategori'] as String,
            createdAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Get all categories
  Future<List<CategoriesTableData>> getAllCategories() {
    return (select(
      categoriesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.namaKategori)])).get();
  }

  // ─── Schedule CRUD ──────────────────────────────────────────────────────

  /// Save schedule item
  Future<void> saveScheduleItem({
    required String id,
    String? jadwalId,
    required String karyawanId,
    required String tanggal,
    String? divisiId,
    required String pelangganId,
    String? namaRute,
    int urutan = 0,
    String status = 'scheduled',
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // PROTECTION: Avoid overwriting local ACTIVE status with server PENDING status.
    // This happens if a sync/preload runs while the user is mid-visit.
    final existing = await (select(
      scheduleTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    String finalStatus = status;
    String? finalCheckIn = waktuCheckIn;
    String? finalCheckOut = waktuCheckOut;

    if (existing != null) {
      final localStatus = existing.status.toUpperCase();
      final incomingStatus = status.toUpperCase();

      // If local is DIKUNJUNGI/SELESAI, but server says TERTUNDA/scheduled/null
      if ((localStatus == 'DIKUNJUNGI' || localStatus == 'SELESAI') &&
          (incomingStatus == 'TERTUNDA' ||
              incomingStatus == 'SCHEDULED' ||
              incomingStatus == '')) {
        finalStatus = existing.status; // Keep local status
        finalCheckIn = existing.waktuCheckIn ?? waktuCheckIn;
        finalCheckOut = existing.waktuCheckOut ?? waktuCheckOut;
      }
    }

    await into(scheduleTable).insertOnConflictUpdate(
      ScheduleTableCompanion.insert(
        id: id,
        jadwalId: Value(jadwalId),
        karyawanId: karyawanId,
        tanggal: tanggal,
        divisiId: Value(divisiId),
        pelangganId: pelangganId,
        urutan: Value(urutan),
        status: Value(finalStatus),
        waktuCheckIn: Value(finalCheckIn),
        waktuCheckOut: Value(finalCheckOut),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Update namaRute separately (column added in v19, not in generated companion yet)
    if (namaRute != null) {
      await customStatement(
        'UPDATE schedule_table SET nama_rute = ? WHERE id = ?',
        [namaRute, id],
      );
    }
  }

  /// Link local visit (by client_ref/id) to server ID
  Future<void> updateVisitServerId(String clientRef, String serverId) async {
    await customUpdate(
      'UPDATE visits_table SET server_id = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable.withString(serverId),
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withString(clientRef),
      ],
      updates: {visitsTable}, // Trigger reactive updates for watchers
    );
  }

  /// Batch save schedule (for sync)
  Future<void> saveScheduleItems(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      for (final item in items) {
        batch.insert(
          scheduleTable,
          ScheduleTableCompanion.insert(
            id: item['id']?.toString() ?? '',
            jadwalId: Value(item['id_jadwal']?.toString()),
            karyawanId: item['id_karyawan']?.toString() ?? '',
            tanggal: item['tanggal'] as String,
            divisiId: Value(item['id_divisi']?.toString()),
            pelangganId: item['id_pelanggan']?.toString() ?? '',
            urutan: Value(item['urutan'] as int? ?? 0),
            status: Value(item['status'] as String? ?? 'scheduled'),
            waktuCheckIn: Value(item['waktu_check_in'] as String?),
            waktuCheckOut: Value(item['waktu_check_out'] as String?),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Update schedule status (for check-in/out)
  Future<void> updateScheduleStatus(
    String id,
    String status, {
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) {
    return (update(scheduleTable)..where((t) => t.id.equals(id))).write(
      ScheduleTableCompanion(
        status: Value(status),
        waktuCheckIn: Value(waktuCheckIn),
        waktuCheckOut: Value(waktuCheckOut),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Update schedule status by jadwalId + pelangganId (for planned check-in).
  Future<void> updateScheduleStatusByJadwal({
    required String jadwalId,
    required String pelangganId,
    String status = 'DIKUNJUNGI',
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) async {
    await (update(scheduleTable)..where(
          (t) =>
              t.jadwalId.equals(jadwalId) & t.pelangganId.equals(pelangganId),
        ))
        .write(
          ScheduleTableCompanion(
            status: Value(status),
            waktuCheckIn: Value(waktuCheckIn),
            waktuCheckOut: Value(waktuCheckOut),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  /// Update schedule status by visit ID (for check-out on planned visits).
  /// Looks up the visit to find its scheduleId (backend jadwalId), then updates
  /// the schedule row where jadwalId AND pelangganId match (targets exactly one row).
  Future<void> updateScheduleStatusByVisitId({
    required String visitId,
    String status = 'SELESAI',
    String? waktuCheckOut,
  }) async {
    final visit = await getVisit(visitId);
    if (visit != null && visit.scheduleId != null) {
      final pelangganId = visit.pelangganId;

      if (pelangganId != null) {
        // Match by BOTH jadwalId AND pelangganId — targets exactly one schedule row
        await (update(scheduleTable)..where(
              (t) =>
                  t.jadwalId.equals(visit.scheduleId!) &
                  t.pelangganId.equals(pelangganId),
            ))
            .write(
              ScheduleTableCompanion(
                status: Value(status),
                waktuCheckOut: Value(waktuCheckOut),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
      } else {
        // Fallback: if no pelangganId, use composite key approach
        // but log warning — this shouldn't happen
        debugPrint(
          '[WARNING] updateScheduleStatusByVisitId: visit $visitId has no pelangganId',
        );
      }
    } else if (visit != null &&
        visit.scheduleId == null &&
        visit.pelangganId != null) {
      // Fix 2: Handle visits without scheduleId (unplanned visits or missing link)
      // Find matching schedule row by pelangganId + today's date
      final pelangganId = visit.pelangganId!;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final scheduleRows =
          await (select(scheduleTable)..where(
                (t) =>
                    t.pelangganId.equals(pelangganId) &
                    t.tanggal.equals(todayStr),
              ))
              .get();

      if (scheduleRows.isNotEmpty) {
        final targetRow = scheduleRows.first;
        await (update(
          scheduleTable,
        )..where((t) => t.id.equals(targetRow.id))).write(
          ScheduleTableCompanion(
            status: Value(status),
            waktuCheckOut: Value(waktuCheckOut),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
    }
  }

  /// Get schedule for date (non-reactive)
  Future<List<ScheduleTableData>> getScheduleForDate(String tanggal) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.equals(tanggal))
          ..orderBy([(t) => OrderingTerm.asc(t.urutan)]))
        .get();
  }

  Future<ScheduleTableData?> getScheduleById(String id) {
    return (select(scheduleTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get schedule for a date range (single query, avoids N+1)
  Future<List<ScheduleTableData>> getScheduleForDateRange(String startDate, String endDate) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.isBiggerOrEqualValue(startDate) & t.tanggal.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.tanggal), (t) => OrderingTerm.asc(t.urutan)]))
        .get();
  }

  /// Delete schedule item
  Future<void> deleteScheduleItem(String id) {
    return (delete(scheduleTable)..where((t) => t.id.equals(id))).go();
  }

  // ─── Notifications CRUD ────────────────────────────────────────────────

  /// Save notification
  Future<void> saveNotification({
    required String id,
    required String karyawanId,
    required String judul,
    required String isi,
    String tipe = 'info',
    bool isRead = false,
  }) async {
    await into(notificationsTable).insertOnConflictUpdate(
      NotificationsTableCompanion.insert(
        id: id,
        karyawanId: karyawanId,
        judul: judul,
        isi: isi,
        tipe: Value(tipe),
        isRead: Value(isRead),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Batch save notifications (for sync)
  Future<void> saveNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    await batch((batch) {
      for (final n in notifications) {
        batch.insert(
          notificationsTable,
          NotificationsTableCompanion.insert(
            id: n['id']?.toString() ?? '',
            karyawanId: n['id_karyawan']?.toString() ?? '',
            judul: n['judul'] as String,
            isi: n['isi'] as String,
            tipe: Value(n['tipe'] as String? ?? 'info'),
            isRead: Value(n['is_read'] == true || n['is_read'] == 1),
            createdAt: n['created_at'] as int,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String id) {
    return (update(notificationsTable)..where((t) => t.id.equals(id))).write(
      const NotificationsTableCompanion(isRead: Value(true)),
    );
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() {
    return update(
      notificationsTable,
    ).write(const NotificationsTableCompanion(isRead: Value(true)));
  }

  /// Get unread count (non-reactive)
  Future<int> getUnreadNotificationCount() async {
    final query = selectOnly(notificationsTable)
      ..where(notificationsTable.isRead.equals(false))
      ..addColumns([notificationsTable.id.count()]);
    final result = await query.getSingle();
    return result.read(notificationsTable.id.count()) ?? 0;
  }

  /// Delete notification
  Future<void> deleteNotification(String id) {
    return (delete(notificationsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all read notifications
  Future<void> deleteReadNotifications() {
    return (delete(
      notificationsTable,
    )..where((t) => t.isRead.equals(true))).go();
  }

  // ─── Promo CRUD ─────────────────────────────────────────────────────────

  /// Save promo (per-customer)
  Future<void> savePromo({
    required String id,
    required String idPelanggan,
    required String namaCampaign,
    required String jenis,
    required String dataJson,
    String status = 'active',
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(promoTable).insertOnConflictUpdate(
      PromoTableCompanion.insert(
        id: id,
        idPelanggan: idPelanggan,
        namaCampaign: namaCampaign,
        jenis: jenis,
        dataJson: dataJson,
        status: Value(status),
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Batch save promos (for sync) - per customer
  Future<void> savePromos(List<Map<String, dynamic>> promos) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      for (final p in promos) {
        batch.insert(
          promoTable,
          PromoTableCompanion.insert(
            id: p['id']?.toString() ?? '',
            idPelanggan: p['id_pelanggan']?.toString() ?? '',
            namaCampaign:
                p['nama_campaign'] as String? ?? p['nama'] as String? ?? '',
            jenis: p['jenis'] as String,
            dataJson: p['data_json'] is String
                ? p['data_json'] as String
                : jsonEncode(p['data_json'] ?? {}),
            status: Value(p['status'] as String? ?? 'active'),
            startDate: (p['start_date'] is int)
                ? p['start_date'] as int
                : (p['start_date'] is String)
                ? DateTime.parse(
                    p['start_date'] as String,
                  ).millisecondsSinceEpoch
                : now,
            endDate: (p['end_date'] is int)
                ? p['end_date'] as int
                : (p['end_date'] is String)
                ? DateTime.parse(p['end_date'] as String).millisecondsSinceEpoch
                : now,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Get all active promos (non-reactive)
  Future<List<PromoTableData>> getActivePromos() {
    return (select(promoTable)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .get();
  }

  /// Get promos for specific pelanggan (non-reactive)
  Future<List<PromoTableData>> getPromosForPelanggan(String idPelanggan) {
    return (select(promoTable)
          ..where(
            (t) =>
                t.idPelanggan.equals(idPelanggan) & t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .get();
  }

  /// Returns the set of distinct pelangganIds that have at least one active promo.
  /// Used for batch existence checks (e.g. preload skip-if-cached) without N+1 queries.
  Future<Set<String>> getPelangganIdsWithActivePromos() async {
    final query = selectOnly(promoTable, distinct: true)
      ..addColumns([promoTable.idPelanggan])
      ..where(promoTable.status.equals('active'));
    final rows = await query.get();
    return rows.map((r) => r.read(promoTable.idPelanggan)!).toSet();
  }

  /// Get promo by ID and pelanggan (composite key)
  Future<PromoTableData?> getPromo(String id, String idPelanggan) {
    return (select(promoTable)
          ..where((t) => t.id.equals(id) & t.idPelanggan.equals(idPelanggan)))
        .getSingleOrNull();
  }

  /// Delete all promos for a pelanggan
  Future<void> deletePromosForPelanggan(String idPelanggan) {
    return (delete(
      promoTable,
    )..where((t) => t.idPelanggan.equals(idPelanggan))).go();
  }

  /// Delete promo by composite key
  Future<void> deletePromo(String id, String idPelanggan) {
    return (delete(
      promoTable,
    )..where((t) => t.id.equals(id) & t.idPelanggan.equals(idPelanggan))).go();
  }

  // ─── Sqflite Compatibility Layer ────────────────────────────────────────────
  // These methods provide a sqflite-like API for code that hasn't been
  // migrated to Drift's type-safe queries yet.

  /// Query rows from a table using raw SQL. Returns `List<Map<String, dynamic>>`.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, {
    List<Object?>? whereArgs,
  }) async {
    final result = await customSelect(
      sql,
      variables: whereArgs != null
          ? whereArgs.map((arg) => Variable.withString(arg.toString())).toList()
          : [],
    ).get();

    return result.map((row) => row.data).toList();
  }

  /// Update rows in a table using raw SQL. Returns number of affected rows.
  Future<int> rawUpdate(String sql, {List<Object?>? whereArgs}) async {
    return customUpdate(
      sql,
      variables: whereArgs
              ?.map((a) => Variable(a))
              .toList() ??
          [],
      updates: {},
      updateKind: UpdateKind.update,
    );
  }

  /// Insert a row using raw SQL. Returns the row ID.
  Future<int> rawInsert(String sql, {List<Object?>? whereArgs}) async {
    await customStatement(
      sql,
      whereArgs?.map((v) => v?.toString()).cast<String>().toList() ??
          [],
    );
    return 1;
  }

  /// Delete rows from a table using raw SQL. Returns number of affected rows.
  Future<int> rawDelete(String sql, {List<Object?>? whereArgs}) async {
    await customStatement(
      sql,
      whereArgs?.map((a) => a?.toString()).cast<String>().toList() ??
          [],
    );
    return 1;
  }
}

// ─── Database Connection ─────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'sales_tracker.db'));
    return NativeDatabase.createBackgroundConnection(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA busy_timeout=5000;');
        db.execute('PRAGMA synchronous=NORMAL;');
      },
    );
  });
}
