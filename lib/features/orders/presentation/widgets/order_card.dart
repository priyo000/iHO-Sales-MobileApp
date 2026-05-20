import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/constants/order_status.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/widgets/store_image.dart';

/// A single order card for use inside ListView.builder.
/// Extracted to a separate widget class so Flutter can properly recycle
/// list items for better performance with large datasets.
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final void Function(Map<String, dynamic>) onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
      case 'success':
        return Colors.green;
      case 'proses':
      case 'process':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'batal':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pelanggan = order['pelanggan'] as Map<String, dynamic>? ?? {};
    final items = order['items'] as List? ?? [];
    final total = double.tryParse(order['total_tagihan'].toString()) ?? 0.0;
    // Parse date: prefer tanggal_transaksi (epoch ms from API) over created_at
    DateTime? date;
    final tanggalTx = order['tanggal_transaksi'];
    if (tanggalTx is int) {
      date = DateTime.fromMillisecondsSinceEpoch(tanggalTx);
    } else {
      // Fallback: created_at (epoch ms) or tanggal_transaksi (ISO string)
      final createdAt = order['created_at'];
      if (createdAt is int) {
        date = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else if (createdAt is String) {
        date = DateTime.tryParse(createdAt)?.toLocal();
      } else {
        final dateStr = order['tanggal_transaksi'] as String?;
        date = dateStr != null ? DateTime.tryParse(dateStr)?.toLocal() : null;
      }
    }
    final statusColor = _getStatusColor(order['status'] ?? '');
    final isOffline = order['is_local'] == true;
    final statusText = (order['status'] ?? '-').toString().toUpperCase();
    final noPesanan = order['no_pesanan'] as String?;
    final isPendingSync = isOffline && noPesanan == null;

    return GestureDetector(
      onTap: () => onTap(order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: order number + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isPendingSync)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          OrderStatus.pending.code,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    Text(
                      noPesanan ?? 'Menunggu sinkronisasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: noPesanan == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row: store image + name + date | qty + total
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StoreImage(
                  url: pelanggan['foto_toko_url'] as String?,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(8),
                  fallbackIconSize: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pelanggan['nama_toko'] ??
                            pelanggan['nama_pelanggan'] ??
                            pelanggan['nama_pemilik'] ??
                            pelanggan['nama'] ??
                            'Unknown Store',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date != null ? dateFormat.format(date) : '-',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '${items.length} items',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
