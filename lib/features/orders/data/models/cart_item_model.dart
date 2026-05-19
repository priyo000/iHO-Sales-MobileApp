import 'product_model.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double? negotiatedPrice;
  final String? selectedUnitId;
  final String? selectedUnitName;

  CartItem({
    required this.product,
    required this.quantity,
    this.negotiatedPrice,
    this.selectedUnitId,
    this.selectedUnitName,
  });

  double get unitPrice {
    if (negotiatedPrice != null) return negotiatedPrice!;
    if (selectedUnitId != null) {
      final unit = product.units.where((u) => u.id == selectedUnitId).firstOrNull;
      if (unit?.hargaJual != null) return unit!.hargaJual!;
    }
    return product.hargaJual;
  }

  double get price => unitPrice;

  double get totalPrice => price * quantity;

  CartItem copyWith({
    int? quantity,
    double? negotiatedPrice,
    bool clearNegotiatedPrice = false,
    String? selectedUnitId,
    String? selectedUnitName,
  }) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      negotiatedPrice: clearNegotiatedPrice ? null : (negotiatedPrice ?? this.negotiatedPrice),
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      selectedUnitName: selectedUnitName ?? this.selectedUnitName,
    );
  }
}
