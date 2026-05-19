import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';

class OrderItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat fmt;
  final Map<String, dynamic>? promoApplied;
  final Map<String, dynamic>? hadiahItem;

  const OrderItemTile({
    super.key,
    required this.item,
    required this.fmt,
    this.promoApplied,
    this.hadiahItem,
  });

  @override
  Widget build(BuildContext context) {
    final product = item["produk"] as Map<String, dynamic>? ?? {};
    final nama =
        product["nama_produk"] as String? ??
        item["nama_barang"] as String? ??
        "Produk";
    final satuan = product["satuan"] as String? ?? "pcs";
    final qtyActual = item["jumlah"] as int? ?? 0;
    final qtyOrdered = item["jumlah_pesanan"] as int? ?? qtyActual;
    final hargaSatuan =
        double.tryParse(item["harga_satuan"]?.toString() ?? "0") ?? 0;
    final totalHarga =
        double.tryParse(item["total_harga"]?.toString() ?? "0") ??
        (hargaSatuan * qtyActual);
    final isHadiah = item["is_hadiah"] == true;
    final keterangan = item["keterangan"] as String?;
    final hasBackorder = qtyActual < qtyOrdered;
    final hargaTebus =
        double.tryParse(item["harga_tebus"]?.toString() ?? "0") ?? 0;
    final hargaNormal =
        double.tryParse(product["harga_jual"]?.toString() ?? "0") ?? 0;

    final hasPromo = promoApplied != null;
    final promoJenis = promoApplied?["jenis"] as String? ?? "";
    final promoNama = promoApplied?["nama_promo"] as String? ?? "";
    final promoDiskon =
        double.tryParse(promoApplied?["diskon_amount"]?.toString() ?? "0") ?? 0;
    final isPromoHadiah = promoJenis == "hadiah";
    final isNego = !isHadiah && hargaNormal > 0 && hargaSatuan < hargaNormal;
    final totalSebelumDiskon = hargaSatuan * qtyActual;
    final totalFinal = (totalSebelumDiskon - promoDiskon).clamp(
      0.0,
      double.infinity,
    );

    Color jenisColor(String j) {
      switch (j) {
        case "aturan_harga":
          return Colors.blue;
        case "grosir":
          return Colors.purple;
        case "hadiah":
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    String jenisLabel(String j) {
      switch (j) {
        case "aturan_harga":
          return "Harga Spesial";
        case "grosir":
          return "Grosir";
        case "hadiah":
          return "Hadiah";
        default:
          return "Promo";
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHadiah
              ? Colors.orange.shade200
              : hasPromo
              ? AppTheme.success.withValues(alpha: 0.25)
              : hasBackorder
              ? Colors.orange.shade200
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isHadiah
                        ? Colors.orange.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isHadiah ? Icons.card_giftcard : Icons.inventory_2_outlined,
                    size: 24,
                    color: isHadiah ? Colors.orange : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHadiah) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: hargaTebus > 0
                                    ? Colors.orange.shade400
                                    : AppTheme.success,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                hargaTebus > 0 ? "TEBUS" : "BONUS",
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (keterangan != null && keterangan.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          keterangan,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            "$qtyActual $satuan",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "  x  ",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          if (isNego) ...[
                            Text(
                              fmt.format(hargaNormal),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            fmt.format(
                              isHadiah && hargaTebus > 0
                                  ? hargaTebus
                                  : hargaSatuan,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isNego
                                  ? AppTheme.primary
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hasBackorder) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Kirim $qtyActual/$qtyOrdered",
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isHadiah && promoDiskon > 0) ...[
                      Text(
                        fmt.format(totalSebelumDiskon),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        fmt.format(totalFinal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                    ] else
                      Text(
                        fmt.format(isHadiah ? totalHarga : totalSebelumDiskon),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isHadiah
                              ? Colors.orange.shade700
                              : AppTheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (hasBackorder)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(top: BorderSide(color: Colors.orange.shade100)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Kekurangan ${qtyOrdered - qtyActual} $satuan — akan di-backorder",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          if (!isHadiah && hasPromo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FBF4),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.success.withValues(alpha: 0.15),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, size: 12, color: AppTheme.success),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: jenisColor(promoJenis).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          jenisLabel(promoJenis),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: jenisColor(promoJenis),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          promoNama,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  if ((promoJenis == "aturan_harga" || promoJenis == "grosir") &&
                      promoDiskon > 0)
                    _buildPriceBreakdown(
                      hargaSatuan: hargaSatuan,
                      totalSebelumDiskon: totalSebelumDiskon,
                      promoDiskon: promoDiskon,
                      qtyActual: qtyActual,
                    )
                  else if (isPromoHadiah && hadiahItem != null)
                    _buildHadiahBreakdown(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown({
    required double hargaSatuan,
    required double totalSebelumDiskon,
    required double promoDiskon,
    required int qtyActual,
  }) {
    final hargaFinalPerPcs = qtyActual > 0
        ? (totalSebelumDiskon - promoDiskon) / qtyActual
        : hargaSatuan;
    final selisihPerPcs = hargaSatuan - hargaFinalPerPcs;
    final persen =
        hargaSatuan > 0 ? (selisihPerPcs / hargaSatuan * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fmt.format(hargaSatuan),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 10, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      fmt.format(hargaFinalPerPcs),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      " / pcs",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "Hemat ${fmt.format(selisihPerPcs)}/pcs x $qtyActual = ${fmt.format(promoDiskon)}",
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          if (persen > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "-${persen % 1 == 0 ? persen.toStringAsFixed(0) : persen.toStringAsFixed(1)}%",
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

  Widget _buildHadiahBreakdown() {
    final namaProdukHadiah =
        (hadiahItem!["produk"] as Map?)?["nama_produk"] as String? ??
        "Produk Hadiah";
    final ht =
        double.tryParse(hadiahItem!["harga_satuan"]?.toString() ?? "0") ?? 0;
    final qtyHadiah = hadiahItem!["jumlah"] as int? ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaProdukHadiah,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  "$qtyHadiah pcs",
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ht > 0 ? Colors.orange.shade400 : AppTheme.success,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              ht > 0 ? fmt.format(ht) : "Gratis",
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
