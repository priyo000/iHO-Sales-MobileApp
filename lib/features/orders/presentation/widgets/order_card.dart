import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sales_tracker_mobile/core/constants/order_status.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/utils/status_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_badge.dart';
import 'package:sales_tracker_mobile/core/widgets/store_image.dart';

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

  @override
  Widget build(BuildContext context) {
    final pelanggan = order['pelanggan'] as Map<String, dynamic>? ?? {};
    final items = order['items'] as List? ?? [];
    final total = double.tryParse(order['total_tagihan'].toString()) ?? 0.0;

    DateTime? date;
    final tanggalTx = order['tanggal_transaksi'];
    if (tanggalTx is int) {
      date = DateTime.fromMillisecondsSinceEpoch(tanggalTx);
    } else {
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

    final statusRaw = (order['status'] ?? '').toString();
    final orderStatus = OrderStatus.fromCode(statusRaw);
    final statusColor = StatusStyles.color(orderStatus);
    final isOffline = order['is_local'] == true;
    final noPesanan = order['no_pesanan'] as String?;
    final isPendingSync = isOffline && noPesanan == null;

    return GestureDetector(
      onTap: () => onTap(order),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.textMuted.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isPendingSync) ...[
                        const AppBadge(
                          label: 'BELUM SYNC',
                          color: AppColors.textSecondary,
                          icon: Icons.cloud_upload_outlined,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          noPesanan ?? 'Menunggu sinkronisasi',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: noPesanan == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppBadge(
                  label: orderStatus.label.toUpperCase(),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StoreImage(
                  url: pelanggan['foto_toko_url'] as String?,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  fallbackIconSize: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pelanggan['nama_toko'] ??
                            pelanggan['nama_pelanggan'] ??
                            pelanggan['nama_pemilik'] ??
                            pelanggan['nama'] ??
                            'Toko Tidak Dikenal',
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        date != null ? dateFormat.format(date) : '-',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(total),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${items.length} item',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
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
