import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import 'models/product_model.dart';
import 'models/cart_item_model.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CartRepository(db);
});

class CartRepository {
  final AppDatabase _db;

  CartRepository(this._db);

  Stream<List<CartItemsTableData>> watchCartItems({String? pelangganId}) {
    return _db.watchCartItems(pelangganId: pelangganId);
  }

  Future<void> saveCartItem({
    String? pelangganId,
    required Product product,
    required int quantity,
    double? negotiatedPrice,
  }) async {
    await _db.saveCartItem(
      pelangganId: pelangganId,
      productJson: jsonEncode(product.toJson()),
      productId: product.id,
      quantity: quantity,
      negotiatedPrice: negotiatedPrice,
    );
  }

  Future<void> removeCartItem(String productId) async {
    await _db.removeCartItem(productId);
  }

  Future<void> clearCart({String? pelangganId}) async {
    await _db.clearCart(pelangganId: pelangganId);
  }

  Future<List<CartItemsTableData>> getCartItems({String? pelangganId}) async {
    return _db.getCartItems(pelangganId: pelangganId);
  }

  CartItem cartItemFromRow(CartItemsTableData row) {
    final product = Product.fromJson(jsonDecode(row.productJson));
    return CartItem(
      product: product,
      quantity: row.quantity,
      negotiatedPrice: row.negotiatedPrice,
      selectedUnitId: row.unitId,
      selectedUnitName: row.unitName,
    );
  }

  Stream<List<CartItem>> watchCartItemModels({String? pelangganId}) {
    return watchCartItems(
      pelangganId: pelangganId,
    ).map((rows) => rows.map(cartItemFromRow).toList());
  }
}
