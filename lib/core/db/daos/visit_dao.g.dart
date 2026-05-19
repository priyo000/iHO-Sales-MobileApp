// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_dao.dart';

// ignore_for_file: type=lint
mixin _$VisitDaoMixin on DatabaseAccessor<AppDatabase> {
  $VisitsTableTable get visitsTable => attachedDatabase.visitsTable;
  VisitDaoManager get managers => VisitDaoManager(this);
}

class VisitDaoManager {
  final _$VisitDaoMixin _db;
  VisitDaoManager(this._db);
  $$VisitsTableTableTableManager get visitsTable =>
      $$VisitsTableTableTableManager(_db.attachedDatabase, _db.visitsTable);
}
