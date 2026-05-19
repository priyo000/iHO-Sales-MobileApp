import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../providers/database_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService(ref.watch(appDatabaseProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Cache TTL Constants — beda resource, beda durasi
// ─────────────────────────────────────────────────────────────────────────────

class CacheTTL {
  // Semua data adalah PERMANEN — tidak pernah expire secara otomatis
  // User harus manual refresh / preload ulang jika ingin update dari server
  static const products = Duration(days: 99999);
  static const schedule = Duration(days: 99999);
  static const customers = Duration(days: 99999);
  static const promos = Duration(days: 99999);
  static const orders = Duration(days: 99999);
  static const dashboard = Duration(days: 99999);
  static const reports = Duration(days: 99999);
}

// ─────────────────────────────────────────────────────────────────────────────
// Cache Key Constants
// ─────────────────────────────────────────────────────────────────────────────

class CacheKeys {
  static String schedule(String date) => 'schedule_$date';
  static String customers({
    String status = 'all',
    int page = 1,
    String? search,
  }) {
    if (search != null && search.isNotEmpty) {
      return 'customers_${status}_p${page}_search_${search.toLowerCase()}';
    }
    return 'customers_${status}_p$page';
  }

  static String customer(int id) => 'customer_$id';
  static String products({String? search}) => 'products_${search ?? 'all'}';
  static String dashboard({double? lat, double? lng}) =>
      'dashboard_${lat?.toStringAsFixed(4)}_${lng?.toStringAsFixed(4)}';
  static String reports(String period, {String? start, String? end}) =>
      'reports_${period}_${start ?? ''}_${end ?? ''}';
  static String orderHistory({String? status, int page = 1}) =>
      'orders_${status ?? 'all'}_p$page';
}

// ─────────────────────────────────────────────────────────────────────────────
// OfflineCacheService — simpan & baca cache untuk semua fitur
// ─────────────────────────────────────────────────────────────────────────────

class OfflineCacheService {
  final AppDatabase _db;

  OfflineCacheService(this._db);

  // ── Generic Cache ─────────────────────────────────────────────────────────

  Future<void> save(String key, dynamic data) async {
    try {
      await _db.cacheData(key, data);
    } catch (e) {
      log('[Cache] Gagal menyimpan $key: $e');
    }
  }

  Future<T?> get<T>(String key) async {
    try {
      return await _db.getCached(key) as T?;
    } catch (e) {
      log('[Cache] Gagal membaca $key: $e');
      return null;
    }
  }

  /// Cek apakah cache sudah expired berdasarkan TTL
  Future<bool> isExpired(String key, Duration ttl) async {
    try {
      final cachedAt = await _db.getCacheTime(key);
      if (cachedAt == null) return true;
      return DateTime.now().difference(cachedAt) > ttl;
    } catch (e) {
      log('[Cache] Gagal cek TTL $key: $e');
      return true; // Jika error, anggap expired
    }
  }

  /// Ambil cache hanya jika belum expired, return null jika expired
  Future<T?> getWithTTL<T>(String key, Duration ttl) async {
    if (await isExpired(key, ttl)) return null;
    return get<T>(key);
  }

  Future<void> invalidate(String key) async {
    await _db.clearCache(key);
  }

  // ── Schedule Cache ────────────────────────────────────────────────────────

  /// Menyimpan data jadwal dengan strategi merge yang cerdas
  Future<void> saveSchedule(
    String date,
    List<dynamic> newData, {
    bool isServerSync = true,
  }) async {
    final oldData = await getSchedule(date);
    if (oldData == null || oldData.isEmpty) {
      await save(CacheKeys.schedule(date), newData);
      return;
    }

    final Map<String, Map<String, dynamic>> merged = {};

    // 1. Identifikasi data lama (local cache)
    for (final item in oldData) {
      // PERBAIKAN: Resolve local_ref jika sudah ada mapping-nya
      // Agar saat sync dari server, key-nya sama dengan server (p_ID_ASLI vs p_LOCAL_REF)
      final pId = item['id_pelanggan'] ?? item['pelanggan']?['id'];
      final resolvedPId = await getServerId(pId?.toString() ?? '') ?? pId;

      final kunId = item['id_kunjungan'];
      final resolvedKunId = await getServerId(kunId?.toString() ?? '') ?? kunId;

      final Map<String, dynamic> resolvedItem = {
        ...Map<String, dynamic>.from(item),
        if (resolvedPId != null) 'id_pelanggan': resolvedPId,
        if (resolvedKunId != null) 'id_kunjungan': resolvedKunId,
      };

      final key = _getScheduleItemKey(resolvedItem);
      merged[key] = resolvedItem;
    }

    // 2. Gabungkan dengan data baru
    for (final newItem in newData) {
      final key = _getScheduleItemKey(newItem);
      final oldItem = merged[key];

      if (oldItem != null && isServerSync) {
        // STRATEGI MERGE saat Sync dari Server:
        // Pertahankan status lokal HANYA jika benar-benar sedang kunjungan (belum checkout sama sekali)
        // Jika sudah ada waktu_check_out di lokal (offline checkout pending), JANGAN override — biarkan server
        // yang jadi truth setelah sync berhasil, atau pertahankan offline complete.
        final bool hasOfflineCheckout = oldItem['waktu_check_out'] != null;
        final bool isCurrentlyVisitingLokal =
            oldItem['status_kunjungan'] == 'DIKUNJUNGI' &&
            oldItem['waktu_check_in'] != null &&
            !hasOfflineCheckout; // sudah checkout offline → jangan pertahankan sebagai 'sedang kunjungan'

        final bool isOfflineComplete =
            oldItem['status_kunjungan'] == 'DIKUNJUNGI' &&
            oldItem['waktu_check_out'] != null &&
            oldItem['is_offline'] == true;

        merged[key] = {
          ...Map<String, dynamic>.from(newItem),
          // Pertahankan status lokal jika masih dalam proses offline
          if (isCurrentlyVisitingLokal || isOfflineComplete)
            'status_kunjungan': 'DIKUNJUNGI',
          if (isCurrentlyVisitingLokal)
            'waktu_check_in': oldItem['waktu_check_in'],
          if (isOfflineComplete) ...{
            'waktu_check_in': oldItem['waktu_check_in'],
            'waktu_check_out': oldItem['waktu_check_out'],
          },
          // Jaga perhitungan pesanan count (pilih yang lebih besar/lebih baru)
          'pesanan_count':
              (oldItem['pesanan_count'] ?? 0) > (newItem['pesanan_count'] ?? 0)
              ? oldItem['pesanan_count']
              : newItem['pesanan_count'],
        };
      } else {
        // Jika item baru (unplanned dari lokal) atau bukan sync server (langsung timpa)
        merged[key] = Map<String, dynamic>.from(newItem);
      }
    }

    await save(CacheKeys.schedule(date), merged.values.toList());
  }

  // Helper untuk mendapatkan key unik per item jadwal
  String _getScheduleItemKey(Map<String, dynamic> item) {
    final jId = item['id_jadwal'];
    final pId = item['id_pelanggan'] ?? item['pelanggan']?['id'];

    // Kombinasi id_jadwal dan id_pelanggan adalah KEY PALING UNIK untuk menghindari baris tertimpa
    // dalam satu jadwal/rute yang berisi banyak pelanggan
    if (jId != null && pId != null) return 'j_${jId}_p_${pId}';

    // Fallback untuk kunjungan tidak terencana (unplanned)
    // Prioritaskan Pelanggan ID agar tetap unik per toko pada hari tersebut
    if (pId != null) return 'p_$pId';

    // Fallback terakhir
    if (jId != null) return 'j_$jId';
    if (item['id_kunjungan'] != null) return 'k_${item['id_kunjungan']}';

    // Last resort: Hash dari data atau random
    return 'temp_${item.hashCode}';
  }

  Future<List<dynamic>?> getSchedule(String date) async {
    return await get<List<dynamic>>(CacheKeys.schedule(date));
  }

  /// Update status kunjungan di cache jadwal (untuk refleksi offline check-in/out)
  Future<void> updateScheduleItemStatus({
    required String date,
    dynamic pelangganId,
    required String newStatus,
    String? waktuCheckIn,
    String? waktuCheckOut,
    dynamic kunjunganLocalId,
    Map<String, dynamic>? pelangganData,
    Map<String, dynamic>? extraFields,
  }) async {
    final cached = await getSchedule(date) ?? [];

    // Normalize pelangganId untuk comparison - convert to string untuk flexible matching
    final pelangganIdStr = pelangganId?.toString();

    bool found = false;
    final updated = cached.map((item) {
      final p = item['pelanggan'];
      final String? itemIdPel = (item['id_pelanggan'] ?? p?['id'])?.toString();

      // Mapping harus ketat - use toString() for flexible comparison
      // Supports matching: int vs int, String vs String, String vs int
      final bool matchPelanggan =
          pelangganIdStr != null &&
          itemIdPel != null &&
          itemIdPel == pelangganIdStr;

      final bool matchKunjungan =
          kunjunganLocalId != null &&
          item['id_kunjungan'] != null &&
          item['id_kunjungan'].toString() == kunjunganLocalId.toString();

      if (matchPelanggan || matchKunjungan) {
        found = true;

        // Prevent ONLY duplicate check-in: skip if already CHECKED_IN (has check-in time)
        // BUT allow check-out update: if has check-in but NO check-out, allow adding check-out time
        final existingCheckIn = item['waktu_check_in'];

        // If trying to set check-in but already has check-in → skip duplicate
        if (waktuCheckIn != null && existingCheckIn != null) {
          return item; // Already checked in, skip duplicate
        }

        // Otherwise, allow the update (including check-out)
        return {
          ...Map<String, dynamic>.from(item),
          'status_kunjungan': newStatus,
          if (waktuCheckIn != null) 'waktu_check_in': waktuCheckIn,
          if (waktuCheckOut != null) 'waktu_check_out': waktuCheckOut,
          if (kunjunganLocalId != null) 'id_kunjungan': kunjunganLocalId,
          ...?extraFields,
        };
      }
      return item;
    }).toList();

    // Jika tidak ketemu dan ada data pelanggan, tambahkan sebagai kunjungan tidak terencana (unplanned)
    if (!found && pelangganData != null) {
      updated.add({
        'id': kunjunganLocalId,
        'id_jadwal': null,
        'id_pelanggan': pelangganId,
        'id_kunjungan': kunjunganLocalId,
        'status_kunjungan': newStatus,
        'waktu_check_in': waktuCheckIn,
        'waktu_check_out': waktuCheckOut,
        'pesanan_count': 0,
        'is_unplanned': true,
        'pelanggan': pelangganData,
        ...?extraFields,
      });
    }

    await saveSchedule(date, updated, isServerSync: false);
    log(
      '[Cache] Schedule $date diupdate: pelanggan $pelangganId / visit $kunjunganLocalId → $newStatus (found: $found)',
    );
  }

  /// Update pesanan_count di cache jadwal secara optimistik
  Future<void> updateSchedulePesananCount({
    required String date,
    required dynamic pelangganId,
    dynamic kunjunganId, // Jika null = order tanpa kunjungan → skip
    int? count, // Jika null, akan increment dari yang ada
    Map<String, dynamic>?
    pelangganData, // fallback: buat entry baru jika tidak ada
  }) async {
    // Skip jika tidak ada kunjungan (order tanpa kunjungan)
    if (kunjunganId == null) {
      log(
        '[Cache] Order tanpa kunjungan (no kunjunganId), pesanan_count tidak diupdate ke schedule.',
      );
      return;
    }

    var cached = await getSchedule(date);

    // Coba ambil data pelanggan dari cache jika tidak disediakan caller
    var pCache = pelangganData;
    if (pCache == null && pelangganId != null) {
      pCache = await getCustomer(
        pelangganId is int
            ? pelangganId
            : int.tryParse(pelangganId.toString()) ?? 0,
      );
    }

    // Jika cache jadwal kosong, buat entry minimal dengan pelanggan ini
    if (cached == null) {
      if (pCache == null) {
        log(
          '[Cache] ⚠️ Cache jadwal kosong untuk $date, pesanan_count tidak bisa di-update (tidak ada data pelanggan $pelangganId).',
        );
        return;
      }
      cached = [
        {
          'id': null,
          'id_jadwal': null,
          'id_pelanggan': pelangganId,
          'pelanggan': pCache,
          'status_kunjungan': 'DIKUNJUNGI',
          'pesanan_count': 0,
          'is_unplanned': true,
        },
      ];
    }

    bool found = false;
    final updated = cached.map((item) {
      final p = item['pelanggan'];
      // Robust comparison using toString()
      if (p != null && p['id'].toString() == pelangganId.toString()) {
        found = true;
        final currentCount = item['pesanan_count'] as int? ?? 0;
        return {
          ...Map<String, dynamic>.from(item),
          'pesanan_count': count ?? (currentCount + 1),
        };
      }
      return item;
    }).toList();

    // Jika pelanggan tidak ditemukan di cache jadwal, tambahkan entry baru
    if (!found && pCache != null) {
      log(
        '[Cache] ⚠️ Pelanggan $pelangganId tidak ditemukan di cache jadwal. Menambahkan entry baru.',
      );
      updated.add({
        'id': null,
        'id_jadwal': null,
        'id_pelanggan': pelangganId,
        'pelanggan': pCache,
        'status_kunjungan': 'DIKUNJUNGI',
        'pesanan_count': count ?? 1,
        'is_unplanned': true,
      });
    }

    await saveSchedule(date, updated, isServerSync: false);
  }

  // ── Customer Cache ────────────────────────────────────────────────────────

  Future<void> saveCustomers(
    dynamic data, {
    String status = 'all',
    int page = 1,
    String? search,
  }) async {
    await save(
      CacheKeys.customers(status: status, page: page, search: search),
      data,
    );
  }

  Future<dynamic> getCustomers({
    String status = 'all',
    int page = 1,
    String? search,
  }) async {
    return await get(
      CacheKeys.customers(status: status, page: page, search: search),
    );
  }

  Future<void> saveCustomer(int id, Map<String, dynamic> data) async {
    await save(CacheKeys.customer(id), data);
  }

  Future<Map<String, dynamic>?> getCustomer(int id) async {
    return await get<Map<String, dynamic>>(CacheKeys.customer(id));
  }

  /// Tambahkan pelanggan baru ke cache list (untuk offline create)
  Future<void> addPendingCustomerToCache(Map<String, dynamic> tempData) async {
    // SSOT Fix: Simpan ke cache key sesuai status prospectus
    // Sebelumnya selalu save ke 'all' → tidak ketemu di cache 'prospect'
    final status = (tempData['status'] as String?)?.toLowerCase() ?? 'all';

    var cached = await getCustomers(status: status);

    Map<String, dynamic> data;
    if (cached == null) {
      // If no cache exists yet, create minimal structure
      data = {
        'data': [tempData],
        'current_page': 1,
        'last_page': 1,
      };
    } else {
      data = Map<String, dynamic>.from(cached);
      final list = List<dynamic>.from(data['data'] ?? []);
      list.insert(0, tempData); // Tambah di awal
      data['data'] = list;
    }

    // Simpan ke cache status spesifik (prospect/active/pending) agar langsung ketemu
    await saveCustomers(data, status: status);

    // Juga simpan ke 'all' agar fallback chain di _getAndFilterCached() tetap bekerja
    var cachedAll = await getCustomers(status: 'all');
    if (cachedAll == null) {
      await saveCustomers(data, status: 'all');
    } else {
      final allData = Map<String, dynamic>.from(cachedAll);
      final allList = List<dynamic>.from(allData['data'] ?? []);
      allList.insert(0, tempData);
      allData['data'] = allList;
      await saveCustomers(allData, status: 'all');
    }
  }

  Future<DateTime?> getCustomersUpdateTime({String status = 'all'}) async {
    return await _db.getCacheTime(CacheKeys.customers(status: status, page: 1));
  }

  // ── Products Cache ────────────────────────────────────────────────────────

  Future<void> saveProducts(dynamic data, {String? search}) async {
    await save(CacheKeys.products(search: search), data);
  }

  Future<dynamic> getProducts({String? search}) async {
    return await get(CacheKeys.products(search: search));
  }

  Future<DateTime?> getProductsUpdateTime() async {
    return await _db.getCacheTime(CacheKeys.products(search: null));
  }

  // ── Dashboard Cache ───────────────────────────────────────────────────────

  Future<void> saveDashboard(
    Map<String, dynamic> data, {
    double? lat,
    double? lng,
  }) async {
    await save(CacheKeys.dashboard(lat: lat, lng: lng), data);
  }

  Future<Map<String, dynamic>?> getDashboard({double? lat, double? lng}) async {
    return await get<Map<String, dynamic>>(
      CacheKeys.dashboard(lat: lat, lng: lng),
    );
  }

  // ── Reports Cache ─────────────────────────────────────────────────────────

  Future<void> saveReports(
    Map<String, dynamic> data,
    String period, {
    String? start,
    String? end,
  }) async {
    await save(CacheKeys.reports(period, start: start, end: end), data);
  }

  Future<Map<String, dynamic>?> getReports(
    String period, {
    String? start,
    String? end,
  }) async {
    return await get<Map<String, dynamic>>(
      CacheKeys.reports(period, start: start, end: end),
    );
  }

  // ── Order History Cache ───────────────────────────────────────────────────

  Future<void> saveOrders(dynamic data, {String? status, int page = 1}) async {
    await save(CacheKeys.orderHistory(status: status, page: page), data);
  }

  Future<dynamic> getOrders({String? status, int page = 1}) async {
    return await get(CacheKeys.orderHistory(status: status, page: page));
  }

  // ── ID Mapping Helpers ──────────────────────────────────────────────────

  Future<void> saveRefMapping(String localRef, String serverId) async {
    await _db.saveRefMapping(localRef, serverId);
  }

  Future<String?> getServerId(String localRef) async {
    return await _db.getServerId(localRef);
  }
}
