// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductsTableTable get productsTable => attachedDatabase.productsTable;
  $ProductUnitsTableTable get productUnitsTable =>
      attachedDatabase.productUnitsTable;
  $CategoriesTableTable get categoriesTable => attachedDatabase.categoriesTable;
  ProductDaoManager get managers => ProductDaoManager(this);
}

class ProductDaoManager {
  final _$ProductDaoMixin _db;
  ProductDaoManager(this._db);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db.attachedDatabase, _db.productsTable);
  $$ProductUnitsTableTableTableManager get productUnitsTable =>
      $$ProductUnitsTableTableTableManager(
        _db.attachedDatabase,
        _db.productUnitsTable,
      );
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(
        _db.attachedDatabase,
        _db.categoriesTable,
      );
}
