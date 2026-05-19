import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import '../app_database.dart';

part 'order_dao.g.dart';

@DriftAccessor(tables: [OrdersTable])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  Future<String> saveOrder({
    required String id,
    String? kunjunganId,
    String? pelangganId,
    String status = 'PENDING',
    required String itemsJson,
    String? notes,
    String? promosJson,
    double totalTagihan = 0,
    String? serverId,
    String? clientRef,
    String? noPesanan,
    int? tanggalTransaksi,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    dev.log('[DB] saveOrder id=$id, noPesanan=$noPesanan, serverId=$serverId');

    final updatedRows =
        await (update(ordersTable)..where((t) => t.id.equals(id))).write(
          OrdersTableCompanion(
            isLocal: Value(serverId != null ? 0 : 1),
            status: Value(status),
            itemsJson: Value(itemsJson),
            notes: Value(notes),
            promosJson: Value(promosJson),
            totalTagihan: Value(totalTagihan),
            serverId: Value(serverId),
            clientRef: Value(clientRef),
            updatedAt: Value(now),
            tanggalTransaksi: Value(tanggalTransaksi ?? now),
            noPesanan: Value(noPesanan),
            kunjunganId: Value(kunjunganId),
            pelangganId: Value(pelangganId),
          ),
        );

    if (updatedRows == 0) {
      await into(ordersTable).insert(
        OrdersTableCompanion.insert(
          id: id,
          isLocal: serverId != null ? const Value(0) : const Value(1),
          kunjunganId: Value(kunjunganId),
          pelangganId: Value(pelangganId),
          status: Value(status),
          itemsJson: itemsJson,
          notes: Value(notes),
          promosJson: Value(promosJson),
          totalTagihan: Value(totalTagihan),
          serverId: Value(serverId),
          clientRef: Value(clientRef),
          createdAt: now,
          updatedAt: now,
          tanggalTransaksi: tanggalTransaksi ?? now,
          noPesanan: Value(noPesanan),
        ),
      );
    }
    return id;
  }

  Future<OrdersTableData?> getOrder(String id) async {
    return await (select(ordersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<OrdersTableData?> getOrderByClientRef(String clientRef) async {
    return await (select(ordersTable)
          ..where((t) => t.clientRef.equals(clientRef))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isLocal),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OrdersTableData?> getOrderByServerId(String serverId) async {
    return await (select(ordersTable)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isLocal),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OrdersTableData?> getOrderByNoPesanan(String noPesanan) async {
    return await (select(ordersTable)
          ..where((t) => t.noPesanan.equals(noPesanan))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isLocal),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> deleteDuplicateOrdersForCanonical({
    required String canonicalId,
    String? serverId,
    String? noPesanan,
    String? clientRef,
  }) async {
    await (delete(ordersTable)..where(
          (t) =>
              t.id.equals(canonicalId).not() &
              ((serverId != null
                      ? t.serverId.equals(serverId)
                      : const Constant(false)) |
                  (noPesanan != null
                      ? t.noPesanan.equals(noPesanan)
                      : const Constant(false)) |
                  (clientRef != null
                      ? t.clientRef.equals(clientRef)
                      : const Constant(false))),
        ))
        .go();
  }

  Future<List<OrdersTableData>> getPendingOrders() async {
    return await (select(ordersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markOrderSynced(String id, String serverId) async {
    await (update(ordersTable)..where((t) => t.id.equals(id))).write(
      OrdersTableCompanion(
        isLocal: const Value(0),
        serverId: Value(serverId),
        status: const Value('SYNCED'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteOrder(String id) async {
    await (delete(ordersTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<OrdersTableData>> getOrdersByPelanggan(String pelangganId) async {
    return await (select(ordersTable)
          ..where((t) => t.pelangganId.equals(pelangganId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<OrdersTableData>> getAllOrders() async {
    return await (select(ordersTable)
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .get();
  }

  Future<List<OrdersTableData>> getOrdersInRange(
    String startDate,
    String endDate,
  ) async {
    final startMs = DateTime.parse(startDate).millisecondsSinceEpoch;
    final endMs =
        DateTime.parse(endDate).add(const Duration(days: 1)).millisecondsSinceEpoch;

    return await (select(ordersTable)
          ..where(
            (t) =>
                t.tanggalTransaksi.isBiggerOrEqualValue(startMs) &
                t.tanggalTransaksi.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.tanggalTransaksi)]))
        .get();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────────

  Stream<List<OrdersTableData>> watchAllOrders() {
    return (select(ordersTable)
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }

  Stream<List<OrdersTableData>> watchPendingOrders() {
    return (select(ordersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }

  Stream<OrdersTableData?> watchOrder(String id) {
    return (select(ordersTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<OrdersTableData>> watchOrdersByPelanggan(String pelangganId) {
    return (select(ordersTable)
          ..where((t) => t.pelangganId.equals(pelangganId))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }

  Stream<List<OrdersTableData>> watchOrdersByStatus(String status) {
    return (select(ordersTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggalTransaksi)]))
        .watch();
  }
}
