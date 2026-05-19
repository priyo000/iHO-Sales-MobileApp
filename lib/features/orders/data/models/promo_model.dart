// Models for promo system

class PromoAturanHargaItem {
  final String idProduk;
  final String? namaProduk;
  final double hargaNormal;
  final double? hargaManual;
  final double? diskonPersen;

  const PromoAturanHargaItem({
    required this.idProduk,
    this.namaProduk,
    required this.hargaNormal,
    this.hargaManual,
    this.diskonPersen,
  });

  double get hargaFinal {
    if (hargaManual != null) return hargaManual!;
    if (diskonPersen != null) return hargaNormal * (1 - diskonPersen! / 100);
    return hargaNormal;
  }

  factory PromoAturanHargaItem.fromJson(Map<String, dynamic> j) =>
      PromoAturanHargaItem(
        idProduk: j['id_produk']?.toString() ?? '',
        namaProduk: j['nama_produk'] as String?,
        hargaNormal: double.tryParse(j['harga_normal'].toString()) ?? 0,
        hargaManual: j['harga_manual'] != null ? double.tryParse(j['harga_manual'].toString()) : null,
        diskonPersen: j['diskon_persen'] != null ? double.tryParse(j['diskon_persen'].toString()) : null,
      );
}

class PromoAturanHarga {
  final String idCampaign;
  final String namaPromo;
  final String jenis;
  final String? tanggalMulai;
  final String? tanggalAkhir;
  final List<PromoAturanHargaItem> items;

  const PromoAturanHarga({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    this.tanggalMulai,
    this.tanggalAkhir,
    required this.items,
  });

  /// True jika tanggal_akhir sudah lewat hari ini.
  bool get isExpired {
    final end = tanggalAkhir;
    if (end == null || end.isEmpty) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return end.compareTo(today) < 0;
  }

