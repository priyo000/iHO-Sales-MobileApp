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
