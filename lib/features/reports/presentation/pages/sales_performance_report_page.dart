import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

import '../controllers/reports_controller.dart';
import '../widgets/report_breakdown_card.dart';
import '../widgets/report_offline_banner.dart';
import '../widgets/report_sales_trend_card.dart';
import '../widgets/report_skeleton.dart';
import '../widgets/sales_performance_filter_bar.dart';
import '../widgets/sales_performance_summary_grid.dart';

class SalesPerformanceReportPage extends ConsumerStatefulWidget {
  const SalesPerformanceReportPage({super.key});

  @override
  ConsumerState<SalesPerformanceReportPage> createState() =>
      _SalesPerformanceReportPageState();
}

class _SalesPerformanceReportPageState
    extends ConsumerState<SalesPerformanceReportPage> {
  Future<void> _pickCustomRange() async {
    final currentRange = ref.read(customDateRangeProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      initialDateRange:
          currentRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'Pilih Rentang Laporan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    if (picked.duration.inDays > 90) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Batas maksimum laporan Kustom adalah 90 hari.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    ref.read(customDateRangeProvider.notifier).setDateRange(picked);
    ref.read(reportsControllerProvider.notifier).loadCustomRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportsControllerProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final dateRangeStr = reportState.value?['date_range'] ?? 'Memuat...';

    return AppScaffold(
      appBar: AppBar(title: const Text('Laporan')),
      backgroundColor: AppColors.backgroundLight,
      safeAreaBottom: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportsControllerProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SalesPerformanceFilterBar(
                selectedPeriod: selectedPeriod,
                dateRangeLabel: dateRangeStr,
                onPeriodSelected: (period) => ref
                    .read(reportsControllerProvider.notifier)
                    .setPeriod(period),
                onPickCustomRange: _pickCustomRange,
              ),
              const SizedBox(height: AppSpacing.xl),
              reportState.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () {
                  final oldData = reportState.value;
                  if (oldData != null) {
                    return _SalesPerformanceContent(data: oldData);
                  }
                  return const ReportSkeleton();
                },
                error: (err, stack) => AppErrorView(
                  message: 'Gagal memuat laporan: $err',
                  onRetry: () =>
                      ref.invalidate(reportsControllerProvider),
                ),
                data: (data) => _SalesPerformanceContent(data: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesPerformanceContent extends StatelessWidget {
  const _SalesPerformanceContent({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isCached = data['is_cached'] == true;
    final isEmpty = data['is_empty'] == true;
    final totalPenjualan = (data['total_penjualan'] as num?) ?? 0;
    final totalOrder = (data['total_order'] as num?)?.toInt() ?? 0;
    final kunjunganPct = data['kunjungan_pct']?.toString() ?? '0';
    final kunjunganFraction = data['kunjungan_fraction']?.toString() ?? '0/0';

    // Apply same effective_rate conversion as _parseStats: auto-detect ratio
    // vs percentage. (Preserved from legacy behaviour.)
    final effectiveCallPctRaw = data['effective_call_pct'] ?? 0;
    final effectiveCallPct = effectiveCallPctRaw is num
        ? (effectiveCallPctRaw > 1
              ? effectiveCallPctRaw / 100
              : effectiveCallPctRaw.toDouble())
        : (double.tryParse(effectiveCallPctRaw.toString()) ?? 0);
    final effectiveCallFraction =
        data['effective_call_fraction']?.toString() ?? '0/0';

    final chartData = (data['chart_data'] as List<dynamic>?) ?? const [];

    final rincian =
        (data['rincian'] as Map?)?.cast<String, dynamic>() ?? const {};
    final terencanaCount =
        (rincian['terencana_count'] as num? ?? 0).toInt();
    final tidakTerencanaCount =
        (rincian['tidak_terencana_count'] as num? ?? 0).toInt();
    final belumDikunjungiCount =
        (rincian['belum_dikunjungi_count'] as num? ?? 0).toInt();
    final terencanaPct = (rincian['terencana_pct'] as num? ?? 0).toInt();
    final tidakTerencanaPct =
        (rincian['tidak_terencana_pct'] as num? ?? 0).toInt();
    final belumDikunjungiPct =
        (rincian['belum_dikunjungi_pct'] as num? ?? 0).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportOfflineBanner(isEmpty: isEmpty, isCached: isCached),
        SalesPerformanceSummaryGrid(
          totalPenjualan: totalPenjualan,
          totalOrder: totalOrder,
          kunjunganPct: kunjunganPct,
          kunjunganFraction: kunjunganFraction,
          effectiveCallPct: effectiveCallPct,
          effectiveCallFraction: effectiveCallFraction,
        ),
        const SizedBox(height: AppSpacing.xl),
        ReportBreakdownCard(
          terencanaCount: terencanaCount,
          tidakTerencanaCount: tidakTerencanaCount,
          belumDikunjungiCount: belumDikunjungiCount,
          terencanaPct: terencanaPct,
          tidakTerencanaPct: tidakTerencanaPct,
          belumDikunjungiPct: belumDikunjungiPct,
        ),
        const SizedBox(height: AppSpacing.xl),
        ReportSalesTrendCard(chartData: chartData),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
