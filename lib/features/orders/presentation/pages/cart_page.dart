import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/cart_controller.dart';
import '../controllers/promo_controller.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/promo_banner.dart';
import '../widgets/order_summary_card.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final promoSelection = ref.watch(promoSelectionProvider);
    final promo = promoSelection.selectedPromo;
    final subtotal = ref.read(cartControllerProvider.notifier).totalAmount;
    final diskon = promoSelection.totalDiskon;
    final total = (subtotal - diskon).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartState.items.length,
              itemBuilder: (_, i) {
                final item = cartState.items[i];
                return CartItemTile(
                  item: item,
                  onQtyChanged: (qty) => ref
                      .read(cartControllerProvider.notifier)
                      .updateQuantity(item.product.id, qty),
                  onRemove: () => ref
                      .read(cartControllerProvider.notifier)
                      .removeItem(item.product.id),
                  onDiskonRecalculate: (productId) {
                    final currentCart = ref.read(cartControllerProvider);
                    final selectedPromo = ref.read(promoSelectionProvider).promoForProduct(productId);
                    if (selectedPromo == null) return;

                    final pelangganId = currentCart.pelangganId;
                    if (pelangganId == null) return;
                    final pelangganIdStr = pelangganId.toString();

                    final promosAsync = ref.read(availablePromosProvider(pelangganIdStr));
                    final promos = promosAsync.valueOrNull;
                    if (promos == null || promos.isEmpty) return;

                    ref.read(promoSelectionProvider.notifier)
                        .recalculateDiskonForProduct(
                          productId: productId,
                          allCartItems: currentCart.items,
                          promos: promos,
                        );
                  },
                );
              },
            ),
          ),
          if (promo != null) PromoBanner(promo: promo),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OrderSummaryCard(
                  subtotal: subtotal,
                  diskon: diskon,
                  total: total,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final cartState = ref.read(cartControllerProvider);
                      context.push(
                        '/order-review',
                        extra: {'kunjunganId': cartState.kunjunganId},
                      );
                    },
                    child: const Text('Lanjut ke Review'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
