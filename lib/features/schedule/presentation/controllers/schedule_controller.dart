import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/schedule_repository.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE NOTIFIERS — Keep for UI interaction (date, search)
// ─────────────────────────────────────────────────────────────────────────────

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  @override
  set state(DateTime value) => super.state = value;
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class ScheduleSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final scheduleSearchProvider = NotifierProvider<ScheduleSearchNotifier, String>(
  ScheduleSearchNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PROVIDERS — Reactive SSOT (Preferred)
// These return combined schedule+pelanggan data as List<Map<String, dynamic>>
// ─────────────────────────────────────────────────────────────────────────────

/// Watch schedule for a specific date as `Stream<List<Map<String, dynamic>>>`
/// Joins ScheduleTable with customer data from CustomersTable.
/// Also merges unplanned visits (kunjungan diluar jadwal) from VisitsTable
/// where scheduleId == null, so they appear on the schedule list with a timer.
final scheduleStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tanggal) {
      final scheduleRepo = ref.watch(scheduleRepositoryProvider);
      final db = ref.watch(appDatabaseProvider);

      // Stream 1: Scheduled visits from schedule_table
      final scheduleStream = scheduleRepo.watchScheduleForDate(tanggal);

      // Stream 2: Today's visits from visits_table (for unplanned visit detection)
      final visitsStream = db.watchTodayVisits();

      // Combine both streams using a StreamController so the output is reactive
      // to changes in EITHER table (schedule_table OR visits_table).
      // StreamProvider manages a single listener, so a regular controller is fine.
      final controller = StreamController<List<Map<String, dynamic>>>();

      List<ScheduleTableData>? lastScheduleItems;
      List<VisitsTableData>? lastVisitItems;

      Future<void> emitCombined() async {
        if (lastScheduleItems == null || lastVisitItems == null) return;

        try {
          // ── Batch load all data upfront to avoid N+1 queries ────────────
          final allPelangganIds = <String>{
            ...lastScheduleItems!.map((i) => i.pelangganId),
            ...lastVisitItems!
                .where((v) => v.pelangganId != null)
                .map((v) => v.pelangganId!),
          };

          // Batch load customers
          final customerMap = <String, CustomersTableData>{};
          for (final id in allPelangganIds) {
            final c = await db.getCustomer(id);
            if (c != null) customerMap[id] = c;
          }

          // Batch load visits and orders for all relevant pelanggan
          final visitsMap = <String, List<VisitsTableData>>{};
          final ordersMap = <String, List<OrdersTableData>>{};
          for (final id in allPelangganIds) {
            visitsMap[id] = await db.getVisitsByPelanggan(id);
            ordersMap[id] = await db.getOrdersByPelanggan(id);
          }

          // ── Part A: Map scheduled items ─────────────────────────────────
          final List<Map<String, dynamic>> result = [];
          final Set<String> scheduledPelangganIds = {};

          for (final item in lastScheduleItems!) {
            scheduledPelangganIds.add(item.pelangganId);
            final customer = customerMap[item.pelangganId];

            final visits = visitsMap[item.pelangganId] ?? [];
            final matchingVisit = visits.where((v) {
              final checkIn = v.waktuCheckIn;
              if (checkIn == null) return false;
              return checkIn.startsWith(tanggal);
            }).firstOrNull;

            final orders = ordersMap[item.pelangganId] ?? [];
            final int pesananCount;
            if (matchingVisit != null) {
              pesananCount = orders.where((o) =>
                o.kunjunganId == matchingVisit.id ||
                o.kunjunganId == matchingVisit.serverId?.toString()
              ).length;
            } else {
              pesananCount = 0;
            }

            result.add(_scheduleToMap(
              item,
              customer,
              kunjunganId: matchingVisit?.serverId ?? (matchingVisit?.id),
              pesananCount: pesananCount,
            ));
          }

          // ── Part B: Merge unplanned visits (scheduleId == null) ───────────
          final unplannedVisits = lastVisitItems!.where((v) {
            if (v.scheduleId != null) return false;
            final checkIn = v.waktuCheckIn;
            if (checkIn == null) return false;
            if (!checkIn.startsWith(tanggal)) return false;
            final pelId = v.pelangganId?.toString() ?? '';
            if (scheduledPelangganIds.contains(pelId)) return false;
            return true;
          }).toList();

          for (final visit in unplannedVisits) {
            final pelIdStr = visit.pelangganId?.toString() ?? '';
            final customer = customerMap[pelIdStr];

            final String visitStatus;
            if (visit.waktuCheckOut != null) {
              visitStatus = 'SELESAI';
            } else {
              visitStatus = 'DIKUNJUNGI';
            }

            int pesananCount = 0;
            final orders = ordersMap[pelIdStr] ?? [];
            pesananCount = orders.where((o) =>
              o.kunjunganId == visit.id ||
              o.kunjunganId == visit.serverId?.toString()
            ).length;

            result.add(_unplannedVisitToMap(
              visit,
              customer,
              tanggal: tanggal,
              visitStatus: visitStatus,
              pesananCount: pesananCount,
            ));
          }

          if (!controller.isClosed) {
            controller.add(result);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      }

      final scheduleSub = scheduleStream.listen((items) {
        lastScheduleItems = items;
        emitCombined();
      }, onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      });

      final visitsSub = visitsStream.listen((items) {
        lastVisitItems = items;
        emitCombined();
      }, onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      });

      ref.onDispose(() {
        scheduleSub.cancel();
        visitsSub.cancel();
        controller.close();
      });

      return controller.stream;
    });

