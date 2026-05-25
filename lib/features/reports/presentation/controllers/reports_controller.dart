import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reports_repository.dart';

final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportsControllerState>(
      ReportsController.new,
    );

final selectedPeriodProvider = NotifierProvider<SelectedPeriodNotifier, String>(
  SelectedPeriodNotifier.new,
);

class SelectedPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'Minggu Ini';
  void setPeriod(String period) => state = period;
}

final customDateRangeProvider =
    NotifierProvider<CustomDateRangeNotifier, DateTimeRange?>(
      CustomDateRangeNotifier.new,
    );

class CustomDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void setDateRange(DateTimeRange range) => state = range;
}

// ─────────────────────────────────────────────────────────────────────────────
// ReportsController — manages report state for the Laporan page.
// State flow: loading (initial) → loaded (data or empty) → error fallback
// ─────────────────────────────────────────────────────────────────────────────

class ReportsController extends Notifier<ReportsControllerState> {
  @override
  ReportsControllerState build() {
    state = ReportsControllerState();
    _loadReport('Minggu Ini');
    return state;
  }

  void setPeriod(String period) {
    // Update selectedPeriodProvider so UI stays in sync
    ref.read(selectedPeriodProvider.notifier).setPeriod(period);
    if (period == 'Kustom') {
      final currentRange = ref.read(customDateRangeProvider);
      if (currentRange != null) {
        loadCustomRange(currentRange);
        return;
      }
    }
    if (state.selectedRange == period) return;
    state = state.copyWith(selectedRange: period, isLoading: true);
    _loadReport(period);
  }

  void loadCustomRange(DateTimeRange range) {
    // Update selectedPeriodProvider so UI stays in sync
    ref.read(selectedPeriodProvider.notifier).setPeriod('Kustom');
    state = state.copyWith(selectedRange: 'Kustom', isLoading: true);
    _loadCustomRange(range.start, range.end);
  }

  Future<void> _loadReport(String period) async {
    final repo = ref.read(reportsRepositoryProvider);

    try {
      final data = await repo.getReportData(period);

      // Guard: if period changed while loading, discard result
      if (state.selectedRange != period) {
        developer.log(
          '[ReportsCtrl] _loadReport discarded: period changed from $period to ${state.selectedRange}',
        );
        return;
      }

      final stats = data != null ? _parseStats(data) : const ReportStats();
      final dateRange = data?['date_range'] as String?;

      state = state.copyWith(
        selectedRange: period,
        stats: stats,
        isLoading: false,
        dateRange: dateRange,
      );
    } catch (e, st) {
      debugPrint('[ReportsController] _loadReport error: $e\n$st');
      // Guard: if period changed while loading, discard error state too
      if (state.selectedRange != period) {
        developer.log(
          '[ReportsCtrl] _loadReport error discarded: period changed from $period to ${state.selectedRange}',
        );
        return;
      }
      // On error: show empty stats with "Tidak tersedia"
      state = state.copyWith(
        selectedRange: period,
        stats: const ReportStats(),
        isLoading: false,
        dateRange: 'Tidak tersedia',
      );
    }
  }

  Future<void> _loadCustomRange(DateTime startDate, DateTime endDate) async {
    final repo = ref.read(reportsRepositoryProvider);

    try {
      final data = await repo.getCustomRangeReport(startDate, endDate);
      final stats = data != null ? _parseStats(data) : const ReportStats();
      final dateRange = data?['date_range'] as String?;

      state = state.copyWith(
        selectedRange: 'Kustom',
        stats: stats,
        isLoading: false,
        dateRange: dateRange,
      );
    } catch (e, st) {
      debugPrint('[ReportsController] _loadCustomRange error: $e\n$st');
      state = state.copyWith(
        selectedRange: 'Kustom',
        stats: const ReportStats(),
        isLoading: false,
        dateRange: 'Tidak tersedia',
      );
    }
  }

