// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_dao.dart';

// ignore_for_file: type=lint
mixin _$CacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalCacheTableTable get localCacheTable => attachedDatabase.localCacheTable;
  $SyncMetadataTableTable get syncMetadataTable =>
      attachedDatabase.syncMetadataTable;
  CacheDaoManager get managers => CacheDaoManager(this);
}

class CacheDaoManager {
  final _$CacheDaoMixin _db;
  CacheDaoManager(this._db);
  $$LocalCacheTableTableTableManager get localCacheTable =>
      $$LocalCacheTableTableTableManager(
        _db.attachedDatabase,
        _db.localCacheTable,
      );
  $$SyncMetadataTableTableTableManager get syncMetadataTable =>
      $$SyncMetadataTableTableTableManager(
        _db.attachedDatabase,
        _db.syncMetadataTable,
      );
}
