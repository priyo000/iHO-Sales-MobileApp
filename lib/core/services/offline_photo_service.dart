import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OfflinePhotoService
//
// Menyimpan foto ke filesystem lokal saat operasi offline.
// Path disimpan di sync_queue payload → saat sync (online), foto di-upload
// dari path ini, lalu file lokal dihapus.
//
// Lokasi: {documentsDir}/offline_photos/{operation}_{timestamp}.jpg
// ─────────────────────────────────────────────────────────────────────────────

final offlinePhotoServiceProvider = Provider<OfflinePhotoService>((ref) {
  return OfflinePhotoService();
});

class OfflinePhotoService {
  static const String _dirName = 'offline_photos';

  /// Simpan satu foto ke lokal storage.
  /// [operationType]: misal 'checkout', 'pelanggan', 'ktp'
  /// Returns: absolute path file yang disimpan, atau null jika gagal.
  Future<String?> savePhoto(File photo, String operationType) async {
    try {
      final dir = await _getPhotoDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = p.join(dir.path, '${operationType}_$timestamp.jpg');

      // Kompres dulu sebelum disimpan
      final compressed = await FlutterImageCompress.compressWithFile(
        photo.absolute.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 60,
      );

      if (compressed != null) {
        await File(destPath).writeAsBytes(compressed);
      } else {
        // Fallback: copy langsung tanpa kompres
        await photo.copy(destPath);
      }

      log('[OfflinePhoto] Tersimpan: $destPath');
      return destPath;
    } catch (e) {
      log('[OfflinePhoto] Gagal simpan foto: $e');
      return null;
    }
  }

  /// Simpan banyak foto sekaligus.
  /// Returns: `Map<fieldName, localPath>` — null jika foto null/gagal.
  Future<Map<String, String>> savePhotos(
    Map<String, File?> photos,
    String operationType,
  ) async {
    final result = <String, String>{};
    for (final entry in photos.entries) {
      if (entry.value == null) continue;
      final path = await savePhoto(
        entry.value!,
        '${operationType}_${entry.key}',
      );
      if (path != null) {
        result[entry.key] = path;
      }
    }
    return result;
  }

  /// Hapus file foto lokal setelah berhasil di-sync ke server.
  Future<void> deletePhoto(String? localPath) async {
    if (localPath == null) return;
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        log('[OfflinePhoto] Dihapus setelah sync: $localPath');
      }
    } catch (e) {
      log('[OfflinePhoto] Gagal hapus foto: $e');
    }
  }

  /// Hapus beberapa foto sekaligus.
  Future<void> deletePhotos(List<String?> paths) async {
    await Future.wait(paths.map(deletePhoto));
  }

  /// Cek apakah file foto masih ada di storage.
  Future<bool> exists(String localPath) async {
    return File(localPath).exists();
  }

  /// Hapus foto-foto orphan: file di /offline_photos yang lebih tua dari
  /// [maxAgeDays] hari. Dipanggil saat startup untuk membersihkan sisa crash.
  Future<void> cleanupOrphanPhotos({int maxAgeDays = 4}) async {
    try {
      final dir = await _getPhotoDir();
      final files = dir.listSync().whereType<File>().toList();
      final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
      int deleted = 0;

      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
          deleted++;
        }
      }

      if (deleted > 0) {
        log(
          '[OfflinePhoto] Cleanup: $deleted file orphan dihapus (lebih tua dari $maxAgeDays hari).',
        );
      }
    } catch (e) {
      log('[OfflinePhoto] Cleanup gagal: $e');
    }
  }

  /// Hapus foto bukti kunjungan yang sudah disimpan via [VisitDao.savePhotoPaths]
  /// dan lebih tua dari [maxAgeDays]. Set [maxAgeDays] = 0 untuk hapus semua
  /// (manual purge).
  /// Returns: jumlah file yang dihapus.
  Future<int> cleanupOldVisitPhotos(
    AppDatabase db, {
    int maxAgeDays = 4,
  }) async {
    int totalDeleted = 0;
    try {
      final cutoff = maxAgeDays > 0
          ? DateTime.now().subtract(Duration(days: maxAgeDays))
          : DateTime.now().add(const Duration(days: 1));
      final visits = await db.visitDao.getVisitsWithLocalPhotos();

      for (final visit in visits) {
        final raw = visit.localPhotoPaths;
        if (raw == null || raw.isEmpty) continue;
        Map<String, dynamic> parsed;
        try {
          parsed = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        bool anyDeleted = false;
        bool anyRetained = false;
        for (final entry in parsed.entries) {
          final path = entry.value?.toString();
          if (path == null || path.isEmpty) continue;
          final file = File(path);
          if (!await file.exists()) {
            anyDeleted = true;
            continue;
          }
          if (maxAgeDays == 0) {
            await file.delete();
            anyDeleted = true;
            totalDeleted++;
            continue;
          }
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoff)) {
            await file.delete();
            anyDeleted = true;
            totalDeleted++;
          } else {
            anyRetained = true;
          }
        }

        if (anyDeleted && !anyRetained) {
          await db.visitDao.clearLocalPhotoPaths(visit.id);
        }
      }

      if (totalDeleted > 0) {
        log(
          '[OfflinePhoto] Visit photo cleanup: $totalDeleted file dihapus '
          '(maxAgeDays=$maxAgeDays).',
        );
      }
    } catch (e) {
      log('[OfflinePhoto] cleanupOldVisitPhotos gagal: $e');
    }
    return totalDeleted;
  }

  /// Kompres file gambar sebelum upload.
  /// Returns compressed bytes, atau bytes original jika kompresi gagal.
  Future<List<int>?> compressImage(
    File file, {
    int minWidth = 1024,
    int minHeight = 1024,
    int quality = 60,
  }) async {
    try {
      final bytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
      );
      return bytes;
    } catch (_) {
      // Fallback: return original bytes uncompressed
      return file.readAsBytesSync();
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<Directory> _getPhotoDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(appDir.path, _dirName));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }
}
