import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/sync_service.dart';

// ─── Dashboard SSOT Repository ───────────────────────────────────────────────
//
// Dashboard aggregates stats from existing Drift tables (SSOT).
// No separate dashboard table exists - stats are computed on read.
// All source data (schedule, orders, visits, customers) is already synced
// to Drift via their respective repositories during preload.
// ────────────────────────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);
  return DashboardRepository(db, sync);
});

class DashboardRepository {
  final AppDatabase _db;
  final SyncService _sync;

  DashboardRepository(this._db, this._sync);

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _getRouteName(String scheduleId) async {
    final rows = await _db.rawQuery(
      'SELECT nama_rute FROM schedule_table WHERE id = ?',
      whereArgs: [scheduleId],
    );
    if (rows.isNotEmpty) {
      return rows.first['nama_rute'] as String?;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // READ: Compute dashboard stats from Drift tables (SSOT)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get dashboard stats - computed from Drift tables
  /// This is the SSOT approach: no cache, reads directly from local Drift
  /// [employeeId] — current user's employee ID for filtering "Pelanggan Baru"
  Future<Map<String, dynamic>> getDashboardStats({String? employeeId}) async {
    log('[DashboardRepo] Computing dashboard stats from Drift...');

    try {
      final today = _todayKey();

      // Get today's visits — split by planned (has scheduleId) vs unplanned
      final todayVisits = await _db.getTodayVisits();
      final plannedVisits = todayVisits.where((v) => v.scheduleId != null).toList();
      final unplannedVisits = todayVisits.where((v) => v.scheduleId == null).toList();
      final plannedCheckedOut = plannedVisits
          .where((v) => v.status == 'CHECKED_OUT')
          .length;
      final unplannedCheckedOut = unplannedVisits
          .where((v) => v.status == 'CHECKED_OUT')
          .length;
      final checkedOutVisits = plannedCheckedOut + unplannedCheckedOut;
      final totalVisitsToday = todayVisits.length;

      // Get ALL orders today (synced + local/pending), exclude BATAL/CANCEL
      final allOrdersToday = await _db.getOrdersInRange(today, today);
      final totalOrderHariIni = allOrdersToday.where((o) {
        final status = o.status.toUpperCase();
        return !status.contains('BATAL') && !status.contains('CANCEL');
      }).length;

      // Pelanggan Baru = customer yang dibuat oleh user ini hari ini (SSOT).
      // Filter: createdById == employeeId AND createdAt hari ini AND status != prospect.
      // createdById diisi dari server `created_by_id` saat customer sync.
      // Untuk customer offline (isLocal=1), createdById diisi dari session saat create.
      final todayStart = DateTime.parse(today).millisecondsSinceEpoch;
      final todayEnd = DateTime.parse(
        today,
      ).add(const Duration(days: 1)).millisecondsSinceEpoch;
      final allCustomers = await _db.getAllLocalCustomers();
      final todayCustomers = allCustomers.where((c) {
        if (c.createdAt < todayStart || c.createdAt >= todayEnd) return false;
        if (employeeId != null && c.createdById != null) {
          return c.createdById == employeeId;
        }
        // Fallback: isLocal=1 (offline-created by this user, belum sync)
        return c.isLocal == 1;
      }).toList();
      final newCustomersCount = todayCustomers
          .where((c) {
            final status = c.status?.toLowerCase() ?? '';
            return status != 'prospect';
          })
          .length;
      final prospectCount = todayCustomers
          .where((c) => c.status?.toLowerCase() == 'prospect')
          .length;

      // Get pending mutations from sync queue (semua jenis operation yang
      // di-queue offline-first → masuk ke Sync Bar di Beranda)
      final pendingCheckOuts = await _sync.getPendingByType('check_out');
      final pendingCheckIns = await _sync.getPendingByType('check_in');
      final pendingUpdateOrders = await _sync.getPendingByType('update_order');
      final pendingUpdateOrderStatus =
          await _sync.getPendingByType('update_order_status');
      final pendingCreateCustomers =
          await _sync.getPendingByType('create_pelanggan');
      final pendingUpdateCustomers =
          await _sync.getPendingByType('update_pelanggan');
      final pendingUpdateCustomerPhotos =
          await _sync.getPendingByType('update_customer_photo');

      // Calculate offline simulations
      final offlineCheckoutsCount = pendingCheckOuts.where((e) {
        final createdAt = e['created_at'];
        return createdAt is int &&
            createdAt >= todayStart &&
            createdAt < todayEnd;
      }).length;

      // Pending orders count (for sync badge, not for dashboard total)
      final pendingOrders = await _db.getPendingOrders();

      // Calculate effective calls
      final effectiveCalls = await _db.getEffectiveCallsInRange(today, today);

      // Hit rate = (effective calls / total visits) * 100
      final hitRatePercentage = totalVisitsToday > 0
          ? ((effectiveCalls / totalVisitsToday) * 100).round()
          : 0;

      // Calculate total sales today
      final totalSalesToday = await _db.getOrdersTotalInRange(today, today);

      final todaySchedule = await _db.getScheduleForDate(today);
      final plannedSchedule = todaySchedule
          .where((s) => s.jadwalId != null)
          .toList();
      final scheduledVisits = plannedSchedule.length;

      return {
        'kunjungan_selesai': checkedOutVisits + offlineCheckoutsCount,
        'kunjungan_rute_selesai': plannedCheckedOut,
        'target_kunjungan': scheduledVisits,
        'luar_rute': unplannedVisits.length,
        'total_order_hari_ini': totalOrderHariIni,
        'pelanggan_baru_hari_ini': newCustomersCount,
        'prospek_hari_ini': prospectCount,
        'effective_calls': effectiveCalls,
        'hit_rate_percentage': hitRatePercentage,
        'total_sales_today': totalSalesToday,
        'pending_sync_count':
            pendingCheckOuts.length +
            pendingCheckIns.length +
            pendingOrders.length +
            pendingUpdateOrders.length +
            pendingUpdateOrderStatus.length +
            pendingCreateCustomers.length +
            pendingUpdateCustomers.length +
            pendingUpdateCustomerPhotos.length,
        'rute_hari_ini': plannedSchedule.isNotEmpty
            ? {
                'id': plannedSchedule.first.id,
                'name': await _getRouteName(plannedSchedule.first.id) ?? 'Rute Hari Ini',
                'keterangan': '$scheduledVisits titik kunjungan',
                'total_titik': scheduledVisits,
                'dikunjungi': plannedCheckedOut,
                'sisa': scheduledVisits - plannedCheckedOut,
              }
            : null,
      };
    } catch (e) {
      log('[DashboardRepo] Error computing stats: $e');
      return {};
    }
  }
}
