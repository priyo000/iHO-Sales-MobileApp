import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_tracker_mobile/core/db/app_database.dart';
import 'package:sales_tracker_mobile/core/providers/database_providers.dart';

/// Provider
final reportsLocalDataSourceProvider = Provider<ReportsLocalDataSource>((ref) {
  return ReportsLocalDataSource(ref.read(appDatabaseProvider));
});

/// ReportsLocalDataSource — computes report stats purely from local SSOT tables.
/// No network required. Always available offline.
class ReportsLocalDataSource {
  final AppDatabase _db;
  ReportsLocalDataSource(this._db);

  /// Compute stats for a date range.
  /// [startDate] and [endDate] format: 'yyyy-MM-dd'.
  /// targetVisit is computed from schedule_table for the given range.
  Future<LocalReportStats> computeStats({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final visits = await _db.getVisitsInRange(startDate, endDate);
      final totalCalls = visits.length;

      final effectiveCalls = await _db.getEffectiveCallsInRange(
        startDate,
        endDate,
      );
      final effectiveRate = totalCalls > 0 ? effectiveCalls / totalCalls : 0.0;

      final totalPenjualan = await _db.getOrdersTotalInRange(
        startDate,
        endDate,
      );
      final orders = await _db.getOrdersInRange(startDate, endDate);
      final totalOrders = orders.where((o) {
        final status = o.status.toUpperCase();
        return !status.contains('BATAL') && !status.contains('CANCEL');
      }).length;

      final dailySales = await _db.getDailySalesInRange(startDate, endDate);

      // Compute targetVisit from schedule_table for the date range (single query)
      final scheduleInRange = await _db.getScheduleForDateRange(startDate, endDate);
      final targetVisit = scheduleInRange.length;

      int dalamRute = 0;
      int luarRute = 0;
      for (final v in visits) {
        if (v.scheduleId != null) {
          dalamRute++;
        } else {
          luarRute++;
        }
      }

      final belum = targetVisit - dalamRute;

      developer.log(
        '[ReportsLocal] range=$startDate..$endDate: '
        'visits=$totalCalls, effective=$effectiveCalls, target=$targetVisit, '
        'sales=$totalPenjualan, planned=$dalamRute, unplanned=$luarRute',
      );

      return LocalReportStats(
        totalPenjualan: totalPenjualan,
        totalOrders: totalOrders,
        totalCalls: totalCalls,
        effectiveCalls: effectiveCalls,
        effectiveRate: effectiveRate,
        plannedVisits: dalamRute,
        unplannedVisits: luarRute,
        missedVisits: belum < 0 ? 0 : belum,
        targetVisit: targetVisit,
        dailySales: dailySales,
      );
    } catch (e, st) {
      developer.log('[ReportsLocal] computeStats ERROR: $e\n$st');
      rethrow;
    }
  }

  /// Returns true if there is ANY local visit or order data in the given range.
  Future<bool> hasData(String startDate, String endDate) async {
    try {
      final visits = await _db.getVisitsInRange(startDate, endDate);
      if (visits.isNotEmpty) return true;
      final orders = await _db.getOrdersInRange(startDate, endDate);
      return orders.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Immutable stats container from local SSOT computation.
class LocalReportStats {
  final double totalPenjualan;
  final int totalOrders;
  final int totalCalls; // total visits (planned + unplanned)
  final int effectiveCalls; // visits with orders
  final double effectiveRate; // effectiveCalls / totalCalls
  final int plannedVisits; // dalamRute (visited planned)
  final int unplannedVisits; // luarRute (unplanned visits)
  final int missedVisits; // planned but not visited
  final int targetVisit; // total planned visits target
  final Map<String, double> dailySales;

  const LocalReportStats({
    required this.totalPenjualan,
    required this.totalOrders,
    required this.totalCalls,
    required this.effectiveCalls,
    required this.effectiveRate,
    required this.plannedVisits,
    required this.unplannedVisits,
    required this.missedVisits,
    required this.targetVisit,
    required this.dailySales,
  });

  /// Convert to a flat Map matching the API response shape.
  /// [dateRangeStr] is the human-readable date range label.
  Map<String, dynamic> toMap({required String dateRangeStr}) {
    final totalPotential = targetVisit + unplannedVisits;
    final plannedPct = totalPotential > 0
        ? (plannedVisits / totalPotential * 100)
        : 0.0;
    final unplannedPct = totalPotential > 0
        ? (unplannedVisits / totalPotential * 100)
        : 0.0;
    final missedPct = (100 - plannedPct - unplannedPct).clamp(0.0, 100.0);
    // Kunjungan: visited / target
    final visitPct = targetVisit > 0
        ? (plannedVisits / targetVisit * 100)
        : 0.0;

    return {
      'total_penjualan': totalPenjualan,
      'total_order': totalOrders,
      'kunjungan_pct': visitPct.round(),
      'kunjungan_fraction': '$plannedVisits/$targetVisit Target',
      'effective_call_pct': (effectiveRate * 100).round(),
      'effective_call_fraction': '$effectiveCalls/$totalCalls Call',
      'chart_data': _buildChartData(),
      'rincian': {
        'terencana_count': plannedVisits,
        'tidak_terencana_count': unplannedVisits,
        'belum_dikunjungi_count': missedVisits,
        'terencana_pct': plannedPct.round(),
        'tidak_terencana_pct': unplannedPct.round(),
        'belum_dikunjungi_pct': missedPct.round(),
      },
      'is_cached': true,
      'is_empty': false,
      'is_local': true,
      'date_range': dateRangeStr,
    };
  }

  /// Build chart data from dailySales map.
  /// Keys in dailySales are 'YYYY-MM-DD' format.
  /// Chart shows daily bars for the period with actual sales values.
  List<Map<String, dynamic>> _buildChartData() {
    if (dailySales.isEmpty) return [];

    // Sort dates chronologically
    final sortedKeys = dailySales.keys.toList()..sort();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> chart = [];
    double maxVal = 0;

    for (final key in sortedKeys) {
      final val = dailySales[key] ?? 0.0;
      if (val > maxVal) maxVal = val;

      // Label: "02 Mei" format
      final parts = key.split('-');
      final day = parts.length >= 3 ? parts[2] : key;
      final month = parts.length >= 2 ? int.tryParse(parts[1]) ?? 1 : 1;
      final label = '$day ${_monthName(month)}';

      chart.add({'label': label, 'value': val, 'isActive': key == todayStr});
    }

    // Normalize height
    maxVal = maxVal > 0 ? maxVal : 1;
    for (int i = 0; i < chart.length; i++) {
      chart[i]['heightFactor'] = (chart[i]['value'] as double) / maxVal;
    }

    return chart;
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
