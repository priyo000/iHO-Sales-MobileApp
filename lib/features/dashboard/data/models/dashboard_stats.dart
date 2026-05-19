class RuteHariIni {
  final String id;
  final String name;
  final int totalTitik;
  final int dikunjungi;
  final int sisa;

  const RuteHariIni({
    required this.id,
    required this.name,
    required this.totalTitik,
    required this.dikunjungi,
    required this.sisa,
  });

  factory RuteHariIni.fromMap(Map<String, dynamic> map) {
    return RuteHariIni(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Rute Hari Ini') as String,
      totalTitik: (map['total_titik'] ?? 0) as int,
      dikunjungi: (map['dikunjungi'] ?? 0) as int,
      sisa: (map['sisa'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'total_titik': totalTitik,
        'dikunjungi': dikunjungi,
        'sisa': sisa,
      };
}

class DashboardStats {
  final int kunjunganSelesai;
  final int targetKunjungan;
  final int luarRute;
  final int totalOrderHariIni;
  final int pelangganBaruHariIni;
  final int prospekHariIni;
  final int effectiveCalls;
  final double totalSalesToday;
  final int pendingSyncCount;
  final RuteHariIni? ruteHariIni;

  const DashboardStats({
    this.kunjunganSelesai = 0,
    this.targetKunjungan = 0,
    this.luarRute = 0,
    this.totalOrderHariIni = 0,
    this.pelangganBaruHariIni = 0,
    this.prospekHariIni = 0,
    this.effectiveCalls = 0,
    this.totalSalesToday = 0,
    this.pendingSyncCount = 0,
    this.ruteHariIni,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      kunjunganSelesai: (map['kunjungan_selesai'] ?? 0) as int,
      targetKunjungan: (map['target_kunjungan'] ?? 0) as int,
      luarRute: (map['luar_rute'] ?? 0) as int,
      totalOrderHariIni: (map['total_order_hari_ini'] ?? 0) as int,
      pelangganBaruHariIni: (map['pelanggan_baru_hari_ini'] ?? 0) as int,
      prospekHariIni: (map['prospek_hari_ini'] ?? 0) as int,
      effectiveCalls: (map['effective_calls'] ?? 0) as int,
      totalSalesToday: ((map['total_sales_today'] ?? 0) as num).toDouble(),
      pendingSyncCount: (map['pending_sync_count'] ?? 0) as int,
      ruteHariIni: map['rute_hari_ini'] != null
          ? RuteHariIni.fromMap(Map<String, dynamic>.from(map['rute_hari_ini'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'kunjungan_selesai': kunjunganSelesai,
        'target_kunjungan': targetKunjungan,
        'luar_rute': luarRute,
        'total_order_hari_ini': totalOrderHariIni,
        'pelanggan_baru_hari_ini': pelangganBaruHariIni,
        'prospek_hari_ini': prospekHariIni,
        'effective_calls': effectiveCalls,
        'total_sales_today': totalSalesToday,
        'pending_sync_count': pendingSyncCount,
        'rute_hari_ini': ruteHariIni?.toMap(),
      };
}
