import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/dio_client.dart';
import '../constants/api_constants.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';

const _allowedUpdateHosts = {'app.intigroup.top'};

final appUpdateServiceProvider =
    StateNotifierProvider<AppUpdateService, AsyncValue<Map<String, dynamic>>>(
      (ref) => AppUpdateService(),
    );

class AppUpdateService extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  AppUpdateService() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.data({
      'hasUpdate': false,
      'status': 'idle',
      'progress': '0',
    });
    await checkUpdate();
  }

  Future<void> checkUpdate() async {
    try {
      final dio = DioClient();
      final response = await dio.get(
        '${ApiConstants.baseUrl}/app-update/check',
      );
      if (response != null &&
          response['status'] == 'success' &&
          response['data'] != null) {
        final backendData = response['data'] as Map<String, dynamic>;
        final packageInfo = await PackageInfo.fromPlatform();

        final int backendVersionCode =
            int.tryParse(backendData['version_code'].toString()) ?? 0;
        final int currentVersionCode =
            int.tryParse(packageInfo.buildNumber) ?? 0;

        final Map<String, dynamic> updateInfo = {
          'hasUpdate': backendVersionCode > currentVersionCode,
          'versionName': backendData['version_name'],
          'versionCode': backendVersionCode,
          'downloadUrl': backendData['download_url'],
          'releaseNotes': backendData['release_notes'],
          'isForce':
              backendData['is_force'] == 1 || backendData['is_force'] == true,
          'currentVersion': packageInfo.version,
          'currentBuild': packageInfo.buildNumber,
          'status': 'idle',
          'progress': '0',
        };
        state = AsyncValue.data(updateInfo);
        return;
      }
    } catch (e) {
      // Quietly fail
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      state = AsyncValue.data({
        'hasUpdate': false,
        'currentVersion': packageInfo.version,
        'currentBuild': packageInfo.buildNumber,
        'status': 'idle',
        'progress': '0',
      });
    } catch (_) {
      state = const AsyncValue.data({'hasUpdate': false});
    }
  }

  void downloadAndInstall(String url) async {
    final parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        !_allowedUpdateHosts.contains(parsedUrl.host)) {
      final currentData = state.value ?? {};
      state = AsyncValue.data({
        ...currentData,
        'status': 'INVALID_DOWNLOAD_URL',
      });
      return;
    }

    log('Checking permission for OTA update...');

    // Explicitly try to request permission for Install Unknown Apps
    final status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      log(
        'Permission not granted! Requesting specifically for Install Unknown Apps...',
      );
      final result = await Permission.requestInstallPackages.request();
      if (!result.isGranted) {
        log('User denied or did not allow install from unknown sources');
        final currentData = state.value ?? {};
        state = AsyncValue.data({
          ...currentData,
          'status': 'PERMISSION_NOT_GRANTED_ERROR',
          'progress': '0',
        });
        return;
      }
    }

    try {
      final currentData = state.value ?? {};
      state = AsyncValue.data({
        ...currentData,
        'status': 'STARTING',
        'progress': '0',
      });

      log('Executing OTA update with URL: $url');
      OtaUpdate()
          .execute(url)
          .listen(
            (OtaEvent event) {
              final currentData = state.value ?? {};
              log('OTA Status: ${event.status.name}, Value: ${event.value}');

              state = AsyncValue.data({
                ...currentData,
                'status': event.status.name,
                'progress':
                    event.value ??
                    (event.status == OtaStatus.DOWNLOADING
                        ? '0'
                        : currentData['progress']),
              });
            },
            onError: (e) {
              log('OTA Stream Error: $e');
              final currentData = state.value ?? {};
              state = AsyncValue.data({
                ...currentData,
                'status': 'DOWNLOAD_ERROR',
                'progress': '0',
              });
            },
          );
    } catch (e) {
      log('OTA Execute Catch: $e');
      final currentData = state.value ?? {};
      state = AsyncValue.data({
        ...currentData,
        'status': 'INTERNAL_ERROR',
        'progress': '0',
      });
    }
  }
}
