import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_badge.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_chip.dart';
import 'package:sales_tracker_mobile/core/widgets/app_empty_state.dart';
import 'package:sales_tracker_mobile/core/widgets/app_loading.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

import '../../data/models/product_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/promo_controller.dart';

class ProductCatalogPage extends ConsumerStatefulWidget {
  final dynamic kunjunganId;
  final dynamic pelangganId;
  final Map<String, dynamic>? pelangganData;
  final bool isEdit;
  final dynamic orderId;
  final String? localRef;
  final String? initialNotes;

  const ProductCatalogPage({
    super.key,
    this.kunjunganId,
    this.pelangganId,
    this.pelangganData,
    this.isEdit = false,
    this.orderId,
    this.localRef,
    this.initialNotes,
  });

  @override
  ConsumerState<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends ConsumerState<ProductCatalogPage> {
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isRefreshingPromo = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider.notifier).initForCustomer(
            widget.pelangganId,
            widget.pelangganData,
            widget.kunjunganId,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshPromo() async {
    final pelangganId = widget.pelangganId;
    if (pelangganId == null) return;
    final id = int.tryParse(pelangganId.toString());
    if (id == null) return;

    setState(() => _isRefreshingPromo = true);
    try {
      await refreshPromos(ref, id.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.surface,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Data promo berhasil diperbarui',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingPromo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(productControllerProvider);

    late final AsyncValue<List<Product>> productsAsync;
    if (_selectedCategoryId != null) {
      if (_searchQuery.isNotEmpty) {
        productsAsync = ref.watch(
          productsByCategoryAndSearchStreamProvider((
            kategoriId: _selectedCategoryId!,
            query: _searchQuery,
          )),
        );
      } else {
        productsAsync = ref.watch(
          productsByCategoryStreamProvider(_selectedCategoryId!),
        );
      }
    } else {
      productsAsync = _searchQuery.isEmpty
          ? ref.watch(productsStreamProvider)
          : ref.watch(productSearchStreamProvider(_searchQuery));
    }

    final cartState = ref.watch(cartControllerProvider);
    final promoSelection = ref.watch(promoSelectionProvider);
    final cartTotal = cartState.items.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.totalPrice -
          (promoSelection.promoForProduct(item.product.id)?.diskonAmount ?? 0),
    );

    final pelangganIdStr = widget.pelangganId?.toString();
    final hasPelanggan = pelangganIdStr != null && pelangganIdStr.isNotEmpty;

    return AppScaffold(
      body: Column(
        children: [
          _buildHeader(hasPelanggan: hasPelanggan),
          Expanded(
            child: productsAsync.when(
              loading: () => const AppLoading(),
              error: (error, _) => Center(
                child: Text(
                  'Error: $error',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Produk tidak ditemukan',
                  );
                }

                final formatter = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final existingItem = cartState.items
                        .where((i) => i.product.id == product.id)
                        .firstOrNull;
                    final inCart = existingItem != null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ProductCard(
                        product: product,
                        formattedPrice: formatter.format(
                          product.defaultUnit?.hargaJual ?? product.hargaJual,
                        ),
                        unitLabel:
                            product.defaultUnit?.nama ?? product.satuan,
                        inCart: inCart,
                        cartQty: existingItem?.quantity ?? 0,
                        onTap: () => context.push(
                          '/product-order',
                          extra: {
                            'product': product,
                            'pelangganId': widget.pelangganId is int
                                ? widget.pelangganId
                                : int.tryParse(
                                    widget.pelangganId?.toString() ?? '',
                                  ),
                            'existingCartItem': existingItem,
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomBar: cartState.items.isEmpty
          ? null
          : SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton.primary(
                    label:
                        '${cartState.items.length} Item • ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cartTotal)}',
                    leadingIcon: Icons.shopping_cart,
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    onPressed: () {
                      if (widget.isEdit) {
                        context.pop();
                      } else {
                        context.push(
                          '/order-review',
                          extra: {
                            'kunjunganId': widget.kunjunganId,
                            'pelangganId': widget.pelangganId,
                            'pelangganData': widget.pelangganData,
                            'isEdit': widget.isEdit,
                            'orderId': widget.orderId,
                            'localRef': widget.localRef,
                            'initialNotes': widget.initialNotes,
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader({required bool hasPelanggan}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                if (hasPelanggan) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _isRefreshingPromo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.discount_outlined),
                          tooltip: 'Refresh Promo',
                          onPressed: _refreshPromo,
                          color: AppColors.primary,
                        ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryChips(
              selectedCategoryId: _selectedCategoryId,
              onSelected: (id) =>
                  setState(() => _selectedCategoryId = id),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return categoriesAsync.when(
      data: (categories) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: 'Semua',
                  selected: selectedCategoryId == null,
                  onTap: () => onSelected(null),
                ),
              ),
              ...categories.map((cat) {
                final isSelected = selectedCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: cat.namaKategori,
                    selected: isSelected,
                    onTap: () => onSelected(cat.id),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox(height: 40),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String formattedPrice;
  final String unitLabel;
  final bool inCart;
  final int cartQty;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.formattedPrice,
    required this.unitLabel,
    required this.inCart,
    required this.cartQty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: inCart
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: CachedNetworkImage(
                        imageUrl:
                            product.gambarUrl ?? 'https://placehold.co/200',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ColoredBox(
                          color: AppColors.divider,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: AppColors.divider,
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    if (inCart)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: AppBadge(
                          label: '$cartQty',
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.namaProduk,
                              style: AppTextStyles.titleMedium
                                  .copyWith(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              product.kodeBarang,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (unitLabel.isNotEmpty)
                                    Text(
                                      '/ $unitLabel',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedPrice,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppButton(
                              label: inCart ? 'Edit' : '+ Pilih',
                              variant: inCart
                                  ? AppButtonVariant.secondary
                                  : AppButtonVariant.primary,
                              size: AppButtonSize.sm,
                              onPressed: onTap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