  /// Parse raw API/local Map → ReportStats domain object.
  /// All fields have defensive casting to handle String/int/double/malformed values.
  ReportStats _parseStats(Map<String, dynamic> data) {
    // ── Chart data ────────────────────────────────────────────────────
    final chartRaw = data['chart_data'] as List? ?? [];
    final chartData = chartRaw.map((c) {
      final m = c as Map<String, dynamic>;
      return ChartData(
        m['label']?.toString() ?? '',
        (m['value'] is num)
            ? (m['value'] as num).toDouble()
            : (double.tryParse(m['value']?.toString() ?? '') ?? 0),
      );
    }).toList();

    // ── Safe number parsers ───────────────────────────────────────────
    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.round();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(cleaned) ?? 0;
      }
      return 0;
    }

    double toDouble(dynamic val) {
      if (val == null) return 0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) {
        var cleaned = val.replaceAll(RegExp(r'[^0-9.,]'), '');
        if (cleaned.contains(',') && cleaned.contains('.')) {
          final parts = cleaned.split('.');
          final frac = parts.last.replaceFirst(',', '.');
          cleaned = '${parts.take(parts.length - 1).join()}$frac';
        } else if (cleaned.contains(',')) {
          cleaned = cleaned.replaceFirst(',', '.');
        }
        return double.tryParse(cleaned) ?? 0;
      }
      return 0;
    }

    int parseFirstFromFraction(dynamic val) {
      if (val == null) return 0;
      final str = val.toString().trim();
      if (str.isEmpty) return 0;
      final slash = str.indexOf('/');
      if (slash < 0) return toInt(str);
      return toInt(str.substring(0, slash).trim());
    }

    int parseSecondFromFraction(dynamic val) {
      if (val == null) return 0;
      final str = val.toString().trim();
      if (str.isEmpty) return 0;
      final slash = str.indexOf('/');
      if (slash < 0) return 0;
      final afterSlash = str.substring(slash + 1).trim();
      // Remove non-numeric suffix like "Target" or "Call"
      final numericPart = afterSlash.replaceAll(RegExp(r'[^0-9]'), '');
      return toInt(numericPart);
    }

    // Kunjungan: dalamRute / targetKunjungan
    // Backend sends: "33/4 Target" in kunjungan_fraction
    final totalVisit = parseFirstFromFraction(
      data['kunjungan_fraction'],
    ); // dalamRute
    final targetVisit = parseSecondFromFraction(
      data['kunjungan_fraction'],
    ); // targetKunjungan

    // Effective Call: visits with orders / total visits
    // Backend sends: "4/33 Call" in effective_call_fraction
    final effectiveCall = parseFirstFromFraction(
      data['effective_call_fraction'],
    ); // visits with orders
    final totalCall = parseSecondFromFraction(
      data['effective_call_fraction'],
    ); // total visits

    // effectiveRate: effectiveCall / totalCall (percentage as ratio 0-1)
    final effectiveRate = totalCall > 0 ? effectiveCall / totalCall : 0.0;

    final orderValue = toDouble(data['total_penjualan']);
    final totalOrder = toInt(data['total_order']);

    // ── Rincian Kunjungan (Visit Breakdown) ───────────────────────────
    final rincianRaw = data['rincian'] as Map<String, dynamic>? ?? {};
    final rincian = RincianKunjungan(
      terencanaCount: toInt(rincianRaw['terencana_count']),
      tidakTerencanaCount: toInt(rincianRaw['tidak_terencana_count']),
      belumDikunjungiCount: toInt(rincianRaw['belum_dikunjungi_count']),
      terencanaPct: toDouble(rincianRaw['terencana_pct']).round(),
      tidakTerencanaPct: toDouble(rincianRaw['tidak_terencana_pct']).round(),
      belumDikunjungiPct: toDouble(rincianRaw['belum_dikunjungi_pct']).round(),
    );

    // Debug: trace exact values received
    developer.log('[ReportsCtrl] _parseStats input:');
    developer.log(
      '  kunjungan_fraction=${data['kunjungan_fraction']} → totalVisit=$totalVisit, targetVisit=$targetVisit',
    );
    developer.log(
      '  effective_call_fraction=${data['effective_call_fraction']} → effectiveCall=$effectiveCall, totalCall=$totalCall',
    );
    developer.log('  effective_rate=$effectiveRate (effectiveCall/totalCall)');
    developer.log(
      '  total_penjualan=${data['total_penjualan']} → orderValue=$orderValue',
    );
    developer.log('  rincian=$rincian');

    return ReportStats(
      totalVisit: totalVisit,
      targetVisit: targetVisit,
      effectiveCall: effectiveCall,
      totalCall: totalCall,
      effectiveRate: effectiveRate,
      totalOrder: totalOrder,
      orderValue: orderValue,
      chartData: chartData,
      rincian: rincian,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State & Models — kept exactly as-is for widget compatibility
// ─────────────────────────────────────────────────────────────────────────────

class ReportsControllerState {
  final String selectedRange;
  final ReportStats? stats;
  final bool isLoading;
  final String? dateRange;

  ReportsControllerState({
    this.selectedRange = 'Minggu Ini',
    this.stats,
    this.isLoading = true,
    this.dateRange,
  });

  /// Flat map for page widgets. Returns null while loading (triggers "Memuat...").
  Map<String, dynamic>? get value {
    if (stats == null) return null;
    final s = stats!;
    // Kunjungan: visited / target (dikunjungi / (dikunjungi + belum))
    final kunjunganPct = s.targetVisit > 0
        ? (s.totalVisit / s.targetVisit * 100)
        : 0.0;
    // Effective Call: with orders / total visits (effectiveCall / totalCall)
    final effectiveCallPct = s.totalCall > 0
        ? (s.effectiveCall / s.totalCall * 100)
        : 0.0;
    return {
      'date_range': dateRange ?? 'Memuat...',
      'is_cached': false,
      'is_empty': s.totalVisit == 0 && s.effectiveCall == 0,
      'total_penjualan': s.orderValue,
      'total_order': s.totalOrder,
      // Kunjungan: visited / target
      'kunjungan_pct': kunjunganPct.toStringAsFixed(1),
      'kunjungan_fraction': '${s.totalVisit}/${s.targetVisit}',
      // Effective Call: with orders / total visits
      'effective_call_pct': effectiveCallPct.toStringAsFixed(1),
      'effective_call_fraction': '${s.effectiveCall}/${s.totalCall}',
      'chart_data': s.chartData
          .map((c) => {'label': c.label, 'value': c.value})
          .toList(),
      'rincian': {
        'terencana_count': s.rincian.terencanaCount,
        'tidak_terencana_count': s.rincian.tidakTerencanaCount,
        'belum_dikunjungi_count': s.rincian.belumDikunjungiCount,
        'terencana_pct': s.rincian.terencanaPct,
        'tidak_terencana_pct': s.rincian.tidakTerencanaPct,
        'belum_dikunjungi_pct': s.rincian.belumDikunjungiPct,
      },
    };
  }

  Widget when({
    Widget Function()? loading,
    Widget Function(Object error, StackTrace stack)? error,
    required Widget Function(Map<String, dynamic> data) data,
    bool skipLoadingOnRefresh = false,
    bool skipLoadingOnReload = false,
  }) {
    if (isLoading &&
        loading != null &&
        !(skipLoadingOnReload || skipLoadingOnRefresh)) {
      return loading();
    }
    return data(value ?? {});
  }

  ReportsControllerState copyWith({
    String? selectedRange,
    ReportStats? stats,
    bool? isLoading,
    String? dateRange,
  }) => ReportsControllerState(
    selectedRange: selectedRange ?? this.selectedRange,
    stats: stats ?? this.stats,
    isLoading: isLoading ?? this.isLoading,
    dateRange: dateRange ?? this.dateRange,
  );
}

class RincianKunjungan {
  final int terencanaCount;
  final int tidakTerencanaCount;
  final int belumDikunjungiCount;
  final int terencanaPct;
  final int tidakTerencanaPct;
  final int belumDikunjungiPct;

  const RincianKunjungan({
    this.terencanaCount = 0,
    this.tidakTerencanaCount = 0,
    this.belumDikunjungiCount = 0,
    this.terencanaPct = 0,
    this.tidakTerencanaPct = 0,
    this.belumDikunjungiPct = 0,
  });

  int get total => terencanaCount + tidakTerencanaCount + belumDikunjungiCount;
}

class ReportStats {
  final int totalVisit; // dalamRute (visited planned visits)
  final int targetVisit; // targetKunjungan (total planned visits)
  final int effectiveCall; // visits with orders
  final int totalCall; // total visits (dalamRute + luarRute)
  final double effectiveRate; // effectiveCall / totalCall
  final int totalOrder;
  final double orderValue;
  final List<ChartData> chartData;
  final RincianKunjungan rincian;

  const ReportStats({
    this.totalVisit = 0,
    this.targetVisit = 0,
    this.effectiveCall = 0,
    this.totalCall = 0,
    this.effectiveRate = 0,
    this.totalOrder = 0,
    this.orderValue = 0,
    this.chartData = const [],
    this.rincian = const RincianKunjungan(),
  });
}

class ChartData {
  final String label;
  final double value;
  const ChartData(this.label, this.value);
}
