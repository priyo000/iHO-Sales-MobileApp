import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../providers/database_providers.dart';
import 'connectivity_service.dart';
import 'offline_photo_service.dart';
import '../network/dio_client.dart' show DioAuthException, OfflineException, ServerException;
import 'sync/sync_exceptions.dart';

export 'sync/sync_exceptions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final photoStorage = ref.watch(offlinePhotoServiceProvider);
  final service = SyncService(localDb, connectivity, photoStorage, ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Jumlah item yang belum tersinkronisasi (untuk badge di UI).
/// Reactive Drift watch — auto-emit setiap perubahan syncQueueTable,
/// tidak perlu broadcast manual yang bisa miss event saat UI belum subscribe.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingCount();
});

final failedSyncItemsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return db.watchFailedItems().map(
    (rows) => rows.map((r) => syncService.syncQueueItemToMap(r)).toList(),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// SyncService — orkestrasi sync queue ke server saat online
// ─────────────────────────────────────────────────────────────────────────────

class SyncService {
  Map<String, dynamic> _sanitizeOrderPayloadForLog(
    Map<String, dynamic> payload,
  ) {
    final safe = <String, dynamic>{};
    const keepKeys = {
      'id_kunjungan',
      'id_pelanggan',
      'client_ref',
      'catatan',
      'items',
      'promos_applied',
      'hadiah_ditebus',
    };

    for (final entry in payload.entries) {
      if (keepKeys.contains(entry.key)) {
        safe[entry.key] = entry.value;
      }
    }

    final items = (safe['items'] as List?) ?? const [];
    safe['items_count'] = items.length;
    safe['promos_count'] =
        ((safe['promos_applied'] as List?) ?? const []).length;
    safe['hadiah_count'] =
        ((safe['hadiah_ditebus'] as List?) ?? const []).length;

    return safe;
  }

  void _logCreateOrderDiagnostics({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required int statusCode,
    required String errorMessage,
  }) {
    final safePayload = _sanitizeOrderPayloadForLog(payload);
    log(
      '[SyncService][OrderPromo][FAIL] '
      'method=$method endpoint=$endpoint status=$statusCode '
      'message=$errorMessage payload=${jsonEncode(safePayload)}',
    );
    debugPrint(
      '[SyncService][OrderPromo][FAIL] method=$method endpoint=$endpoint status=$statusCode message=$errorMessage payload=${jsonEncode(safePayload)}',
    );
  }

  static const int _maxRetry = 5;

  /// Defer counter is tracked separately from retry budget. A child item
  /// (e.g. create_order waiting on check_in) can defer many times during a
  /// flaky network without exhausting its retry budget; only real failures
  /// count against retry.
  static const int _maxDefer = 50;
  final Map<String, int> _deferCount = {};

  /// Base sync interval when queue is empty (30s → 60s → 120s → max 5min).
  /// Grows exponentially after each empty sync cycle.
  static const Duration _baseSyncInterval = Duration(seconds: 30);
  static const Duration _maxSyncInterval = Duration(minutes: 5);

  Duration _calculateBackoffDelay(int retryCount) {
    if (retryCount <= 0) return const Duration(seconds: 1);
    final delay = Duration(seconds: (1 << (retryCount - 1)).clamp(1, 60));
    return delay.inSeconds > 60 ? const Duration(seconds: 60) : delay;
  }

  /// Calculate next sync interval based on last sync result.
  /// Empty queue → double interval (up to max). Has items → reset to base.
  Duration _calculateNextSyncInterval({required bool hasItemsInQueue}) {
    if (hasItemsInQueue) {
      _emptyCycleCount = 0;
      return _baseSyncInterval;
    }
    _emptyCycleCount++;
    final factor = (1 << _emptyCycleCount).clamp(1, 10); // max 10x
    final interval = Duration(
      seconds: (_baseSyncInterval.inSeconds * factor).clamp(
        _baseSyncInterval.inSeconds,
        _maxSyncInterval.inSeconds,
      ),
    );
    log(
      '[SyncService] ⏰ Next sync in ${interval.inSeconds}s (empty cycles: $_emptyCycleCount)',
    );
    return interval;
  }

  final AppDatabase _localDb;
  final ConnectivityService _connectivity;
  final OfflinePhotoService _photoStorage;
  final Ref _ref;

  StreamSubscription<bool>? _connectivitySub;
  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  // Exponential backoff state for idle sync intervals
  int _emptyCycleCount = 0;
  Timer? _idleSyncTimer;

  SyncService(
    this._localDb,
    this._connectivity,
    this._photoStorage,
    this._ref,
  ) {
    _init();
  }

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  Future<int> getPendingCountSnapshot() async {
    return _localDb.syncDao.getPendingCount();
  }

  /// Ambil item yang sudah gagal melebihi batas retry (untuk ditampilkan ke user)
  Future<List<Map<String, dynamic>>> getFailedItems() async {
    final allItems = await _localDb.syncDao.getAllQueueItems();
    final failedItems = allItems.where(
      (item) => item.status == 'failed' || item.status == 'failed_permanently',
    );
    return failedItems.map((r) => _syncQueueItemToMap(r)).toList();
  }

  /// Hapus item yang sudah gagal permanen (dipakai dari UI)
  Future<void> discardFailed(String localRef) async {
    await _localDb.syncDao.removeFromQueue(localRef);
    await _broadcastPendingCount();
    log('[SyncService] 🗑️ Item gagal dihapus manual: $localRef');
  }

  /// Ambil item pending berdasarkan tipe (untuk delta-sync guard di repository).
  /// Includes 'syncing' status by default — in-flight mutations harus dilindungi
  /// dari overwrite oleh delta sync yang berjalan paralel.
  Future<List<Map<String, dynamic>>> getPendingByType(String operation) async {
    final rows = await _localDb.getPendingByOperation(operation);
    return rows.map(_syncQueueItemToMap).toList();
  }

  /// Ambil item pending berdasarkan local_ref
  Future<Map<String, dynamic>?> getPendingItem(String localRef) async {
    final allItems = await _localDb.syncDao.getAllQueueItems();
    final item = allItems
        .where(
          (i) =>
              i.localRef == localRef &&
              (i.status == 'pending' ||
                  i.status == 'failed' ||
                  i.status == 'failed_permanently'),
        )
        .firstOrNull;
    if (item == null) return null;
    return _syncQueueItemToMap(item);
  }

  Map<String, dynamic> syncQueueItemToMap(SyncQueueTableData item) =>
      _syncQueueItemToMap(item);

  /// Convert SyncQueueTableData to `Map<String, dynamic>`
  Map<String, dynamic> _syncQueueItemToMap(SyncQueueTableData item) {
    return {
      'id': item.id,
      'local_ref': item.localRef,
      'operation': item.operation,
      'endpoint': item.endpoint,
      'method': item.method,
      'payload': jsonDecode(item.payload),
      'created_at': item.createdAt,
      'retry_count': item.retryCount,
      'status': item.status,
      'error_message': item.errorMessage,
      'last_server_id': item.lastServerId,
      'server_synced_at': item.serverSyncedAt,
    };
  }

  Future<void> updatePendingPayload(
    String localRef,
    Map<String, dynamic> payload,
  ) async {
    await _localDb.syncDao.updatePayload(localRef, payload);
  }

  Future<void> removePendingItem(String localRef) async {
    await _localDb.syncDao.removeFromQueue(localRef);
    _deferCount.remove(localRef);
    await _broadcastPendingCount();
  }

  /// Reset retry count agar item gagal bisa dicoba lagi
  Future<void> retryFailed(String localRef) async {
    await _localDb.syncDao.resetForRetry(localRef);
    log('[SyncService] 🔄 Retry manual: $localRef');
    syncAll();
  }

  /// Update isi payload (misal ganti kode pelanggan) lalu retry item yang gagal
  Future<void> updatePayloadAndRetry(
    String localRef,
    Map<String, dynamic> newPayload,
  ) async {
    await _localDb.syncDao.updatePayload(localRef, newPayload);

    // Setelah diupdate, reset error state dan jadikan pending
    await _localDb.rawUpdate(
      'UPDATE ${AppDatabase.tableSyncQueue} SET retry_count = 0, status = ?, error_message = NULL WHERE local_ref = ?',
      whereArgs: ['pending', localRef],
    );

    // Aktifkan juga child/dependency-nya jika ada yang ke-cancel
    // karena sebelumnya parent gagal permanen.
    await _restoreDependentItems(localRef);

    log('[SyncService] 📝 Payload diupdate & diretry: $localRef');
    syncAll();
  }

  /// Aktifkan lagi child items yang tadinya 'cancelled_dependency'
  Future<void> _restoreDependentItems(String parentRef) async {
    final items = await _localDb.syncDao.getAllQueueItems();

    for (final item in items) {
      if (item.status != 'cancelled_dependency') continue;

      final currentRef = item.localRef;
      final endpoint = item.endpoint;
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      bool isDependent = false;

      if (endpoint.contains(parentRef)) isDependent = true;
      for (final value in payload.values) {
        if (value.toString() == parentRef) isDependent = true;
      }

      if (isDependent) {
        await _localDb.rawUpdate(
          'UPDATE ${AppDatabase.tableSyncQueue} SET status = ?, error_message = NULL, retry_count = 0 WHERE local_ref = ?',
          whereArgs: ['pending', currentRef],
        );
        log(
          '[SyncService] ♻️ Memulihkan dependency $currentRef karena parent direvisi.',
        );
        await _restoreDependentItems(currentRef);
      }
    }
  }

  void _init() {
    _localDb.syncDao.resetStuckSyncing().then((_) {
      log('[SyncService] Stuck syncing items reset to pending.');
    });
    _localDb.syncDao.clearStaleSyncLock(ttlMinutes: 5).then((_) {
      log('[SyncService] Stale sync locks cleared.');
    });

    _connectivitySub = _connectivity.onStatusChange.listen((isOnline) async {
      if (isOnline) {
        final hasToken = await _ref.read(tokenStorageProvider).hasToken();
        if (!hasToken) {
          log('[SyncService] Online but no token, skip sync.');
          return;
        }
        log('[SyncService] Network kembali online. Memulai sync...');
        syncAll();
      }
    });
  }

  // ── Core Sync Function ────────────────────────────────────────────────────

  /// Proses semua item pending di queue, kirim ke server secara berurutan
  Future<void> syncAll() async {
    return await _syncAllInternal();
  }

  Future<void> _syncAllInternal() async {
    final got = await _localDb.syncDao.acquireSyncLock('syncAll', ttlMinutes: 5);
    if (!got) {
      log('[SyncService] Sync sudah berjalan, skip.');
      return;
    }

    try {
      final hasToken = await _ref.read(tokenStorageProvider).hasToken();
      if (!hasToken) {
        log('[SyncService] No auth token, skip sync.');
        return;
      }

      final isOnline = await _connectivity.checkNow();
      log('[SyncService] 🌐 isOnline=$isOnline');
      if (!isOnline) return;

      log('[SyncService] Memulai siklus sinkronisasi...');

      while (true) {
        // Ambil antrean terbaru setiap iterasi untuk menghindari data "basi" (stale)
        // terutama setelah item sebelumnya di-patch IDs-nya.
        final queue = await _localDb.syncDao.getAllQueueItems();

        // DEBUG: Log semua queue item yang tersedia
        log('[SyncService] 📋 Queue snapshot: ${queue.length} items');
        for (final i in queue) {
          log(
            '  └─ ${i.localRef} | ${i.operation} | status=${i.status} | retry=${i.retryCount} | endpoint=${i.endpoint}',
          );
        }

        // Cari item pertama yang bisa diproses
        final item = queue.where((i) {
          final status = i.status;
          final retry = i.retryCount;
          return status != 'failed_permanently' &&
              status != 'cancelled_dependency' &&
              status != 'syncing' &&
              retry < _maxRetry;
        }).firstOrNull;

        if (item == null) {
          log(
            '[SyncService] Sinkronisasi selesai: Tidak ada item yang bisa diproses.',
          );
          break;
        }

        final localRef = item.localRef;
        final op = item.operation;
        final status = item.status;
        final retryCount = item.retryCount;
        log(
          '[SyncService] ▶️ Dipilih: $localRef | op=$op | status=$status | retry=$retryCount',
        );

        // DEBUG: Log kenapa item lain TIDAK dipilih
        for (final i in queue) {
          if (i.localRef == localRef) continue;
          final itemRetry = i.retryCount;
          final itemStatus = i.status;
          String skipReason;
          if (itemRetry >= _maxRetry) {
            skipReason = 'retry_max';
          } else if (itemStatus == 'failed_permanently') {
            skipReason = 'failed_perm';
          } else if (itemStatus == 'cancelled_dependency') {
            skipReason = 'cancelled';
          } else if (itemStatus == 'syncing') {
            skipReason = 'syncing';
          } else {
            skipReason = 'OK';
          }
          log(
            '  └─ ⏭️ Skip: ${i.localRef} | ${i.operation} | reason=$skipReason',
          );
        }

        await _localDb.syncDao.updateQueueStatus(localRef, 'syncing');

        try {
          // Convert SyncQueueTableData to Map for _processItem
          final itemMap = _syncQueueItemToMap(item);
          final dynamic response = await _processItem(itemMap);
          // Mark as synced by server BEFORE removing from queue
          // This prevents duplicate sync if app is killed/restarted
          await _localDb.markServerSynced(localRef);
          await _localDb.syncDao.removeFromQueue(localRef);
          _deferCount.remove(localRef);
          log('[SyncService] ✅ $localRef berhasil disinkronkan.');

          await _finalizeSyncSuccess(item, response);
        } on SyncDeferredException catch (e) {
          final defers = (_deferCount[localRef] ?? 0) + 1;
          _deferCount[localRef] = defers;
          if (defers >= _maxDefer) {
            log('[SyncService] ❌ $localRef deferred too many times, marking failed: $e');
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'failed_permanently',
              errorMessage: 'Dependency never resolved after $_maxDefer cycles: $e',
            );
            _deferCount.remove(localRef);
          } else {
            log('[SyncService] ⏳ $localRef deferred ($defers/$_maxDefer): $e');
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'pending',
              errorMessage: 'Menunggu dependency: $e',
            );
          }
          continue;
        } on OfflineException catch (e) {
          log('[SyncService] ⚠️ Offline: $e. Menghentikan sync cycle.');
          await _localDb.syncDao.updateQueueStatus(localRef, 'pending');
          break; // No point continuing when offline
        } on SocketException catch (e) {
          log(
            '[SyncService] ⚠️ Koneksi bermasalah: $e. Lanjut ke item berikutnya.',
          );
          await _localDb.syncDao.updateQueueStatus(localRef, 'pending');
          continue; // Lanjut ke item berikutnya
        } on TimeoutException catch (e) {
          log('[SyncService] ⚠️ Timeout: $e. Lanjut ke item berikutnya.');
          await _localDb.syncDao.updateQueueStatus(localRef, 'pending');
          continue; // Lanjut ke item berikutnya
        } on SyncServerException catch (e) {
          // 401/Unauthorized — AuthInterceptor already handles token refresh
          // transparently. If we still get 401 here, refresh failed → force logout.
          if (e.statusCode == 401 ||
              (e.message.toLowerCase().contains('unauthorized') ||
                  e.message.toLowerCase().contains('unauthenticated'))) {
            log(
              '[SyncService] 🛑 401 after AuthInterceptor refresh — session expired.',
            );
            throw DioAuthException('Token expired, please login again');
          }
          final op = item.operation;
          if (op == 'create_order') {
            final endpoint = item.endpoint;
            final method = item.method;
            final rawPayload = jsonDecode(item.payload);
            final payload = rawPayload is Map<String, dynamic>
                ? rawPayload
                : Map<String, dynamic>.from(rawPayload as Map? ?? const {});
            _logCreateOrderDiagnostics(
              endpoint: endpoint,
              method: method,
              payload: payload,
              statusCode: e.statusCode,
              errorMessage: e.message,
            );
          }

          final isServerError = e.statusCode >= 500 && e.statusCode <= 599;
          final isRateLimited = e.statusCode == 429 || e.statusCode == 503;

          if (isServerError || isRateLimited) {
            final backoff = _calculateBackoffDelay(retryCount);
            log(
              '[SyncService] ⚠️ Server/RateLimit Error (${e.statusCode}): '
              '${e.message}. Retry setelah ${backoff.inSeconds}s.',
            );
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'pending',
              errorMessage:
                  'Server error (${e.statusCode}) — retry setelah ${backoff.inSeconds}s',
            );
            await _broadcastPendingCount();
            await Future.delayed(backoff);
            continue;
          }

          // Resource gone on server (404/410) → cancel, jangan retry forever
          if (e.statusCode == 404 || e.statusCode == 410) {
            log('[SyncService] 🚫 $localRef resource hilang (${e.statusCode}): $e');
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'cancelled_dependency',
              errorMessage: 'Resource tidak ditemukan di server (${e.statusCode})',
            );
            await _broadcastPendingCount();
            continue;
          }

          // Validation/business logic errors (4xx) → failed_permanently SEGERA
          // (jangan retry — 4xx tidak akan tiba-tiba berhasil tanpa user fix data)
          final isClientError = e.statusCode >= 400 && e.statusCode < 500;
          if (isClientError) {
            log('[SyncService] ❌ $localRef client error (${e.statusCode}), failed permanently: $e');
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'failed_permanently',
              errorMessage: 'Validation error (${e.statusCode}): ${e.message}',
            );
            await _broadcastPendingCount();
            continue;
          }

          // Unknown / non-HTTP errors → bounded retry
          await _localDb.syncDao.incrementRetry(localRef);
          if (retryCount + 1 >= _maxRetry) {
            log('[SyncService] ❌ $localRef gagal permanen setelah $_maxRetry retry: $e');
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'failed_permanently',
              errorMessage: e.toString(),
            );
          } else {
            log('[SyncService] ⚠️ $localRef error lain: $e');
            await _localDb.syncDao.updateQueueStatus(
              localRef,
              'failed',
              errorMessage: e.toString(),
            );
          }
          await _broadcastPendingCount();
        } catch (e) {
          log('[SyncService] ❌ $localRef error lokal: $e');
          await _localDb.syncDao.incrementRetry(localRef);
          await _localDb.syncDao.updateQueueStatus(
            localRef,
            'failed',
            errorMessage: e.toString(),
          );
          await _broadcastPendingCount();
        }
      }
    } finally {
      await _localDb.syncDao.releaseSyncLock('syncAll');
    }

    final remaining = await _localDb.syncDao.getPendingCount();
    _emitPendingCount(remaining);

    // ── Schedule next sync with exponential backoff when idle ─────────────
    // If queue is empty, grow interval; if items exist, reset to base interval.
    _idleSyncTimer?.cancel();
    _idleSyncTimer = Timer(
      _calculateNextSyncInterval(hasItemsInQueue: remaining > 0),
      () => syncAll(),
    );
  }

  /// Kirim satu item queue ke server — JSON atau multipart jika ada foto
  Future<dynamic> _processItem(Map<String, dynamic> item) async {
    // ── Skip already-synced items ──────────────────────────────────────────
    // If server_synced_at is set, this item was already confirmed by the server
    // in a previous sync cycle (before app was killed). Just remove from queue.
    final serverSyncedAt = item['server_synced_at'] as int?;
    if (serverSyncedAt != null) {
      log(
        '[SyncService] ⏭️ Item ${item['local_ref']} sudah synced sebelumnya, skip.',
      );
      await _localDb.syncDao.removeFromQueue(item['local_ref'] as String);
      return null;
    }

    var endpoint = item['endpoint'] as String;
    final method = item['method'] as String;
    var payload = Map<String, dynamic>.from(
      item['payload'] as Map<String, dynamic>,
    );
    final localOrderId = payload.remove('_local_order_id')?.toString();

    // Resolusi otomatis local_ref -> server_id via RefID Map
    final resolved = await _resolveLocalRefs(endpoint, payload);
    endpoint = resolved.endpoint;
    payload = resolved.payload;

    // ── Pre-send validation: defer jika dependency belum resolved ─────────
    final operation = item['operation']?.toString() ?? '';
    if (operation == 'create_order') {
      final kunId = payload['id_kunjungan'];
      if (kunId != null) {
        final kunIdStr = kunId.toString();
        // Jika masih berupa localRef pattern (check_in_*, create_*), defer ke siklus berikutnya
        // UUID dan integer IDs are considered resolved
        if (kunIdStr.startsWith('check_in_') || kunIdStr.startsWith('create_') || kunIdStr.startsWith('visit_')) {
          log(
            '[SyncService] ⏳ create_order di-defer: id_kunjungan belum resolved ($kunIdStr). '
            'Menunggu check_in sync selesai.',
          );
          throw SyncDeferredException('id_kunjungan belum resolved: $kunIdStr');
        }
      }
    }

    // ── check_out dependency check ────────────────────────────────────────
    if (operation == 'check_out') {
      final kunId = payload['id_kunjungan'];
      if (kunId != null) {
        final kunIdStr = kunId.toString();
        // Jika masih berupa localRef pattern, defer ke siklus berikutnya
        if (kunIdStr.startsWith('check_in_') || kunIdStr.startsWith('create_') || kunIdStr.startsWith('visit_')) {
          log(
            '[SyncService] ⏳ check_out di-defer: id_kunjungan belum resolved ($kunIdStr). '
            'Menunggu check_in sync selesai.',
          );
          throw SyncDeferredException('id_kunjungan belum resolved: $kunIdStr');
        }
      }
    }

    // Cek apakah ada foto lokal yang perlu di-upload
    final rawPhotoPaths = payload.remove('_photo_paths');
    final photoPaths = rawPhotoPaths is Map
        ? rawPhotoPaths.cast<String, String>()
        : <String, String>{};

    final hasPhotos = photoPaths.isNotEmpty;

    if (hasPhotos) {
      // Multipart request untuk data + foto
      return await _processMultipart(
        endpoint: endpoint,
        method: method,
        fields: payload.map((k, v) => MapEntry(k, v.toString())),
        photoPaths: photoPaths,
      );
    } else {
      // JSON request biasa (tanpa foto)
      return await _processJson(
        endpoint: endpoint,
        method: method,
        payload: payload,
        localOrderId: localOrderId,
      );
    }
  }

  Future<dynamic> _processJson({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? localOrderId,
  }) async {
    final dio = _ref.read(dioClientProvider);

    try {
      dynamic response;
      if (method == 'POST') {
        response = await dio.post(endpoint, data: payload);
      } else if (method == 'PUT') {
        response = await dio.put(endpoint, data: payload);
      } else if (method == 'DELETE') {
        response = await dio.delete(endpoint, data: payload);
      } else {
        throw SyncServerException('Method tidak dikenal: $method', 400);
      }
      if (method == 'PUT' && localOrderId != null && response is Map) {
        await _patchUpdatedOrderFromResponse(
          localOrderId,
          Map<String, dynamic>.from(response),
        );
      }
      return response;
    } on ServerException catch (e) {
      final msg = e.data is Map
          ? (e.data['error']?['message'] ?? e.data['message'] ?? e.message ?? 'Server error')
          : (e.message ?? 'Server error');
      throw SyncServerException(msg.toString(), e.statusCode ?? 500);
    }
  }

  Future<void> _patchUpdatedOrderFromResponse(
    String localOrderId,
    Map<String, dynamic> responseData,
  ) async {
    try {
      final existingOrder =
          await _localDb.getOrder(localOrderId) ??
          await _localDb.getOrderByClientRef(localOrderId);
      if (existingOrder == null) return;

      final itemsJson = responseData['items'] != null
          ? jsonEncode(responseData['items'])
          : existingOrder.itemsJson;
      final promosJson = responseData['promos'] != null
          ? jsonEncode(responseData['promos'])
          : (responseData['promos_applied'] != null
                ? jsonEncode(responseData['promos_applied'])
                : existingOrder.promosJson);
      final totalTagihan = responseData['total_tagihan'];
      final tanggalTransaksi = responseData['tanggal_transaksi'] != null
          ? DateTime.tryParse(
              responseData['tanggal_transaksi'].toString(),
            )?.millisecondsSinceEpoch
          : null;

      await _localDb.saveOrder(
        id: existingOrder.id,
        kunjunganId: existingOrder.kunjunganId,
        pelangganId: existingOrder.pelangganId,
        status: responseData['status']?.toString() ?? existingOrder.status,
        itemsJson: itemsJson,
        notes: existingOrder.notes,
        promosJson: promosJson,
        totalTagihan: totalTagihan is num
            ? totalTagihan.toDouble()
            : double.tryParse(totalTagihan?.toString() ?? '') ??
                  existingOrder.totalTagihan,
        serverId: existingOrder.serverId,
        clientRef: existingOrder.clientRef,
        noPesanan:
            responseData['no_pesanan']?.toString() ?? existingOrder.noPesanan,
        tanggalTransaksi: tanggalTransaksi ?? existingOrder.tanggalTransaksi,
      );
      await _localDb.deleteDuplicateOrdersForCanonical(
        canonicalId: existingOrder.id,
        serverId: existingOrder.serverId,
        noPesanan:
            responseData['no_pesanan']?.toString() ?? existingOrder.noPesanan,
        clientRef: existingOrder.clientRef,
      );
    } catch (e) {
      log('[Sync] ⚠️ Gagal patch updated order $localOrderId: $e');
    }
  }

  Future<dynamic> _processMultipart({
    required String endpoint,
    required String method,
    required Map<String, String> fields,
    required Map<String, String> photoPaths,
  }) async {
    final dio = _ref.read(dioClientProvider);
    final formData = FormData();

    for (final entry in fields.entries) {
      formData.fields.add(MapEntry(entry.key, entry.value));
    }

    for (final entry in photoPaths.entries) {
      final file = File(entry.value);
      if (await file.exists()) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value,
              filename: '${entry.key}.jpg',
            ),
          ),
        );
      } else {
        log('[SyncService] ❌ File foto hilang: ${entry.value}');
        throw SyncServerException(
          'Foto ${entry.key} hilang dari device storage. Mohon ulangi upload.',
          422,
        );
      }
    }

    try {
      final response = await dio.uploadFile(
        endpoint,
        formData: formData,
        method: method,
      );

      await _photoStorage.deletePhotos(photoPaths.values.toList());
      return response;
    } on ServerException catch (e) {
      final msg = e.data is Map
          ? (e.data['error']?['message'] ?? e.data['message'] ?? e.message ?? 'Server error')
          : (e.message ?? 'Server error');
      throw SyncServerException(msg.toString(), e.statusCode ?? 500);
    }
  }

  // ── Enqueue — unified entry point ──────────────────────────────────────────

  /// Tambahkan operasi ke sync queue.
  /// [triggerSync] — jika true, langsung coba sync saat online.
  /// [txn] — jika provided, uses existing sqflite transaction (caller manages commit/rollback).
  Future<String> enqueue({
    required String operation,
    required String endpoint,
    String method = 'POST',
    Map<String, dynamic> payload = const {},
    bool triggerSync = false,
  }) async {
    final ref = await _localDb.syncDao.enqueue(
      operation: operation,
      endpoint: endpoint,
      method: method,
      payload: payload,
    );
    await _broadcastPendingCount();
    if (triggerSync) syncAll();
    return ref;
  }

  // ── Convenience Enqueue Helpers (backward-compatible) ─────────────────────

  Future<String> enqueueCheckIn({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'check_in',
    endpoint: endpoint,
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueCheckOut({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'check_out',
    endpoint: endpoint,
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueUpdateScheduleStatus({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'update_schedule_status',
    endpoint: endpoint,
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueCreateOrder({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'create_order',
    endpoint: endpoint,
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueCreatePelanggan({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'create_pelanggan',
    endpoint: endpoint,
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueUpdatePelanggan({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'update_pelanggan',
    endpoint: endpoint,
    method: 'PUT',
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueCreateProspect({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'create_prospect',
    endpoint: endpoint,
    payload: payload,
    triggerSync: true,
  );

  Future<String> enqueueReadNotification({required String endpoint}) => enqueue(
    operation: 'read_notification',
    endpoint: endpoint,
    triggerSync: true,
  );

  Future<String> enqueueUpdateCustomerPhoto({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) => enqueue(
    operation: 'update_customer_photo',
    endpoint: endpoint,
    method: 'PUT',
    payload: payload,
    triggerSync: true,
  );

  /// Sync single customer creation NOW and return server response.
  /// Used by mutateCreateCustomer to get server ID immediately for online scenarios.
  /// This enables subsequent operations (check-in) to use correct server ID.
  ///
  /// Coordinates with `syncAll` via the same DB-level 'syncAll' lock to avoid
  /// double-processing the same queue item from two paths.
  Future<dynamic> syncCreateCustomerNow({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final localRef = await _localDb.syncDao.enqueue(
      operation: 'create_pelanggan',
      endpoint: endpoint,
      method: 'POST',
      payload: payload,
    );
    await _broadcastPendingCount();

    log(
      '[SyncService] syncCreateCustomerNow: enqueued $localRef, waiting for sync...',
    );

    const maxWaitMs = 15000;
    const pollIntervalMs = 100;
    int waitedMs = 0;

    final got = await _localDb.syncDao.acquireSyncLock('syncAll', ttlMinutes: 5);
    if (got) {
      try {
        final items = await _localDb.syncDao.getAllQueueItems();
        final item = items.where((i) => i.localRef == localRef).firstOrNull;
        if (item == null) {
          return await _reconstructCustomerResponse(localRef, payload);
        }
        if (item.status == 'failed_permanently') {
          throw SyncServerException(
            'Customer creation failed permanently: ${item.errorMessage}',
            422,
          );
        }

        await _localDb.syncDao.updateQueueStatus(localRef, 'syncing');
        try {
          final itemMap = _syncQueueItemToMap(item);
          final response = await _processItem(itemMap);

          final serverId = response is Map
              ? (response['id'] ?? response['data']?['id'])
              : null;
          if (serverId != null) {
            await _localDb.syncDao.saveRefMapping(localRef, serverId.toString());
            final itemPayload = jsonDecode(item.payload) as Map<String, dynamic>;
            final clientRef = itemPayload['client_ref'] as String?;
            if (clientRef != null) {
              await _localDb.syncDao.saveRefMapping(clientRef, serverId.toString());
            }
            await _patchDependentItems(
              localRef,
              serverId,
              clientRef: clientRef,
            );
          }

          await _localDb.markServerSynced(localRef);
          await _localDb.syncDao.removeFromQueue(localRef);
          _deferCount.remove(localRef);
          await _broadcastPendingCount();
          log(
            '[SyncService] syncCreateCustomerNow: ✅ synced, server_id=$serverId',
          );
          return response;
        } catch (e) {
          log(
            '[SyncService] syncCreateCustomerNow: sync failed: $e, re-queuing',
          );
          await _localDb.syncDao.updateQueueStatus(
            localRef,
            'failed',
            errorMessage: e.toString(),
          );
          await _broadcastPendingCount();
          rethrow;
        }
      } finally {
        await _localDb.syncDao.releaseSyncLock('syncAll');
      }
    }

    // Lock held by another sync loop — observe-only mode.
    while (waitedMs < maxWaitMs) {
      final items = await _localDb.syncDao.getAllQueueItems();
      final item = items.where((i) => i.localRef == localRef).firstOrNull;

      if (item == null) {
        log(
          '[SyncService] syncCreateCustomerNow: item $localRef drained by syncAll',
        );
        return await _reconstructCustomerResponse(localRef, payload);
      }

      if (item.status == 'failed_permanently') {
        throw SyncServerException(
          'Customer creation failed permanently: ${item.errorMessage}',
          422,
        );
      }

      await Future.delayed(const Duration(milliseconds: pollIntervalMs));
      waitedMs += pollIntervalMs;
    }

    throw SyncServerException(
      'Timeout waiting for customer sync after ${maxWaitMs}ms',
      408,
    );
  }

  /// Build a server-shaped response after `syncAll` has drained a
  /// `create_pelanggan` queue item. Looks up the saved server_id mapping and
  /// the Drift customer row (via `_drift_record_id` planted in the payload).
  Future<Map<String, dynamic>> _reconstructCustomerResponse(
    String localRef,
    Map<String, dynamic> payload,
  ) async {
    final serverId = await _localDb.syncDao.getServerId(localRef);
    final driftId = payload['_drift_record_id']?.toString() ?? localRef;
    final customer = await _localDb.getCustomer(driftId);
    return {
      'id': serverId ?? customer?.serverId,
      'kode_pelanggan': customer?.kodePelanggan,
      'nama_toko': customer?.namaToko,
      'nama_pemilik': customer?.namaPemilik,
      'no_hp_pribadi': customer?.noHpPribadi,
      'alamat_usaha': customer?.alamatUsaha,
      'status': customer?.status,
    };
  }


  /// Post-success finalization: save ref mapping, patch dependent queue items,
  /// and update local Drift records (customer/order) with server data.
  /// Called after both the main success path and the 401 retry success path.
  Future<void> _finalizeSyncSuccess(
    SyncQueueTableData item,
    dynamic response,
  ) async {
    final localRef = item.localRef;
    final op = item.operation;
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    final serverId = response is Map
        ? (response['id'] ?? response['data']?['id'])
        : null;
    log(
      '[SyncService] 📦 response type=${response.runtimeType}, isMap=${response is Map}, serverId=$serverId',
    );

    if (serverId == null) return;

    if (op == 'check_in' ||
        op == 'create_pelanggan' ||
        op == 'create_prospect') {
      try {
        await _localDb.syncDao.saveRefMapping(localRef, serverId.toString());
        final clientRef = payload['client_ref'];
        if (clientRef != null) {
          await _localDb.syncDao.saveRefMapping(
            clientRef.toString(),
            serverId.toString(),
          );
          log(
            '[SyncService] 🗺️ Mapped client_ref=$clientRef → server_id=$serverId',
          );
        }
      } catch (e) {
        log(
          '[Sync] ⚠️ saveRefMapping gagal untuk $localRef → $serverId: $e',
        );
      }
      final clientRefForPatch = payload['client_ref'];
      await _patchDependentItems(
        localRef,
        serverId,
        clientRef: clientRefForPatch,
      );

      if (op == 'create_pelanggan' || op == 'create_prospect') {
        try {
          final resolvedServerId = serverId.toString();
          final serverData = response is Map
              ? (response['data'] ?? response) as Map<String, dynamic>
              : <String, dynamic>{};
          final driftRecordId =
              payload['_drift_record_id']?.toString() ?? localRef;
          await _localDb.saveCustomer(
            id: driftRecordId,
            serverId: resolvedServerId,
            kodePelanggan: serverData['kode_pelanggan'] as String?,
            namaToko:
                serverData['nama_toko'] as String? ??
                payload['nama_toko'] as String?,
            namaPemilik:
                serverData['nama_pemilik'] as String? ??
                payload['nama_pemilik'] as String?,
            noHpPribadi:
                serverData['no_hp_pribadi'] as String? ??
                payload['no_hp_pribadi'] as String?,
            alamatUsaha:
                serverData['alamat_usaha'] as String? ??
                payload['alamat_usaha'] as String?,
            status:
                serverData['status'] as String? ??
                payload['status'] as String?,
          );
          log(
            '[SyncService] ✅ Customer $driftRecordId updated with serverId=$resolvedServerId, kode=${serverData['kode_pelanggan']}',
          );
        } catch (e) {
          log('[Sync] ⚠️ Gagal update customer Drift record: $e');
        }
      }
    }

    if (op == 'create_order') {
      try {
        final responseData = response is Map ? response : <String, dynamic>{};
        final noPesanan =
            responseData['no_pesanan'] ?? responseData['data']?['no_pesanan'];
        final itemsJson = responseData['items'] != null
            ? jsonEncode(responseData['items'])
            : null;
        final promosJson = responseData['promos'] != null
            ? jsonEncode(responseData['promos'])
            : (responseData['promos_applied'] != null
                  ? jsonEncode(responseData['promos_applied'])
                  : null);

        final serverStatus = responseData['status']?.toString();
        final serverTotalTagihan = responseData['total_tagihan'];

        final orderClientRef = payload['client_ref']?.toString();
        OrdersTableData? existingOrder;
        if (orderClientRef != null) {
          existingOrder = await _localDb.getOrderByClientRef(orderClientRef);
        }
        existingOrder ??= await _localDb.getOrder(localRef);
        if (existingOrder != null) {
          final serverTanggal = responseData['tanggal_transaksi'];
          final tanggalTransaksi = serverTanggal != null
              ? DateTime.tryParse(
                  serverTanggal.toString(),
                )?.millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;

          final resolvedStatus = serverStatus ?? existingOrder.status;
          final resolvedTotal = serverTotalTagihan != null
              ? (serverTotalTagihan is num
                    ? serverTotalTagihan.toDouble()
                    : double.tryParse(serverTotalTagihan.toString()) ??
                          existingOrder.totalTagihan)
              : existingOrder.totalTagihan;
          final String resolvedServerId = serverId.toString();

          await _localDb.saveOrder(
            id: existingOrder.id,
            kunjunganId: existingOrder.kunjunganId,
            pelangganId: existingOrder.pelangganId,
            status: resolvedStatus,
            itemsJson: itemsJson ?? existingOrder.itemsJson,
            notes: existingOrder.notes,
            promosJson: promosJson ?? existingOrder.promosJson,
            totalTagihan: resolvedTotal,
            serverId: resolvedServerId,
            clientRef: existingOrder.clientRef,
            noPesanan: noPesanan,
            tanggalTransaksi: tanggalTransaksi,
          );
          await _localDb.deleteDuplicateOrdersForCanonical(
            canonicalId: existingOrder.id,
            serverId: resolvedServerId,
            noPesanan: noPesanan?.toString(),
            clientRef: existingOrder.clientRef,
          );
          log(
            '[SyncService] ✅ Order $localRef updated with no_pesanan=$noPesanan, status=$resolvedStatus, serverId=$resolvedServerId, tanggal=$tanggalTransaksi',
          );
        }

        final clientRef = payload['client_ref'];
        if (clientRef != null) {
          await _localDb.syncDao.saveRefMapping(
            clientRef.toString(),
            serverId.toString(),
          );
        }
      } catch (e) {
        log('[Sync] ⚠️ Gagal update order $localRef dengan server data: $e');
      }
    }
  }

  /// Patching item di queue yang tadinya pakai localRef ATAU client_ref
  /// ke ID asli dari server (UUID string).
  Future<void> _patchDependentItems(
    String localRef,
    dynamic serverId, {
    String? clientRef,
  }) async {
    final items = await _localDb.syncDao.getAllQueueItems();

    // serverId is now a UUID string
    final resolvedServerId = serverId.toString();

    // Build set of semua ref yang harus di-patch (localRef + client_ref)
    final refsToPatch = {localRef};
    if (clientRef != null && clientRef.isNotEmpty) {
      refsToPatch.add(clientRef);
    }

    for (final item in items) {
      final currentRef = item.localRef;
      var endpoint = item.endpoint;
      var payload = jsonDecode(item.payload) as Map<String, dynamic>;
      var changed = false;

      // Patch endpoint (misal path/.../check_in_123 -> path/.../50)
      for (final ref in refsToPatch) {
        if (endpoint.contains(ref)) {
          endpoint = endpoint.replaceAll(ref, serverId.toString());
          changed = true;
        }
      }

      // Patch payload (misal id_kunjungan: visit_xxx -> id_kunjungan: 50)
      for (final entry in payload.entries) {
        if (refsToPatch.contains(entry.value.toString())) {
          // Untuk kolom yang ekspektasinya bigint, selalu simpan sebagai int
          if (entry.key == 'id_kunjungan' ||
              entry.key == 'id_pelanggan' ||
              entry.key == 'id_jadwal') {
            payload[entry.key] = resolvedServerId;
          } else {
            payload[entry.key] = serverId;
          }
          changed = true;
        }
      }

      if (changed) {
        await _localDb.rawUpdate(
          'UPDATE ${AppDatabase.tableSyncQueue} SET endpoint = ?, payload = ? WHERE local_ref = ?',
          whereArgs: [endpoint, jsonEncode(payload), currentRef],
        );
        log(
          '[SyncService] 🪄 Patched $currentRef: Replace ${refsToPatch.join(', ')} → $resolvedServerId',
        );
      }
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  Future<void> _broadcastPendingCount() async {
    final count = await _localDb.syncDao.getPendingCount();
    _emitPendingCount(count);
  }

  void _emitPendingCount(int count) {
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(count);
    }
  }

  /// Resolusi otomatis local_ref ke server_id dari tabel pemetaan permanen.
  /// Berguna jika parent (check_in) sudah sukses dan terhapus dari queue,
  /// tapi child (check_out/order) masih menyisakan local_ref.
  Future<({String endpoint, Map<String, dynamic> payload})> _resolveLocalRefs(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final mappings = await _localDb.getAllRefMappings();
    if (mappings.isEmpty) return (endpoint: endpoint, payload: payload);

    var newEndpoint = endpoint;
    final Map<String, dynamic> newPayload = Map<String, dynamic>.from(payload);
    var changed = false;

    for (final entry in mappings.entries) {
      final localRef = entry.key;
      final serverId = entry.value;

      // 1. Ganti di endpoint path (e.g. /kunjungan/check_in_123)
      if (newEndpoint.contains(localRef)) {
        newEndpoint = newEndpoint.replaceAll(localRef, serverId);
        changed = true;
      }

      // 2. Ganti di payload value (e.g. id_kunjungan: check_in_123)
      for (final pEntry in newPayload.entries) {
        if (pEntry.value.toString() == localRef) {
          // UUID migration: all entity IDs are now String
          newPayload[pEntry.key] = serverId;
          log(
            '[SyncService] 🪄 Resolved ${pEntry.key}: $localRef → $serverId',
          );
          changed = true;
        }
      }
    }

    if (changed) {
      log(
        '[SyncService] 🪄 Resolved local refs for $newEndpoint. Payload keys: ${newPayload.keys}',
      );
    }

    return (endpoint: newEndpoint, payload: newPayload);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _idleSyncTimer?.cancel();
    _pendingCountController.close();
  }
}
