import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider — stream status koneksi (true = online, false = offline)
// ─────────────────────────────────────────────────────────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider yang bisa di-watch dari UI untuk tahu status network saat ini
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
});

// ─────────────────────────────────────────────────────────────────────────────
// ConnectivityService
//
// Cek dua lapis:
//   1. Network layer (WiFi / Mobile / Ethernet) via connectivity_plus
//   2. Server reachability (ping endpoint /api/ping atau server host) via DNS lookup
//
// Mengapa dua lapis?
//   - connectivity_plus hanya cek ada-tidaknya koneksi jaringan ke router.
//   - Server bisa mati walau jaringan bagus (tether WiFi, captive portal, dll).
//   - Tanpa cek layer-2, repository mengira online tapi HTTP call timeout.
// ─────────────────────────────────────────────────────────────────────────────

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;
  bool _isOnline = true;

  // Host yang dipakai untuk reachability check (ambil hostname dari baseUrl)
  static final String _reachabilityHost = Uri.parse(ApiConstants.baseUrl).host;

  ConnectivityService() {
    _init();
  }

  bool get isOnline => _isOnline;

  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> _init() async {
    // Cek status awal: emit network layer dulu (instant), verifikasi di background
    // Ini mencegah spinner loading muter terus saat DNS lookup lambat
    final results = await _connectivity.checkConnectivity();
    final hasNetwork = _hasConnection(results);

    if (!hasNetwork) {
      _isOnline = false;
      _controller.add(false);
      return;
    }

    // Ada network: anggap online dulu, user bisa langsung interaksi
    _isOnline = true;
    _controller.add(true);
    log('[Connectivity] Network tersedia → status ONLINE (initial)');

    // Verifikasi reachability di background (tidak blocking)
    _verifyReachability().then((reachable) {
      if (!reachable && _isOnline) {
        log(
          '[Connectivity] Server tidak reachable, tapi network tersedia — tetap ONLINE untuk sync attempt',
        );
      }
    });

    // Listen perubahan network layer
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasNetwork = _hasConnection(results);

      if (!hasNetwork) {
        // Langsung tandai offline — tidak perlu ping
        if (_isOnline) {
          _isOnline = false;
          _controller.add(false);
        }
        return;
      }

      // Ada network: anggap online dulu, verifikasi reachability di background
      // Ini penting agar sync bisa jalan bahkan jika DNS lookup lambat/gagal
      if (!_isOnline) {
        _isOnline = true;
        _controller.add(true);
        log('[Connectivity] Network tersedia → status ONLINE');
      }

      // Verifikasi reachability di background (tidak blocking)
      _verifyReachability().then((reachable) {
        if (!reachable && _isOnline) {
          // Server benar-benar tidak reachable → tetap online untuk sync attempt
          // Sync akan fail gracefully jika server down
          log(
            '[Connectivity] Server tidak reachable, tapi network tersedia — tetap ONLINE untuk sync attempt',
          );
        }
      });
    });

    // Periodic reachability check — runs both when online and offline
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      final results = await _connectivity.checkConnectivity();
      if (!_hasConnection(results)) {
        if (_isOnline) {
          _isOnline = false;
          _controller.add(false);
        }
        return;
      }
      final reachable = await _verifyReachability();
      if (reachable && !_isOnline) {
        _isOnline = true;
        _controller.add(true);
        log('[Connectivity] Periodic check: kembali ONLINE');
      } else if (!reachable && _isOnline) {
        _isOnline = false;
        _controller.add(false);
        log('[Connectivity] Periodic check: server unreachable → OFFLINE');
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        results.any(
          (r) =>
              r == ConnectivityResult.mobile ||
              r == ConnectivityResult.wifi ||
              r == ConnectivityResult.ethernet,
        );
  }

  /// Verifikasi server benar-benar bisa dijangkau via DNS lookup.
  /// Lebih ringan dari HTTP ping — cukup untuk deteksi server down.
  Future<bool> _verifyReachability() async {
    try {
      final addresses = await InternetAddress.lookup(
        _reachabilityHost,
      ).timeout(const Duration(seconds: 5));
      return addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
    } on SocketException {
      log('[Connectivity] DNS lookup gagal — server tidak bisa dijangkau.');
      return false;
    } on TimeoutException {
      log('[Connectivity] DNS lookup timeout — server tidak bisa dijangkau.');
      return false;
    } catch (e) {
      log('[Connectivity] Reachability check error: $e');
      return false;
    }
  }

  /// Cek koneksi aktual sebelum melakukan operasi.
  /// Melakukan dua-lapis cek: network + server reachability.
  Future<bool> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!_hasConnection(results)) {
        _isOnline = false;
        return false;
      }
      _isOnline = await _verifyReachability();
      return _isOnline;
    } catch (_) {
      _isOnline = false;
      return false;
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _subscription?.cancel();
    _controller.close();
  }
}
