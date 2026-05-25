import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/utils/currency_formatter.dart';

import 'report_metric_card.dart';
import 'report_primary_metric_card.dart';

/// KPI summary block: hero "Total Penjualan" card stacked above the
/// "Kunjungan" + "Effective Call" tile pair.
class SalesPerformanceSummaryGrid extends StatelessWidget {
  const SalesPerformanceSummaryGrid({
    super.key,
    required this.totalPenjualan,
    required this.totalOrder,
    required this.kunjunganPct,
    required this.kunjunganFraction,
    required this.effectiveCallPct,
    required this.effectiveCallFraction,
  });

  final num totalPenjualan;
  final int totalOrder;

  /// Display percentage already formatted as string (e.g. "75.0").
  final String kunjunganPct;
  final String kunjunganFraction;

  /// Effective-call percentage as a 0-100 double (already converted from
  /// ratio if necessary by the caller).
  final double effectiveCallPct;
  final String effectiveCallFraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReportPrimaryMetricCard(
          title: 'Total Penjualan',
          value: CurrencyFormatter.format(totalPenjualan),
          subText: '$totalOrder order pada periode ini',
          icon: Icons.monetization_on_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ReportMetricCard(
                title: 'Kunjungan',
                value: '$kunjunganPct%',
                subText: kunjunganFraction,
                icon: Icons.storefront_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ReportMetricCard(
                title: 'Effective Call',
                value: '${effectiveCallPct.toStringAsFixed(1)}%',
                subText: effectiveCallFraction,
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
