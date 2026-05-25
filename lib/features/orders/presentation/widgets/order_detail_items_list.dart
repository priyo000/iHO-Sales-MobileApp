import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loading.dart';
import 'hadiah_nota_info_section.dart';
import 'order_item_tile.dart';
import 'order_summary_section.dart';

class OrderDetailItemsList extends StatelessWidget {
  const OrderDetailItemsList({
    super.key,
    required this.items,
    required this.regularItems,
    required this.promos,
    required this.hadiahNotaPromos,
    required this.subtotalItems,
    required this.diskonTotal,
    required this.total,
    required this.totalHadiah,
    required this.currencyFormat,
    required this.isLoading,
  });

  final List<dynamic> items;
  final List<dynamic> regularItems;
  final List<dynamic> promos;
  final List<dynamic> hadiahNotaPromos;
  final double subtotalItems;
  final double diskonTotal;
  final double total;
  final double totalHadiah;
  final NumberFormat currencyFormat;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Detail Pesanan',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: AppLoading(),
          )
        else if (items.isEmpty)
          Text(
            'Tidak ada item.',
            style: AppTextStyles.bodyMedium,
          )
        else ...[
          ...regularItems.map<Widget>((item) {
            final itemPromo = promos
                .where(
                  (p) =>
                      p['jenis'] != 'hadiah_nota' &&
                      p['id_produk'] != null &&
                      p['id_produk'].toString() ==
                          item['id_produk'].toString(),
                )
                .firstOrNull;
            final hadiahItem = itemPromo != null
                ? items
                    .where(
                      (i) =>
                          i['is_hadiah'] == true &&
                          i['id_promo_campaign'].toString() ==
                              itemPromo['id_promo_campaign'].toString(),
                    )
                    .firstOrNull
                : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: OrderItemTile(
                item: item as Map<String, dynamic>,
                fmt: currencyFormat,
                promoApplied: itemPromo as Map<String, dynamic>?,
                hadiahItem: hadiahItem as Map<String, dynamic>?,
              ),
            );
          }),
          if (hadiahNotaPromos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            HadiahNotaInfoSection(
              hadiahNotaPromos: hadiahNotaPromos,
              items: items,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          OrderSummarySection(
            subtotal: subtotalItems,
            diskonTotal: diskonTotal,
            totalHadiah: totalHadiah,
            grandTotal: total,
            fmt: currencyFormat,
          ),
        ],
      ],
    );
  }
}
