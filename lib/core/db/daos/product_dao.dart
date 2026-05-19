import 'package:drift/drift.dart';

import '../app_database.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [ProductsTable, ProductUnitsTable, CategoriesTable])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // ─── Products CRUD ──────────────────────────────────────────────────────

  Future<void> saveProduct({
    required String id,
    String? perusahaanId,
    String? sku,
    String? kodeBarang,
    required String namaProduk,
    String? kategoriId,
    String? satuan,
    String? deskripsi,
    double? hargaDasar,
    double? hargaJual,
    int stokTersedia = 0,
    String? gambarUrl,
    String status = 'active',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(productsTable).insertOnConflictUpdate(
      ProductsTableCompanion.insert(
        id: id,
        perusahaanId: Value(perusahaanId),
        sku: Value(sku),
        kodeBarang: Value(kodeBarang),
        namaProduk: namaProduk,
        kategoriId: Value(kategoriId),
        satuan: Value(satuan),
        deskripsi: Value(deskripsi),
        hargaDasar: Value(hargaDasar),
        hargaJual: Value(hargaJual),
        stokTersedia: Value(stokTersedia),
        gambarUrl: Value(gambarUrl),
        status: Value(status),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      for (final p in products) {
        final hargaDasarRaw = p['harga_dasar'];
        final hargaJualRaw = p['harga_jual'];
        double? hargaDasar;
        double? hargaJual;
        if (hargaDasarRaw is num) {
          hargaDasar = hargaDasarRaw.toDouble();
        } else if (hargaDasarRaw is String) {
          hargaDasar = double.tryParse(hargaDasarRaw);
        }
        if (hargaJualRaw is num) {
          hargaJual = hargaJualRaw.toDouble();
        } else if (hargaJualRaw is String) {
          hargaJual = double.tryParse(hargaJualRaw);
        }

        String? namaKategori;
        final kategoriObj = p['kategori'];
        if (kategoriObj is Map) {
          namaKategori = kategoriObj['nama_kategori'] as String?;
        }

        b.insert(
          productsTable,
          ProductsTableCompanion.insert(
            id: p['id']?.toString() ?? '',
            perusahaanId: Value(p['id_perusahaan']?.toString()),
            sku: Value(p['sku'] as String?),
            kodeBarang: Value(p['kode_barang'] as String?),
            namaProduk: p['nama_produk'] as String? ?? '',
            kategoriId: Value(p['id_kategori']?.toString()),
            kategori: Value(namaKategori),
            satuan: Value(p['satuan'] as String?),
            deskripsi: Value(p['deskripsi'] as String?),
            hargaDasar: Value(hargaDasar),
            hargaJual: Value(hargaJual),
            stokTersedia: Value(p['stok_tersedia'] as int? ?? 0),
            gambarUrl: Value(p['gambar_url'] as String?),
            status: Value(p['status'] as String? ?? 'active'),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<ProductsTableData?> getProduct(String id) {
    return (select(productsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<ProductsTableData>> getAllProducts() {
    return (select(productsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .get();
  }

  Future<List<ProductsTableData>> searchProducts(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(productsTable)
          ..where(
            (t) =>
                t.namaProduk.lower().like(q) |
                t.kodeBarang.lower().like(q) |
                t.sku.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .get();
  }

  Future<void> deleteProduct(String id) {
    return (delete(productsTable)..where((t) => t.id.equals(id))).go();
  }

  // ─── Product Units ─────────────────────────────────────────────────────

  Future<List<ProductUnitsTableData>> getUnitsForProduct(String productId) {
    return (select(productUnitsTable)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.konversi)]))
        .get();
  }

  Future<List<ProductUnitsTableData>> getAllProductUnits() {
    return (select(productUnitsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.konversi)]))
        .get();
  }

  Future<void> saveProductUnits(List<ProductUnitsTableCompanion> units) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(productUnitsTable, units);
    });
  }

  Future<void> deleteUnitsForProduct(String productId) {
    return (delete(productUnitsTable)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }

  // ─── Categories ────────────────────────────────────────────────────────

  Future<void> saveCategory({
    required String id,
    required String namaKategori,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(categoriesTable).insertOnConflictUpdate(
      CategoriesTableCompanion.insert(
        id: id,
        namaKategori: namaKategori,
        createdAt: now,
      ),
    );
  }

  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((b) {
      for (final c in categories) {
        b.insert(
          categoriesTable,
          CategoriesTableCompanion.insert(
            id: c['id']?.toString() ?? '',
            namaKategori: c['nama_kategori'] as String,
            createdAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<CategoriesTableData>> getAllCategories() {
    return (select(categoriesTable)
          ..orderBy([(t) => OrderingTerm.asc(t.namaKategori)]))
        .get();
  }

  // ─── Watch Methods ─────────────────────────────────────────────────────

  Stream<List<ProductsTableData>> watchAllProducts() {
    return (select(productsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  Stream<List<ProductsTableData>> watchProductsByStatus(String status) {
    return (select(productsTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  Stream<List<ProductsTableData>> watchProductsByCategory(String kategoriId) {
    return (select(productsTable)
          ..where((t) => t.kategoriId.equals(kategoriId))
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  Stream<List<ProductsTableData>> watchProductsByCategoryAndSearch({
    required String kategoriId,
    required String query,
  }) {
    final q = '%${query.toLowerCase()}%';
    return (select(productsTable)
          ..where(
            (t) =>
                t.kategoriId.equals(kategoriId) &
                (t.namaProduk.lower().like(q) |
                    t.kodeBarang.lower().like(q) |
                    t.sku.lower().like(q)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  Stream<List<ProductsTableData>> watchSearchProducts(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(productsTable)
          ..where(
            (t) =>
                t.namaProduk.lower().like(q) |
                t.kodeBarang.lower().like(q) |
                t.sku.lower().like(q),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.namaProduk)]))
        .watch();
  }

  Stream<List<CategoriesTableData>> watchAllCategories() {
    return (select(categoriesTable)
          ..orderBy([(t) => OrderingTerm.asc(t.namaKategori)]))
        .watch();
  }
}
