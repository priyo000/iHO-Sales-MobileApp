import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../services/push_notification_service.dart';
import '../providers/database_providers.dart';
import 'user_provider.dart';

final authProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          'device_name': 'Mobile App',
        },
      );

      final token = response['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Server returned no access token');
      }
      final refreshToken = response['refresh_token'] as String?;
      final user = response['user'] as Map<String, dynamic>;
      final permissions = response['permissions'] as List<dynamic>?;

      final prefs = await SharedPreferences.getInstance();
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.write(token);
      if (refreshToken != null) {
        await tokenStorage.writeRefreshToken(refreshToken);
      }
      await prefs.setString('user_data', jsonEncode(user));
      if (permissions != null) {
        await prefs.setStringList(
          'user_permissions',
          permissions.map((e) => e.toString()).toList(),
        );
      }

      ref.read(userProvider.notifier).setUser(user);

      try {
        final fcmToken = await PushNotificationService.getToken();
        if (fcmToken != null) {
          await apiClient.post(
            ApiConstants.saveFcmToken,
            data: {'fcm_token': fcmToken},
          );
        }
      } catch (e) {
        log('Failed to save FCM token: $e');
      }
    });
  }

  /// Refresh user data from server — called on app startup to ensure
  /// freshly loaded profile fields (e.g. no_hp, kode_karyawan).
  Future<void> refreshUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await ref.read(tokenStorageProvider).read();
      if (token == null) return;

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.me);
      final user = response['user'];
      if (user != null) {
        await prefs.setString('user_data', jsonEncode(user));
        ref.read(userProvider.notifier).setUser(user);
        log('User data refreshed from server.');
      }
    } catch (e) {
      // Silent fail — use cached data if server unreachable
      log('User refresh failed (offline?): $e');
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await ref.read(tokenStorageProvider).clear();
      await prefs.clear();

      final db = ref.read(appDatabaseProvider);
      try { await db.clearAllDomainData(); } catch (e) { log('logout: clearAllDomainData failed: $e'); }
      try { await db.clearAllCache(); } catch (e) { log('logout: clearAllCache failed: $e'); }
      try { await db.clearQueue(); } catch (e) { log('logout: clearQueue failed: $e'); }

      ref.read(userProvider.notifier).clearUser();
    });
  }

  bool _expiredLogoutInProgress = false;

  /// Auto-logout saat token/refresh-token tidak bisa di-recover (session habis).
  /// Berbeda dari [logout]: TIDAK clear sync_queue supaya mutasi offline yang
  /// belum terkirim tetap aman dan akan di-flush setelah user login ulang.
  Future<void> logoutDueToSessionExpired() async {
    if (_expiredLogoutInProgress) return;
    if (ref.read(userProvider) == null) {
      final hasToken = await ref.read(tokenStorageProvider).hasToken();
      if (!hasToken) return;
    }
    _expiredLogoutInProgress = true;
    try {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        final prefs = await SharedPreferences.getInstance();
        await ref.read(tokenStorageProvider).clear();
        await prefs.remove('user_data');
        await prefs.remove('user_permissions');
        await prefs.setBool('session_expired_flag', true);

        final db = ref.read(appDatabaseProvider);
        try { await db.clearAllDomainData(); } catch (e) { log('expiredLogout: clearAllDomainData failed: $e'); }
        try { await db.clearAllCache(); } catch (e) { log('expiredLogout: clearAllCache failed: $e'); }

        ref.read(userProvider.notifier).clearUser();
      });
    } finally {
      _expiredLogoutInProgress = false;
    }
  }
}
