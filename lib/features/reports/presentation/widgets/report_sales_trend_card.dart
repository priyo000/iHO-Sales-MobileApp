import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';

import 'report_sales_bar_chart.dart';

/// Card wrapping the 6-month sales trend chart with its title.
class ReportSalesTrendCard extends StatelessWidget {
  const ReportSalesTrendCard({super.key, required this.chartData});

  final List<dynamic> chartData;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl - 4),
      bordered: false,
      shadow: true,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Penjualan (6 Bulan)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: ReportSalesBarChart(chartData: chartData),
          ),
        ],
      ),
    );
  }
}
