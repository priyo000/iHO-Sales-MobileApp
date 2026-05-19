import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/app_database.dart';
import '../providers/database_providers.dart' as db;
import '../services/connectivity_service.dart';
import '../services/offline_photo_service.dart';
import '../services/download_status_service.dart';
import '../../features/customer/data/customer_repository.dart';
import '../../features/orders/data/product_repository.dart';
import '../../features/orders/data/order_repository.dart';
import '../../features/schedule/data/schedule_repository.dart';
import '../../features/orders/data/promo_repository.dart';
import '../../features/notifications/data/notifications_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PreloadService — Background data preloader saat app pertama kali dibuka
//
// SSOT ARCHITECTURE (v2):
//   - Semua data di-cache secara PERMANEN di lokal Drift (tanpa TTL/expiry)
//   - PreloadService теперь ВЫЗЫВАЕТ repository.syncToDrift() methods
//   - Repository methods write directly to Drift tables
//   - Stream watchers auto-update when Drift tables change
//   - Semua berjalan di background, tidak blocking UI
// ─────────────────────────────────────────────────────────────────────────────

final preloadServiceProvider = Provider<PreloadService>((ref) {
  return PreloadService(
    ref.read(db.appDatabaseProvider),
    ref.read(connectivityServiceProvider),
    ref.read(offlinePhotoServiceProvider),
    ref.read(downloadStatusProvider.notifier),
    ref.read(customerRepositoryProvider),
    ref.read(productRepositoryProvider),
    ref.read(orderRepositoryProvider),
    ref.read(scheduleRepositoryProvider),
    ref.read(promoRepositoryProvider),
    ref.read(notificationsRepositoryProvider),
  );
});

// Key untuk menyimpan timestamp preload terakhir di local_cache
const _kLastPreloadKey = 'meta_last_preload';
const _kLastProductPreloadKey = 'meta_last_product_preload';
const _kLastCustomerPreloadKey = 'meta_last_customer_preload';
const _kLastPromoPreloadKey = 'meta_last_promo_preload';

// Auto-sync threshold: 24 jam — jika last sync > 24 jam, auto sync diam-diam saat app dibuka
const _kAutoSyncThresholdHours = 24;

class PreloadService {
  final AppDatabase _db; // Drift database for SSOT tables
  final ConnectivityService _connectivity;
  final OfflinePhotoService _photoStorage;
  final DownloadStatusNotifier _statusNotifier;
  final CustomerRepository _customerRepo;
  final ProductRepository _productRepo;
  final OrderRepository _orderRepo;
  final ScheduleRepository _scheduleRepo;
  final PromoRepository _promoRepo;
  final NotificationsRepository _notificationsRepo;

  bool _isSyncing = false;

  PreloadService(
    this._db,
    this._connectivity,
    this._photoStorage,
    this._statusNotifier,
    this._customerRepo,
    this._productRepo,
    this._orderRepo,
    this._scheduleRepo,
    this._promoRepo,
    this._notificationsRepo,
  );

  // ── Public entry point ──────────────────────────────────────────────────────