  factory PromoAturanHarga.fromJson(Map<String, dynamic> j) => PromoAturanHarga(
        idCampaign: j['id_campaign']?.toString() ?? '',
        namaPromo: j['nama_promo'] as String? ?? 'Aturan Harga',
        jenis: j['jenis'] as String? ?? 'aturan_harga',
        tanggalMulai: j['tanggal_mulai'] as String?,
        tanggalAkhir: j['tanggal_akhir'] as String?,
        items: (j['items'] as List? ?? [])
            .map((i) => PromoAturanHargaItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class PromoGrosirTier {
  final int minQty;
  final double? hargaSpesial;
  final double? diskonPersen;

  const PromoGrosirTier({
    required this.minQty,
    this.hargaSpesial,
    this.diskonPersen,
  });

  factory PromoGrosirTier.fromJson(Map<String, dynamic> j) => PromoGrosirTier(
        minQty: int.tryParse(j['min_qty'].toString()) ?? 0,
        hargaSpesial: (j['harga_spesial'] as num?)?.toDouble(),
        diskonPersen: (j['diskon_persen'] as num?)?.toDouble(),
      );

  double hargaFinal(double hargaNormal) {
    if (hargaSpesial != null) return hargaSpesial!;
    if (diskonPersen != null) return hargaNormal * (1 - diskonPersen! / 100);
    return hargaNormal;
  }
}

class PromoGrosirItem {
  final String idProduk;
  final String? namaProduk;
  final double hargaNormal;
  final List<PromoGrosirTier> tiers;

  const PromoGrosirItem({
    required this.idProduk,
    this.namaProduk,
    required this.hargaNormal,
    required this.tiers,
  });

  factory PromoGrosirItem.fromJson(Map<String, dynamic> j) => PromoGrosirItem(
        idProduk: j['id_produk']?.toString() ?? '',
        namaProduk: j['nama_produk'] as String?,
        hargaNormal: (j['harga_normal'] as num?)?.toDouble() ?? 0,
        tiers: (j['tiers'] as List? ?? [])
            .map((t) => PromoGrosirTier.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  // Get best tier for given qty
  PromoGrosirTier? getTierForQty(int qty) {
    final eligible = tiers.where((t) => qty >= t.minQty).toList();
    if (eligible.isEmpty) return null;
    eligible.sort((a, b) => b.minQty.compareTo(a.minQty));
    return eligible.first;
  }
}

class PromoGrosir {
  final String idCampaign;
  final String namaPromo;
  final String jenis;
  final String? tanggalMulai;
  final String? tanggalAkhir;
  final List<PromoGrosirItem> items;

  const PromoGrosir({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    this.tanggalMulai,
    this.tanggalAkhir,
    required this.items,
  });

  /// True jika tanggal_akhir sudah lewat hari ini.
  bool get isExpired {
    final end = tanggalAkhir;
    if (end == null || end.isEmpty) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return end.compareTo(today) < 0;
  }

  factory PromoGrosir.fromJson(Map<String, dynamic> j) => PromoGrosir(
        idCampaign: j['id_campaign']?.toString() ?? '',
        namaPromo: j['nama_promo'] as String? ?? 'Grosir',
        jenis: j['jenis'] as String? ?? 'grosir',
        tanggalMulai: j['tanggal_mulai'] as String?,
        tanggalAkhir: j['tanggal_akhir'] as String?,
        items: (j['items'] as List? ?? [])
            .map((i) => PromoGrosirItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class ProdukHadiah {
  final String id;
  final String? namaProduk;

  const ProdukHadiah({required this.id, this.namaProduk});

  factory ProdukHadiah.fromJson(Map<String, dynamic> j) => ProdukHadiah(
        id: j['id']?.toString() ?? '',
        namaProduk: j['nama_produk'] as String?,
      );
}

class PromoHadiahItem {
  final String id;
  final String jenisPemicu;
  final String? idProdukPemicu;
  final String? namaProdukPemicu;
  final int? minQtyPemicu;
  final double? minAmountPemicu;
  final ProdukHadiah produkHadiah;
  final int qtyHadiah;
  final double hargaTebus;

  const PromoHadiahItem({
    required this.id,
    required this.jenisPemicu,
    this.idProdukPemicu,
    this.namaProdukPemicu,
    this.minQtyPemicu,
    this.minAmountPemicu,
    required this.produkHadiah,
    required this.qtyHadiah,
    required this.hargaTebus,
  });

  factory PromoHadiahItem.fromJson(Map<String, dynamic> j) => PromoHadiahItem(
        id: j['id']?.toString() ?? '',
        jenisPemicu: j['jenis_pemicu'] as String? ?? '',
        idProdukPemicu: j['id_produk_pemicu']?.toString(),
        namaProdukPemicu: j['nama_produk_pemicu'] as String?,
        minQtyPemicu: j['min_qty_pemicu'] != null
            ? int.tryParse(j['min_qty_pemicu'].toString())
            : null,
        minAmountPemicu: (j['min_amount_pemicu'] as num?)?.toDouble(),
        produkHadiah: ProdukHadiah.fromJson(
            j['produk_hadiah'] as Map<String, dynamic>),
        qtyHadiah: int.tryParse(j['qty_hadiah'].toString()) ?? 1,
        hargaTebus: double.tryParse(j['harga_tebus'].toString()) ?? 0,
      );


}

class PromoHadiah {
  final String idCampaign;
  final String namaPromo;
  final String jenis;
  final String? tanggalMulai;
  final String? tanggalAkhir;
  final List<PromoHadiahItem> items;

  const PromoHadiah({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    this.tanggalMulai,
    this.tanggalAkhir,
    required this.items,
  });

  /// True jika tanggal_akhir sudah lewat hari ini.
  bool get isExpired {
    final end = tanggalAkhir;
    if (end == null || end.isEmpty) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return end.compareTo(today) < 0;
  }

  factory PromoHadiah.fromJson(Map<String, dynamic> j) => PromoHadiah(
        idCampaign: j['id_campaign']?.toString() ?? '',
        namaPromo: j['nama_promo'] as String? ?? 'Promo Hadiah',
        jenis: j['jenis'] as String? ?? 'hadiah',
        tanggalMulai: j['tanggal_mulai'] as String?,
        tanggalAkhir: j['tanggal_akhir'] as String?,
        items: (j['items'] as List? ?? [])
            .map((i) => PromoHadiahItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class AvailablePromos {
  final String syncedAt;
  final List<PromoAturanHarga> aturanHarga;
  final List<PromoGrosir> grosir;
  final List<PromoHadiah> hadiah;

  const AvailablePromos({
    required this.syncedAt,
    required this.aturanHarga,
    required this.grosir,
    required this.hadiah,
  });

  const AvailablePromos.empty()
      : syncedAt = '',
        aturanHarga = const [],
        grosir = const [],
        hadiah = const [];

  bool get isEmpty =>
      aturanHarga.isEmpty && grosir.isEmpty && hadiah.isEmpty;

  /// Return copy dengan semua promo yang sudah di-expire dibuang.
  AvailablePromos withActiveOnly() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final activeAturan = aturanHarga
        .where((p) => _isActive(p.tanggalMulai, p.tanggalAkhir, today))
        .toList();
    final activeGrosir = grosir
        .where((p) => _isActive(p.tanggalMulai, p.tanggalAkhir, today))
        .toList();
    final activeHadiah = hadiah
        .where((p) => _isActive(p.tanggalMulai, p.tanggalAkhir, today))
        .toList();
    return AvailablePromos(
      syncedAt: syncedAt,
      aturanHarga: activeAturan,
      grosir: activeGrosir,
      hadiah: activeHadiah,
    );
  }

  static bool _isActive(String? mulai, String? akhir, String today) {
    if (mulai != null && mulai.isNotEmpty && mulai.compareTo(today) > 0) return false;
    if (akhir != null && akhir.isNotEmpty && akhir.compareTo(today) < 0) return false;
    // Jika tanggal kosong, anggap aktif (fallback)
    return true;
  }

  factory AvailablePromos.fromJson(Map<String, dynamic> j) => AvailablePromos(
        syncedAt: j['synced_at'] as String? ?? '',
        aturanHarga: (j['aturan_harga'] as List? ?? [])
            .map((i) => PromoAturanHarga.fromJson(i as Map<String, dynamic>))
            .toList(),
        grosir: (j['grosir'] as List? ?? [])
            .map((i) => PromoGrosir.fromJson(i as Map<String, dynamic>))
            .toList(),
        hadiah: (j['hadiah'] as List? ?? [])
            .map((i) => PromoHadiah.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'synced_at': syncedAt,
        'aturan_harga': aturanHarga
            .map((p) => {
                  'id_campaign': p.idCampaign,
                  'nama_promo': p.namaPromo,
                  'jenis': p.jenis,
                  'tanggal_mulai': p.tanggalMulai,
                  'tanggal_akhir': p.tanggalAkhir,
                  'items': p.items
                      .map((i) => {
                            'id_produk': i.idProduk,
                            'nama_produk': i.namaProduk,
                            'harga_normal': i.hargaNormal,
                            'harga_manual': i.hargaManual,
                            'diskon_persen': i.diskonPersen,
                          })
                      .toList(),
                })
            .toList(),
        'grosir': grosir
            .map((p) => {
                  'id_campaign': p.idCampaign,
                  'nama_promo': p.namaPromo,
                  'jenis': p.jenis,
                  'tanggal_mulai': p.tanggalMulai,
                  'tanggal_akhir': p.tanggalAkhir,
                  'items': p.items
                      .map((i) => {
                            'id_produk': i.idProduk,
                            'nama_produk': i.namaProduk,
                            'harga_normal': i.hargaNormal,
                            'tiers': i.tiers
                                .map((t) => {
                                      'min_qty': t.minQty,
                                      'harga_spesial': t.hargaSpesial,
                                      'diskon_persen': t.diskonPersen,
                                    })
                                .toList(),
                          })
                      .toList(),
                })
            .toList(),
        'hadiah': hadiah
            .map((p) => {
                  'id_campaign': p.idCampaign,
                  'nama_promo': p.namaPromo,
                  'jenis': p.jenis,
                  'tanggal_mulai': p.tanggalMulai,
                  'tanggal_akhir': p.tanggalAkhir,
                  'items': p.items
                      .map((i) => {
                            'id': i.id,
                            'jenis_pemicu': i.jenisPemicu,
                            'id_produk_pemicu': i.idProdukPemicu,
                            'nama_produk_pemicu': i.namaProdukPemicu,
                            'min_qty_pemicu': i.minQtyPemicu,
                            'min_amount_pemicu': i.minAmountPemicu,
                            'produk_hadiah': {
                              'id': i.produkHadiah.id,
                              'nama_produk': i.produkHadiah.namaProduk,
                            },
                            'qty_hadiah': i.qtyHadiah,
                            'harga_tebus': i.hargaTebus,
                          })
                      .toList(),
                })
            .toList(),
      };
}

/// Promo yang dipilih untuk satu produk tertentu.
/// Bisa berupa diskon (aturan_harga/grosir) atau hadiah by produk.
class ItemPromoApplied {
  final String idCampaign;
  final String namaPromo;
  final String jenis; // 'aturan_harga' | 'grosir' | 'hadiah'
  final String idProduk;
  final double diskonAmount;

  // Hanya diisi jika jenis == 'hadiah'
  final String? idProdukHadiah;
  final String? namaProdukHadiah;
  final int? qtyHadiah;
  final double? hargaTebus;

  const ItemPromoApplied({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    required this.idProduk,
    required this.diskonAmount,
    this.idProdukHadiah,
    this.namaProdukHadiah,
    this.qtyHadiah,
    this.hargaTebus,
  });

  bool get isHadiah => jenis == 'hadiah';

  /// Konversi ke payload `promos_applied` untuk API
  Map<String, dynamic> toPromoPayload() => {
        'id_campaign': idCampaign,
        'nama_promo': namaPromo,
        'jenis': jenis,
        'id_produk': idProduk,
        'diskon_amount': diskonAmount,
      };

  /// Konversi ke payload `hadiah_ditebus` untuk API (hanya jika isHadiah)
  Map<String, dynamic>? toHadiahPayload() {
    if (!isHadiah || idProdukHadiah == null) return null;
    return {
      'id_campaign': idCampaign,
      'nama_promo': namaPromo,
      'id_produk_hadiah': idProdukHadiah,
      'qty': qtyHadiah ?? 1,
      'harga_tebus': hargaTebus ?? 0,
    };
  }
}

/// Promo hadiah by nota — berlaku di level order, bukan per produk.
class HadiahNotaApplied {
  final String idCampaign;
  final String namaPromo;
  final String idProdukHadiah;
  final String? namaProdukHadiah;
  final int qty;
  final double hargaTebus;

  const HadiahNotaApplied({
    required this.idCampaign,
    required this.namaPromo,
    required this.idProdukHadiah,
    this.namaProdukHadiah,
    required this.qty,
    required this.hargaTebus,
  });

  Map<String, dynamic> toPromoPayload() => {
        'id_campaign': idCampaign,
        'nama_promo': namaPromo,
        'jenis': 'hadiah_nota',
        'id_produk': null,
        'diskon_amount': 0,
      };

  Map<String, dynamic> toHadiahPayload() => {
        'id_campaign': idCampaign,
        'nama_promo': namaPromo,
        'id_produk_hadiah': idProdukHadiah,
        'qty': qty,
        'harga_tebus': hargaTebus,
      };
}

// ─── Legacy aliases (backward compat untuk prepareEdit restore) ──────────────

/// Alias untuk restore promo lama saat edit pesanan
class SelectedPromo {
  final String idCampaign;
  final String namaPromo;
  final String jenis;
  final double diskonTotal;

  const SelectedPromo({
    required this.idCampaign,
    required this.namaPromo,
    required this.jenis,
    required this.diskonTotal,
  });
}

/// Legacy: hadiah ditebus (dipakai saat restore edit)
class HadiahDitebus {
  final String idCampaign;
  final String namaPromo;
  final String idProdukHadiah;
  final String? namaProdukHadiah;
  final int qty;
  final double hargaTebus;

  const HadiahDitebus({
    required this.idCampaign,
    required this.namaPromo,
    required this.idProdukHadiah,
    this.namaProdukHadiah,
    required this.qty,
    required this.hargaTebus,
  });
}
