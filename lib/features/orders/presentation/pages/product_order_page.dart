import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/promo_calculator.dart';
import '../controllers/cart_controller.dart';
import '../controllers/promo_controller.dart';
import '../widgets/inline_promo_selector.dart';

class ProductOrderPage extends ConsumerStatefulWidget {
  final Product product;
  final String? pelangganId;
  final CartItem? existingCartItem; // null = tambah baru, non-null = edit

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

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _qty = widget.existingCartItem?.quantity ?? 1;

    // Initialize unit selection: restore from cart item or default to largest unit
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
      // Replace entire cart item with fresh product from catalog (has units populated)
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

    // Sync diskonAmount terkini ke promoSelectionProvider sebelum pop
    final selectedPromo = ref.read(promoSelectionProvider).promoForProduct(widget.product.id);
    if (selectedPromo != null && widget.pelangganId != null) {
      final promosAsync = ref.read(availablePromosProvider(widget.pelangganId!));
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
          CartItem(product: widget.product, quantity: _qty, negotiatedPrice: effectivePrice),
        ];
        double updatedDiskon = 0;
        if (selectedPromo.jenis == 'aturan_harga') {
          final promo = promos.aturanHarga
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            updatedDiskon = PromoCalculator.aturanHargaDiskonPerProduk(promo, simulatedItems, widget.product.id);
          }
        } else if (selectedPromo.jenis == 'grosir') {
          final promo = promos.grosir
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            updatedDiskon = PromoCalculator.grosirDiskonPerProduk(promo, simulatedItems, widget.product.id);
          }
        }
        ref.read(promoSelectionProvider.notifier)
            .updateDiskonForProduct(widget.product.id, updatedDiskon);
      }
    }

    context.pop(true); // return true = berhasil ditambahkan/diupdate
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
    ref.read(promoSelectionProvider.notifier).clearPromoForProduct(widget.product.id);
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final allowOpenPrice = ref.watch(allowOpenPriceProvider);
    final promoSelection = ref.watch(promoSelectionProvider);
    final selectedPromo = promoSelection.promoForProduct(widget.product.id);
    final priceLocked = selectedPromo != null;

    // Kalau promo dipilih, gunakan harga dari cart (sudah di-reset ke standar)
    final effectivePrice = priceLocked ? widget.product.hargaJual : _price;
    final totalHarga = effectivePrice * _qty;

    // Build cart items untuk promo calculation (simulasi)
    final allCartItems = ref.watch(cartControllerProvider).items;
    final simulatedItems = [
      ...allCartItems.where((i) => i.product.id != widget.product.id),
      CartItem(product: widget.product, quantity: _qty, negotiatedPrice: effectivePrice),
    ];
    final subtotalSimulated = simulatedItems.fold<double>(0, (s, i) => s + i.totalPrice);

    // Hitung ulang diskon secara realtime berdasarkan qty & simulatedItems terkini
    double diskonPromo = 0;
    if (selectedPromo != null && widget.pelangganId != null) {
      final promosAsync = ref.watch(availablePromosProvider(widget.pelangganId!));
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
            diskonPromo = PromoCalculator.aturanHargaDiskonPerProduk(promo, simulatedItems, widget.product.id);
          }
        } else if (selectedPromo.jenis == 'grosir') {
          final promo = promos.grosir
              .where((p) => p.idCampaign == selectedPromo.idCampaign)
              .firstOrNull;
          if (promo != null) {
            diskonPromo = PromoCalculator.grosirDiskonPerProduk(promo, simulatedItems, widget.product.id);
          }
        }
      }
    }

    final totalSetelahDiskon = (totalHarga - diskonPromo).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Produk' : 'Tambah ke Pesanan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(null),
        ),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              tooltip: 'Hapus dari pesanan',
              onPressed: () => _confirmRemove(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Info Card ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.gambarUrl ??
                          'https://placehold.co/200x200/png?text=Produk',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: (ctx2, url2, err2) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.namaProduk,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${widget.product.sku}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _fmt.format(_selectedUnit?.hargaJual ?? widget.product.hargaJual),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                            decoration: (_price < (_selectedUnit?.hargaJual ?? widget.product.hargaJual) && !priceLocked)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Unit Selector ─────────────────────────────────────
            if (widget.product.units.length > 1) ...[
              _SectionLabel('SATUAN'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit?.id,
                    isExpanded: true,
                    items: widget.product.units.map((u) {
                      final priceLabel = u.hargaJual != null
                          ? ' - ${_fmt.format(u.hargaJual)}'
                          : '';
                      return DropdownMenuItem<String>(
                        value: u.id,
                        child: Text(
                          '${u.nama}$priceLabel',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (unitId) {
                      final unit = widget.product.units.firstWhere((u) => u.id == unitId);
                      setState(() {
                        _selectedUnit = unit;
                        _price = unit.hargaJual ?? widget.product.hargaJual;
                        _priceController.text = _price.toStringAsFixed(0);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Qty ────────────────────────────────────────────────
            _SectionLabel('JUMLAH'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: _onQtyTextChanged,
                    ),
                  ),
                  Text(
                    _selectedUnit?.nama ?? widget.product.satuan,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 8),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: _incrementQty,
                    enabled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Harga ──────────────────────────────────────────────
            if (allowOpenPrice) ...[
              _SectionLabel('HARGA NEGO'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: priceLocked ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priceLocked ? Colors.orange.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Rp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: priceLocked ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        enabled: !priceLocked,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: priceLocked ? Colors.grey.shade400 : Colors.black87,
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
                          Icon(Icons.lock, size: 13, color: Colors.orange.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Promo aktif',
                            style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (priceLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Harga dikunci karena promo aktif. Hapus promo untuk ubah harga.',
                    style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // Promo inline
            if (widget.pelangganId != null) ...[
              Row(
                children: [
                  const Expanded(child: _SectionLabel('PROMO')),
                  _isRefreshingPromo
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : GestureDetector(
                          onTap: _refreshPromo,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text('Refresh', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),
              InlinePromoSelector(
                product: widget.product,
                qty: _qty,
                effectivePrice: effectivePrice,
                pelangganId: widget.pelangganId!,
                simulatedItems: simulatedItems,
                subtotal: subtotalSimulated,
              ),
              const SizedBox(height: 20),
            ],

            // ── Summary ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _SummaryLine(
                    label: 'Harga × $_qty ${_selectedUnit?.nama ?? widget.product.satuan}',
                    value: _fmt.format(totalHarga),
                  ),
                  if (diskonPromo > 0) ...[
                    const SizedBox(height: 4),
                    _SummaryLine(
                      label: 'Diskon',
                      value: '- ${_fmt.format(diskonPromo)}',
                      isDiscount: true,
                    ),
                  ],
                  const Divider(height: 16),
                  _SummaryLine(
                    label: 'Total',
                    value: _fmt.format(totalSetelahDiskon),
                    bold: true,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isEdit ? Icons.check : Icons.add_shopping_cart,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEdit ? 'Simpan Perubahan' : 'Tambah ke Pesanan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) _removeFromCart();
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
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
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.primary : Colors.grey.shade400,
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
          style: TextStyle(
            fontSize: 13,
            color: isDiscount ? AppTheme.success : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color ?? (isDiscount ? AppTheme.success : Colors.black87),
          ),
        ),
      ],
    );
  }
}