  /// Panggil sekali saat user sudah login dan app baru dibuka.
  /// Berjalan di background — tidak perlu await di UI.
  ///
  /// Strategi:
  /// 1. Cek apakah data sudah ada — jika BELUM ADA, preload dari server
  /// 2. Jika SUDAH ADA, cek last sync — jika > 24 jam, auto sync diam-diam
  /// 3. Jika ADA dan < 24 jam, skip (pakai data lokal yang ada)
  /// Indikator sync otomatis muncul di UI melalui DownloadStatusNotifier.
  Future<void> runIfStale() async {
    if (_isSyncing) {
      debugPrint('[Preload] Sync already in progress, skip.');
      return;
    }

    // Guard: don't sync if user hasn't logged in yet
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString('auth_token');
    if (hasToken == null || hasToken.isEmpty) {
      debugPrint('[Preload] No auth token, skip preload (user not logged in).');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('[Preload] 🚀 runIfStale() started');

      unawaited(_photoStorage.cleanupOrphanPhotos());

      final isOnline = await _connectivity.checkNow();
      debugPrint('[Preload] 📶 isOnline: $isOnline');
      if (!isOnline) {
        debugPrint('[Preload] ❌ Offline, skip preload.');
        return;
      }

      // Cek apakah data sudah ada
      debugPrint('[Preload] 🔍 Checking if data exists in Drift...');
      final hasSchedule = await _hasAnySchedule();
      final hasProducts = await _hasProducts();
      final hasCustomers = await _hasCustomers();

      debugPrint('[Preload] 📊 Data existence: schedule=$hasSchedule, products=$hasProducts, customers=$hasCustomers');

      // Jika belum ada data, preload semua
      if (!hasSchedule || !hasProducts || !hasCustomers) {
        debugPrint('[Preload] 📦 Data missing, starting preload...');
        
        // 1. Preload foundational data (parallel)
        await Future.wait([
          if (!hasSchedule) _preloadSchedule(),
          if (!hasProducts) _preloadProducts(),
          if (!hasCustomers) _preloadCustomers(),
        ]);

        // 2. Preload dependent data (after foundational data exists)
        await Future.wait([
          _preloadPromosIfNeeded(),
          _preloadOrders(), // Sync orders from API
          _preloadNotifications(), // Sync notifications from API
        ]);
        debugPrint('[Preload] ✅ Preload completed successfully');
        return;
      }

      // Data sudah ada — cek apakah perlu auto-sync foundational data (> 24 jam)
      final lastSync = await getLastPreloadTime();
      bool needsAutoSync = true;
      if (lastSync != null) {
        final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
        if (hoursSinceSync < _kAutoSyncThresholdHours) {
          debugPrint('[Preload] ⏭️ Foundational data exists and last sync was $hoursSinceSync hours ago (< $_kAutoSyncThresholdHours hours) — foundational sync skipped, but orders will still sync.');
          needsAutoSync = false;
        } else {
          debugPrint('[Preload] 🔄 Data exists but last sync was $hoursSinceSync hours ago (> $_kAutoSyncThresholdHours hours), auto syncing all...');
        }
      } else {
        debugPrint('[Preload] 🔄 Data exists but no timestamp found, auto syncing all...');
      }

      // 1. Auto-sync foundational data ONLY if needed (background)
      if (needsAutoSync) {
        await Future.wait([
          _preloadSchedule(),
          _preloadProducts(),
          _preloadCustomers(),
        ]);
      }

      // 2. Auto-sync orders — only when foundational data also syncs (> 24 hours)
      if (needsAutoSync) {
        debugPrint('[Preload] 🔄 Syncing orders from API...');
        await _preloadOrders();
      } else {
        debugPrint('[Preload] ⏭️ Orders sync skipped (< 24 hours since last sync)');
      }

      // 3. Sync dependent data (promos, notifications) — only when foundational syncs
      if (needsAutoSync) {
        await Future.wait([
          _preloadPromosIfNeeded(),
          _preloadNotifications(),
        ]);
      } else {
        debugPrint('[Preload] ⏭️ Promos & Notifications sync skipped (< 24 hours since last sync)');
      }
      debugPrint('[Preload] ✅ Auto sync completed');
    } catch (e, st) {
      debugPrint('[Preload] ❌ Preload/AutoSync failed: $e');
      debugPrint('[Preload] ❌ Stack trace: $st');
    } finally {
      _isSyncing = false;
    }
  }

