import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/promo_calculator.dart';
import '../controllers/cart_controller.dart';
import '../controllers/promo_controller.dart';
import '../widgets/inline_promo_selector.dart';

class ProductOrderPage extends ConsumerStatefulWidget {
  final Product product;
  final String? pelangganId;
  final CartItem? existingCartItem;

  const ProductOrderPage({
    super.key,
    required this.product,
    this.pelangganId,
    this.existingCartItem,
  });

  bool get isEdit => existingCartItem != null;

  @override
  ConsumerState<ProductOrderPage> createState() => _ProductOrderPageState();
}

class _ProductOrderPageState extends ConsumerState<ProductOrderPage> {
  late int _qty;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late double _price;
  bool _isRefreshingPromo = false;
  ProductUnit? _selectedUnit;

  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _qty = widget.existingCartItem?.quantity ?? 1;

    if (widget.existingCartItem?.selectedUnitId != null) {
      _selectedUnit = widget.product.units
          .where((u) => u.id == widget.existingCartItem!.selectedUnitId)
          .firstOrNull;
    }
    _selectedUnit ??= widget.product.defaultUnit;

    _price = widget.existingCartItem?.price ??
        _selectedUnit?.hargaJual ??
        widget.product.hargaJual;
    _qtyController = TextEditingController(text: _qty.toString());
    _priceController = TextEditingController(text: _price.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _incrementQty() {
    setState(() {
      _qty++;
      _qtyController.text = _qty.toString();
    });
  }

  void _decrementQty() {
    if (_qty <= 1) return;
    setState(() {
      _qty--;
      _qtyController.text = _qty.toString();
    });
  }

  void _onQtyTextChanged(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed > 0) {
      setState(() => _qty = parsed);
    }
  }

  void _onPriceChanged(String val) {
    final parsed = double.tryParse(val);
    if (parsed != null) {
      setState(() => _price = parsed);
    }
  }

