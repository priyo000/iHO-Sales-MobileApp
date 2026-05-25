import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_badge.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_empty_state.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

import '../../../../core/providers/database_providers.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/order_history_controller.dart';
import '../controllers/promo_controller.dart';

class OrderReviewPage extends ConsumerStatefulWidget {
  final dynamic kunjunganId;
  final dynamic pelangganId;
  final Map<String, dynamic>? pelangganData;
  final bool isEdit;
  final dynamic orderId;
  final String? localRef;
  final String? initialNotes;

  const OrderReviewPage({
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
  ConsumerState<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends ConsumerState<OrderReviewPage> {
  bool _isSubmitting = false;
  late final String _clientRef;

  @override
  void initState() {
    super.initState();
    _clientRef =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(0xFFFFFF).toRadixString(16)}';
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final promoSelection = ref.watch(promoSelectionProvider);
    final cartItems = cartState.items;

    final subtotal = ref.read(cartControllerProvider.notifier).totalAmount;
    final diskon = promoSelection.totalDiskon;
    final totalHadiah = promoSelection.totalHadiah;
    final finalTotal =
        (subtotal + totalHadiah - diskon).clamp(0.0, double.infinity);

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Review Pesanan'),
      ),
      body: cartItems.isEmpty
          ? AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjang kosong',
              actionLabel: 'Tambah Item',
              onAction: () => context.push('/catalog'),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  shadow: true,
                  bordered: false,
                  child: Column(
                    children: [
                      ...cartItems.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final itemPromo = promoSelection.promoForProduct(
                          item.product.id,
                        );
                        return Column(
                          children: [
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: AppSpacing.lg,
                                endIndent: AppSpacing.lg,
                              ),
                            _OrderItemTile(
                              item: item,
                              itemPromo: itemPromo,
                              currencyFmt: currencyFmt,
                              onTap: () => _editItem(context, ref, item),
                            ),
                          ],
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppButton.secondary(
                          label: 'Tambah Produk',
                          leadingIcon: Icons.add,
                          isFullWidth: true,
                          onPressed: () => context.push(
                            '/catalog',
                            extra: {
                              'kunjunganId': widget.kunjunganId,
                              'pelangganId': widget.pelangganId,
                              'pelangganData': widget.pelangganData,
                              'isEdit': widget.isEdit,
                              'orderId': widget.orderId,
                              'localRef': widget.localRef,
                              'initialNotes': widget.initialNotes,
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  shadow: true,
                  bordered: false,
                  child: Column(
                    children: [
                      _summaryRow(
                        'Subtotal',
                        currencyFmt.format(subtotal),
                        labelStyle: AppTextStyles.bodyMedium,
                        valueStyle: AppTextStyles.bodyMedium,
                      ),
                      if (diskon > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _summaryRow(
                          'Total Diskon',
                          '-${currencyFmt.format(diskon)}',
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.success,
                          ),
                          valueStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (totalHadiah > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hadiah',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.card_giftcard,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                              ],
                            ),
                            Text(
                              '+${currencyFmt.format(totalHadiah)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      _summaryRow(
                        'Total',
                        currencyFmt.format(finalTotal),
                        labelStyle: AppTextStyles.headingSmall,
                        valueStyle: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
      bottomBar: cartItems.isNotEmpty
          ? SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton.primary(
                    label: widget.isEdit
                        ? 'SIMPAN PERUBAHAN'
                        : 'SUBMIT PESANAN',
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submitOrder,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final productRow = await db.getProduct(item.product.id);
    Product freshProduct;
    if (productRow != null) {
      final units = await db.getUnitsForProduct(item.product.id);
      freshProduct = Product(
        id: productRow.id,
        namaProduk: productRow.namaProduk,
        kodeBarang: productRow.kodeBarang ?? '',
        sku: productRow.sku ?? '',
        satuan: productRow.satuan ?? 'pcs',
        hargaJual: productRow.hargaJual ?? 0,
        stokTersedia: productRow.stokTersedia,
        gambarUrl: productRow.gambarUrl,
        idKategori: productRow.kategoriId,
        kategori: productRow.kategori,
        units: units
            .map((u) => ProductUnit(
                  id: u.id,
                  nama: u.nama,
                  konversi: u.konversi,
                  hargaJual: u.hargaJual,
                  isBase: u.isBase,
                ))
            .toList(),
      );
    } else {
      freshProduct = item.product;
    }
    if (!context.mounted) return;
    context.push(
      '/product-order',
      extra: {'product': freshProduct, 'existingCartItem': item},
    );
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final cartState = ref.read(cartControllerProvider);
      final controller = ref.read(orderControllerProvider.notifier);

      final effectiveKunjunganId = widget.kunjunganId ?? cartState.kunjunganId;
      final effectivePelangganId = widget.pelangganId ?? cartState.pelangganId;
      final effectivePelangganData =
          widget.pelangganData ?? cartState.pelangganData;

      dynamic result;

      if (widget.isEdit) {
        final serverOrderId = widget.orderId?.toString();
        if (serverOrderId != null && serverOrderId.isNotEmpty) {
          result = await controller.updateOrder(
            orderId: serverOrderId,
            localOrderId: widget.localRef ?? serverOrderId,
            notes: widget.initialNotes,
          );
        } else if (widget.localRef != null && widget.localRef!.isNotEmpty) {
          result = await controller.updatePendingOrder(
            localRef: widget.localRef!,
            notes: widget.initialNotes,
          );
        }
      } else {
        result = await controller.submitOrder(
          kunjunganId: effectiveKunjunganId,
          pelangganId: effectivePelangganId,
          pelangganData: effectivePelangganData,
          clientRef: _clientRef,
        );
      }

      if (!mounted) return;
      if (result == true) {
        ref.invalidate(allOrdersStreamProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Pesanan berhasil diperbarui!'
                  : 'Pesanan berhasil submitted!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/orders');
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Gagal memperbarui pesanan.'
                  : 'Gagal mengirim pesanan. Silakan coba lagi.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _OrderItemTile extends StatelessWidget {
  final CartItem item;
  final dynamic itemPromo;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;

  const _OrderItemTile({
    required this.item,
    required this.itemPromo,
    required this.currencyFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPromo = itemPromo != null;
    final isHadiah = hasPromo && itemPromo.isHadiah;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: item.product.gambarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.network(
                        item.product.gambarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textMuted,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.namaProduk,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${item.quantity}x ${currencyFmt.format(item.price)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (hasPromo) ...[
                    const SizedBox(height: 6),
                    AppBadge(
                      label: isHadiah
                          ? 'Hadiah'
                          : '-${currencyFmt.format(itemPromo.diskonAmount)}',
                      icon: isHadiah ? Icons.card_giftcard : Icons.local_offer,
                      color:
                          isHadiah ? AppColors.warning : AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
