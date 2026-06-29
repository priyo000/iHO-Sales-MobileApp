import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_database.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable, RefIdMapTable, SyncLockTable])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  static final _random = Random();

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

  // ─── Sync Queue Operations ──────────────────────────────────────────────────

  Future<String> enqueue({
    required String operation,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? ownerKey,
  }) async {
    final pendingItems =
        await (select(syncQueueTable)..where(
              (t) =>
                  t.operation.equals(operation) &
                  t.endpoint.equals(endpoint) &
                  _ownerPredicate(t, ownerKey) &
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
          } catch (_) {}
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
        ownerKey: Value(ownerKey),
      ),
    );

    return localRef;
  }

  Expression<bool> _ownerPredicate($SyncQueueTableTable t, String? ownerKey) {
    if (ownerKey == null || ownerKey.isEmpty) {
      // Legacy queue rows created before owner tracking are still visible to
      // avoid data loss. New sessions should stamp ownerKey on enqueue.
      return t.ownerKey.isNull();
    }
    return t.ownerKey.equals(ownerKey) | t.ownerKey.isNull();
  }

  Future<List<SyncQueueTableData>> getAllQueueItems({String? ownerKey}) async {
    return await (select(syncQueueTable)
          ..where(
            (t) =>
                _ownerPredicate(t, ownerKey) &
                t.status.isIn([
                  'pending',
                  'failed',
                  'failed_permanently',
                  'cancelled_dependency',
                ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<SyncQueueTableData>> getForeignQueueItems(String ownerKey) async {
    return await (select(syncQueueTable)
          ..where(
            (t) =>
                t.ownerKey.isNotNull() &
                t.ownerKey.equals(ownerKey).not() &
                t.status.isIn([
                  'pending',
                  'syncing',
                  'failed',
                  'failed_permanently',
                  'cancelled_dependency',
                ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> updateQueueStatus(
    String localRef,
    String status, {
    String? errorMessage,
  }) async {
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(
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

  Future<void> updateEndpointAndPayload(
    String localRef, {
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(
      SyncQueueTableCompanion(
        endpoint: Value(endpoint),
        payload: Value(jsonEncode(payload)),
      ),
    );
  }

  Future<void> resetRetryAndMarkPending(String localRef) async {
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(
      const SyncQueueTableCompanion(
        retryCount: Value(0),
        status: Value('pending'),
        errorMessage: Value(null),
      ),
    );
  }

  Future<int> incrementRetry(String localRef) async {
    final row = await (select(syncQueueTable)
          ..where((t) => t.localRef.equals(localRef)))
        .getSingleOrNull();
    final nextRetry = (row?.retryCount ?? 0) + 1;
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(SyncQueueTableCompanion(retryCount: Value(nextRetry)));
    return nextRetry;
  }

  Future<void> resetForRetry(String localRef) async {
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(
      const SyncQueueTableCompanion(
        retryCount: Value(0),
        status: Value('pending'),
        errorMessage: Value(null),
      ),
    );
  }

  Future<void> removeFromQueue(String localRef) async {
    await (delete(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .go();
  }

  Future<void> markServerSynced(String localRef) async {
    await (update(syncQueueTable)..where((t) => t.localRef.equals(localRef)))
        .write(
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
    return await (delete(refIdMapTable)
          ..where((t) => t.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // ─── Sync Lock Operations ──────────────────────────────────────────────────

  Future<bool> acquireSyncLock(String lockName, {int ttlMinutes = 2}) async {
    final instanceId = await _getInstanceId();
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: ttlMinutes))
        .millisecondsSinceEpoch;

    return await transaction(() async {
      await (delete(syncLockTable)..where(
            (t) =>
                t.lockName.equals(lockName) &
                t.acquiredAt.isSmallerThanValue(cutoff),
          ))
          .go();

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
      debugPrint('[DB] releaseSyncLock failed: $e - continuing anyway');
    }
  }

  Future<void> clearStaleSyncLock({int ttlMinutes = 2}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(minutes: ttlMinutes))
        .millisecondsSinceEpoch;
    await (delete(syncLockTable)
          ..where((t) => t.acquiredAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
