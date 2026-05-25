import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/status_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/store_image.dart';

class OrderDetailHeader extends StatelessWidget {
  const OrderDetailHeader({
    super.key,
    required this.displayOrder,
    required this.pelanggan,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.date,
    required this.currencyFormat,
    required this.dateFormat,
    this.onRefresh,
  });

  final Map<String, dynamic> displayOrder;
  final Map<String, dynamic> pelanggan;
  final String status;
  final double total;
  final int itemCount;
  final DateTime? date;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final orderStatus = OrderStatus.fromCode(status);
    final statusColor = StatusStyles.color(orderStatus);

    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: AppColors.surface,
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh Detail',
            onPressed: onRefresh,
          ),
      ],
      title: Text(
        displayOrder['no_pesanan']?.toString() ?? 'Detail Pesanan',
        style: AppTextStyles.titleLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              bottom: 60,
              child: ColoredBox(
                color: AppColors.border,
                child: StoreImage(
                  url: pelanggan['foto_toko_url']?.toString(),
                  width: double.infinity,
                  height: double.infinity,
                  fallbackIcon: status == 'PROSPECT'
                      ? Icons.store_outlined
                      : Icons.store,
                  fallbackIconSize: 64,
                ),
              ),
            ),
            Positioned.fill(
              bottom: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.textPrimary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              child: _StoreLabel(pelanggan: pelanggan),
            ),
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _SummaryCard(
                status: status,
                statusColor: statusColor,
                date: date,
                total: total,
                itemCount: itemCount,
                currencyFormat: currencyFormat,
                dateFormat: dateFormat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreLabel extends StatelessWidget {
  const _StoreLabel({required this.pelanggan});

  final Map<String, dynamic> pelanggan;

  @override
  Widget build(BuildContext context) {
    final namaToko = pelanggan['nama_toko'] ??
        pelanggan['nama_pelanggan'] ??
        pelanggan['nama'] ??
        '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOKO PELANGGAN',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.surface.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          namaToko.toString(),
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.surface,
            height: 1.2,
            fontSize: 22,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.status,
    required this.statusColor,
    required this.date,
    required this.total,
    required this.itemCount,
    required this.currencyFormat,
    required this.dateFormat,
  });

  final String status;
  final Color statusColor;
  final DateTime? date;
  final double total;
  final int itemCount;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge(
                label: OrderStatus.fromCode(status).label.toUpperCase(),
                color: statusColor,
              ),
              Flexible(
                child: Text(
                  date != null ? dateFormat.format(date!) : '-',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      currencyFormat.format(total),
                      style: AppTextStyles.headingLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PRODUK',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$itemCount item',
                    style: AppTextStyles.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
