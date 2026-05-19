import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Mendapatkan list permission yang sesuai dengan versi Android device.
  static Future<List<Permission>> getPlatformPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13 (API 33) ke atas menggunakan granular media permissions
      if (sdkInt >= 33) {
        return [
          Permission.location,
          Permission.camera,
          Permission.photos, // Mapping ke READ_MEDIA_IMAGES
          Permission.videos, // Mapping ke READ_MEDIA_VIDEO
        ];
      }
    }

    // Default / Android 12 ke bawah / Platform lain
    return [
      Permission.location,
      Permission.camera,
      Permission.storage, // Legacy storage permission
    ];
  }

  /// Cek apakah semua permission sudah diberikan
  static Future<bool> checkAllPermissions() async {
    final permissions = await getPlatformPermissions();
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) return false;
    }
    return true;
  }

  /// Request semua permission yang dibutuhkan
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    final permissions = await getPlatformPermissions();
    return await permissions.request();
  }
}
