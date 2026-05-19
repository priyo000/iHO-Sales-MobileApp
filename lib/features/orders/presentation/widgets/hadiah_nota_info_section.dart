import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';

class HadiahNotaInfoSection extends StatelessWidget {
  final List hadiahNotaPromos;
  final List items;
  final NumberFormat currencyFormat;

  const HadiahNotaInfoSection({
    super.key,
    required this.hadiahNotaPromos,
    required this.items,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 14, color: Colors.teal.shade700),
                const SizedBox(width: 6),
                Text(
                  "Hadiah Per Nota",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: hadiahNotaPromos.map<Widget>((p) {
                final idCampaign = p["id_promo_campaign"];
                final namaPromo = p["nama_promo"] as String? ?? "Hadiah Nota";
                final hadiahItems = items
                    .where(
                      (i) =>
                          i["is_hadiah"] == true &&
                          i["id_promo_campaign"].toString() ==
                              idCampaign.toString(),
                    )
                    .toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            size: 12,
                            color: Colors.teal.shade600,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              namaPromo,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...hadiahItems.map<Widget>((hi) {
                        final produk = hi["produk"] as Map? ?? {};
                        final namaHadiah =
                            produk["nama_produk"] as String? ?? "Produk Hadiah";
                        final qty = hi["jumlah"] as int? ?? 1;
                        final harga =
                            double.tryParse(
                              hi["harga_satuan"]?.toString() ?? "0",
                            ) ??
                            0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 14,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "$namaHadiah x$qty",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: harga > 0
                                        ? Colors.teal.shade400
                                        : AppTheme.success,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    harga > 0
                                        ? currencyFormat.format(harga)
                                        : "Gratis",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
