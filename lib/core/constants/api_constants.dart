enum Environment { development, production }

class ApiConstants {
  /// Environment is selected at build time via `--dart-define`:
  ///   flutter run --dart-define=ENV=production
  ///   flutter build apk --dart-define=ENV=production
  /// Defaults to development so a bare `flutter run` never accidentally points
  /// a release build at the production API. An explicit base URL override is
  /// also supported via `--dart-define=API_BASE_URL=...`.
  static const Environment _env =
      String.fromEnvironment('ENV', defaultValue: 'development') == 'production'
          ? Environment.production
          : Environment.development;

  // Development: localhost via ADB reverse (real device) or 10.0.2.2 (emulator)
  static const String _devBaseUrl = 'http://127.0.0.1:3000/api/v1/mobile';
  static const String _prodBaseUrl = 'https://iho.intigroup.top/api/v1/mobile';

  static const String _devStorageUrl = 'http://127.0.0.1:3000';
  static const String _prodStorageUrl = 'https://iho.intigroup.top';

  /// Optional full base URL override (`--dart-define=API_BASE_URL=...`).
  /// When provided it takes precedence over the environment defaults.
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    return _env == Environment.production ? _prodBaseUrl : _devBaseUrl;
  }

  static String get storageUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      // Derive storage origin from the override (strip the /api/v1/mobile path).
      final uri = Uri.tryParse(_overrideBaseUrl);
      if (uri != null) return '${uri.scheme}://${uri.host}';
    }
    return _env == Environment.production ? _prodStorageUrl : _devStorageUrl;
  }

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

  // App update lives OUTSIDE the /mobile namespace (backend mounts it at
  // /api/v1/app-update), so build it from the storage origin, not baseUrl.
  static String get appUpdateCheck => '$storageUrl/api/v1/app-update/check';

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
