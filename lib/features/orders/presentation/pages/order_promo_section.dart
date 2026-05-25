import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import '../controllers/promo_controller.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/promo_model.dart';
import '../../data/promo_calculator.dart';

final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

// ---------------------------------------------------------------------------
// Public: inline promo row — dipakai di dalam CartItemCard
// ---------------------------------------------------------------------------

class ProductPromoRow extends ConsumerWidget {
  final CartItem cartItem;
  final String pelangganId;
  final List<CartItem> allCartItems;
  final double subtotal;

  const ProductPromoRow({
    super.key,
    required this.cartItem,
    required this.pelangganId,
    required this.allCartItems,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(availablePromosProvider(pelangganId));
    final selected = ref.watch(
      promoSelectionProvider.select((s) => s.promoForProduct(cartItem.product.id)),
    );

    return promosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (promos) {
        final options = _buildOptions(
          cartItem: cartItem,
          promos: promos,
          allCartItems: allCartItems,
          subtotal: subtotal,
        );
        if (options.isEmpty) return const SizedBox.shrink();

        // Auto-select jika hanya ada 1 promo dan belum ada pilihan
        if (options.length == 1 && selected == null) {
          final opt = options.first;
          final enabled = opt.jenis != 'hadiah' || (opt.syaratOk ?? false);
          if (enabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(promoSelectionProvider.notifier).selectPromoForProduct(
                ItemPromoApplied(
                  idCampaign: opt.idCampaign,
                  namaPromo: opt.namaPromo,
                  jenis: opt.jenis,
                  idProduk: opt.idProduk,
                  diskonAmount: opt.diskonAmount,
                  idProdukHadiah: opt.hadiahItem?.produkHadiah.id,
                  namaProdukHadiah: opt.hadiahItem?.produkHadiah.namaProduk,
                  qtyHadiah: opt.hadiahItem?.qtyHadiah,
                  hargaTebus: opt.hadiahItem?.hargaTebus,
                ),
              );
            });
          }
        }

        return GestureDetector(
          onTap: () => _showPromoSheet(context, ref, options, selected),
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected != null
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected != null
                    ? AppColors.success.withValues(alpha: 0.4)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected != null ? Icons.local_offer : Icons.local_offer_outlined,
                  size: 14,
                  color: selected != null ? AppColors.success : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: selected != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.namaPromo,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                            if (selected.diskonAmount > 0)
                              Text(
                                'Hemat ${_fmt.format(selected.diskonAmount)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success.withValues(alpha: 0.8),
                                ),
                              )
                            else if (selected.isHadiah)
                              Text(
                                'Hadiah: ${selected.namaProdukHadiah ?? ""} x${selected.qtyHadiah ?? 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        )
                      : Text(
                          '${options.length} promo tersedia — Ketuk untuk pilih',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: selected != null ? AppColors.success : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPromoSheet(
    BuildContext context,
    WidgetRef ref,
    List<_PromoOption> options,
    ItemPromoApplied? selected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromoBottomSheet(
        productName: cartItem.product.namaProduk,
        options: options,
        selected: selected,
        onSelect: (opt) {
          ref.read(promoSelectionProvider.notifier).selectPromoForProduct(
            ItemPromoApplied(
              idCampaign: opt.idCampaign,
              namaPromo: opt.namaPromo,
              jenis: opt.jenis,
              idProduk: cartItem.product.id,
              diskonAmount: opt.diskonAmount,
              idProdukHadiah: opt.hadiahItem?.produkHadiah.id,
              namaProdukHadiah: opt.hadiahItem?.produkHadiah.namaProduk,
              qtyHadiah: opt.hadiahItem?.qtyHadiah,
              hargaTebus: opt.hadiahItem?.hargaTebus,
            ),
          );
        },
        onClear: () => ref
            .read(promoSelectionProvider.notifier)
            .clearPromoForProduct(cartItem.product.id),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Public: hadiah by nota section — ditampilkan sekali di bawah semua produk
// ---------------------------------------------------------------------------

class HadiahNotaSection extends ConsumerWidget {
  final String pelangganId;
  final List<CartItem> cartItems;
  final double subtotal;

  const HadiahNotaSection({
    super.key,
    required this.pelangganId,
    required this.cartItems,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(availablePromosProvider(pelangganId));
    final promoSelection = ref.watch(promoSelectionProvider);
    final notifier = ref.read(promoSelectionProvider.notifier);

    return promosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (promos) {
        final tiles = <Widget>[];
        for (final p in promos.hadiah) {
          for (final item in p.items) {
            if (item.jenisPemicu != 'total_nota') continue;
            final syaratOk = PromoCalculator.hadiahSyaratTerpenuhi(
                item, cartItems, subtotal);
            final isSelected = promoSelection.isHadiahSelected(
                p.idCampaign, item.produkHadiah.id);
            tiles.add(_HadiahNotaTile(
              namaPromo: p.namaPromo,
              item: item,
              syaratOk: syaratOk,
              isSelected: isSelected,
              onTap: syaratOk
                  ? () => notifier.toggleHadiahNota(HadiahNotaApplied(
                        idCampaign: p.idCampaign,
                        namaPromo: p.namaPromo,
                        idProdukHadiah: item.produkHadiah.id,
                        namaProdukHadiah: item.produkHadiah.namaProduk,
                        qty: item.qtyHadiah,
                        hargaTebus: item.hargaTebus,
                      ))
                  : null,
            ));
          }
        }
        if (tiles.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('HADIAH PER NOTA'),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: tiles),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet
// ---------------------------------------------------------------------------

class _PromoBottomSheet extends StatefulWidget {
  final String productName;
  final List<_PromoOption> options;
  final ItemPromoApplied? selected;
  final ValueChanged<_PromoOption> onSelect;
  final VoidCallback onClear;

  const _PromoBottomSheet({
    required this.productName,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<_PromoBottomSheet> createState() => _PromoBottomSheetState();
}

class _PromoBottomSheetState extends State<_PromoBottomSheet> {
  int? _selectedIndex; // null = tanpa promo

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _selectedIndex = widget.options.indexWhere(
        (o) =>
            o.idCampaign == widget.selected!.idCampaign &&
            o.jenis == widget.selected!.jenis,
      );
      if (_selectedIndex == -1) _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Text(
            'Pilih Promo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.productName,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          // Tanpa promo option
          _PromoOptionTile(
            isSelected: _selectedIndex == null,
            onTap: () => setState(() => _selectedIndex = null),
            child: const Text(
              'Tanpa Promo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 6),
          // Promo options
          ...List.generate(widget.options.length, (i) {
            final opt = widget.options[i];
            final enabled = opt.jenis != 'hadiah' || (opt.syaratOk ?? false);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PromoOptionTile(
                isSelected: _selectedIndex == i,
                enabled: enabled,
                onTap: enabled ? () => setState(() => _selectedIndex = i) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt.namaPromo,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: enabled ? AppColors.textPrimary : Colors.grey,
                            ),
                          ),
                        ),
                        _JenisBadge(opt.jenis),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Detail per jenis promo
                    if (opt.jenis == 'aturan_harga' && opt.hargaNormal != null && opt.hargaFinal != null)
                      _AturanHargaDetail(opt: opt)
                    else if (opt.jenis == 'grosir' && opt.tiers != null)
                      _GrosirDetail(opt: opt)
                    else if (opt.jenis == 'hadiah' && opt.hadiahItem != null)
                      _HadiahDetail(opt: opt)
                    else
                      Text(
                        opt.benefit,
                        style: TextStyle(
                          fontSize: 11,
                          color: enabled ? AppColors.success : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (opt.syarat.isNotEmpty)
                      Text(
                        opt.syarat,
                        style: TextStyle(
                          fontSize: 10,
                          color: enabled
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedIndex == null) {
                  widget.onClear();
                } else {
                  widget.onSelect(widget.options[_selectedIndex!]);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Terapkan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoOptionTile extends StatelessWidget {
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget child;

  const _PromoOptionTile({
    required this.isSelected,
    required this.child,
    this.enabled = true,
    this.onTap,
  }

  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE3F0FD)
              : enabled ? Colors.grey.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _JenisBadge extends StatelessWidget {
  final String jenis;
  const _JenisBadge(this.jenis);

  @override
  Widget build(BuildContext context) {
    final configs = <String, (String, Color)>{
      'aturan_harga': ('Harga Spesial', Colors.blue),
      'grosir': ('Grosir', Colors.purple),
      'hadiah': ('Hadiah', Colors.orange),
    };
    final cfg = configs[jenis] ?? ('Promo', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.$2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        cfg.$1,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: cfg.$2,
        ),
      ),
    );
  }
}

class _HadiahNotaTile extends StatelessWidget {
  final String namaPromo;
  final PromoHadiahItem item;
  final bool syaratOk;
  final bool isSelected;
  final VoidCallback? onTap;

  const _HadiahNotaTile({
    required this.namaPromo,
    required this.item,
    required this.syaratOk,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: !syaratOk
                      ? Colors.grey.shade300
                      : isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.surface)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaPromo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: syaratOk ? AppColors.textPrimary : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.produkHadiah.namaProduk ?? "Hadiah"} x${item.qtyHadiah}'
                    '${item.hargaTebus > 0 ? " (${_fmt.format(item.hargaTebus)})" : " (Gratis)"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: syaratOk ? AppColors.success : Colors.grey,
                    ),
                  ),
                  Text(
                    'Min. nota ${_fmt.format(item.minAmountPemicu ?? 0)}'
                    '${syaratOk ? " \u2713 Terpenuhi" : " \u2014 Belum terpenuhi"}',
                    style: TextStyle(
                      fontSize: 10,
                      color: syaratOk ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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



// ---------------------------------------------------------------------------
// Detail widgets for bottom sheet
// ---------------------------------------------------------------------------

class _AturanHargaDetail extends StatelessWidget {
  final _PromoOption opt;
  const _AturanHargaDetail({required this.opt});

  @override
  Widget build(BuildContext context) {
    final hNormal = opt.hargaNormal!;
    final hFinal = opt.hargaFinal!;
    final selisih = hNormal - hFinal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt.format(hNormal),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  _fmt.format(hFinal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Builder(builder: (_) {
                final persen = opt.diskonPersen ?? (hNormal > 0 ? (selisih / hNormal * 100) : 0.0);
                if (persen <= 0) return const SizedBox.shrink();
                final persenStr = persen == persen.truncateToDouble()
                    ? '-${persen.toStringAsFixed(0)}%'
                    : '-${persen.toStringAsFixed(1)}%';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    persenStr,
                    style: const TextStyle(fontSize: 10, color: AppColors.surface, fontWeight: FontWeight.bold),
                  ),
                );
              }),
              if (selisih > 0)
                Text(
                  'Hemat ${_fmt.format(selisih)}/pcs',
                  style: const TextStyle(fontSize: 10, color: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrosirDetail extends StatelessWidget {
  final _PromoOption opt;
  const _GrosirDetail({required this.opt});

  @override
  Widget build(BuildContext context) {
    final hNormal = opt.hargaNormal ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...opt.tiers!.map((tier) {
          final hFinal = tier.hargaFinal(hNormal);
          final selisih = hNormal - hFinal;
          final isActive = opt.activeTierMinQty == tier.minQty;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? AppColors.success.withValues(alpha: 0.4) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Min ${tier.minQty} pcs',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.success : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Builder(builder: (_) {
                  final persen = tier.diskonPersen ?? (hNormal > 0 ? ((hNormal - hFinal) / hNormal * 100) : 0.0);
                  if (persen <= 0) return const SizedBox.shrink();
                  final persenStr = persen == persen.truncateToDouble()
                      ? '-${persen.toStringAsFixed(0)}%'
                      : '-${persen.toStringAsFixed(1)}%';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      persenStr,
                      style: const TextStyle(fontSize: 9, color: AppColors.surface, fontWeight: FontWeight.bold),
                    ),
                  );
                }),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmt.format(hFinal),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? AppColors.textPrimary : Colors.grey.shade500,
                      ),
                    ),
                    if (selisih > 0 && hNormal > 0)
                      Text(
                        'Hemat ${_fmt.format(selisih)}/pcs',
                        style: TextStyle(fontSize: 9, color: isActive ? AppColors.success : Colors.grey.shade400),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _HadiahDetail extends StatelessWidget {
  final _PromoOption opt;
  const _HadiahDetail({required this.opt});

  @override
  Widget build(BuildContext context) {
    final item = opt.hadiahItem!;
    final hargaLabel = item.hargaTebus > 0 ? _fmt.format(item.hargaTebus) : 'Gratis';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item.produkHadiah.namaProduk ?? "Hadiah"} x${item.qtyHadiah}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.hargaTebus > 0 ? Colors.orange.shade400 : AppColors.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hargaLabel,
              style: const TextStyle(fontSize: 11, color: AppColors.surface, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
List<_PromoOption> _buildOptions({
  required CartItem cartItem,
  required AvailablePromos promos,
  required List<CartItem> allCartItems,
  required double subtotal,
}) {
  final options = <_PromoOption>[];

  for (final p in promos.aturanHarga) {
    final rule = p.items.where((i) => i.idProduk == cartItem.product.id).firstOrNull;
    if (rule == null) continue;
    final diskon = PromoCalculator.aturanHargaDiskonPerProduk(p, allCartItems, cartItem.product.id);
    options.add(_PromoOption(
      idCampaign: p.idCampaign,
      namaPromo: p.namaPromo,
      jenis: 'aturan_harga',
      idProduk: cartItem.product.id,
      diskonAmount: diskon,
      benefit: diskon > 0 ? 'Hemat ${_fmt.format(diskon)}' : 'Harga spesial berlaku',
      syarat: '',
      hargaNormal: rule.hargaNormal > 0 ? rule.hargaNormal : cartItem.product.hargaJual,
      hargaFinal: rule.hargaFinal,
      diskonPersen: rule.diskonPersen,
    ));
  }

  for (final p in promos.grosir) {
    final item = p.items.where((i) => i.idProduk == cartItem.product.id).firstOrNull;
    if (item == null) continue;
    final diskon = PromoCalculator.grosirDiskonPerProduk(p, allCartItems, cartItem.product.id);
    final tier = item.getTierForQty(cartItem.quantity);
    options.add(_PromoOption(
      idCampaign: p.idCampaign,
      namaPromo: p.namaPromo,
      jenis: 'grosir',
      idProduk: cartItem.product.id,
      diskonAmount: diskon,
      benefit: diskon > 0 ? 'Hemat ${_fmt.format(diskon)}' : 'Harga grosir berlaku',
      syarat: tier != null
          ? 'Tier aktif: min ${tier.minQty} pcs'
          : 'Tambah qty untuk aktifkan tier',
      hargaNormal: item.hargaNormal > 0 ? item.hargaNormal : cartItem.product.hargaJual,
      tiers: item.tiers,
      activeTierMinQty: tier?.minQty,
    ));
  }

  for (final p in promos.hadiah) {
    for (final item in p.items) {
      // jenis_pemicu == 'total_nota' items are intentionally skipped here.
      // Those are order-level hadiah (triggered by the total invoice amount)
      // and are handled separately in HadiahNotaSection (above in this file),
      // not per-product.
      if (item.jenisPemicu != 'produk') continue;
      if (item.idProdukPemicu != cartItem.product.id) continue;
      final syaratOk = PromoCalculator.hadiahSyaratTerpenuhi(item, allCartItems, subtotal);
      final hLabel = item.hargaTebus > 0 ? _fmt.format(item.hargaTebus) : 'Gratis';
      options.add(_PromoOption(
        idCampaign: p.idCampaign,
        namaPromo: p.namaPromo,
        jenis: 'hadiah',
        idProduk: cartItem.product.id,
        diskonAmount: 0,
        benefit: '${item.produkHadiah.namaProduk ?? "Hadiah"} x${item.qtyHadiah} ($hLabel)',
        syarat: syaratOk
            ? '\u2713 Syarat terpenuhi'
            : 'Beli min ${item.minQtyPemicu ?? 0} pcs ${item.namaProdukPemicu ?? ""}',
        syaratOk: syaratOk,
        hadiahItem: item,
      ));
    }
  }

  return options;
}

class _PromoOption {
  final String idCampaign;
  final String namaPromo;
  final String jenis;
  final String idProduk;
  final double diskonAmount;
  final String benefit;
  final String syarat;
  final bool? syaratOk;
  final PromoHadiahItem? hadiahItem;
  final double? hargaNormal;
  final double? hargaFinal;
  final double? diskonPersen;
  final List<PromoGrosirTier>? tiers;
  final int? activeTierMinQty;

  const _PromoOption({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    required this.idProduk,
    required this.diskonAmount,
    required this.benefit,
    required this.syarat,
    this.syaratOk,
    this.hadiahItem,
    this.hargaNormal,
    this.hargaFinal,
    this.diskonPersen,
    this.tiers,
    this.activeTierMinQty,
  });
}
