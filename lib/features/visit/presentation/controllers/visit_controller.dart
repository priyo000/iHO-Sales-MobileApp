import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../data/visit_repository.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../../../orders/data/promo_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stream Providers for SSOT Reactive UI
// ─────────────────────────────────────────────────────────────────────────────

/// Watch all visits - reactive stream for visit list pages
final visitsStreamProvider = Provider<Stream<List<VisitsTableData>>>((ref) {
  return ref.watch(visitRepositoryProvider).watchAllVisits();
});

/// Watch today's visits - for dashboard SSOT
final todayVisitsStreamProvider = Provider<Stream<List<VisitsTableData>>>((
  ref,
) {
  return ref.watch(visitRepositoryProvider).watchTodayVisits();
});

/// Watch pending visits (offline-created, not yet synced)
final pendingVisitsStreamProvider = Provider<Stream<List<VisitsTableData>>>((
  ref,
) {
  return ref.watch(visitRepositoryProvider).watchPendingVisits();
});

/// VisitController — Offline-first check-in/check-out
/// Operasi lokal langsung selesai (instant), tidak ada loading state
final visitControllerProvider = AsyncNotifierProvider<VisitController, void>(
  VisitController.new,
);

class VisitController extends AsyncNotifier<void> {
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  @override
  FutureOr<void> build() {
    return null;
  }

  /// Returns (kunjunganId, isOffline)
  /// [pelangganId] can be int (server ID) or String (local_ref for offline)
  ///
  /// OFFLINE-FIRST: Langsung return hasil optimistik dari lokal DB.
  /// Tidak ada loading state — UI langsung update.
  /// Sync ke server happens di background secara otomatis.
  Future<({dynamic kunjunganId, bool isOffline})> checkIn({
    required String? jadwalId,
    required dynamic
    pelangganId, // int (server ID) or String (local_ref for offline)
    required double lat,
    required double long,
    double? jarakValidasi,
    String?
    scheduledDate, // The actual date of the scheduled visit (may differ from today)
    Map<String, dynamic>? pelangganDataMap,
  }) async {
    if (_isCheckingIn) {
      debugPrint('[VisitController] checkIn() called while already in progress — ignoring duplicate call.');
      return (kunjunganId: null, isOffline: false);
    }
    _isCheckingIn = true;
    try {
      // Langsung mutate lokal (INSTANT - no await for loading state)
      final repository = ref.read(visitRepositoryProvider);
      final response = await repository.checkIn(
        jadwalId: jadwalId,
        pelangganId: pelangganId,
        lat: lat,
        long: long,
        jarakValidasi: jarakValidasi,
        scheduledDate: scheduledDate,
        pelangganDataMap: pelangganDataMap,
      );

      // Invalidate schedule agar UI update dari cache
      ref.invalidate(scheduleControllerProvider);

      // Background sync promo untuk pelanggan yang baru di-check-in
      // Only sync when pelangganId is a valid server ID (int), not local_ref (String)
      final promoSyncId = pelangganId is int ? pelangganId : null;
      if (promoSyncId != null) {
        Future.microtask(() async {
          try {
            final promoRepo = ref.read(promoRepositoryProvider);
            await promoRepo.syncFromApi(promoSyncId.toString());
          } catch (e) {
            debugPrint('[VisitController] Background promo sync failed for $promoSyncId: $e');
          }
        });
      }

      final isOffline = response['is_offline'] == true;
      // For offline visits, use client_ref as kunjunganId so orders/checkouts
      // can reference it and backend will resolve to actual kunjungan ID.
      // For online visits, use the server-returned numeric ID.
      final id = isOffline
          ? (response['client_ref'] ??
                response['data']?['client_ref'] ??
                response['data']?['id'] ??
                response['id'])
          : (response['data']?['id'] ??
                response['id'] ??
                response['id_kunjungan'] ??
                response['data']?['id_kunjungan']);
      return (kunjunganId: id, isOffline: isOffline);
    } catch (e) {
      debugPrint('CheckIn Error: $e');
      rethrow;
    } finally {
      _isCheckingIn = false;
    }
  }

  /// OFFLINE-FIRST: Langsung selesai dari lokal DB.
  /// Tidak ada loading state — UI langsung update.
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
    if (_isCheckingOut) return;
    _isCheckingOut = true;
    try {
      // Langsung mutate lokal (INSTANT - no loading state)
      final repository = ref.read(visitRepositoryProvider);
      await repository.checkOut(
        kunjunganId: kunjunganId,
        lat: lat,
        long: long,
        statusTransaksi: statusTransaksi,
        alasanTidakOrder: alasanTidakOrder,
        detailAlasan: detailAlasan,
        catatan: catatan,
        photos: photos,
        scheduledDate: scheduledDate,
      );

      // Refresh schedule to show updated visit count and status
      ref.invalidate(scheduleControllerProvider);
    } catch (e) {
      debugPrint('CheckOut Error: $e');
      rethrow;
    } finally {
      _isCheckingOut = false;
    }
  }
}
