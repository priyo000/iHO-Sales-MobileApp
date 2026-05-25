import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/product_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/product_card.dart';

class CatalogPage extends ConsumerWidget {
  final int? customerId;
  const CatalogPage({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productControllerProvider);
    final cartState = ref.watch(cartControllerProvider);
    final cartCount = cartState.items.length;

    final products = productsState.asData?.value.items ?? [];

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {},
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final product = products[i];
                return ProductCard(
                  product: product,
                  onAdd: () => ref
                      .read(cartControllerProvider.notifier)
                      .addItem(product, 1),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                final cartState = ref.read(cartControllerProvider);
                context.push(
                  '/order-review',
                  extra: {'kunjunganId': cartState.kunjunganId},
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: Text('Keranjang ($cartCount)'),
            )
          : null,
    );
  }
}
