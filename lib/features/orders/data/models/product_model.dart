class ProductUnit {
  final String id;
  final String nama;
  final double konversi;
  final double? hargaJual;
  final bool isBase;

  const ProductUnit({
    required this.id,
    required this.nama,
    required this.konversi,
    this.hargaJual,
    this.isBase = false,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      konversi: (json['konversi'] as num?)?.toDouble() ?? 1.0,
      hargaJual: (json['harga_jual'] as num?)?.toDouble(),
      isBase: json['is_base'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'konversi': konversi,
    'harga_jual': hargaJual,
    'is_base': isBase,
  };
}

class Product {
  final String id;
  final String namaProduk;
  final String? kategori;
  final String? idKategori;
  final String kodeBarang;
  final String sku;
  final double hargaJual;
  final int stokTersedia;
  final String? gambarUrl;
  final String satuan;
  final List<ProductUnit> units;

  Product({
    required this.id,
    required this.namaProduk,
    this.kategori,
    this.idKategori,
    required this.kodeBarang,
    required this.sku,
    required this.hargaJual,
    required this.stokTersedia,
    this.gambarUrl,
    required this.satuan,
    this.units = const [],
  });

  /// Default unit for ordering — largest conversionRate (first in list, sorted desc by backend)
  ProductUnit? get defaultUnit => units.isNotEmpty ? units.first : null;

  factory Product.fromJson(Map<String, dynamic> json) {
    final kategoriObj = json['kategori'];
    String? namaKategori;
    String? kategoriId;
    if (kategoriObj is Map<String, dynamic>) {
      namaKategori = kategoriObj['nama_kategori'] as String?;
      kategoriId = kategoriObj['id']?.toString();
    }

    final satuanList = json['satuan_list'] as List?;
    final units = satuanList != null
        ? satuanList.map((u) => ProductUnit.fromJson(u as Map<String, dynamic>)).toList()
        : <ProductUnit>[];

    return Product(
      id: json['id'].toString(),
      namaProduk: json['nama_produk'],
      kategori: namaKategori,
      idKategori: kategoriId,
      kodeBarang: json['kode_barang'] ?? '',
      sku: json['sku'] ?? '',
      hargaJual: double.tryParse(json['harga_jual'].toString()) ?? 0.0,
      stokTersedia: json['stok_tersedia'] ?? 0,
      gambarUrl: json['gambar_url'],
      satuan: json['satuan'] ?? 'pcs',
      units: units,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_produk': namaProduk,
      'kode_barang': kodeBarang,
      'sku': sku,
      'harga_jual': hargaJual,
      'stok_tersedia': stokTersedia,
      'gambar_url': gambarUrl,
      'satuan': satuan,
      'kategori': kategori != null
          ? {'nama_kategori': kategori, 'id': idKategori}
          : null,
      'satuan_list': units.map((u) => u.toJson()).toList(),
    };
  }
}
