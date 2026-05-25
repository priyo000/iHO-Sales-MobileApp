import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/utils/currency_formatter.dart';

/// Bar chart visualising the 6-month sales trend.
///
/// Wraps [BarChart] with project-specific styling. The fl_chart configuration
/// is preserved verbatim from the original page.
class ReportSalesBarChart extends StatelessWidget {
  const ReportSalesBarChart({super.key, required this.chartData});

  final List<dynamic> chartData;

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) return const SizedBox();

    double maxY = 0.0;
    for (var d in chartData) {
      final val = (d['value'] as num?)?.toDouble() ?? 0.0;
      if (val > maxY) maxY = val;
    }
    if (maxY == 0) maxY = 1.0;

    // Add some padding to maxY so bars don't hit the very top
    maxY = maxY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final val =
                  (chartData[groupIndex]['value'] as num?)?.toDouble() ?? 0.0;
              return BarTooltipItem(
                CurrencyFormatter.format(val),
                const TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox();
                }
                final label = chartData[index]['label'] ?? '';
                final isActive = chartData[index]['isActive'] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(chartData.length, (index) {
          final d = chartData[index];
          final val = (d['value'] as num?)?.toDouble() ?? 0.0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                width: 26,
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
              ),
            ],
          );
        }),
      ),
    );
  }
}
