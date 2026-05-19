import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/utils/currency_formatter.dart';
import '../controllers/reports_controller.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';

class SalesPerformanceReportPage extends ConsumerStatefulWidget {
  const SalesPerformanceReportPage({super.key});

  @override
  ConsumerState<SalesPerformanceReportPage> createState() =>
      _SalesPerformanceReportPageState();
}

class _SalesPerformanceReportPageState
    extends ConsumerState<SalesPerformanceReportPage> {
  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportsControllerProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final dateRangeStr = reportState.value?['date_range'] ?? 'Memuat...';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Laporan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(reportsControllerProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Periode Laporan',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Segmented Control
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _PeriodButton(
                                    label: 'Minggu Ini',
                                    isSelected: selectedPeriod == 'Minggu Ini',
                                    onTap: () => ref
                                        .read(
                                          reportsControllerProvider.notifier,
                                        )
                                        .setPeriod('Minggu Ini'),
                                  ),
                                  _PeriodButton(
                                    label: 'Bulan Ini',
                                    isSelected: selectedPeriod == 'Bulan Ini',
                                    onTap: () => ref
                                        .read(
                                          reportsControllerProvider.notifier,
                                        )
                                        .setPeriod('Bulan Ini'),
                                  ),
                                  _PeriodButton(
                                    label: 'Kustom',
                                    isSelected: selectedPeriod == 'Kustom',
                                    onTap: () {
                                      ref
                                          .read(
                                            reportsControllerProvider.notifier,
                                          )
                                          .setPeriod('Kustom');
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Date Range Display & Picker
                            InkWell(
                              onTap: selectedPeriod == 'Kustom'
                                  ? () async {
                                      final currentRange = ref.read(
                                        customDateRangeProvider,
                                      );
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 90),
                                        ),
                                        lastDate: DateTime.now(),
                                        initialDateRange:
                                            currentRange ??
                                            DateTimeRange(
                                              start: DateTime.now().subtract(
                                                const Duration(days: 7),
                                              ),
                                              end: DateTime.now(),
                                            ),
                                        helpText: 'Pilih Rentang Laporan',
                                        cancelText: 'Batal',
                                        confirmText: 'Pilih',
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: AppTheme.primary,
                                                    onPrimary: Colors.white,
                                                    onSurface: Colors.black,
                                                  ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppTheme.primary,
                                                    ),
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        if (picked.duration.inDays > 90) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Batas maksimum laporan Kustom adalah 90 hari.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                        ref
                                            .read(
                                              customDateRangeProvider.notifier,
                                            )
                                            .setDateRange(picked);
                                        ref
                                            .read(
                                              reportsControllerProvider
                                                  .notifier,
                                            )
                                            .loadCustomRange(picked);
                                      }
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedPeriod == 'Kustom'
                                      ? AppTheme.primary.withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPeriod == 'Kustom'
                                        ? AppTheme.primary.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      color: selectedPeriod == 'Kustom'
                                          ? AppTheme.primary
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateRangeStr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: selectedPeriod == 'Kustom'
                                            ? AppTheme.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (selectedPeriod == 'Kustom') ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      reportState.when(
                        skipLoadingOnRefresh: true,
                        skipLoadingOnReload: true,
                        loading: () {
                          final oldData = reportState.value;
                          if (oldData != null) {
                            return _buildReportFromMap(oldData);
                          }
                          return const _ReportSkeleton();
                        },
                        error: (err, stack) => AppErrorView(
                          message: 'Gagal memuat laporan: $err',
                          onRetry: () =>
                              ref.invalidate(reportsControllerProvider),
                        ),
                        data: (data) {
                          final isCached = data['is_cached'] == true;
                          final isEmpty = data['is_empty'] == true;
                          final totalPenjualan = data['total_penjualan'] ?? 0;
                          final totalOrder = data['total_order'] ?? 0;
                          final kunjunganPct = data['kunjungan_pct'] ?? 0;
                          final kunjunganFraction =
                              data['kunjungan_fraction'] ?? '0/0';
                          final effectiveCallPctRaw =
                              data['effective_call_pct'] ?? 0;
                          final effectiveCallPct = effectiveCallPctRaw is num
                              ? (effectiveCallPctRaw > 1
                                    ? effectiveCallPctRaw / 100
                                    : effectiveCallPctRaw)
                              : (double.tryParse(
                                      effectiveCallPctRaw.toString(),
                                    ) ??
                                    0);
                          final effectiveCallFraction =
                              data['effective_call_fraction'] ?? '0/0';
                          final chartData =
                              (data['chart_data'] as List<dynamic>?) ?? [];

                          // Safe access untuk rincian (bisa null jika data lama)
                          final rincian =
                              (data['rincian'] as Map?)
                                  ?.cast<String, dynamic>() ??
                              {};
                          final terencanaCount =
                              (rincian['terencana_count'] as num? ?? 0).toInt();
                          final tidakTerencanaCount =
                              (rincian['tidak_terencana_count'] as num? ?? 0)
                                  .toInt();
                          final belumDikunjungiCount =
                              (rincian['belum_dikunjungi_count'] as num? ?? 0)
                                  .toInt();

                          final terencanaPct =
                              (rincian['terencana_pct'] as num? ?? 0).toInt();
                          final tidakTerencanaPct =
                              (rincian['tidak_terencana_pct'] as num? ?? 0)
                                  .toInt();
                          final belumDikunjungiPct =
                              (rincian['belum_dikunjungi_pct'] as num? ?? 0)
                                  .toInt();

                          final totalPotential =
                              terencanaCount +
                              tidakTerencanaCount +
                              belumDikunjungiCount;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Offline / cache indicator
                              if (isEmpty || isCached)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isEmpty
                                        ? Colors.orange[50]
                                        : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isEmpty
                                          ? Colors.orange.shade200
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isEmpty
                                            ? Icons.wifi_off_rounded
                                            : Icons.history_rounded,
                                        size: 16,
                                        color: isEmpty
                                            ? Colors.orange[700]
                                            : Colors.blue[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isEmpty
                                              ? 'Offline & belum ada cache. Buka laporan saat online dulu.'
                                              : 'Menampilkan data terakhir dari cache lokal.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isEmpty
                                                ? Colors.orange[800]
                                                : Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              _PrimaryMetricCard(
                                title: 'Total Penjualan',
                                value: CurrencyFormatter.format(totalPenjualan),
                                subText: '$totalOrder order pada periode ini',
                                icon: Icons.monetization_on_rounded,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Kunjungan',
                                      value: '$kunjunganPct%',
                                      subText: kunjunganFraction,
                                      icon: Icons.storefront_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Effective Call',
                                      value:
                                          '${effectiveCallPct.toStringAsFixed(1)}%',
                                      subText: effectiveCallFraction,
                                      icon: Icons.check_circle_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Visit Breakdown
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Rincian Kunjungan',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Total: $totalPotential',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Multi-segment Progress Bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        height: 16,
                                        child: Row(
                                          children: [
                                            if (terencanaPct > 0)
                                              Expanded(
                                                flex: terencanaPct,
                                                child: Container(
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            if (tidakTerencanaPct > 0)
                                              Expanded(
                                                flex: tidakTerencanaPct,
                                                child: Container(
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            if (belumDikunjungiPct > 0)
                                              Expanded(
                                                flex: belumDikunjungiPct,
                                                child: Container(
                                                  color: Colors.grey[350],
                                                ),
                                              ),
                                            if (terencanaPct == 0 &&
                                                tidakTerencanaPct == 0 &&
                                                belumDikunjungiPct == 0)
                                              Expanded(
                                                child: Container(
                                                  color: Colors.grey[100],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Legends at the bottom
                                    Column(
                                      children: [
                                        _BreakdownLegend(
                                          color: AppTheme.primary,
                                          label: 'Kunjungan Terencana',
                                          value: '$terencanaPct%',
                                          count: '$terencanaCount',
                                        ),
                                        const SizedBox(height: 8),
                                        _BreakdownLegend(
                                          color: Colors.orange,
                                          label: 'Kunjungan Luar Rute',
                                          value: '$tidakTerencanaPct%',
                                          count: '$tidakTerencanaCount',
                                        ),
                                        const SizedBox(height: 8),
                                        _BreakdownLegend(
                                          color: Colors.grey[400]!,
                                          label: 'Belum Dikunjungi',
                                          value: '$belumDikunjungiPct%',
                                          count: '$belumDikunjungiCount',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Monthly Revenue Chart
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tren Penjualan (6 Bulan)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Custom fl_chart
                                    SizedBox(
                                      height: 200,
                                      child: _SalesBarChart(
                                        chartData: chartData,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportFromMap(Map<String, dynamic> data) {
    final isCached = data['is_cached'] == true;
    final isEmpty = data['is_empty'] == true;
    final totalPenjualan = data['total_penjualan'] ?? 0;
    final totalOrder = data['total_order'] ?? 0;
    final kunjunganPct = data['kunjungan_pct'] ?? 0;
    final kunjunganFraction = data['kunjungan_fraction'] ?? '0/0';
    // Apply same effective_rate conversion as _parseStats: auto-detect ratio vs percentage
    final effectiveCallPctRaw = data['effective_call_pct'] ?? 0;
    final effectiveCallPct = effectiveCallPctRaw is num
        ? (effectiveCallPctRaw > 1
              ? effectiveCallPctRaw / 100
              : effectiveCallPctRaw)
        : (double.tryParse(effectiveCallPctRaw.toString()) ?? 0);
    final effectiveCallFraction = data['effective_call_fraction'] ?? '0/0';
    final chartData = (data['chart_data'] as List<dynamic>?) ?? [];
    final rincian = (data['rincian'] as Map?)?.cast<String, dynamic>() ?? {};
    final terencanaCount = (rincian['terencana_count'] as num? ?? 0).toInt();
    final tidakTerencanaCount = (rincian['tidak_terencana_count'] as num? ?? 0)
        .toInt();
    final belumDikunjungiCount =
        (rincian['belum_dikunjungi_count'] as num? ?? 0).toInt();
    final terencanaPct = (rincian['terencana_pct'] as num? ?? 0).toInt();
    final tidakTerencanaPct = (rincian['tidak_terencana_pct'] as num? ?? 0)
        .toInt();
    final belumDikunjungiPct = (rincian['belum_dikunjungi_pct'] as num? ?? 0)
        .toInt();
    final totalPotential =
        terencanaCount + tidakTerencanaCount + belumDikunjungiCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEmpty || isCached)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isEmpty ? Colors.orange[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEmpty ? Colors.orange.shade200 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEmpty ? Icons.wifi_off_rounded : Icons.history_rounded,
                  size: 16,
                  color: isEmpty ? Colors.orange[700] : Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEmpty
                        ? 'Offline & belum ada cache.'
                        : 'Menampilkan data terakhir dari cache lokal.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isEmpty ? Colors.orange[800] : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        _PrimaryMetricCard(
          title: 'Total Penjualan',
          value: CurrencyFormatter.format(totalPenjualan),
          subText: '$totalOrder order pada periode ini',
          icon: Icons.monetization_on_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Kunjungan',
                value: '$kunjunganPct%',
                subText: kunjunganFraction,
                icon: Icons.storefront_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Effective Call',
                value: '${effectiveCallPct.toStringAsFixed(1)}%',
                subText: effectiveCallFraction,
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rincian Kunjungan',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total: $totalPotential',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 16,
                  child: Row(
                    children: [
                      if (terencanaPct > 0)
                        Expanded(
                          flex: terencanaPct,
                          child: Container(color: AppTheme.primary),
                        ),
                      if (tidakTerencanaPct > 0)
                        Expanded(
                          flex: tidakTerencanaPct,
                          child: Container(
                            color: AppTheme.primary.withValues(alpha: 0.45),
                          ),
                        ),
                      if (belumDikunjungiPct > 0)
                        Expanded(
                          flex: belumDikunjungiPct,
                          child: Container(color: Colors.grey[350]),
                        ),
                      if (terencanaPct == 0 &&
                          tidakTerencanaPct == 0 &&
                          belumDikunjungiPct == 0)
                        Expanded(child: Container(color: Colors.grey[100])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  _BreakdownLegend(
                    color: AppTheme.primary,
                    label: 'Kunjungan Terencana',
                    value: '$terencanaPct%',
                    count: '$terencanaCount',
                  ),
                  const SizedBox(height: 8),
                  _BreakdownLegend(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    label: 'Kunjungan Luar Rute',
                    value: '$tidakTerencanaPct%',
                    count: '$tidakTerencanaCount',
                  ),
                  const SizedBox(height: 8),
                  _BreakdownLegend(
                    color: Colors.grey[400]!,
                    label: 'Belum Dikunjungi',
                    value: '$belumDikunjungiPct%',
                    count: '$belumDikunjungiCount',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tren Penjualan (6 Bulan)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _SalesBarChart(chartData: chartData),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _PrimaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final IconData icon;

  const _PrimaryMetricCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
                if (subText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  final List<dynamic> chartData;

  const _SalesBarChart({required this.chartData});

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
            getTooltipColor: (group) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final val =
                  (chartData[groupIndex]['value'] as num?)?.toDouble() ?? 0.0;
              return BarTooltipItem(
                CurrencyFormatter.format(val),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
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
                      color: isActive ? Colors.black : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _BreakdownLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String count;

  const _BreakdownLegend({
    required this.color,
    required this.label,
    required this.value,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Total Sales Card Skeleton
        const ShimmerLoading(
          width: double.infinity,
          height: 120,
          borderRadius: 20,
        ),
        const SizedBox(height: 16),

        // Grid of percentages Skeleton
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: List.generate(
            2,
            (index) => const ShimmerLoading(
              width: double.infinity,
              height: 80,
              borderRadius: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Chart Skeleton
        const ShimmerLoading(
          width: double.infinity,
          height: 300,
          borderRadius: 20,
        ),
        const SizedBox(height: 16),

        // Visit Details Skeleton
        const ShimmerLoading(
          width: double.infinity,
          height: 200,
          borderRadius: 20,
        ),
      ],
    );
  }
}
