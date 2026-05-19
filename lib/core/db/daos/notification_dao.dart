import 'package:drift/drift.dart';

import '../app_database.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [NotificationsTable])
class NotificationDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Future<void> saveNotification({
    required String id,
    required String karyawanId,
    required String judul,
    required String isi,
    String tipe = 'info',
    bool isRead = false,
  }) async {
    await into(notificationsTable).insertOnConflictUpdate(
      NotificationsTableCompanion.insert(
        id: id,
        karyawanId: karyawanId,
        judul: judul,
        isi: isi,
        tipe: Value(tipe),
        isRead: Value(isRead),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> saveNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    await batch((b) {
      for (final n in notifications) {
        b.insert(
          notificationsTable,
          NotificationsTableCompanion.insert(
            id: n['id']?.toString() ?? '',
            karyawanId: n['id_karyawan']?.toString() ?? '',
            judul: n['judul'] as String,
            isi: n['isi'] as String,
            tipe: Value(n['tipe'] as String? ?? 'info'),
            isRead: Value(n['is_read'] == true || n['is_read'] == 1),
            createdAt: n['created_at'] as int,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> markNotificationRead(String id) {
    return (update(notificationsTable)..where((t) => t.id.equals(id))).write(
      const NotificationsTableCompanion(isRead: Value(true)),
    );
  }

  Future<void> markAllNotificationsRead() {
    return update(notificationsTable)
        .write(const NotificationsTableCompanion(isRead: Value(true)));
  }

  Future<int> getUnreadNotificationCount() async {
    final query = selectOnly(notificationsTable)
      ..where(notificationsTable.isRead.equals(false))
      ..addColumns([notificationsTable.id.count()]);
    final result = await query.getSingle();
    return result.read(notificationsTable.id.count()) ?? 0;
  }

  Future<void> deleteNotification(String id) {
    return (delete(notificationsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteReadNotifications() {
    return (delete(notificationsTable)..where((t) => t.isRead.equals(true)))
        .go();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────

  Stream<List<NotificationsTableData>> watchAllNotifications() {
    return (select(notificationsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<NotificationsTableData>> watchUnreadNotifications() {
    return (select(notificationsTable)
          ..where((t) => t.isRead.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchUnreadNotificationCount() {
    final query = selectOnly(notificationsTable)
      ..where(notificationsTable.isRead.equals(false))
      ..addColumns([notificationsTable.id.count()]);
    return query
        .map((row) => row.read(notificationsTable.id.count()) ?? 0)
        .watchSingle();
  }
}
