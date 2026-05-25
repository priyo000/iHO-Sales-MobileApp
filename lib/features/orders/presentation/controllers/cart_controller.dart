import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';

class CartState {
  final List<CartItem> items;
  final dynamic pelangganId;

  /// Data lengkap pelanggan (nama_toko, dll) untuk display di order
  final Map<String, dynamic>? pelangganData;

  /// ID kunjungan (check-in) untuk link order ke kunjungan
  final dynamic kunjunganId;

  CartState({
    required this.items,
    this.pelangganId,
    this.pelangganData,
    this.kunjunganId,
  });

  bool get isEmpty => items.isEmpty;
  int get length => items.length;

  /// True jika ada item yang harganya diubah dari harga standar
  bool get hasOpenPrice => items.any(
    (item) =>
        item.negotiatedPrice != null &&
        item.negotiatedPrice != item.product.hargaJual,
  );
}

final cartControllerProvider =
    NotifierProvider<CartWithDbController, CartState>(CartWithDbController.new);

class CartWithDbController extends Notifier<CartState> {
  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  CartState build() {
    return CartState(
      items: [],
    );
  }

  // ── Public API ─────────────────────────────────────────────────────

  String? _normalizeCustomerId(dynamic pelangganId) {
    if (pelangganId == null) return null;
    final normalized = pelangganId.toString().trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') return null;
    return normalized;
  }

  /// Load cart dari SQLite pada app startup (fire once).
  Future<void> loadFromDatabase() async {
    try {
      final rows = await _db.getCartItems();
      if (rows.isEmpty) return;

      final newItems = <CartItem>[];
      dynamic pelangganId;
      for (final row in rows) {
        final product = Product.fromJson(
          jsonDecode(row.productJson),
        );
        if (pelangganId == null && row.pelangganId != null) {
          pelangganId = row.pelangganId;
        }
        newItems.add(
          CartItem(
            product: product,
            quantity: row.quantity,
            negotiatedPrice: row.negotiatedPrice,
            selectedUnitId: row.unitId,
            selectedUnitName: row.unitName,
          ),
        );
      }
      state = CartState(
        items: newItems,
        pelangganId: pelangganId,
        pelangganData: state.pelangganData,
        kunjunganId: state.kunjunganId,
      );
    } catch (e) {
      debugPrint('[CartController] loadFromDatabase failed: $e');
    }
  }

  /// Sinkronisasi pelanggan. Jika pelanggan berbeda, keranjang dibersihkan.
  /// [kunjunganId] adalah ID kunjungan/check-in untuk link order ke kunjungan.
  void initForCustomer(
    dynamic pelangganId, [
    Map<String, dynamic>? pelangganData,
    dynamic kunjunganId,
  ]) {
    final incomingId = _normalizeCustomerId(pelangganId);
    final currentId = _normalizeCustomerId(state.pelangganId);

    if (currentId == incomingId) {
      // Update pelangganData & kunjunganId even if ID same
      if (pelangganData != null || kunjunganId != null) {
        state = CartState(
          items: state.items,
          pelangganId: incomingId,
          pelangganData: pelangganData ?? state.pelangganData,
          kunjunganId: kunjunganId ?? state.kunjunganId,
        );
      }
      return;
    }

    if (currentId != null && incomingId != null && state.items.isNotEmpty) {
      unawaited(_clearCartDb());
      state = CartState(
        items: [],
        pelangganId: incomingId,
        pelangganData: pelangganData,
        kunjunganId: kunjunganId,
      );
      return;
    }

    state = CartState(
      items: state.items,
      pelangganId: incomingId,
      pelangganData: pelangganData ?? state.pelangganData,
      kunjunganId: kunjunganId ?? state.kunjunganId,
    );
  }

