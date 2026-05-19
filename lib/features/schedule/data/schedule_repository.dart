import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/last_sync_service.dart';
import '../../../../core/services/mutation_queue_service.dart';
import '../../../../core/services/sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level utility functions (exported for test access)
// ─────────────────────────────────────────────────────────────────────────────

/// Parse String ID from dynamic value (handles int→String, null)
String? _parseScheduleId(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return null;
  return str;
}

/// Parse integer from dynamic value (for non-ID numeric fields like topHari, urutan)
int? _parseScheduleInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

/// Parse ISO 8601 string or epoch ms to epoch milliseconds.
/// Returns null if value cannot be parsed — caller should keep existing
/// timestamp instead of stamping `now`.
int? _parseIsoToEpochMs(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  final str = value.toString();
  if (str.isEmpty) return null;
  final parsedInt = int.tryParse(str);
  if (parsedInt != null) return parsedInt;
  return DateTime.tryParse(str)?.millisecondsSinceEpoch;
}

/// Resolve pending visit reference from queue item
/// Prefers client_ref so offline visit token matches backend flow
String resolvePendingVisitRef(Map<String, dynamic> queueItem) {
  final payload = queueItem['payload'];
  if (payload is Map) {
    final clientRef = payload['client_ref']?.toString();
    if (clientRef != null && clientRef.isNotEmpty) {
      return clientRef;
    }
  }
  return queueItem['local_ref']?.toString() ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final lastSync = ref.watch(lastSyncServiceProvider);
  final mutations = ref.watch(mutationQueueServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return ScheduleRepository(db, dio, connectivity, lastSync, mutations, sync);
});

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleRepository — Full SSOT with Reactive Streams
//
// Principles:
// 1. UI reads from LOCAL Drift tables (instant, offline-capable)
// 2. Sync downloads from API → saves to Drift tables
// 3. Streams auto-update UI when data changes
// 4. Search/filter uses SQL WHERE, not in-memory filter
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleRepository {
  final AppDatabase _db;
  final DioClient _dio;
  final ConnectivityService _connectivity;
  final LastSyncService _lastSync;
  final MutationQueueService _mutations;
  final SyncService _sync;

  ScheduleRepository(
    this._db,
    this._dio,
    this._connectivity,
    this._lastSync,
    this._mutations,
    this._sync,
  );

  // ── Public accessor for customer lookup (used by stream providers) ─────────

  /// Get customer by ID from Drift SSOT
  Future<CustomersTableData?> getCustomer(String id) => _db.getCustomer(id);

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE STREAMS — For Real-Time UI Updates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch schedule for a specific date - auto-updates when table changes
  Stream<List<ScheduleTableData>> watchScheduleForDate(String tanggal) {
    return _db.watchScheduleForDate(tanggal);
  }

  /// Watch today's schedule - convenience method
  Stream<List<ScheduleTableData>> watchTodaySchedule() {
    return _db.watchTodaySchedule();
  }

  /// Watch schedule by pelanggan (customer) ID
  Stream<List<ScheduleTableData>> watchScheduleByPelanggan(String pelangganId) {
    return _db.watchScheduleByPelanggan(pelangganId);
  }

  /// Watch schedule by status (scheduled, visited, skipped) for a specific date
  Stream<List<ScheduleTableData>> watchScheduleByStatus(
    String tanggal,
    String status,
  ) {
    return _db.watchScheduleByStatus(tanggal, status);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC — Download from API, Save to Local Drift Table
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync schedule from server to local Drift table
  /// After sync completes, all stream watchers auto-update
  ///
  /// Also upserts customer data from embedded 'pelanggan' object in each
  /// schedule item — ensures customer data is always fresh and available
  /// for JOIN operations.
  Future<void> syncScheduleFromApi({
    String? dateParam,
    bool forceRefresh = false,
  }) async {
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) {
      log('[Schedule SSOT] ❌ Offline, cannot sync schedule for $dateParam');
      return;
    }

    final today =
        dateParam ?? DateTime.now().toIso8601String().substring(0, 10);

    log('[Schedule SSOT] 🔄 Starting sync for $today (forceRefresh=$forceRefresh)');

    // Skip if not force refresh and data already exists
    if (!forceRefresh) {
      final existing = await _db.getScheduleForDate(today);
      if (existing.isNotEmpty) {
        log(
          '[Schedule SSOT] Schedule already cached for $today (${existing.length} items), skipping sync.',
        );
        return;
      }
    }

    try {
      final queryParams = <String, dynamic>{};
      if (dateParam != null) queryParams['date'] = dateParam;

      // Delta sync: only fetch changed since last sync
      final lastModified = await _lastSync.getLastModified(
        SyncResource.schedule,
      );
      if (lastModified != null) {
        queryParams['since'] = lastModified;
      }

      final response = await _dio.get(
        ApiConstants.jadwal,
        queryParameters: queryParams,
      );

      if (response == null) {
        log('[Schedule SSOT] ❌ Response is null for $today');
        return;
      }

      log('[Schedule SSOT] 📥 Response keys: ${(response as Map).keys.toList()}');

      final List<dynamic> dataList = response['data'] as List<dynamic>? ?? [];
      log('[Schedule SSOT] 📦 Found ${dataList.length} schedule items for $today');

      // SSOT guard: build set of visit IDs with pending check_out so server
      // delta tidak overwrite optimistic local CHECKED_OUT state.
      final pendingVisitIds = <String>{};
      final endpointRegex = RegExp(r'/kunjungan/([^/?]+)');
      for (final p in await _sync.getPendingByType('check_out')) {
        final payload = p['payload'];
        if (payload is Map) {
          final visitId = payload['id_kunjungan']?.toString();
          if (visitId != null) pendingVisitIds.add(visitId);
        }
        final endpoint = p['endpoint'] as String?;
        if (endpoint != null) {
          final m = endpointRegex.firstMatch(endpoint);
          if (m != null) pendingVisitIds.add(m.group(1)!);
        }
      }

      // Pre-fetch all existing schedule rows for today (single query)
      // to avoid N+1 reads inside the loop.
      final existingSchedules = await _db.getScheduleForDate(today);
      final existingScheduleById = {
        for (final s in existingSchedules) s.id: s,
      };

      // Save to Drift table - triggers stream update!
      if (dataList.isNotEmpty) {
        for (final item in dataList) {
          final Map<String, dynamic> scheduleData =
              Map<String, dynamic>.from(item as Map);

          // 1. Upsert customer from embedded 'pelanggan' object
          final pelanggan = scheduleData['pelanggan'] as Map<String, dynamic>?;
          if (pelanggan != null) {
            // Use _parseScheduleId for safe dynamic→String conversion
            final pelangganServerId = _parseScheduleId(pelanggan['id']);
            if (pelangganServerId != null) {
              // Note: buildPelangganData returns nama_pelanggan = nama_toko (store name)
              // The owner name (nama_pemilik) is NOT included in this endpoint's response.
              // Fall back to store name if owner name not available.
              final storeName = pelanggan['nama_pelanggan'] as String?;
              final ownerName = pelanggan['nama_pemilik'] as String? ?? storeName;
              await _db.saveCustomer(
                id: pelangganServerId,
                serverId: pelangganServerId,
                kodePelanggan: pelanggan['kode_pelanggan'] as String?,
                namaToko: storeName,
                namaPemilik: ownerName,
                alamatUsaha: pelanggan['alamat'] as String?,
                latitude: (pelanggan['latitude'] as num?)?.toDouble(),
                longitude: (pelanggan['longitude'] as num?)?.toDouble(),
                status: pelanggan['status'] as String?,
                noHpPribadi: pelanggan['telepon'] as String?,
                sistemPembayaran: pelanggan['sistem_pembayaran'] as String?,
                caraPembayaran: pelanggan['cara_pembayaran'] as String?,
                limitKreditAwal:
                    (pelanggan['limit_kredit_awal'] as num?)?.toDouble(),
                topHari: _parseScheduleInt(pelanggan['top_hari']),
                fotoTokoPath: pelanggan['foto_toko_url'] as String?,
                createdAt: _parseIsoToEpochMs(pelanggan['created_at']),
                updatedAt: _parseIsoToEpochMs(pelanggan['updated_at']),
              );
              log(
                '[Schedule SSOT] Upserted customer ${pelangganServerId} from embedded data',
              );
            } else {
              log(
                '[Schedule SSOT] ⚠️ Skipping pelanggan - no valid id: ${pelanggan['id']}',
              );
            }
          }

          final jadwalId = _parseScheduleId(scheduleData['id_jadwal']);
          final pelangganId = _parseScheduleId(scheduleData['id_pelanggan']);

          if (pelangganId == null) {
            log('[Schedule SSOT] ⚠️ Skipping item - no valid pelangganId: ${scheduleData['id_pelanggan']}');
            continue;
          }

          // Selalu gunakan ID komposit (jadwal + pelanggan) sebagai Primary Key Drift.
          // Hal ini mencegah duplikasi ketika data di-refresh dan backend mengembalikan
          // id_kunjungan yang berbeda dari null.
          final idJadwalVal = jadwalId ?? '0';
          // Use string concatenation for composite key
          final scheduleId = '${idJadwalVal}_$pelangganId';

          final karyawanId = _parseScheduleId(scheduleData['id_karyawan']) ?? '0';

          // Link visit server ID using client_ref if provided from backend
          final serverKunjunganId = _parseScheduleId(scheduleData['id_kunjungan']);
          final clientRef = scheduleData['client_ref'] as String?;
          if (serverKunjunganId != null && clientRef != null) {
            await _db.updateVisitServerId(clientRef, serverKunjunganId);
            log('[Schedule SSOT] 🔗 Linked visit $clientRef to server_id $serverKunjunganId');
          }

          // For visits that exist on server (id_kunjungan present), ensure they exist in local VisitsTable.
          // This handles: app data cleared but visit still active on server (unplanned or planned).
          if (serverKunjunganId != null && pelangganId != null) {
            if (pendingVisitIds.contains(serverKunjunganId) ||
                (clientRef != null && pendingVisitIds.contains(clientRef))) {
              log('[Schedule SSOT] ⏭️ Skip visit $serverKunjunganId — pending check_out');
            } else {
              await _db.saveVisit(
                id: serverKunjunganId,
                scheduleId: jadwalId,
                pelangganId: pelangganId,
                status: scheduleData['waktu_check_out'] != null ? 'CHECKED_OUT' : 'CHECKED_IN',
                waktuCheckIn: scheduleData['waktu_check_in'] as String?,
                waktuCheckOut: scheduleData['waktu_check_out'] as String?,
                serverId: serverKunjunganId,
              );
              log('[Schedule SSOT] 💾 Saved visit $serverKunjunganId to VisitsTable');
            }
          }

          // SSOT guard: kalau visit ini punya pending check_out di queue,
          // preserve local Drift state (status SELESAI + waktuCheckOut) supaya
          // server delta tidak revert optimistic checkout → timer tidak hidup lagi.
          final hasPendingCheckOut = (serverKunjunganId != null &&
                  pendingVisitIds.contains(serverKunjunganId)) ||
              (clientRef != null && pendingVisitIds.contains(clientRef));

          String scheduleStatus =
              scheduleData['status_kunjungan'] as String? ?? 'scheduled';
          String? waktuCheckIn = scheduleData['waktu_check_in'] as String?;
          String? waktuCheckOut = scheduleData['waktu_check_out'] as String?;

          if (hasPendingCheckOut) {
            final existing = existingScheduleById[scheduleId];
            if (existing != null) {
              scheduleStatus = existing.status;
              waktuCheckIn = existing.waktuCheckIn ?? waktuCheckIn;
              waktuCheckOut = existing.waktuCheckOut ?? waktuCheckOut;
              log(
                '[Schedule SSOT] ⏭️ Preserve schedule $scheduleId state — pending check_out',
              );
            }
          }

          await _db.saveScheduleItem(
            id: scheduleId,
            jadwalId: jadwalId,
            karyawanId: karyawanId,
            tanggal: today,
            divisiId: _parseScheduleId(scheduleData['id_divisi']),
            pelangganId: pelangganId,
            urutan: _parseScheduleInt(scheduleData['urutan']) ?? 0,
            status: scheduleStatus,
            waktuCheckIn: waktuCheckIn,
            waktuCheckOut: waktuCheckOut,
          );
          log('[Schedule SSOT] ✅ Saved schedule id=$scheduleId for pelanggan=$pelangganId');
        }
      }

      log(
        '[Schedule SSOT] ✅ Synced ${dataList.length} schedule items to Drift table',
      );

      // Mark delta sync timestamp so next sync only fetches changes
      await _lastSync.setLastSync(
        SyncResource.schedule,
        lastModified: DateTime.now(),
      );
    } on DioException catch (e) {
      log('[Schedule SSOT] ❌ Sync failed: $e');
    } catch (e) {
      log('[Schedule SSOT] ❌ Sync error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTATIONS — Offline-First Writes via MutationQueueService
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check-in — 100% offline-first via MutationQueueService
  Future<Map<String, dynamic>> checkIn({
    required String? jadwalId,
    required String pelangganId,
    required double lat,
    required double lng,
    double? jarakValidasi,
  }) async {
    return _mutations.mutateCheckIn(
      jadwalId: jadwalId,
      pelangganId: pelangganId,
      lat: lat,
      long: lng,
      jarakValidasi: jarakValidasi,
      pelangganDataMap: null,
    );
  }

  /// Update schedule status (visited, skipped, etc.)
  Future<void> updateStatus({
    required String id,
    required String status,
    String? waktuCheckIn,
    String? waktuCheckOut,
  }) async {
    await _db.updateScheduleStatus(
      id,
      status,
      waktuCheckIn: waktuCheckIn,
      waktuCheckOut: waktuCheckOut,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY COMPATIBILITY — For code not yet migrated to streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get schedule for date (legacy method, prefer streams)
  Future<List<ScheduleTableData>> getScheduleForDate(String tanggal) async {
    return await _db.getScheduleForDate(tanggal);
  }

  /// Get today's schedule - alias for getScheduleForDate with auto date
  Future<List<ScheduleTableData>> getTodaySchedule({String? date}) async {
    final today = date ?? DateTime.now().toIso8601String().substring(0, 10);
    return await _db.getScheduleForDate(today);
  }

  /// Sync schedule from API - alias for syncScheduleFromApi
  Future<void> syncTodayScheduleFromApi({
    String? dateParam,
    bool forceRefresh = false,
  }) async {
    await syncScheduleFromApi(dateParam: dateParam, forceRefresh: forceRefresh);
  }

  /// Get cached schedule for date (for SWR in controllers)
  Future<List<ScheduleTableData>?> getCachedSchedule(String date) async {
    final result = await _db.getScheduleForDate(date);
    return result.isNotEmpty ? result : null;
  }
}
