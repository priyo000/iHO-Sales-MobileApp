import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';

import 'report_period_button.dart';

/// Filter bar that combines the period segmented-control with the date range
/// display + custom-range picker trigger.
class SalesPerformanceFilterBar extends StatelessWidget {
  const SalesPerformanceFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.dateRangeLabel,
    required this.onPeriodSelected,
    required this.onPickCustomRange,
  });

  final String selectedPeriod;
  final String dateRangeLabel;
  final ValueChanged<String> onPeriodSelected;
  final VoidCallback onPickCustomRange;

  static const List<String> _periods = ['Minggu Ini', 'Bulan Ini', 'Kustom'];

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedPeriod == 'Kustom';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl - 4),
      bordered: false,
      shadow: true,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Periode Laporan',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                for (final period in _periods)
                  ReportPeriodButton(
                    label: period,
                    isSelected: selectedPeriod == period,
                    onTap: () => onPeriodSelected(period),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: isCustom ? onPickCustomRange : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: isCustom
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isCustom
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: isCustom ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      dateRangeLabel,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCustom
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCustom) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
