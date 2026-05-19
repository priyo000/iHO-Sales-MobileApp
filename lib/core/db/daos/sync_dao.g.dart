// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncQueueTableTable get syncQueueTable => attachedDatabase.syncQueueTable;
  $RefIdMapTableTable get refIdMapTable => attachedDatabase.refIdMapTable;
  $SyncLockTableTable get syncLockTable => attachedDatabase.syncLockTable;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(
        _db.attachedDatabase,
        _db.syncQueueTable,
      );
  $$RefIdMapTableTableTableManager get refIdMapTable =>
      $$RefIdMapTableTableTableManager(_db.attachedDatabase, _db.refIdMapTable);
  $$SyncLockTableTableTableManager get syncLockTable =>
      $$SyncLockTableTableTableManager(_db.attachedDatabase, _db.syncLockTable);
}
