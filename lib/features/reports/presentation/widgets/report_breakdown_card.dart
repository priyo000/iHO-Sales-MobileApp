import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';

import 'report_breakdown_legend.dart';

/// Card showing the "Rincian Kunjungan" multi-segment progress bar with
/// per-bucket legends.
class ReportBreakdownCard extends StatelessWidget {
  const ReportBreakdownCard({
    super.key,
    required this.terencanaCount,
    required this.tidakTerencanaCount,
    required this.belumDikunjungiCount,
    required this.terencanaPct,
    required this.tidakTerencanaPct,
    required this.belumDikunjungiPct,
  });

  final int terencanaCount;
  final int tidakTerencanaCount;
  final int belumDikunjungiCount;
  final int terencanaPct;
  final int tidakTerencanaPct;
  final int belumDikunjungiPct;

  int get _total =>
      terencanaCount + tidakTerencanaCount + belumDikunjungiCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl - 4),
      bordered: false,
      shadow: true,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian Kunjungan',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total: $_total',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl - 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 2),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (terencanaPct > 0)
                    Expanded(
                      flex: terencanaPct,
                      child: const ColoredBox(color: AppColors.primary),
                    ),
                  if (tidakTerencanaPct > 0)
                    Expanded(
                      flex: tidakTerencanaPct,
                      child: const ColoredBox(color: AppColors.warning),
                    ),
                  if (belumDikunjungiPct > 0)
                    Expanded(
                      flex: belumDikunjungiPct,
                      child: ColoredBox(
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  if (terencanaPct == 0 &&
                      tidakTerencanaPct == 0 &&
                      belumDikunjungiPct == 0)
                    const Expanded(
                      child: ColoredBox(color: AppColors.divider),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Column(
            children: [
              ReportBreakdownLegend(
                color: AppColors.primary,
                label: 'Kunjungan Terencana',
                value: '$terencanaPct%',
                count: '$terencanaCount',
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportBreakdownLegend(
                color: AppColors.warning,
                label: 'Kunjungan Luar Rute',
                value: '$tidakTerencanaPct%',
                count: '$tidakTerencanaCount',
              ),
              const SizedBox(height: AppSpacing.sm),
              ReportBreakdownLegend(
                color: AppColors.textMuted,
                label: 'Belum Dikunjungi',
                value: '$belumDikunjungiPct%',
                count: '$belumDikunjungiCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
