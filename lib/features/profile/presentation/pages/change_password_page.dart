import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';
import 'package:sales_tracker_mobile/core/widgets/app_text_field.dart';

import '../controllers/change_password_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (!_formKey.currentState!.validate()) return;

      await ref
          .read(changePasswordControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      if (!mounted) return;

      final state = ref.read(changePasswordControllerProvider);
      if (state.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.lg,
                ),
                child: Text(
                  'Pastikan password baru Anda kuat dan sulit ditebak untuk keamanan akun.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                shadow: true,
                bordered: false,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _currentPasswordController,
                      label: 'Password Saat Ini',
                      hint: 'Masukkan password saat ini',
                      type: AppTextFieldType.password,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _newPasswordController,
                      label: 'Password Baru',
                      hint: 'Masukkan password baru',
                      type: AppTextFieldType.password,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Password Baru',
                      hint: 'Ulangi password baru',
                      type: AppTextFieldType.password,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v != _newPasswordController.text) {
                          return 'Password tidak cocok';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton.primary(
                label: 'Simpan Perubahan',
                size: AppButtonSize.lg,
                isFullWidth: true,
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
