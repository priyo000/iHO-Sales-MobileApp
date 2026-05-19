import 'dart:convert';
import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_service.dart';
import 'connectivity_service.dart';
import 'token_storage.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log('[BackgroundSync] Memulai task: $task');

    // Extract token dari inputData yang di-pass dari main app.
    // Ini menghindari issue di mana SharedPreferences tidak punya context
    // yang sama di isolate terpisah.
    final token = inputData?['token'] as String?;

    // ProviderContainer untuk isolate ini
    // NOTE: Background sync berjalan di isolate terpisah.
    // Sync queue dan SSOT operations tetap di main app melalui
    // Workmanager callback - kita hanya trigger sync di sini.
    final container = ProviderContainer();

    try {
      if (task == 'preWorkSync') {
        // Pre-Work Sync: fetch semua data kritis sebelum sales berangkat
        await _executePreWorkSync(container, token);
      } else {
        // syncAll() sudah menangani sync lock secara internal — tidak perlu
        // acquire manual di sini agar tidak terjadi double-lock.
        final syncService = container.read(syncServiceProvider);
        await syncService.syncAll();
      }

      log('[BackgroundSync] Task selesai: $task');
      return true;
    } catch (e) {
      log('[BackgroundSync] Task gagal ($task): $e');
      return false; // Task will be retried by OS
    } finally {
      // WAJIB: dispose container agar tidak ada memory leak
      container.dispose();
    }
  });
}

/// Pre-Work Sync: only runs the outbound sync queue.
/// Background isolate cannot write to the main isolate's Drift streams,
/// so we only process pending mutations here — data pull happens in main.
Future<void> _executePreWorkSync(ProviderContainer container, String? token) async {
  final connectivity = container.read(connectivityServiceProvider);
  final isOnline = await connectivity.checkNow();
  if (!isOnline) {
    log('[PreWorkSync] Device offline, skip pre-work sync.');
    return;
  }

  try {
    final syncService = container.read(syncServiceProvider);
    await syncService.syncAll();
    await _savePreWorkSyncTime(status: 'success');
    log('[PreWorkSync] Outbound sync queue processed.');
  } catch (e) {
    log('[PreWorkSync] Error saat sync: $e');
    await _savePreWorkSyncTime(status: 'failed', error: e.toString());
    rethrow;
  }
}

Future<void> _savePreWorkSyncTime({required String status, String? error}) async {
  final prefs = await SharedPreferences.getInstance();
  final data = {
    'last_sync': DateTime.now().toIso8601String(),
    'status': status,
    if (error != null) 'error': error,
  };
  await prefs.setString('pre_work_sync_time', jsonEncode(data));
}


class BackgroundSyncService {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerPeriodicSync() async {
    // Ambil token dari SharedPreferences di main app sebelum passing ke WorkManager
    final tokenStorage = TokenStorage();
    final token = await tokenStorage.read();

    // Write sync queue (existing) — setiap 15 menit
    // BackoffPolicy.exponential: kalau task gagal (return false / throw),
    // OS retry dengan interval naik bertahap mulai dari 30 detik (30s → 60s → 120s …),
    // dibanding nunggu 15 menit berikutnya. Battery-friendly + reliable untuk
    // koneksi flaky di lapangan.
    Workmanager().registerPeriodicTask(
      'offline-sync-task',
      'syncAllData',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
      inputData: {'token': token},
    );

    // Smart pre-fetch: opportunistic sync saat charging + WiFi
    // WorkManager minimal frequency 15 menit, tapi kita pakai one-off
    // yang di-trigger dari app lifecycle (main.dart)
    log('[BackgroundSync] Smart pre-fetch registered (app launch + 12h TTL).');
  }

  /// Trigger pre-work sync manual (untuk testing atau saat app launch pertama kali)
  static Future<void> triggerPreWorkSyncNow() async {
    // Ambil token dari SharedPreferences di main app sebelum passing ke WorkManager
    final tokenStorage = TokenStorage();
    final token = await tokenStorage.read();

    Workmanager().registerOneOffTask(
      'pre-work-sync-now',
      'preWorkSync',
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      inputData: {'token': token},
    );
    log('[BackgroundSync] Pre-work sync triggered manually with token.');
  }
}