  /// Force sync promo untuk pelanggan tertentu — dipanggil dari tombol refresh manual.
  Future<void> forceRefreshPromo(String idPelanggan) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final isOnline = await _connectivity.checkNow();
      if (!isOnline) {
        debugPrint('[Preload] Offline, skip force refresh promo.');
        return;
      }
      await _promoRepo.syncFromApi(idPelanggan.toString());
      debugPrint('[Preload] Force refresh promo untuk pelanggan $idPelanggan selesai.');
    } finally {
      _isSyncing = false;
    }
  }

  /// Force refresh SEMUA data — dipanggil dari tombol "Perbarui Data" di beranda.
  /// Selalu fetch ulang dari server dan timpa data lokal.
  Future<void> forceRefreshAll() async {
    if (_isSyncing) {
      debugPrint('[Preload] Sync already in progress, skip.');
      return;
    }
    _isSyncing = true;

    try {
      final isOnline = await _connectivity.checkNow();
      if (!isOnline) {
        debugPrint('[Preload] Offline, skip force refresh all.');
        return;
      }

      debugPrint('[Preload] Force refresh all — mulai preload (full refresh)...');

      // Jalankan semua preload secara paralel dengan forceRefresh=true
      // sehingga benar-benar fetch ulang dari server (bukan delta sync)
      await Future.wait([
        _preloadSchedule(forceRefresh: true),
        _preloadProducts(forceRefresh: true),
        _preloadCustomers(forceRefresh: true),
        _preloadPromosIfNeeded(forceRefresh: true),
        _preloadOrders(forceRefresh: true),
        _preloadNotifications(forceRefresh: true),
      ]);

      debugPrint('[Preload] Force refresh all selesai.');
    } finally {
      _isSyncing = false;
    }
  }

  /// Mengembalikan timestamp preload terakhir yang paling recent.
  /// Digunakan UI untuk menampilkan "Terakhir diperbarui: HH:MM".
  Future<DateTime?> getLastPreloadTime() async {
    final timestamps = await Future.wait([
      _db.getCacheTime(_kLastPreloadKey),
      _db.getCacheTime(_kLastProductPreloadKey),
      _db.getCacheTime(_kLastCustomerPreloadKey),
      _db.getCacheTime(_kLastPromoPreloadKey),
    ]);

    DateTime? latest;
    for (final dt in timestamps) {
      if (dt == null) continue;
      if (latest == null || dt.isAfter(latest)) {
        latest = dt;
      }
    }
    return latest;
  }

  // ── Existence checks (tanpa TTL) ─────────────────────────────────────────────

  /// Cek apakah ada minimal 1 data schedule di Drift (SSOT check)
  Future<bool> _hasAnySchedule() async {
    // Check Drift directly since that's where syncScheduleFromApi writes
    // Cek tanggal hari ini dan ±3 hari
    final today = DateTime.now();
    for (int i = -3; i <= 3; i++) {
      final date = today.add(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final schedule = await _db.getScheduleForDate(dateStr);
      if (schedule.isNotEmpty) return true;
    }
    return false;
  }

  /// Cek apakah ada data produk di Drift (SSOT check)
  Future<bool> _hasProducts() async {
    // Check Drift directly since that's where syncProductsFromApi writes
    final products = await _db.getAllProducts();
    return products.isNotEmpty;
  }

  /// Cek apakah ada data pelanggan di Drift (SSOT check)
  Future<bool> _hasCustomers() async {
    // Check Drift directly since that's where syncCustomersToDrift writes
    final customers = await _db.getAllLocalCustomers();
    return customers.isNotEmpty;
  }

  // ── Schedule Preload ─────────────────────────────────────────────────────────

  Future<void> _preloadSchedule({bool forceRefresh = false}) async {
    const taskId = 'preload_schedule';
    _statusNotifier.addTask(taskId, 'Memperbarui Jadwal Kunjungan');

    debugPrint('[Preload] Mulai preload jadwal ±3 hari ke Drift...');
    try {
      final today = DateTime.now();

      // Fetch ±3 hari secara paralel (7 tanggal)
      // Each call syncs to Drift via repository
      final dates = List.generate(7, (i) => today.add(Duration(days: i - 3)));
      await Future.wait(
        dates.map((date) async {
          final dateStr = date.toIso8601String().substring(0, 10);
          await _scheduleRepo.syncScheduleFromApi(
            dateParam: dateStr,
            forceRefresh: forceRefresh,
          );
        }).toList(),
      );

      debugPrint('[Preload] Selesai preload ${dates.length} hari jadwal ke Drift ✅');
      await _savePreloadTimestamp(_kLastPreloadKey);
      _statusNotifier.completeTask(taskId);
    } catch (e) {
      _statusNotifier.removeTask(taskId);
    }
  }

  // ── Product Preload ──────────────────────────────────────────────────────────

  Future<void> _preloadProducts({bool forceRefresh = false}) async {
    const taskId = 'preload_products';
    _statusNotifier.addTask(taskId, 'Memperbarui Katalog Produk');

    debugPrint('[Preload] Mulai preload katalog produk ke Drift...');
    try {
      // Call repository method that syncs to Drift
      await _productRepo.syncProductsFromApi(forceRefresh: forceRefresh);
      await _savePreloadTimestamp(_kLastProductPreloadKey);
      debugPrint('[Preload] Produk di-Drift ✅');
      _statusNotifier.completeTask(taskId);
    } catch (e) {
      debugPrint('[Preload] Gagal preload produk: $e');
      _statusNotifier.removeTask(taskId);
    }
  }

  // ── Customer Preload ─────────────────────────────────────────────────────────

  Future<void> _preloadCustomers({bool forceRefresh = false}) async {
    const taskId = 'preload_customers';
    _statusNotifier.addTask(taskId, 'Memperbarui Master Pelanggan');

    debugPrint('[Preload] Mulai preload semua pelanggan ke Drift...');
    try {
      // Call repository method that syncs to Drift
      // This writes directly to Drift customersTable, triggering stream updates
      await _customerRepo.syncCustomersToDrift(forceRefresh: forceRefresh);
      await _savePreloadTimestamp(_kLastCustomerPreloadKey);
      debugPrint('[Preload] Pelanggan di-Drift ✅');
      _statusNotifier.completeTask(taskId);
    } catch (e) {
      debugPrint('[Preload] Gagal preload pelanggan: $e');
      _statusNotifier.removeTask(taskId);
    }
  }

  // ── Promo Preload ─────────────────────────────────────────────────────────────

  /// Preload promo HANYA jika belum ada di cache.
  /// Uses BULK endpoint: 1 request for ALL pelanggan (instead of N requests).
  Future<void> _preloadPromosIfNeeded({bool forceRefresh = false}) async {
    // Ambil SEMUA pelanggan dari Drift (after syncCustomersToDrift ran)
    final allCustomers = await _db.getAllLocalCustomers();
    if (allCustomers.isEmpty) {
      debugPrint('[Preload] Tidak ada pelanggan di Drift, skip promo preload.');
      return;
    }

    // Extract pelanggan IDs (server IDs are Strings after UUID migration)
    final pelangganIds = allCustomers
        .where((c) => c.serverId != null)
        .map((c) => c.serverId!)
        .toList();

    if (pelangganIds.isEmpty) {
      debugPrint('[Preload] Tidak ada pelanggan dengan serverId, skip promo preload.');
      return;
    }

    // Batch-load all pelangganIds with promos in 1 query (avoids N+1).
    // On forceRefresh, skip the cache check and re-fetch promos for ALL pelanggan.
    final List<String> missingPromos;
    if (forceRefresh) {
      missingPromos = pelangganIds;
    } else {
      final pelangganIdsWithPromos = await _db.getPelangganIdsWithActivePromos();
      missingPromos = pelangganIds
          .where((id) => !pelangganIdsWithPromos.contains(id))
          .toList();
    }

    if (missingPromos.isEmpty) {
      debugPrint('[Preload] Semua promo sudah ada di cache, skip.');
      return;
    }

    debugPrint(
      '[Preload] Mulai preload promo untuk ${missingPromos.length} pelanggan (bulk)...',
    );
    const taskId = 'preload_promos';
    _statusNotifier.addTask(taskId, 'Memperbarui Data Promo');

    try {
      // OPTIMIZED: 1 bulk request instead of N individual requests
      final saved = await _promoRepo.syncBulkFromApi(missingPromos);
      await _savePreloadTimestamp(_kLastPromoPreloadKey);
      debugPrint('[Preload] Promo bulk sync: $saved promos untuk ${missingPromos.length} pelanggan ✅');
      _statusNotifier.completeTask(taskId);
    } catch (e) {
      debugPrint('[Preload] Gagal preload promo (bulk): $e');
      // Fallback: try individual sync if bulk fails (backward compat)
      debugPrint('[Preload] Fallback ke individual sync...');
      try {
        await Future.wait(
          missingPromos.map((id) => _promoRepo.syncFromApi(id)).toList(),
        );
        await _savePreloadTimestamp(_kLastPromoPreloadKey);
        debugPrint('[Preload] Promo fallback sync selesai ✅');
        _statusNotifier.completeTask(taskId);
      } catch (e2) {
        debugPrint('[Preload] Gagal preload promo (fallback): $e2');
        _statusNotifier.removeTask(taskId);
      }
    }
  }

  // ── Orders Preload ──────────────────────────────────────────────────────────

  Future<void> _preloadOrders({bool forceRefresh = false}) async {
    const taskId = 'preload_orders';
    _statusNotifier.addTask(taskId, 'Memperbarui Data Pesanan');

    debugPrint('[Preload] Mulai preload pesanan 30 hari terakhir dari API...');
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final since = thirtyDaysAgo.toIso8601String().split('T').first;
      // forceRefresh=true: skip `since` so server returns full dataset
      await _orderRepo.syncOrdersFromApi(since: forceRefresh ? null : since);
      debugPrint('[Preload] Pesanan 30 hari terakhir di-Drift ✅');
      _statusNotifier.completeTask(taskId);
    } catch (e) {
      debugPrint('[Preload] Gagal preload pesanan: $e');
      _statusNotifier.removeTask(taskId);
    }
  }

  // ── Notifications Preload ─────────────────────────────────────────────────────

  Future<void> _preloadNotifications({bool forceRefresh = false}) async {
    const taskId = 'preload_notifications';
    _statusNotifier.addTask(taskId, 'Memperbarui Notifikasi');

    debugPrint('[Preload] Mulai preload notifikasi dari API...');
    try {
      await _notificationsRepo.syncFromApi(forceRefresh: forceRefresh);
      debugPrint('[Preload] Notifikasi di-Drift ✅');
      _statusNotifier.completeTask(taskId);
    } catch (e) {
      debugPrint('[Preload] Gagal preload notifikasi: $e');
      _statusNotifier.removeTask(taskId);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _savePreloadTimestamp(String key) async {
    await _db.cacheData(key, DateTime.now().toIso8601String());
  }
}
