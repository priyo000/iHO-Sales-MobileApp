// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_dao.dart';

// ignore_for_file: type=lint
mixin _$CartDaoMixin on DatabaseAccessor<AppDatabase> {
  $CartItemsTableTable get cartItemsTable => attachedDatabase.cartItemsTable;
  CartDaoManager get managers => CartDaoManager(this);
}

class CartDaoManager {
  final _$CartDaoMixin _db;
  CartDaoManager(this._db);
  $$CartItemsTableTableTableManager get cartItemsTable =>
      $$CartItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.cartItemsTable,
      );
}
