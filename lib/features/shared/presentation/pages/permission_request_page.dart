import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';

import '../../../../core/permission/permission_service.dart';

class PermissionRequestPage extends StatefulWidget {
  const PermissionRequestPage({super.key});

  @override
  State<PermissionRequestPage> createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> {
  Map<Permission, bool> _permissionStates = {
    Permission.location: false,
    Permission.camera: false,
    Permission.storage: false,
  };

  @override
  void initState() {
    super.initState();
    _checkInitialStates();
  }

  Future<void> _checkInitialStates() async {
    final isNewAndroid =
        await Permission.photos.status != PermissionStatus.denied;
    final Map<Permission, bool> states = {};

    states[Permission.location] = await Permission.location.isGranted;
    states[Permission.camera] = await Permission.camera.isGranted;

    if (isNewAndroid) {
      states[Permission.storage] = await Permission.photos.isGranted;
    } else {
      states[Permission.storage] = await Permission.storage.isGranted;
    }

    if (mounted) setState(() => _permissionStates = states);
  }

  Future<void> _requestPermissions() async {
    final statuses = await PermissionService.requestAll();
    final isNewAndroid =
        await Permission.photos.status != PermissionStatus.denied;

    final Map<Permission, bool> states = {};
    states[Permission.location] = statuses[Permission.location]?.isGranted ??
        _permissionStates[Permission.location]!;
    states[Permission.camera] = statuses[Permission.camera]?.isGranted ??
        _permissionStates[Permission.camera]!;

    if (isNewAndroid) {
      states[Permission.storage] = statuses[Permission.photos]?.isGranted ??
          _permissionStates[Permission.storage]!;
    } else {
      states[Permission.storage] = statuses[Permission.storage]?.isGranted ??
          _permissionStates[Permission.storage]!;
    }

    if (mounted) setState(() => _permissionStates = states);

    final allGranted = states.values.every((isGranted) => isGranted);
    if (allGranted) {
      if (mounted) context.go('/login');
    } else {
      bool hasPermanentlyDenied = false;
      statuses.forEach((permission, status) {
        if (status.isPermanentlyDenied) {
          hasPermanentlyDenied = true;
        }
      });

      if (hasPermanentlyDenied && mounted) {
        _showSettingsDialog();
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
          'Beberapa izin penting ditolak secara permanen. Silakan aktifkan manual di Settings untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Buka Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              const Icon(
                Icons.security_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Izin Aplikasi', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sales Tracker membutuhkan izin berikut agar semua fitur (Absensi, Foto, & Rute) berjalan lancar.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                description: 'Untuk validasi titik check-in & tracking rute.',
                isGranted: _permissionStates[Permission.location] ?? false,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PermissionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera',
                description: 'Untuk mengambil foto bukti kunjungan & toko.',
                isGranted: _permissionStates[Permission.camera] ?? false,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PermissionTile(
                icon: Icons.folder_outlined,
                title: 'Penyimpanan',
                description: 'Untuk menyimpan data & lampiran aplikasi.',
                isGranted: _permissionStates[Permission.storage] ?? false,
              ),
              const Spacer(),
              AppButton.primary(
                label: 'Berikan Semua Izin',
                size: AppButtonSize.lg,
                isFullWidth: true,
                onPressed: _requestPermissions,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isGranted
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.divider,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted ? AppColors.success : AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color:
                        isGranted ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppColors.success)
          else
            const Icon(Icons.circle_outlined, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
