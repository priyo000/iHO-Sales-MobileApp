import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import '../../db/app_database.dart';
import '../../constants/api_constants.dart';
import '../sync_service.dart';
import '../offline_photo_service.dart';

class VisitMutation {
  final AppDatabase _db;
  final SyncService _sync;
  final OfflinePhotoService _photoStorage;
  final String Function(String) generateLocalRef;
  final Future<void> Function() triggerSync;

  VisitMutation(
    this._db,
    this._sync,
    this._photoStorage, {
    required this.generateLocalRef,
    required this.triggerSync,
  });

  String get _endpointKunjungan => ApiConstants.kunjungan;

  Future<Map<String, dynamic>> mutateCheckIn({
    String? jadwalId,
    required dynamic pelangganId,
    required double lat,
    required double long,
    double? jarakValidasi,
    String? scheduledDate,
    Map<String, dynamic>? pelangganDataMap,
  }) async {
    final todayVisits = await _db.getTodayVisits();
    final alreadyExists = todayVisits.any(
      (v) => v.pelangganId == pelangganId.toString(),
    );
    if (alreadyExists) {
      debugPrint(
        '[VisitMutation] Visit already exists for pelanggan $pelangganId today, skipping.',
      );
      final existing = todayVisits.firstWhere(
        (v) => v.pelangganId == pelangganId.toString(),
      );
      return {
        'id': existing.id,
        'client_ref': existing.id,
        'local_ref': existing.id,
        'id_pelanggan': pelangganId,
        'waktu_check_in': existing.waktuCheckIn,
        'status_kunjungan': existing.status,
        'is_offline': existing.isLocal == 1,
        'duplicate': true,
      };
    }

    final clientRef =
        'visit_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 99999).toString().padLeft(5, '0')}';
    final visitRef = clientRef;
    final now = DateTime.now().toIso8601String();

    await _db.saveVisit(
      id: visitRef,
      scheduleId: jadwalId,
      pelangganId: pelangganId?.toString(),
      status: 'CHECKED_IN',
      latIn: lat,
      longIn: long,
      waktuCheckIn: now,
    );

    if (jadwalId != null && pelangganId != null) {
      final pelIdStr = pelangganId.toString();
      await _db.updateScheduleStatusByJadwal(
        jadwalId: jadwalId,
        pelangganId: pelIdStr,
        status: 'DIKUNJUNGI',
        waktuCheckIn: now,
      );
    } else if (jadwalId == null && pelangganId != null) {
      final pelIdStr = pelangganId.toString();
      final n = DateTime.now();
      final today =
          '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      final todaySchedules = await _db.getScheduleForDate(today);
      final match = todaySchedules
          .where((s) => s.pelangganId == pelIdStr)
          .firstOrNull;
      if (match != null) {
        await _db.updateScheduleStatus(match.id, 'DIKUNJUNGI', waktuCheckIn: now);
        dev.log('[VisitMutation] Fallback: updated schedule ${match.id}');
      }
    }

    final syncRef = await _sync.enqueueCheckIn(
      endpoint: _endpointKunjungan,
      payload: {
        'client_ref': clientRef,
        'id_jadwal': jadwalId,
        'id_pelanggan': pelangganId,
        'latitude_check_in': lat,
        'longitude_check_in': long,
        'jarak_validasi': jarakValidasi,
        'waktu_check_in': now,
      },
    );

    dev.log('[VisitMutation] Check-in queued. visitRef=$visitRef syncRef=$syncRef');
    triggerSync();

    return {
      'id': visitRef,
      'client_ref': clientRef,
      'local_ref': syncRef,
      'id_pelanggan': pelangganId,
      'waktu_check_in': now,
      'status_kunjungan': 'DIKUNJUNGI',
      'is_offline': true,
    };
  }

  Future<void> mutateCheckOut({
    required dynamic kunjunganId,
    required double lat,
    required double long,
    required bool statusTransaksi,
    String? alasanTidakOrder,
    String? detailAlasan,
    String? catatan,
    Map<String, dynamic>? photos,
  }) async {
    final idStr = kunjunganId.toString();

    var existingVisit = await _db.getVisit(idStr);
    existingVisit ??= await _db.getVisitByServerId(idStr);

    if (existingVisit == null) {
      debugPrint('[VisitMutation] Visit $kunjunganId not found in Drift, aborting checkout.');
      throw 'Visit $kunjunganId not found locally.';
    }
    if (existingVisit.status == 'CHECKED_OUT') {
      debugPrint('[VisitMutation] Visit $kunjunganId already CHECKED_OUT, skipping.');
      return;
    }

    final localId = existingVisit.id;
    final serverIdForApi = existingVisit.serverId ?? idStr;

    final now = DateTime.now().toIso8601String();

    final Map<String, File?> normalizedPhotos = {};
    if (photos != null) {
      int idx = 1;
      for (final entry in photos.entries) {
        if (entry.value != null) {
          normalizedPhotos['foto_$idx'] = entry.value as File?;
          idx++;
        }
      }
    }

    final savedPhotoPaths = normalizedPhotos.isNotEmpty
        ? await _photoStorage.savePhotos(
            normalizedPhotos,
            'checkout',
          )
        : <String, String>{};

    await _db.updateVisitCheckout(
      id: localId,
      status: 'CHECKED_OUT',
      latOut: lat,
      longOut: long,
      waktuCheckOut: now,
      alasanTidak: alasanTidakOrder,
      catatan: catatan,
      photosPending: normalizedPhotos.isNotEmpty ? 1 : 0,
    );

    await _db.updateScheduleStatusByVisitId(
      visitId: localId,
      status: 'SELESAI',
      waktuCheckOut: now,
    );

    final checkOutEndpoint = '$_endpointKunjungan/$serverIdForApi';
    await _sync.enqueueCheckOut(
      endpoint: checkOutEndpoint,
      payload: {
        'id_kunjungan': serverIdForApi,
        'status_transaksi': statusTransaksi ? '1' : '0',
        'alasan_tidak_order': alasanTidakOrder ?? '',
        'detail_alasan': detailAlasan ?? '',
        'catatan': catatan ?? '',
        'latitude_check_out': lat.toString(),
        'longitude_check_out': long.toString(),
        'waktu_check_out': now,
        if (savedPhotoPaths.isNotEmpty) '_photo_paths': savedPhotoPaths,
      },
    );

    triggerSync();

    dev.log('[VisitMutation] Check-out queued. localId=$localId serverId=$serverIdForApi');
  }
}
