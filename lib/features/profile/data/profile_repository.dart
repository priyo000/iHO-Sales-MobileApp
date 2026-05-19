import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_tracker_mobile/core/network/dio_client.dart';
import 'package:sales_tracker_mobile/core/constants/api_constants.dart';
import 'package:sales_tracker_mobile/core/services/connectivity_service.dart';
import 'package:sales_tracker_mobile/core/providers/database_providers.dart';

class ProfileRepository {
  final DioClient _dioClient;
  final ConnectivityService _connectivity;

  ProfileRepository(this._dioClient, this._connectivity);

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Ganti password membutuhkan koneksi aktif (keamanan: tidak boleh di-queue)
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) {
      throw 'Tidak dapat mengubah password saat offline. '
          'Pastikan Anda terhubung ke internet dan coba lagi.';
    }

    final response = await _dioClient.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
    return response['message'] ?? 'Password berhasil diperbarui.';
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.read(dioClientProvider),
    ref.read(connectivityServiceProvider),
  );
});
