import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';

// State untuk proses change password
class ChangePasswordState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ChangePasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      // Parse pesan error dari server jika tersedia
      final raw = e.toString();
      String message = 'Terjadi kesalahan. Coba lagi.';
      if (raw.contains('Password saat ini tidak sesuai')) {
        message = 'Password saat ini tidak sesuai.';
      } else if (raw.contains('422')) {
        message = 'Password baru minimal 6 karakter.';
      } else if (raw.contains('Unauthorized')) {
        message = 'Sesi habis, silakan login kembali.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  void reset() {
    state = const ChangePasswordState();
  }
}

final changePasswordControllerProvider =
    NotifierProvider<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );
