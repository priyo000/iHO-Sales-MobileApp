import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import '../../../../core/providers/database_providers.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/promo_controller.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../controllers/order_history_controller.dart';

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
    final finalTotal = (subtotal + totalHadiah - diskon).clamp(
      0.0,
      double.infinity,
    );

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Review Pesanan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang kosong',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/catalog'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Items Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                                indent: 16,
                                endIndent: 16,
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
                      // Tambah Produk Button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _DashedOutlineButton(
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
                          icon: Icons.add,
                          label: 'Tambah Produk',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Order Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(color: Colors.black87),
                          ),
                          Text(
                            currencyFmt.format(subtotal),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      if (diskon > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Diskon',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                            Text(
                              '-${currencyFmt.format(diskon)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (totalHadiah > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Hadiah',
                                  style: TextStyle(color: Colors.orange),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.card_giftcard,
                                  color: Colors.orange[700],
                                  size: 16,
                                ),
                              ],
                            ),
                            Text(
                              '+${currencyFmt.format(totalHadiah)}',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            currencyFmt.format(finalTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(widget.isEdit
                            ? 'SIMPAN PERUBAHAN'
                            : 'SUBMIT PESANAN'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _editItem(BuildContext context, WidgetRef ref, CartItem item) async {
    // Fetch fresh product with units from DB to ensure dropdown renders
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.product.gambarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.gambarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(Icons.inventory_2_outlined, color: Colors.grey[400]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.namaProduk,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity}x ${currencyFmt.format(item.price)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (hasPromo) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHadiah
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHadiah)
                            Icon(
                              Icons.card_giftcard,
                              size: 12,
                              color: Colors.orange[700],
                            )
                          else
                            Icon(
                              Icons.local_offer,
                              size: 12,
                              color: Colors.green[700],
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isHadiah
                                ? 'Hadiah'
                                : '-${currencyFmt.format(itemPromo.diskonAmount)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isHadiah
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

/// Dashed outline button with blue theme
class _DashedOutlineButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _DashedOutlineButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primary,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
