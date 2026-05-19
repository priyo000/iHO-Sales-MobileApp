// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_dao.dart';

// ignore_for_file: type=lint
mixin _$ReportsDaoMixin on DatabaseAccessor<AppDatabase> {
  $OrdersTableTable get ordersTable => attachedDatabase.ordersTable;
  $VisitsTableTable get visitsTable => attachedDatabase.visitsTable;
  ReportsDaoManager get managers => ReportsDaoManager(this);
}

class ReportsDaoManager {
  final _$ReportsDaoMixin _db;
  ReportsDaoManager(this._db);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db.attachedDatabase, _db.ordersTable);
  $$VisitsTableTableTableManager get visitsTable =>
      $$VisitsTableTableTableManager(_db.attachedDatabase, _db.visitsTable);
}
