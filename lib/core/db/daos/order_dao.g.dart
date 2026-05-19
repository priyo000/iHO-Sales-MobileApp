// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dao.dart';

// ignore_for_file: type=lint
mixin _$OrderDaoMixin on DatabaseAccessor<AppDatabase> {
  $OrdersTableTable get ordersTable => attachedDatabase.ordersTable;
  OrderDaoManager get managers => OrderDaoManager(this);
}

class OrderDaoManager {
  final _$OrderDaoMixin _db;
  OrderDaoManager(this._db);
  $$OrdersTableTableTableManager get ordersTable =>
      $$OrdersTableTableTableManager(_db.attachedDatabase, _db.ordersTable);
}
