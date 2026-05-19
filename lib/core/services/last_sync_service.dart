import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../providers/database_providers.dart';

/// Resource identifiers for delta sync tracking.
/// Use these constants when calling setLastSync / getLastSync.
class SyncResource {
  static const String orders = 'orders';
  static const String visits = 'visits';
  static const String customers = 'customers';
  static const String products = 'products';
  static const String schedule = 'schedule';
  static const String promos = 'promos';
  static const String notifications = 'notifications';
  static const String dashboard = 'dashboard';
  static const String reports = 'reports';
}

/// Provider for LastSyncService.
final lastSyncServiceProvider = Provider<LastSyncService>((ref) {
  return LastSyncService(ref.watch(appDatabaseProvider));
});

/// Service for tracking per-resource last sync timestamps.
/// Enables delta sync: only fetch records changed since last sync.
class LastSyncService {
  final AppDatabase _db;

  LastSyncService(this._db);

  /// Get the last sync timestamp for a resource.
  /// Returns null if never synced — caller should do full sync.
  Future<DateTime?> getLastSync(String resource) => _db.getLastSync(resource);

  /// Get the server-side last_modified timestamp for a resource.
  /// Returns null if never synced — caller should do full sync.
  /// This value is sent as `?since=` parameter to backend.
  Future<String?> getLastModified(String resource) =>
      _db.getLastModified(resource);

  /// Record successful sync for a resource.
  /// Call this AFTER fetching and storing server data.
  /// [lastModified] is optional — pass server's response header value if available.
  Future<void> setLastSync(String resource, {DateTime? lastModified}) =>
      _db.setLastSync(resource, lastModified: lastModified);

  /// Force full sync by clearing last sync timestamp.
  Future<void> clearLastSync(String resource) => _db.clearLastSync(resource);

  /// Get all resource sync states (for debugging / UI display).
  Future<Map<String, DateTime?>> getAllSyncStates() async {
    final futures = <String, Future<DateTime?>>{
      SyncResource.orders: getLastSync(SyncResource.orders),
      SyncResource.visits: getLastSync(SyncResource.visits),
      SyncResource.customers: getLastSync(SyncResource.customers),
      SyncResource.products: getLastSync(SyncResource.products),
      SyncResource.schedule: getLastSync(SyncResource.schedule),
      SyncResource.promos: getLastSync(SyncResource.promos),
      SyncResource.dashboard: getLastSync(SyncResource.dashboard),
      SyncResource.reports: getLastSync(SyncResource.reports),
    };

    final Map<String, DateTime?> result = {};
    for (final entry in futures.entries) {
      result[entry.key] = await entry.value;
    }
    return result;
  }
}
