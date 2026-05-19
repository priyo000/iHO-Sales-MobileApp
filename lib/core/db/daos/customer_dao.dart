import 'package:drift/drift.dart';

import '../app_database.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [CustomersTable])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  CustomerDao(super.db);

  Future<String> saveCustomer({
    required String id,
    String? serverId,
    String? kodePelanggan,
    String? namaToko,
    String? namaPemilik,
    String? noHpPribadi,
    String? alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    String? fotoTokoPath,
    String? fotoKtpPath,
    String? noKtpPemilik,
    String? sistemPembayaran,
    String? caraPembayaran,
    String? namaBank,
    String? cabangBank,
    String? noRekening,
    String? atasNamaRekening,
    int? topHari,
    double? limitKreditAwal,
    String? kotaUsaha,
    String? kecamatanUsaha,
    String? provinsiUsaha,
    String? dataJson,
    String? createdById,
    int? createdAt,
    int? updatedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await (select(customersTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    final preservedCreatedAt = createdAt ?? existing?.createdAt ?? now;
    final preservedCreatedById = createdById ?? existing?.createdById;
    await into(customersTable).insertOnConflictUpdate(
      CustomersTableCompanion.insert(
        id: id,
        isLocal: Value(serverId == null ? 1 : 0),
        serverId: Value(serverId),
        kodePelanggan: Value(kodePelanggan),
        namaToko: Value(namaToko),
        namaPemilik: Value(namaPemilik),
        noHpPribadi: Value(noHpPribadi),
        alamatUsaha: Value(alamatUsaha),
        latitude: Value(latitude),
        longitude: Value(longitude),
        status: Value(status),
        fotoTokoPath: Value(fotoTokoPath),
        fotoKtpPath: Value(fotoKtpPath),
        noKtpPemilik: Value(noKtpPemilik),
        sistemPembayaran: Value(sistemPembayaran),
        caraPembayaran: Value(caraPembayaran),
        namaBank: Value(namaBank),
        cabangBank: Value(cabangBank),
        noRekening: Value(noRekening),
        atasNamaRekening: Value(atasNamaRekening),
        topHari: Value(topHari),
        limitKreditAwal: Value(limitKreditAwal),
        kotaUsaha: Value(kotaUsaha),
        kecamatanUsaha: Value(kecamatanUsaha),
        provinsiUsaha: Value(provinsiUsaha),
        dataJson: Value(dataJson),
        createdById: Value(preservedCreatedById),
        createdAt: preservedCreatedAt,
        updatedAt: updatedAt ?? now,
      ),
    );
    return id;
  }

  Future<void> saveCustomers(List<Map<String, dynamic>> customers) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      for (final c in customers) {
        final id = c['id']?.toString() ?? '';
        final serverId = c['id']?.toString() ?? c['server_id']?.toString();
        final createdAt = _parseEpochMs(c['created_at']) ?? now;
        final updatedAt = _parseEpochMs(c['updated_at']) ?? now;
        b.insert(
          customersTable,
          CustomersTableCompanion.insert(
            id: id,
            isLocal: Value(serverId == null ? 1 : 0),
            serverId: Value(serverId),
            kodePelanggan: Value(c['kode_pelanggan'] as String?),
            namaToko: Value(c['nama_toko'] as String?),
            namaPemilik: Value(c['nama_pemilik'] as String?),
            noHpPribadi: Value(c['no_hp_pribadi'] as String?),
            alamatUsaha: Value(c['alamat_usaha'] as String?),
            latitude: Value(_parseDouble(c['latitude'])),
            longitude: Value(_parseDouble(c['longitude'])),
            status: Value(c['status'] as String?),
            fotoTokoPath: Value(
              c['foto_toko'] as String? ??
                  c['foto_toko_url'] as String? ??
                  c['foto_toko_path'] as String?,
            ),
            fotoKtpPath: Value(
              c['foto_ktp'] as String? ??
                  c['foto_ktp_url'] as String? ??
                  c['foto_ktp_path'] as String?,
            ),
            noKtpPemilik: Value(c['no_ktp_pemilik'] as String?),
            sistemPembayaran: Value(c['sistem_pembayaran'] as String?),
            caraPembayaran: Value(c['cara_pembayaran'] as String?),
            namaBank: Value(c['nama_bank'] as String?),
            cabangBank: Value(c['cabang_bank'] as String?),
            noRekening: Value(c['no_rekening'] as String?),
            atasNamaRekening: Value(c['atas_nama_rekening'] as String?),
            topHari: Value(_parseInt(c['top_hari'])),
            limitKreditAwal: Value(_parseDouble(c['limit_kredit_awal'])),
            kotaUsaha: Value(c['kota_usaha'] as String?),
            kecamatanUsaha: Value(c['kecamatan_usaha'] as String?),
            provinsiUsaha: Value(c['provinsi_usaha'] as String?),
            dataJson: Value(c['data_json'] as String?),
            createdById: Value(c['created_by_id'] as String?),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<CustomersTableData?> getCustomer(String id) async {
    return await (select(customersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CustomersTableData>> getPendingCustomers() async {
    return await (select(customersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markCustomerSynced(String id, String serverId) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      CustomersTableCompanion(
        isLocal: const Value(0),
        serverId: Value(serverId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteCustomer(String id) async {
    await (delete(customersTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<CustomersTableData>> getAllLocalCustomers() async {
    return await (select(customersTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────────

  Stream<List<CustomersTableData>> watchAllCustomers() {
    return (select(customersTable)
          ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
        .watch();
  }

  Stream<List<CustomersTableData>> watchCustomersByStatus(String status) {
    if (status.contains(',')) {
      final statuses =
          status.split(',').map((s) => s.trim().toLowerCase()).toList();
      return (select(customersTable)
            ..where((t) => t.status.lower().isIn(statuses) | t.status.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
          .watch();
    }
    return (select(customersTable)
          ..where(
            (t) =>
                t.status.lower().equals(status.toLowerCase()) |
                t.status.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
        .watch();
  }

  Stream<List<CustomersTableData>> watchSearchCustomers(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(customersTable)
          ..where(
            (t) =>
                t.namaToko.lower().like(q) |
                t.namaPemilik.lower().like(q) |
                t.noHpPribadi.like(q) |
                t.kodePelanggan.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaToko)]))
        .watch();
  }

  Stream<List<CustomersTableData>> watchPendingCustomers() {
    return (select(customersTable)
          ..where((t) => t.isLocal.equals(1))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.isNotEmpty) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }

  int? _parseEpochMs(dynamic value) {
    if (value == null) return null;
    if (value is int) return value < 1000000000000 ? value * 1000 : value;
    if (value is double) {
      final v = value.toInt();
      return v < 1000000000000 ? v * 1000 : v;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return parsed < 1000000000000 ? parsed * 1000 : parsed;
    return DateTime.tryParse(value.toString())?.millisecondsSinceEpoch;
  }
}
