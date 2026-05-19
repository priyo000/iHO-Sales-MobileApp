import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

part 'cache_dao.g.dart';

@DriftAccessor(tables: [LocalCacheTable, SyncMetadataTable])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

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
    await (delete(syncMetadataTable)
          ..where((t) => t.resource.equals(resource)))
        .go();
  }

  Future<void> clearAllLastSync() async {
    await delete(syncMetadataTable).go();
  }
}
