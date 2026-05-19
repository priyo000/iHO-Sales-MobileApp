import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/promo_model.dart';
import '../../data/promo_calculator.dart';
import '../../presentation/controllers/promo_controller.dart';

final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class InlinePromoSelector extends ConsumerWidget {
  final Product product;
  final int qty;
  final double effectivePrice;
  final String pelangganId;
  final List<CartItem> simulatedItems;
  final double subtotal;

  const InlinePromoSelector({
    super.key,
    required this.product,
    required this.qty,
    required this.effectivePrice,
    required this.pelangganId,
    required this.simulatedItems,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(availablePromosProvider(pelangganId));
    final selected = ref.watch(
      promoSelectionProvider.select((s) => s.promoForProduct(product.id)),
    );
    final notifier = ref.read(promoSelectionProvider.notifier);

    return promosAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
      error: (err, st) => const SizedBox.shrink(),
      data: (promos) {
        final cartItem = CartItem(
          product: product,
          quantity: qty,
          negotiatedPrice: effectivePrice,
        );
        final options = buildPromoOptions(
          cartItem: cartItem,
          promos: promos,
          allCartItems: simulatedItems,
          subtotal: subtotal,
        );

        if (options.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Tidak ada promo tersedia untuk produk ini',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              PromoTile(
                isSelected: selected == null,
                onTap: () => notifier.clearPromoForProduct(product.id),
                title: 'Tanpa Promo',
                subtitle: null,
                detail: null,
                enabled: true,
              ),
              ...options.map((opt) {
                final isSelected = selected?.idCampaign == opt.idCampaign &&
                    selected?.jenis == opt.jenis;
                return PromoTile(
                  isSelected: isSelected,
                  enabled: opt.enabled,
                  onTap: opt.enabled
                      ? () => notifier.selectPromoForProduct(
                            ItemPromoApplied(
                              idCampaign: opt.idCampaign,
                              namaPromo: opt.namaPromo,
                              jenis: opt.jenis,
                              idProduk: product.id,
                              diskonAmount: opt.diskonAmount,
                              idProdukHadiah: opt.hadiahItem?.produkHadiah.id,
                              namaProdukHadiah:
                                  opt.hadiahItem?.produkHadiah.namaProduk,
                              qtyHadiah: opt.hadiahItem?.qtyHadiah,
                              hargaTebus: opt.hadiahItem?.hargaTebus,
                            ),
                          )
                      : null,
                  title: opt.namaPromo,
                  subtitle: opt.benefit,
                  detail: opt.detail,
                  jenis: opt.jenis,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class PromoTile extends StatelessWidget {
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;
  final Widget? detail;
  final String? jenis;

  const PromoTile({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.detail,
    this.enabled = true,
    this.jenis,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: !enabled
                      ? Colors.grey.shade300
                      : isSelected
                          ? AppTheme.primary
                          : Colors.grey.shade400,
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
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: !enabled
                                ? Colors.grey.shade400
                                : isSelected
                                    ? AppTheme.primary
                                    : Colors.black87,
                          ),
                        ),
                      ),
                      if (jenis != null) PromoJenisBadge(jenis!),
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            enabled ? AppTheme.success : Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    detail!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoJenisBadge extends StatelessWidget {
  final String jenis;
  const PromoJenisBadge(this.jenis, {super.key});

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

class PromoEntry {
  final String idCampaign;
  final String namaPromo;
  final String jenis;
  final double diskonAmount;
  final String benefit;
  final Widget? detail;
  final bool enabled;
  final PromoHadiahItem? hadiahItem;

  const PromoEntry({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    required this.diskonAmount,
    required this.benefit,
    required this.enabled,
    this.detail,
    this.hadiahItem,
  });
}

List<PromoEntry> buildPromoOptions({
  required CartItem cartItem,
  required AvailablePromos promos,
  required List<CartItem> allCartItems,
  required double subtotal,
}) {
  final options = <PromoEntry>[];

  for (final p in promos.aturanHarga) {
    final rule =
        p.items.where((i) => i.idProduk == cartItem.product.id).firstOrNull;
    if (rule == null) continue;
    final diskon = PromoCalculator.aturanHargaDiskonPerProduk(p, allCartItems, cartItem.product.id);
    final hNormal =
        rule.hargaNormal > 0 ? rule.hargaNormal : cartItem.product.hargaJual;
    options.add(PromoEntry(
      idCampaign: p.idCampaign,
      namaPromo: p.namaPromo,
      jenis: 'aturan_harga',
      diskonAmount: diskon,
      benefit:
          diskon > 0 ? 'Hemat ${_fmt.format(diskon)}' : 'Harga spesial berlaku',
      enabled: true,
      detail: _AturanHargaDetail(
        hNormal: hNormal,
        hFinal: rule.hargaFinal,
        diskonPersen: rule.diskonPersen,
      ),
    ));
  }

  for (final p in promos.grosir) {
    final item =
        p.items.where((i) => i.idProduk == cartItem.product.id).firstOrNull;
    if (item == null) continue;
    final diskon = PromoCalculator.grosirDiskonPerProduk(p, allCartItems, cartItem.product.id);
    final hNormal =
        item.hargaNormal > 0 ? item.hargaNormal : cartItem.product.hargaJual;
    final activeTier = item.getTierForQty(cartItem.quantity);
    options.add(PromoEntry(
      idCampaign: p.idCampaign,
      namaPromo: p.namaPromo,
      jenis: 'grosir',
      diskonAmount: diskon,
      benefit: diskon > 0
          ? 'Hemat ${_fmt.format(diskon)}'
          : 'Tambah qty untuk aktifkan tier',
      enabled: true,
      detail: _GrosirTiersDetail(
        tiers: item.tiers,
        hNormal: hNormal,
        activeTierMinQty: activeTier?.minQty,
      ),
    ));
  }

  for (final p in promos.hadiah) {
    for (final item in p.items) {
      // jenis_pemicu == 'total_nota' items are intentionally skipped here.
      // Those are order-level hadiah (triggered by the total invoice amount)
      // and are handled separately in HadiahNotaSection inside
      // order_promo_section.dart, not per-product.
      if (item.jenisPemicu != 'produk') continue;
      if (item.idProdukPemicu != cartItem.product.id) continue;
      final syaratOk = PromoCalculator.hadiahSyaratTerpenuhi(
          item, allCartItems, subtotal);
      options.add(PromoEntry(
        idCampaign: p.idCampaign,
        namaPromo: p.namaPromo,
        jenis: 'hadiah',
        diskonAmount: 0,
        benefit: syaratOk
            ? 'Syarat terpenuhi'
            : 'Beli min ${item.minQtyPemicu ?? 0} pcs',
        enabled: syaratOk,
        hadiahItem: item,
        detail: _HadiahItemDetail(item: item),
      ));
    }
  }

  return options;
}

class _AturanHargaDetail extends StatelessWidget {
  final double hNormal;
  final double hFinal;
  final double? diskonPersen;

  const _AturanHargaDetail({
    required this.hNormal,
    required this.hFinal,
    required this.diskonPersen,
  });

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
              ],
            ),
          ),
          Builder(builder: (_) {
            final persen = diskonPersen ?? (hNormal > 0 ? ((hNormal - hFinal) / hNormal * 100) : 0.0);
            if (persen <= 0) return const SizedBox.shrink();
            final persenStr = persen == persen.truncateToDouble()
                ? '-${persen.toStringAsFixed(0)}%'
                : '-${persen.toStringAsFixed(1)}%';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                persenStr,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GrosirTiersDetail extends StatelessWidget {
  final List<PromoGrosirTier> tiers;
  final double hNormal;
  final int? activeTierMinQty;

  const _GrosirTiersDetail({
    required this.tiers,
    required this.hNormal,
    required this.activeTierMinQty,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tiers.map((tier) {
        final hFinal = tier.hargaFinal(hNormal);
        final isActive = activeTierMinQty == tier.minQty;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? AppTheme.success.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Text(
                'Min ${tier.minQty} pcs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                  color:
                      isActive ? AppTheme.success : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Builder(builder: (_) {
                final persen = tier.diskonPersen ?? (hNormal > 0 ? ((hNormal - hFinal) / hNormal * 100) : 0.0);
                if (persen <= 0) return const SizedBox.shrink();
                final persenStr = persen == persen.truncateToDouble()
                    ? '-${persen.toStringAsFixed(0)}%'
                    : '-${persen.toStringAsFixed(1)}%';
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.success : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    persenStr,
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }),
              Text(
                _fmt.format(hFinal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HadiahItemDetail extends StatelessWidget {
  final PromoHadiahItem item;
  const _HadiahItemDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final hargaLabel = item.hargaTebus > 0
        ? _fmt.format(item.hargaTebus)
        : 'Gratis';
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
              color: item.hargaTebus > 0 ? Colors.orange.shade400 : AppTheme.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hargaLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