  void _confirm() {
    final cartNotifier = ref.read(cartControllerProvider.notifier);
    if (widget.isEdit) {
      cartNotifier.removeItem(widget.product.id);
      cartNotifier.addItem(widget.product, _qty, selectedUnit: _selectedUnit);
      if (_price != (_selectedUnit?.hargaJual ?? widget.product.hargaJual)) {
        cartNotifier.updatePrice(widget.product.id, _price);
      }
    } else {
      cartNotifier.addItem(widget.product, _qty, selectedUnit: _selectedUnit);
      if (_price != (_selectedUnit?.hargaJual ?? widget.product.hargaJual)) {
        cartNotifier.updatePrice(widget.product.id, _price);
      }
    }

    final selectedPromo =
        ref.read(promoSelectionProvider).promoForProduct(widget.product.id);
    if (selectedPromo != null && widget.pelangganId != null) {
      final promosAsync =
          ref.read(availablePromosProvider(widget.pelangganId!));
      final promos = promosAsync.when(
        data: (v) => v,
        loading: () => null,
        error: (_, _) => null,
      );
      if (promos != null) {
        final effectivePrice = widget.product.hargaJual;
        final allCartItems = ref.read(cartControllerProvider).items;
        final simulatedItems = [
          ...allCartItems.where((i) => i.product.id != widget.product.id),
          CartItem(
            product: widget.product,
            quantity: _qty,
            negotiatedPrice: effectivePrice,
          ),
        ];
        double updatedDiskon = 0;
        if (selectedPromo.jenis == 'aturan_harga') {
          final promo = promos.aturanHarga
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            updatedDiskon = PromoCalculator.aturanHargaDiskonPerProduk(
              promo,
              simulatedItems,
              widget.product.id,
            );
          }
        } else if (selectedPromo.jenis == 'grosir') {
          final promo = promos.grosir
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            updatedDiskon = PromoCalculator.grosirDiskonPerProduk(
              promo,
              simulatedItems,
              widget.product.id,
            );
          }
        }
        ref
            .read(promoSelectionProvider.notifier)
            .updateDiskonForProduct(widget.product.id, updatedDiskon);
      }
    }

    context.pop(true);
  }

  Future<void> _refreshPromo() async {
    if (widget.pelangganId == null) return;
    setState(() => _isRefreshingPromo = true);
    try {
      await refreshPromos(ref, widget.pelangganId!);
    } finally {
      if (mounted) setState(() => _isRefreshingPromo = false);
    }
  }

  void _removeFromCart() {
    ref.read(cartControllerProvider.notifier).removeItem(widget.product.id);
    ref
        .read(promoSelectionProvider.notifier)
        .clearPromoForProduct(widget.product.id);
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final allowOpenPrice = ref.watch(allowOpenPriceProvider);
    final promoSelection = ref.watch(promoSelectionProvider);
    final selectedPromo = promoSelection.promoForProduct(widget.product.id);
    final priceLocked = selectedPromo != null;

    final effectivePrice = priceLocked ? widget.product.hargaJual : _price;
    final totalHarga = effectivePrice * _qty;

    final allCartItems = ref.watch(cartControllerProvider).items;
    final simulatedItems = [
      ...allCartItems.where((i) => i.product.id != widget.product.id),
      CartItem(
        product: widget.product,
        quantity: _qty,
        negotiatedPrice: effectivePrice,
      ),
    ];
    final subtotalSimulated =
        simulatedItems.fold<double>(0, (s, i) => s + i.totalPrice);

    double diskonPromo = 0;
    if (selectedPromo != null && widget.pelangganId != null) {
      final promosAsync =
          ref.watch(availablePromosProvider(widget.pelangganId!));
      final promos = promosAsync.when(
        data: (v) => v,
        loading: () => null,
        error: (_, _) => null,
      );
      if (promos != null) {
        if (selectedPromo.jenis == 'aturan_harga') {
          final promo = promos.aturanHarga
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            diskonPromo = PromoCalculator.aturanHargaDiskonPerProduk(
              promo,
              simulatedItems,
              widget.product.id,
            );
          }
        } else if (selectedPromo.jenis == 'grosir') {
          final promo = promos.grosir
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            diskonPromo = PromoCalculator.grosirDiskonPerProduk(
              promo,
              simulatedItems,
              widget.product.id,
            );
          }
        }
      }
    }

    final totalSetelahDiskon =
        (totalHarga - diskonPromo).clamp(0, double.infinity);

    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Produk' : 'Tambah ke Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Hapus dari pesanan',
              onPressed: () => _confirmRemove(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductInfoCard(priceLocked: priceLocked),
            const SizedBox(height: AppSpacing.xl),
            if (widget.product.units.length > 1) ...[
              const _SectionLabel('SATUAN'),
              const SizedBox(height: AppSpacing.sm),
              _buildUnitSelector(),
              const SizedBox(height: AppSpacing.lg),
            ],
            const _SectionLabel('JUMLAH'),
            const SizedBox(height: AppSpacing.sm),
            _buildQtySelector(),
            const SizedBox(height: AppSpacing.xl),
            if (allowOpenPrice) ...[
              const _SectionLabel('HARGA NEGO'),
              const SizedBox(height: AppSpacing.sm),
              _buildPriceField(priceLocked: priceLocked),
              if (priceLocked)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                  ),
                  child: Text(
                    'Harga dikunci karena promo aktif. Hapus promo untuk ubah harga.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (widget.pelangganId != null) ...[
              Row(
                children: [
                  const Expanded(child: _SectionLabel('PROMO')),
                  if (_isRefreshingPromo)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: _refreshPromo,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Refresh',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              InlinePromoSelector(
                product: widget.product,
                qty: _qty,
                effectivePrice: effectivePrice,
                pelangganId: widget.pelangganId!,
                simulatedItems: simulatedItems,
                subtotal: subtotalSimulated,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _SummaryLine(
                    label:
                        'Harga × $_qty ${_selectedUnit?.nama ?? widget.product.satuan}',
                    value: _fmt.format(totalHarga),
                  ),
                  if (diskonPromo > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _SummaryLine(
                      label: 'Diskon',
                      value: '- ${_fmt.format(diskonPromo)}',
                      isDiscount: true,
                    ),
                  ],
                  const Divider(height: AppSpacing.lg),
                  _SummaryLine(
                    label: 'Total',
                    value: _fmt.format(totalSetelahDiskon),
                    bold: true,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomBar: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton.primary(
              label: widget.isEdit ? 'Simpan Perubahan' : 'Tambah ke Pesanan',
              leadingIcon:
                  widget.isEdit ? Icons.check : Icons.add_shopping_cart,
              size: AppButtonSize.lg,
              isFullWidth: true,
              onPressed: _confirm,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoCard({required bool priceLocked}) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadow: true,
      bordered: false,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: CachedNetworkImage(
              imageUrl: widget.product.gambarUrl ??
                  'https://placehold.co/200x200/png?text=Produk',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorWidget: (ctx, url, err) => const ColoredBox(
                color: AppColors.divider,
                child: Icon(Icons.broken_image, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.namaProduk,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${widget.product.sku}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                Text(
                  _fmt.format(
                    _selectedUnit?.hargaJual ?? widget.product.hargaJual,
                  ),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                    decoration: (_price <
                                (_selectedUnit?.hargaJual ??
                                    widget.product.hargaJual) &&
                            !priceLocked)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit?.id,
          isExpanded: true,
          items: widget.product.units.map((u) {
            final priceLabel =
                u.hargaJual != null ? ' - ${_fmt.format(u.hargaJual)}' : '';
            return DropdownMenuItem<String>(
              value: u.id,
              child: Text(
                '${u.nama}$priceLabel',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (unitId) {
            final unit =
                widget.product.units.firstWhere((u) => u.id == unitId);
            setState(() {
              _selectedUnit = unit;
              _price = unit.hargaJual ?? widget.product.hargaJual;
              _priceController.text = _price.toStringAsFixed(0);
            });
          },
        ),
      ),
    );
  }

  Widget _buildQtySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: _decrementQty,
            enabled: _qty > 1,
          ),
          Expanded(
            child: TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: _onQtyTextChanged,
            ),
          ),
          Text(
            _selectedUnit?.nama ?? widget.product.satuan,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          _QtyButton(
            icon: Icons.add,
            onTap: _incrementQty,
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField({required bool priceLocked}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: priceLocked ? AppColors.divider : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: priceLocked
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Rp',
            style: AppTextStyles.titleMedium.copyWith(
              color: priceLocked
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _priceController,
              enabled: !priceLocked,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.titleLarge.copyWith(
                fontSize: 18,
                color:
                    priceLocked ? AppColors.textMuted : AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: _onPriceChanged,
            ),
          ),
          if (priceLocked)
            Row(
              children: [
                const Icon(
                  Icons.lock,
                  size: 13,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Promo aktif',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Hapus ${widget.product.namaProduk} dari pesanan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) _removeFromCart();
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.divider,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final bool isDiscount;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDiscount ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (bold ? AppTextStyles.titleLarge : AppTextStyles.bodySmall)
              .copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color ??
                (isDiscount ? AppColors.success : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
