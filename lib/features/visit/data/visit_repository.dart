import 'dart:io';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/services/mutation_queue_service.dart';
import '../../../../core/providers/database_providers.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository(
    ref.watch(appDatabaseProvider),
    ref.read(mutationQueueServiceProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// VisitRepository — SSOT Pattern
//
// READ:  From Drift streams (instant, offline-first)
// WRITE: Via MutationQueueService (writes to Drift first, queues sync)
//
// This ensures:
// - UI always reads from local Drift (instant)
// - Writes are queued for server sync
// - No direct server calls in read path
// ─────────────────────────────────────────────────────────────────────────────

class VisitRepository {
  final AppDatabase _db;
  final MutationQueueService _mutations;

  VisitRepository(this._db, this._mutations);

  // ═══════════════════════════════════════════════════════════════════════════
  // READ — Stream from Drift (SSOT instant read)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all visits - reactive stream
  Stream<List<VisitsTableData>> watchAllVisits() {
    return _db.watchAllVisits();
  }

  /// Watch today's visits - for dashboard SSOT
  Stream<List<VisitsTableData>> watchTodayVisits() {
    return _db.watchTodayVisits();
  }

  /// Watch pending visits (offline-created, not yet synced)
  Stream<List<VisitsTableData>> watchPendingVisits() {
    return _db.watchPendingVisits();
  }

  /// Watch visits by pelanggan
  Stream<List<VisitsTableData>> watchVisitsByPelanggan(String pelangganId) {
    return _db.watchVisitsByPelanggan(pelangganId);
  }

  /// Watch single visit by ID
  Stream<VisitsTableData?> watchVisit(String id) {
    return _db.watchVisit(id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE — Via MutationQueueService (Drift first, then sync)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check-in — write to Drift immediately, queue for server sync.
  /// Returns optimistic data for UI consumption.
  Future<Map<String, dynamic>> checkIn({
    required String? jadwalId,
    required dynamic pelangganId,
    required double lat,
    required double long,
    double? jarakValidasi,
    String? scheduledDate,
    Map<String, dynamic>? pelangganDataMap,
  }) async {
    log('[VisitRepo] SSOT check-in for pelanggan: $pelangganId');
    return _mutations.mutateCheckIn(
      jadwalId: jadwalId,
      pelangganId: pelangganId,
      lat: lat,
      long: long,
      jarakValidasi: jarakValidasi,
      scheduledDate: scheduledDate,
      pelangganDataMap: pelangganDataMap,
    );
  }

  /// Check-out — write to Drift immediately, queue for server sync.
  Future<void> checkOut({
    required dynamic kunjunganId,
    required double lat,
    required double long,
    required bool statusTransaksi,
    String? alasanTidakOrder,
    String? detailAlasan,
    String? catatan,
    Map<String, File?>? photos,
    String? scheduledDate,
  }) async {
    log('[VisitRepo] SSOT check-out for kunjungan: $kunjunganId');
    return _mutations.mutateCheckOut(
      kunjunganId: kunjunganId,
      lat: lat,
      long: long,
      statusTransaksi: statusTransaksi,
      alasanTidakOrder: alasanTidakOrder,
      detailAlasan: detailAlasan,
      catatan: catatan,
      photos: photos,
    );
  }
}
