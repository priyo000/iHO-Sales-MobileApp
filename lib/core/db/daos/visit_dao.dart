import 'package:drift/drift.dart';

import '../app_database.dart';

part 'visit_dao.g.dart';

@DriftAccessor(tables: [VisitsTable])
class VisitDao extends DatabaseAccessor<AppDatabase> with _$VisitDaoMixin {
  VisitDao(super.db);

  Future<String> saveVisit({
    required String id,
    String? scheduleId,
    dynamic pelangganId,
    String status = 'CHECKED_IN',
    double? latIn,
    double? longIn,
    double? latOut,
    double? longOut,
    String? waktuCheckIn,
    String? waktuCheckOut,
    String? alasanTidak,
    String? catatan,
    String? serverId,
    int photosPending = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = VisitsTableCompanion.insert(
      id: id,
      isLocal: Value(serverId == null ? 1 : 0),
      scheduleId: Value(scheduleId),
      pelangganId: Value(pelangganId?.toString()),
      status: Value(status),
      latIn: Value(latIn),
      longIn: Value(longIn),
      latOut: Value(latOut),
      longOut: Value(longOut),
      waktuCheckIn: Value(waktuCheckIn),
      waktuCheckOut: Value(waktuCheckOut),
      alasanTidak: Value(alasanTidak),
      catatan: Value(catatan),
      serverId: Value(serverId),
      photosPending: Value(photosPending),
      createdAt: now,
      updatedAt: now,
    );
    await into(visitsTable).insert(
      companion,
      onConflict: DoUpdate(
        (old) => VisitsTableCompanion(
          isLocal: Value(serverId == null ? 1 : 0),
          scheduleId: Value(scheduleId),
          pelangganId: Value(pelangganId?.toString()),
          status: Value(status),
          latIn: Value(latIn),
          longIn: Value(longIn),
          latOut: Value(latOut),
          longOut: Value(longOut),
          waktuCheckIn: Value(waktuCheckIn),
          waktuCheckOut: Value(waktuCheckOut),
          alasanTidak: Value(alasanTidak),
          catatan: Value(catatan),
          serverId: Value(serverId),
          photosPending: Value(photosPending),
          updatedAt: Value(now),
        ),
      ),
    );
    return id;
  }

  Future<void> updateVisitCheckout({
    required String id,
    String status = 'CHECKED_OUT',
    double? latOut,
    double? longOut,
    String? waktuCheckOut,
    String? alasanTidak,
    String? catatan,
    int photosPending = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(visitsTable)..where((t) => t.id.equals(id))).write(
      VisitsTableCompanion(
        status: Value(status),
        latOut: Value(latOut),
        longOut: Value(longOut),
        waktuCheckOut: Value(waktuCheckOut),
        alasanTidak: Value(alasanTidak),
        catatan: Value(catatan),
        photosPending: Value(photosPending),
        updatedAt: Value(now),
      ),
    );
  }

  Future<VisitsTableData?> getVisit(String id) async {
    return await (select(visitsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<VisitsTableData?> getVisitByServerId(String serverId) async {
    return await (select(visitsTable)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  Future<List<VisitsTableData>> getPendingVisits() async {
    return await (select(visitsTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markVisitSynced(String id, String serverId) async {
    await (update(visitsTable)..where((t) => t.id.equals(id))).write(
      VisitsTableCompanion(
        isLocal: const Value(0),
        serverId: Value(serverId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateVisitPelangganId(String visitId, String pelangganId) async {
    await (update(visitsTable)..where((t) => t.id.equals(visitId))).write(
      VisitsTableCompanion(
        pelangganId: Value(pelangganId.toString()),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateVisitServerId(String clientRef, String serverId) async {
    await customUpdate(
      'UPDATE visits_table SET server_id = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable.withString(serverId),
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withString(clientRef),
      ],
      updates: {visitsTable},
    );
  }

  Future<void> deleteVisit(String id) async {
    await (delete(visitsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<VisitsTableData>> getVisitsByPelanggan(String pelangganId) async {
    return await (select(visitsTable)
          ..where((t) => t.pelangganId.equals(pelangganId.toString()))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<VisitsTableData>> getTodayVisits() async {
    final now = DateTime.now();
    final startUtc =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endUtc = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();
    return await (select(visitsTable)
          ..where((t) =>
              t.waktuCheckIn.isBiggerOrEqualValue(startUtc) &
              t.waktuCheckIn.isSmallerThanValue(endUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<VisitsTableData>> getVisitsInRange(
    String startDate,
    String endDate,
  ) async {
    final startMs = DateTime.parse(startDate).millisecondsSinceEpoch;
    final endMs =
        DateTime.parse(endDate).add(const Duration(days: 1)).millisecondsSinceEpoch;

    return await (select(visitsTable)
          ..where(
            (t) =>
                (t.waktuCheckIn.isNotNull() &
                    t.waktuCheckIn.isBiggerOrEqualValue(
                      DateTime.fromMillisecondsSinceEpoch(startMs).toIso8601String(),
                    ) &
                    t.waktuCheckIn.isSmallerThanValue(
                      DateTime.fromMillisecondsSinceEpoch(endMs).toIso8601String(),
                    )) |
                (t.waktuCheckIn.isNull() &
                    t.createdAt.isBiggerOrEqualValue(startMs) &
                    t.createdAt.isSmallerThanValue(endMs)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.waktuCheckIn)]))
        .get();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────────

  Stream<List<VisitsTableData>> watchAllVisits() {
    return (select(visitsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<VisitsTableData>> watchPendingVisits() {
    return (select(visitsTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<VisitsTableData?> watchVisit(String id) {
    return (select(visitsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<VisitsTableData>> watchVisitsByPelanggan(String pelangganId) {
    return (select(visitsTable)
          ..where((t) => t.pelangganId.equals(pelangganId.toString()))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<VisitsTableData>> watchTodayVisits() {
    final now = DateTime.now();
    final startUtc =
        DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endUtc = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();
    return (select(visitsTable)
          ..where((t) =>
              t.waktuCheckIn.isBiggerOrEqualValue(startUtc) &
              t.waktuCheckIn.isSmallerThanValue(endUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
