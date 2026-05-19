// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_dao.dart';

// ignore_for_file: type=lint
mixin _$PromoDaoMixin on DatabaseAccessor<AppDatabase> {
  $PromoTableTable get promoTable => attachedDatabase.promoTable;
  PromoDaoManager get managers => PromoDaoManager(this);
}

class PromoDaoManager {
  final _$PromoDaoMixin _db;
  PromoDaoManager(this._db);
  $$PromoTableTableTableManager get promoTable =>
      $$PromoTableTableTableManager(_db.attachedDatabase, _db.promoTable);
}
