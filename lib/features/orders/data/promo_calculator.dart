import 'models/cart_item_model.dart';
import 'models/promo_model.dart';

/// Pure business logic untuk kalkulasi diskon promo.
/// Tidak bergantung pada state management — bisa di-test secara independen.
class PromoCalculator {
  const PromoCalculator._();

  /// Hitung total diskon untuk promo aturan_harga berdasarkan cart.
  static double aturanHargaDiskon(
    PromoAturanHarga promo,
    List<CartItem> cartItems,
  ) {
    if (cartItems.isEmpty) return 0;

    double diskon = 0;
    for (final rule in promo.items) {
      final cartItem = _findCartItem(cartItems, rule.idProduk);
      if (cartItem == null || cartItem.quantity <= 0) continue;

      final hargaNormal = rule.hargaNormal > 0
          ? rule.hargaNormal
          : cartItem.product.hargaJual;
      final hargaFinal = rule.hargaFinal;
      diskon += (hargaNormal - hargaFinal) * cartItem.quantity;
    }
    return diskon.clamp(0, double.infinity);
  }

  /// Hitung total diskon untuk promo grosir berdasarkan cart.
  static double grosirDiskon(
    PromoGrosir promo,
    List<CartItem> cartItems,
  ) {
    if (cartItems.isEmpty) return 0;

    double diskon = 0;
    for (final item in promo.items) {
      final cartItem = _findCartItem(cartItems, item.idProduk);
      if (cartItem == null || cartItem.quantity <= 0) continue;

      final tier = item.getTierForQty(cartItem.quantity);
      if (tier == null) continue;

      final hargaNormal = item.hargaNormal > 0
          ? item.hargaNormal
          : cartItem.product.hargaJual;
      final hargaFinal = tier.hargaFinal(hargaNormal);
      diskon += (hargaNormal - hargaFinal) * cartItem.quantity;
    }
    return diskon.clamp(0, double.infinity);
  }

  /// Hitung diskon aturan_harga untuk SATU produk saja (hindari stacking).
  static double aturanHargaDiskonPerProduk(
    PromoAturanHarga promo,
    List<CartItem> cartItems,
    String idProduk,
  ) {
    final rule = promo.items.where((i) => i.idProduk == idProduk).firstOrNull;
    if (rule == null) return 0;
    final cartItem = _findCartItem(cartItems, idProduk);
    if (cartItem == null || cartItem.quantity <= 0) return 0;
    final hargaNormal = rule.hargaNormal > 0 ? rule.hargaNormal : cartItem.product.hargaJual;
    final hargaFinal = rule.hargaFinal;
    return ((hargaNormal - hargaFinal) * cartItem.quantity).clamp(0, double.infinity);
  }

  /// Hitung diskon grosir untuk SATU produk saja (hindari stacking).
  static double grosirDiskonPerProduk(
    PromoGrosir promo,
    List<CartItem> cartItems,
    String idProduk,
  ) {
    final item = promo.items.where((i) => i.idProduk == idProduk).firstOrNull;
    if (item == null) return 0;
    final cartItem = _findCartItem(cartItems, idProduk);
    if (cartItem == null || cartItem.quantity <= 0) return 0;
    final tier = item.getTierForQty(cartItem.quantity);
    if (tier == null) return 0;
    final hargaNormal = item.hargaNormal > 0 ? item.hargaNormal : cartItem.product.hargaJual;
    final hargaFinal = tier.hargaFinal(hargaNormal);
    return ((hargaNormal - hargaFinal) * cartItem.quantity).clamp(0, double.infinity);
  }

  /// Cek apakah syarat hadiah terpenuhi berdasarkan cart dan total.
  static bool hadiahSyaratTerpenuhi(
    PromoHadiahItem item,
    List<CartItem> cartItems,
    double totalAmount,
  ) {
    if (item.jenisPemicu == 'total_nota') {
      return item.minAmountPemicu != null &&
          totalAmount >= item.minAmountPemicu!;
    }
    // jenis_pemicu == 'produk'
    if (item.idProdukPemicu == null || item.minQtyPemicu == null) return false;
    final cartItem = _findCartItem(cartItems, item.idProdukPemicu!);
    if (cartItem == null) return false;
    return cartItem.quantity >= item.minQtyPemicu!;
  }

  static CartItem? _findCartItem(List<CartItem> items, String idProduk) {
    try {
      return items.firstWhere((c) => c.product.id == idProduk);
    } catch (_) {
      return null;
    }
  }
}