  void addItem(Product product, int quantity, {ProductUnit? selectedUnit}) {
    if (quantity <= 0) return;

    final unit = selectedUnit ?? product.defaultUnit;

    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      final oldItem = state.items[existingIndex];
      final newQuantity = oldItem.quantity + quantity;
      newItems = [...state.items];
      newItems[existingIndex] = oldItem.copyWith(
        quantity: newQuantity,
        selectedUnitId: unit?.id,
        selectedUnitName: unit?.nama,
      );
    } else {
      newItems = [
        ...state.items,
        CartItem(
          product: product,
          quantity: quantity,
          selectedUnitId: unit?.id,
          selectedUnitName: unit?.nama,
        ),
      ];
    }

    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_persistState());
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final newItems = [
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];

    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_persistOneItem(productId));
  }

  void updateUnit(String productId, ProductUnit? unit) {
    final newItems = [
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(
            selectedUnitId: unit?.id,
            selectedUnitName: unit?.nama,
          )
        else
          item,
    ];

    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_persistOneItem(productId));
  }

  void updatePrice(String productId, double price) {
    final newItems = [
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(negotiatedPrice: price)
        else
          item,
    ];

    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_persistOneItem(productId));
  }

  void removeItem(String productId) {
    final newItems = state.items
        .where((item) => item.product.id != productId)
        .toList();
    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_removeOneDbItem(productId));
  }

  void clear() {
    state = CartState(
      items: [],
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_clearCartDb());
  }

  /// Reset semua harga ke harga standar (dipanggil saat semua promo di-clear)
  void resetPrices() {
    final newItems = [
      for (final item in state.items) item.copyWith(clearNegotiatedPrice: true),
    ];
    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_persistState());
  }

  /// Reset harga satu produk ke harga standar (dipanggil saat promo per produk dipilih)
  void resetPriceForProduct(String productId) {
    final newItems = [
      for (final item in state.items)
        if (item.product.id == productId)
          item.copyWith(clearNegotiatedPrice: true)
        else
          item,
    ];
    state = CartState(
      items: newItems,
      pelangganId: state.pelangganId,
      pelangganData: state.pelangganData,
      kunjunganId: state.kunjunganId,
    );
    unawaited(_persistOneItem(productId));
  }

  // ── Internal helpers ───────────────────────────────────────────────

  Future<void> _persistState() async {
    try {
      await _db.transaction(() async {
        await _db.clearCart();
        for (final item in state.items) {
          await _db.saveCartItem(
            pelangganId: state.pelangganId,
            productJson: jsonEncode(item.product.toJson()),
            productId: item.product.id,
            quantity: item.quantity,
            negotiatedPrice: item.negotiatedPrice,
            unitId: item.selectedUnitId,
            unitName: item.selectedUnitName,
          );
        }
      });
    } catch (e) {
      debugPrint('[CartController] _persistState failed: $e');
    }
  }

  Future<void> _persistOneItem(String productId) async {
    try {
      final item = state.items.firstWhere(
        (i) => i.product.id == productId,
        orElse: () => throw StateError('not_found'),
      );
      await _db.saveCartItem(
        pelangganId: state.pelangganId,
        productJson: jsonEncode(item.product.toJson()),
        productId: productId,
        quantity: item.quantity,
        negotiatedPrice: item.negotiatedPrice,
        unitId: item.selectedUnitId,
        unitName: item.selectedUnitName,
      );
    } catch (e) {
      debugPrint('[CartController] _persistOneItem failed: $e');
    }
  }

  Future<void> _removeOneDbItem(String productId) async {
    try {
      await _db.removeCartItem(productId);
    } catch (e) {
      debugPrint('[CartController] _removeOneDbItem failed: $e');
    }
  }

  Future<void> _clearCartDb() async {
    try {
      await _db.clearCart();
    } catch (e) {
      debugPrint('[CartController] _clearCartDb failed: $e');
    }
  }

  double get totalAmount {
    return state.items.fold(0, (sum, item) => sum + item.totalPrice);
  }
}
