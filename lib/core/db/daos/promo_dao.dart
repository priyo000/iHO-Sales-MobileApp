import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

part 'promo_dao.g.dart';

@DriftAccessor(tables: [PromoTable])
class PromoDao extends DatabaseAccessor<AppDatabase> with _$PromoDaoMixin {
  PromoDao(super.db);

  Future<void> savePromo({
    required String id,
    required String idPelanggan,
    required String namaCampaign,
    required String jenis,
    required String dataJson,
    String status = 'active',
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(promoTable).insertOnConflictUpdate(
      PromoTableCompanion.insert(
        id: id,
        idPelanggan: idPelanggan,
        namaCampaign: namaCampaign,
        jenis: jenis,
        dataJson: dataJson,
        status: Value(status),
        startDate: startDate.millisecondsSinceEpoch,
        endDate: endDate.millisecondsSinceEpoch,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> savePromos(List<Map<String, dynamic>> promos) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      for (final p in promos) {
        b.insert(
          promoTable,
          PromoTableCompanion.insert(
            id: p['id']?.toString() ?? '',
            idPelanggan: p['id_pelanggan']?.toString() ?? '',
            namaCampaign:
                p['nama_campaign'] as String? ?? p['nama'] as String? ?? '',
            jenis: p['jenis'] as String,
            dataJson: p['data_json'] is String
                ? p['data_json'] as String
                : jsonEncode(p['data_json'] ?? {}),
            status: Value(p['status'] as String? ?? 'active'),
            startDate: (p['start_date'] is int)
                ? p['start_date'] as int
                : (p['start_date'] is String)
                    ? DateTime.parse(p['start_date'] as String)
                        .millisecondsSinceEpoch
                    : now,
            endDate: (p['end_date'] is int)
                ? p['end_date'] as int
                : (p['end_date'] is String)
                    ? DateTime.parse(p['end_date'] as String)
                        .millisecondsSinceEpoch
                    : now,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<PromoTableData>> getActivePromos() {
    return (select(promoTable)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .get();
  }

  Future<List<PromoTableData>> getPromosForPelanggan(String idPelanggan) {
    return (select(promoTable)
          ..where(
            (t) =>
                t.idPelanggan.equals(idPelanggan) & t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .get();
  }

  Future<Set<String>> getPelangganIdsWithActivePromos() async {
    final query = selectOnly(promoTable, distinct: true)
      ..addColumns([promoTable.idPelanggan])
      ..where(promoTable.status.equals('active'));
    final rows = await query.get();
    return rows.map((r) => r.read(promoTable.idPelanggan)!).toSet();
  }

  Future<PromoTableData?> getPromo(String id, String idPelanggan) {
    return (select(promoTable)
          ..where((t) => t.id.equals(id) & t.idPelanggan.equals(idPelanggan)))
        .getSingleOrNull();
  }

  Future<void> deletePromosForPelanggan(String idPelanggan) {
    return (delete(promoTable)
          ..where((t) => t.idPelanggan.equals(idPelanggan)))
        .go();
  }

  Future<void> deletePromo(String id, String idPelanggan) {
    return (delete(promoTable)
          ..where((t) => t.id.equals(id) & t.idPelanggan.equals(idPelanggan)))
        .go();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────

  Stream<List<PromoTableData>> watchActivePromos() {
    return (select(promoTable)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  Stream<List<PromoTableData>> watchPromosByType(String jenis) {
    return (select(promoTable)
          ..where((t) => t.jenis.equals(jenis) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  Stream<List<PromoTableData>> watchPromosForPelanggan(String idPelanggan) {
    return (select(promoTable)
          ..where(
            (t) =>
                t.idPelanggan.equals(idPelanggan) & t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }

  Stream<List<PromoTableData>> watchPromosByTypeForPelanggan(
    String idPelanggan,
    String jenis,
  ) {
    return (select(promoTable)
          ..where(
            (t) =>
                t.idPelanggan.equals(idPelanggan) &
                t.jenis.equals(jenis) &
                t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaCampaign)]))
        .watch();
  }
}
