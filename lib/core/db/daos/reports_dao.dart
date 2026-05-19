import 'package:drift/drift.dart';

import '../app_database.dart';

part 'reports_dao.g.dart';

@DriftAccessor(tables: [OrdersTable, VisitsTable])
class ReportsDao extends DatabaseAccessor<AppDatabase> with _$ReportsDaoMixin {
  ReportsDao(super.db);

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
                      DateTime.fromMillisecondsSinceEpoch(startMs)
                          .toIso8601String(),
                    ) &
                    t.waktuCheckIn.isSmallerThanValue(
                      DateTime.fromMillisecondsSinceEpoch(endMs)
                          .toIso8601String(),
                    )) |
                (t.waktuCheckIn.isNull() &
                    t.createdAt.isBiggerOrEqualValue(startMs) &
                    t.createdAt.isSmallerThanValue(endMs)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.waktuCheckIn)]))
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

  Future<double> getOrdersTotalInRange(String startDate, String endDate) async {
    final orders = await getOrdersInRange(startDate, endDate);
    double total = 0;
    for (final order in orders) {
      final status = order.status.toUpperCase();
      if (status.contains('BATAL') || status.contains('CANCEL')) continue;
      total += order.totalTagihan;
    }
    return total;
  }

  Future<int> getEffectiveCallsInRange(String startDate, String endDate) async {
    final startMs = DateTime.parse(startDate).millisecondsSinceEpoch;
    final endMs =
        DateTime.parse(endDate).add(const Duration(days: 1)).millisecondsSinceEpoch;

    final orders =
        await (select(ordersTable)..where(
              (t) =>
                  t.tanggalTransaksi.isBiggerOrEqualValue(startMs) &
                  t.tanggalTransaksi.isSmallerThanValue(endMs) &
                  t.kunjunganId.isNotNull(),
            ))
            .get();

    final seenKunj = <String>{};
    for (final order in orders) {
      final status = order.status.toUpperCase();
      if (status.contains('BATAL') || status.contains('CANCEL')) continue;
      final kunjId = order.kunjunganId?.toString();
      if (kunjId != null) seenKunj.add(kunjId);
    }
    return seenKunj.length;
  }

  Future<Map<String, double>> getDailySalesInRange(
    String startDate,
    String endDate,
  ) async {
    final orders = await getOrdersInRange(startDate, endDate);
    final Map<String, double> daily = {};

    for (final order in orders) {
      final status = order.status.toUpperCase();
      if (status.contains('BATAL') || status.contains('CANCEL')) continue;
      final createdAt =
          DateTime.fromMillisecondsSinceEpoch(order.tanggalTransaksi);
      final dateKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      daily[dateKey] =
          (daily[dateKey] ?? 0) +
          ((order.totalTagihan as num?)?.toDouble() ?? 0);
    }

    return daily;
  }
}
