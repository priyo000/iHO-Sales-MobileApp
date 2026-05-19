import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_local_data_source.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.read(reportsLocalDataSourceProvider));
});

class ReportsRepository {
  final ReportsLocalDataSource _localDs;

  ReportsRepository(this._localDs);

  // ── Period mapping ──────────────────────────────────────────────────────────

  String _mapPeriod(String period) {
    switch (period) {
      case 'week':
      case 'Minggu Ini':
        return 'minggu_ini';
      case 'month':
      case 'Bulan Ini':
        return 'bulan_ini';
      case 'kustom':
      case 'Kustom':
        return 'kustom';
      default:
        return 'minggu_ini';
    }
  }

  // ── Date range computation ───────────────────────────────────────────────────

  DateTime _getStartDate(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'minggu_ini':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case 'bulan_ini':
        return DateTime(now.year, now.month, 1);
      default:
        final fallback = now.subtract(const Duration(days: 7));
        return DateTime(fallback.year, fallback.month, fallback.day);
    }
  }

  DateTime _getEndDate(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'minggu_ini':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final saturday = monday.add(const Duration(days: 5));
        return DateTime(saturday.year, saturday.month, saturday.day);
      case 'bulan_ini':
        return DateTime(now.year, now.month + 1, 0);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  // ── Get Reports ──────────────────────────────────────────────────────────────

  /// Get report data — SSOT: always compute from local Drift tables.
  /// Data is already synced to Drift via preload (schedule, visits, orders).
  /// No API call needed — instant, offline-first.
  Future<Map<String, dynamic>?> getReportData(String period) async {
    final periodKey = _mapPeriod(period);
    final startDate = _getStartDate(periodKey);
    final endDate = _getEndDate(periodKey);

    developer.log(
      '[Reports] 📦 SSOT: Computing from local Drift (period=$periodKey)',
    );
    return _getLocalReport(periodKey, startDate, endDate);
  }

  /// Get report for custom date range — always computed from local Drift.
  Future<Map<String, dynamic>?> getCustomRangeReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _getLocalReport('kustom', startDate, endDate);
  }

  /// Compute report from Drift SSOT tables.
  Future<Map<String, dynamic>?> _getLocalReport(
    String period,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final stats = await _localDs.computeStats(
        startDate: startStr,
        endDate: endStr,
      );

      return stats.toMap(dateRangeStr: _formatDateRange(startDate, endDate));
    } catch (e) {
      developer.log('[Reports] ❌ Local compute failed: $e');
      return null;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
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
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }
}
