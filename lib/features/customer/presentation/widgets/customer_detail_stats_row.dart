import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'customer_stat_card.dart';

/// Stats row showing last visit date and total monthly orders for a customer.
class CustomerDetailStatsRow extends StatelessWidget {
  const CustomerDetailStatsRow({
    super.key,
    required this.pelanggan,
    this.fallback,
  });

  final Map<String, dynamic> pelanggan;
  final Map<String, dynamic>? fallback;

  static String _formatLastVisitDate(dynamic lastVisitDate) {
    if (lastVisitDate == null) return 'Belum Ada';
    try {
      final date = DateTime.parse(lastVisitDate.toString());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Belum Ada';
    }
  }

  static String _formatDaysAgo(dynamic days) {
    if (days == null) return 'Belum pernah';
    final dayCount =
        (days is int ? days : int.tryParse(days.toString()) ?? 0).abs();
    if (dayCount == 0) return 'Hari ini';
    if (dayCount == 1) return '1 hari yang lalu';
    if (dayCount < 7) return '$dayCount hari yang lalu';
    if (dayCount < 30) {
      final weeks = (dayCount / 7).floor();
      return '$weeks minggu yang lalu';
    }
    final months = (dayCount / 30).floor();
    return '$months bulan yang lalu';
  }

  static String _formatGrowthPercentage(dynamic growth) {
    if (growth == null) return '0%';
    final growthValue =
        growth is num ? growth : num.tryParse(growth.toString()) ?? 0;
    final sign = growthValue >= 0 ? '+' : '';
    return '$sign${growthValue.toStringAsFixed(1)}% dari bulan lalu';
  }

  static IconData _getGrowthIcon(dynamic growth) {
    if (growth == null) return Icons.trending_flat;
    final growthValue =
        growth is num ? growth : num.tryParse(growth.toString()) ?? 0;
    if (growthValue > 0) return Icons.trending_up;
    if (growthValue < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }

  static Color _getGrowthColor(dynamic growth) {
    if (growth == null) return AppColors.textMuted;
    final growthValue =
        growth is num ? growth : num.tryParse(growth.toString()) ?? 0;
    if (growthValue > 0) return AppColors.success;
    if (growthValue < 0) return AppColors.error;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final lastVisit =
        pelanggan['last_visit_date'] ?? fallback?['last_visit_date'];
    final daysSince = pelanggan['days_since_last_visit'] ??
        fallback?['days_since_last_visit'];
    final orders =
        pelanggan['orders_this_month'] ?? fallback?['orders_this_month'];
    final growth =
        pelanggan['growth_percentage'] ?? fallback?['growth_percentage'];

    return Row(
      children: [
        Expanded(
          child: CustomerStatCard(
            label: 'Kunjungan Terakhir',
            value: _formatLastVisitDate(lastVisit),
            subtext: _formatDaysAgo(daysSince),
            subicon: Icons.event,
            subcolor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: CustomerStatCard(
            label: 'Total Pesanan',
            value: orders?.toString() ?? '0',
            subtext: _formatGrowthPercentage(growth),
            subicon: _getGrowthIcon(growth),
            subcolor: _getGrowthColor(growth),
          ),
        ),
      ],
    );
  }
}
