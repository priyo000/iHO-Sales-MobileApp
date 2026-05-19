import 'package:drift/drift.dart';

import '../app_database.dart';

part 'cart_dao.g.dart';

@DriftAccessor(tables: [CartItemsTable])
class CartDao extends DatabaseAccessor<AppDatabase> with _$CartDaoMixin {
  CartDao(super.db);

  Future<void> saveCartItem({
    String? pelangganId,
    required String productJson,
    required String productId,
    required int quantity,
    double? negotiatedPrice,
    String? unitId,
    String? unitName,
  }) async {
    await into(cartItemsTable).insertOnConflictUpdate(
      CartItemsTableCompanion.insert(
        pelangganId: Value(pelangganId),
        productJson: productJson,
        productId: productId,
        quantity: quantity,
        negotiatedPrice: Value(negotiatedPrice),
        unitId: Value(unitId),
        unitName: Value(unitName),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> removeCartItem(String productId) async {
    await (delete(cartItemsTable)..where((t) => t.productId.equals(productId)))
        .go();
  }

  Future<List<CartItemsTableData>> getCartItems({String? pelangganId}) async {
    if (pelangganId != null) {
      return await (select(cartItemsTable)
            ..where((t) => t.pelangganId.equals(pelangganId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
    }
    return await (select(cartItemsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> clearCart({String? pelangganId}) async {
    if (pelangganId != null) {
      await (delete(cartItemsTable)
            ..where((t) => t.pelangganId.equals(pelangganId)))
          .go();
    } else {
      await delete(cartItemsTable).go();
    }
  }

  Stream<List<CartItemsTableData>> watchCartItems({String? pelangganId}) {
    if (pelangganId != null) {
      return (select(cartItemsTable)
            ..where((t) => t.pelangganId.equals(pelangganId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();
    }
    return (select(cartItemsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }
}
