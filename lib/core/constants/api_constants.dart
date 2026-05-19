enum Environment { development, production }

class ApiConstants {
  static const Environment _env = Environment.development;

  // Development: 10.0.2.2 = localhost dari Android Emulator
  // Untuk physical device, ganti ke IP WSL (cek: hostname -I di WSL terminal)
  static const String _devBaseUrl = 'http://10.0.2.2:3000/api/v1/mobile';
  static const String _prodBaseUrl = 'https://app.intigroup.top/api/v1/mobile';

  static const String _devStorageUrl = 'http://10.0.2.2:3000';
  static const String _prodStorageUrl = 'https://app.intigroup.top';

  static String get baseUrl =>
      _env == Environment.development ? _devBaseUrl : _prodBaseUrl;

  static String get storageUrl =>
      _env == Environment.development ? _devStorageUrl : _prodStorageUrl;

  // Auth
  static String get login => '$baseUrl/login';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get me => '$baseUrl/me';
  static String get changePassword => '$baseUrl/change-password';
  static String get saveFcmToken => '$baseUrl/save-fcm-token';

  // Sync
  static String get syncJadwal => '$baseUrl/sync/jadwal';
  static String get syncPelanggan => '$baseUrl/sync/pelanggan';
  static String get syncProduk => '$baseUrl/sync/produk';
  static String get syncPesanan => '$baseUrl/sync/pesanan';
  static String get syncNotifikasi => '$baseUrl/sync/notifikasi';

  // Operations
  static String get dashboard => '$baseUrl/dashboard';
  static String get kunjungan => '$baseUrl/kunjungan';
  static String get pesanan => '$baseUrl/pesanan';
  static String get promoAvailable => '$baseUrl/promo/available';

  // Legacy aliases (for backward compat during migration)
  static String get jadwal => syncJadwal;
  static String get produk => syncProduk;
  static String get pelanggan => syncPelanggan;
  static String get notifikasi => syncNotifikasi;
  static String get promoAvailableBulk => '$baseUrl/promo/available/bulk';

  static String? resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final origin = storageUrl;
    return path.startsWith('/') ? '$origin$path' : '$origin/$path';
  }
}
