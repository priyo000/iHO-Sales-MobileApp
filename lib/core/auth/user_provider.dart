import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() {
    _loadAndRefresh();
    return null;
  }

  /// Load from cache only — server refresh is handled by PreloadService.
  Future<void> _loadAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      state = jsonDecode(userData);
    }
  }

  void setUser(Map<String, dynamic>? user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

final userProvider = NotifierProvider<UserNotifier, Map<String, dynamic>?>(
  UserNotifier.new,
);

/// Derived provider: apakah divisi sales ini mengizinkan open price.
/// Default true (backward compatible) jika data divisi belum ada.
final allowOpenPriceProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  final divisi = user?['karyawan']?['divisi'];
  if (divisi == null) return true;
  return divisi['allow_open_price'] as bool? ?? true;
});

/// Build a stable, opaque owner key for the cached user session.
///
/// Used to stamp offline sync-queue mutations so a queue created by one login
/// is never silently flushed under a different user's credentials on the same
/// device. Format is versioned (`v1|...`) so it can evolve without colliding
/// with legacy null-owned rows.
String? buildSyncOwnerKey(Map<String, dynamic>? user) {
  if (user == null) return null;
  final companyId = user['id_perusahaan']?.toString() ??
      user['company_id']?.toString() ??
      user['companyId']?.toString();
  final divisionId = user['karyawan']?['id_divisi']?.toString() ??
      user['id_divisi']?.toString() ??
      user['divisionId']?.toString();
  final userId = user['id']?.toString() ??
      user['karyawan']?['id']?.toString() ??
      user['employee_id']?.toString();
  if (companyId == null && divisionId == null && userId == null) return null;
  return 'v1|$companyId|$divisionId|$userId';
}