/// Convert ScheduleTableData to Map with full pelanggan data from CustomersTable
Map<String, dynamic> _scheduleToMap(
  ScheduleTableData row,
  CustomersTableData? customer, {
  dynamic kunjunganId,
  int pesananCount = 0,
}) {
  return {
    'id': row.id,
    'id_jadwal': row.jadwalId,
    'id_pelanggan': row.pelangganId,
    'id_kunjungan': kunjunganId,
    'tanggal_kunjungan': row.tanggal,
    'status_kunjungan': row.status,
    'waktu_check_in': row.waktuCheckIn,
    'waktu_check_out': row.waktuCheckOut,
    'pelangganId': row.pelangganId,
    'pesanan_count': pesananCount,
    'pelanggan': customer != null
        ? {
            'id': customer.serverId ?? customer.id,
            'kode_pelanggan': customer.kodePelanggan,
            'nama_toko': customer.namaToko,
            'nama_pelanggan': customer.namaPemilik,
            'alamat': customer.alamatUsaha,
            'latitude': customer.latitude,
            'longitude': customer.longitude,
            'status': customer.status,
            'telepon': customer.noHpPribadi,
            'foto_toko_url': customer.fotoTokoPath,
          }
        : {'id': row.pelangganId},
  };
}

/// Convert an unplanned VisitsTableData to the same Map shape as _scheduleToMap.
/// Key differentiator: 'id_jadwal' is null for unplanned visits.
Map<String, dynamic> _unplannedVisitToMap(
  VisitsTableData visit,
  CustomersTableData? customer, {
  required String tanggal,
  required String visitStatus,
  int pesananCount = 0,
}) {
  final pelIdStr = visit.pelangganId?.toString() ?? '';
  final pelIdInt = int.tryParse(pelIdStr);
  return {
    'id': 'unplanned_${visit.id}',
    'id_jadwal': null, // Key differentiator for unplanned visits
    'id_pelanggan': pelIdInt ?? pelIdStr,
    'id_kunjungan': visit.serverId ?? visit.id,
    'tanggal_kunjungan': tanggal,
    'status_kunjungan': visitStatus,
    'waktu_check_in': visit.waktuCheckIn,
    'waktu_check_out': visit.waktuCheckOut,
    'pelangganId': pelIdInt ?? pelIdStr,
    'pesanan_count': pesananCount,
    'pelanggan': customer != null
        ? {
            'id': customer.serverId ?? customer.id,
            'kode_pelanggan': customer.kodePelanggan,
            'nama_toko': customer.namaToko,
            'nama_pelanggan': customer.namaPemilik,
            'alamat': customer.alamatUsaha,
            'latitude': customer.latitude,
            'longitude': customer.longitude,
            'status': customer.status,
            'telepon': customer.noHpPribadi,
            'foto_toko_url': customer.fotoTokoPath,
          }
        : {'id': pelIdInt ?? pelIdStr},
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGACY CONTROLLER — Kept for backward compatibility during migration
// Migrated pages should use stream providers above instead.
// ─────────────────────────────────────────────────────────────────────────────

final scheduleControllerProvider =
    AsyncNotifierProvider<ScheduleController, List<dynamic>>(
      ScheduleController.new,
    );

class ScheduleController extends AsyncNotifier<List<dynamic>> {
  @override
  FutureOr<List<dynamic>> build() async {
    final date = ref.watch(selectedDateProvider);
    final dateStr = date.toIso8601String().split('T')[0];

    // Watch sync count agar UI update saat sinkronisasi selesai
    ref.watch(pendingSyncCountProvider);

    final repo = ref.read(scheduleRepositoryProvider);

    // 1. SSOT: Langsung return cached data (INSTAN - tanpa loading)
    // Sync ke server happens secara async di background
    final cachedData = await repo.getTodaySchedule(date: dateStr);
    final mappedCachedData = await _mapScheduleData(cachedData, repo, dateStr: dateStr);

    // 2. Trigger background revalidation (tanpa await - tidak block UI)
    // Use Future.microtask agar tidak block build() async ini
    Future.microtask(() => _revalidate(repo, dateStr));

    return _filterData(mappedCachedData);
  }

  Future<List<Map<String, dynamic>>> _mapScheduleData(List<ScheduleTableData> data, ScheduleRepository repo, {required String dateStr}) async {
    final db = ref.read(appDatabaseProvider);
    final List<Map<String, dynamic>> result = [];
    final Set<String> scheduledPelangganIds = {};

    for (final item in data) {
      scheduledPelangganIds.add(item.pelangganId);
      final customer = await repo.getCustomer(item.pelangganId);

      // Enrich with visit ID and order count (same logic as stream provider)
      final visits = await db.getVisitsByPelanggan(item.pelangganId);
      final matchingVisit = visits.where((v) {
        final checkIn = v.waktuCheckIn;
        if (checkIn == null) return false;
        return checkIn.startsWith(item.tanggal);
      }).firstOrNull;

      final orders = await db.getOrdersByPelanggan(item.pelangganId);
      final int pesananCount;
      if (matchingVisit != null) {
        pesananCount = orders.where((o) =>
          o.kunjunganId == matchingVisit.id ||
          o.kunjunganId == matchingVisit.serverId?.toString()
        ).length;
      } else {
        pesananCount = 0;
      }

      result.add(_scheduleToMap(
        item,
        customer,
        kunjunganId: matchingVisit?.serverId ?? (matchingVisit?.id),
        pesananCount: pesananCount,
      ));
    }

    // ── Merge unplanned visits (kunjungan diluar jadwal) ─────────────────
    final todayVisits = await db.getTodayVisits();
    final unplannedVisits = todayVisits.where((v) {
      if (v.scheduleId != null) return false;
      final checkIn = v.waktuCheckIn;
      if (checkIn == null) return false;
      if (!checkIn.startsWith(dateStr)) return false;
      final pelId = v.pelangganId?.toString() ?? '';
      if (scheduledPelangganIds.contains(pelId)) return false;
      return true;
    }).toList();

    for (final visit in unplannedVisits) {
      final pelIdStr = visit.pelangganId?.toString() ?? '';
      final customer = pelIdStr.isNotEmpty
          ? await db.getCustomer(pelIdStr)
          : null;

      final String visitStatus;
      if (visit.waktuCheckOut != null) {
        visitStatus = 'SELESAI';
      } else {
        visitStatus = 'DIKUNJUNGI';
      }

      int pesananCount = 0;
      if (pelIdStr.isNotEmpty) {
        final orders = await db.getOrdersByPelanggan(pelIdStr);
        pesananCount = orders.where((o) =>
          o.kunjunganId == visit.id ||
          o.kunjunganId == visit.serverId?.toString()
        ).length;
      }

      result.add(_unplannedVisitToMap(
        visit,
        customer,
        tanggal: dateStr,
        visitStatus: visitStatus,
        pesananCount: pesananCount,
      ));
    }

    return result;
  }

  Future<void> _revalidate(
    ScheduleRepository repo,
    String dateStr, {
    bool forceRefresh = false,
  }) async {
    try {
      await repo.syncTodayScheduleFromApi(
        dateParam: dateStr,
        forceRefresh: forceRefresh,
      );

      final freshData = await repo.getTodaySchedule(date: dateStr);
      final mappedFreshData = await _mapScheduleData(freshData, repo, dateStr: dateStr);

      // RACE CONDITION GUARD: hanya update UI jika user masih di tanggal yang sama
      final currentDateStr = ref
          .read(selectedDateProvider)
          .toIso8601String()
          .split('T')[0];

      if (dateStr == currentDateStr) {
        state = AsyncData(_filterData(mappedFreshData));
      }
    } catch (_) {
      // Abaikan jika offline / server error
    }
  }

  List<dynamic> _filterData(List<dynamic> data) {
    final search = ref.read(scheduleSearchProvider);
    if (search.isEmpty) return data;

    final query = search.toLowerCase();
    return data.where((item) {
      final p = item['pelanggan'] ?? {};
      final nameToko = p['nama_toko']?.toString().toLowerCase() ?? '';
      final namePel = p['nama_pelanggan']?.toString().toLowerCase() ?? '';
      final address = p['alamat']?.toString().toLowerCase() ?? '';

      return nameToko.contains(query) ||
          namePel.contains(query) ||
          address.contains(query);
    }).toList();
  }

  Future<void> refresh() async {
    final date = ref.read(selectedDateProvider);
    final dateStr = date.toIso8601String().split('T')[0];
    final repo = ref.read(scheduleRepositoryProvider);

    // Force refresh dari server
    await _revalidate(repo, dateStr, forceRefresh: true);
  }
}
