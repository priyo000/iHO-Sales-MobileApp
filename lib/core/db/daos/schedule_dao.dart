import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../app_database.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [ScheduleTable, VisitsTable])
class ScheduleDao extends DatabaseAccessor<AppDatabase> with _$ScheduleDaoMixin {
  ScheduleDao(super.db);

  Future<void> saveScheduleItem({
    required String id,
    String? jadwalId,
    required String karyawanId,
    required String tanggal,
    String? divisiId,
    required String pelangganId,
    int urutan = 0,
    String status = 'scheduled',
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await (select(scheduleTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    String finalStatus = status;
    String? finalCheckIn = waktuCheckIn;
    String? finalCheckOut = waktuCheckOut;

    if (existing != null) {
      final localStatus = existing.status.toUpperCase();
      final incomingStatus = status.toUpperCase();

      if ((localStatus == 'DIKUNJUNGI' || localStatus == 'SELESAI') &&
          (incomingStatus == 'TERTUNDA' ||
              incomingStatus == 'SCHEDULED' ||
              incomingStatus == '')) {
        finalStatus = existing.status;
        finalCheckIn = existing.waktuCheckIn ?? waktuCheckIn;
        finalCheckOut = existing.waktuCheckOut ?? waktuCheckOut;
      }
    }

    await into(scheduleTable).insertOnConflictUpdate(
      ScheduleTableCompanion.insert(
        id: id,
        jadwalId: Value(jadwalId),
        karyawanId: karyawanId,
        tanggal: tanggal,
        divisiId: Value(divisiId),
        pelangganId: pelangganId,
        urutan: Value(urutan),
        status: Value(finalStatus),
        waktuCheckIn: Value(finalCheckIn),
        waktuCheckOut: Value(finalCheckOut),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> saveScheduleItems(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      for (final item in items) {
        b.insert(
          scheduleTable,
          ScheduleTableCompanion.insert(
            id: item['id']?.toString() ?? '',
            jadwalId: Value(item['id_jadwal']?.toString()),
            karyawanId: item['id_karyawan']?.toString() ?? '',
            tanggal: item['tanggal'] as String,
            divisiId: Value(item['id_divisi']?.toString()),
            pelangganId: item['id_pelanggan']?.toString() ?? '',
            urutan: Value(item['urutan'] as int? ?? 0),
            status: Value(item['status'] as String? ?? 'scheduled'),
            waktuCheckIn: Value(item['waktu_check_in'] as String?),
            waktuCheckOut: Value(item['waktu_check_out'] as String?),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updateScheduleStatus(
    String id,
    String status, {
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) {
    return (update(scheduleTable)..where((t) => t.id.equals(id))).write(
      ScheduleTableCompanion(
        status: Value(status),
        waktuCheckIn: Value(waktuCheckIn),
        waktuCheckOut: Value(waktuCheckOut),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateScheduleStatusByJadwal({
    required String jadwalId,
    required String pelangganId,
    String status = 'DIKUNJUNGI',
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) async {
    await (update(scheduleTable)..where(
          (t) =>
              t.jadwalId.equals(jadwalId) & t.pelangganId.equals(pelangganId),
        ))
        .write(
          ScheduleTableCompanion(
            status: Value(status),
            waktuCheckIn: Value(waktuCheckIn),
            waktuCheckOut: Value(waktuCheckOut),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> updateScheduleStatusByVisitId({
    required String visitId,
    String status = 'SELESAI',
    String? waktuCheckOut,
  }) async {
    final visit = await (select(visitsTable)
          ..where((t) => t.id.equals(visitId)))
        .getSingleOrNull();

    if (visit != null && visit.scheduleId != null) {
      final pelangganId = visit.pelangganId;
      if (pelangganId != null) {
        await (update(scheduleTable)..where(
              (t) =>
                  t.jadwalId.equals(visit.scheduleId!) &
                  t.pelangganId.equals(pelangganId),
            ))
            .write(
              ScheduleTableCompanion(
                status: Value(status),
                waktuCheckOut: Value(waktuCheckOut),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
      } else {
        debugPrint(
          '[WARNING] updateScheduleStatusByVisitId: visit $visitId has no pelangganId',
        );
      }
    } else if (visit != null &&
        visit.scheduleId == null &&
        visit.pelangganId != null) {
      final pelangganId = visit.pelangganId!;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final scheduleRows =
          await (select(scheduleTable)..where(
                (t) =>
                    t.pelangganId.equals(pelangganId) &
                    t.tanggal.equals(todayStr),
              ))
              .get();

      if (scheduleRows.isNotEmpty) {
        final targetRow = scheduleRows.first;
        await (update(scheduleTable)
              ..where((t) => t.id.equals(targetRow.id)))
            .write(
              ScheduleTableCompanion(
                status: Value(status),
                waktuCheckOut: Value(waktuCheckOut),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
      }
    }
  }

  Future<List<ScheduleTableData>> getScheduleForDate(String tanggal) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.equals(tanggal))
          ..orderBy([(t) => OrderingTerm.asc(t.urutan)]))
        .get();
  }

  Future<ScheduleTableData?> getScheduleById(String id) {
    return (select(scheduleTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<ScheduleTableData>> getScheduleForDateRange(
    String startDate,
    String endDate,
  ) {
    return (select(scheduleTable)
          ..where(
            (t) =>
                t.tanggal.isBiggerOrEqualValue(startDate) &
                t.tanggal.isSmallerOrEqualValue(endDate),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.tanggal),
            (t) => OrderingTerm.asc(t.urutan),
          ]))
        .get();
  }

  Future<void> deleteScheduleItem(String id) {
    return (delete(scheduleTable)..where((t) => t.id.equals(id))).go();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────

  Stream<List<ScheduleTableData>> watchScheduleForDate(String tanggal) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.equals(tanggal))
          ..orderBy([(t) => OrderingTerm.asc(t.urutan)]))
        .watch();
  }

  Stream<List<ScheduleTableData>> watchScheduleByStatus(
    String tanggal,
    String status,
  ) {
    return (select(scheduleTable)
          ..where((t) => t.tanggal.equals(tanggal) & t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.urutan)]))
        .watch();
  }

  Stream<List<ScheduleTableData>> watchTodaySchedule() {
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    return watchScheduleForDate(today);
  }

  Stream<List<ScheduleTableData>> watchScheduleByPelanggan(String pelangganId) {
    return (select(scheduleTable)
          ..where((t) => t.pelangganId.equals(pelangganId))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggal)]))
        .watch();
  }
}
