import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sales_tracker_mobile/core/auth/auth_controller.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/providers/database_providers.dart';
import 'package:sales_tracker_mobile/core/services/app_update_service.dart';
import 'package:sales_tracker_mobile/core/services/offline_photo_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_badge.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_loading.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userName =
        user?['karyawan']?['nama_lengkap'] ?? user?['username'] ?? 'User';
    final userPhone = user?['karyawan']?['no_hp'] ??
        user?['no_hp'] ??
        user?['karyawan']?['no_telepon'] ??
        '-';
    final userRole = user?['peran']?.toString() == 'super_admin'
        ? 'Super Admin'
        : 'Sales Lapangan';

    return AppScaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : '?',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.textOnPrimary,
                        fontSize: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    userName,
                    style: AppTextStyles.headingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppBadge(
                    label: userRole,
                    color: AppColors.primary,
                    size: AppBadgeSize.md,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Consumer(
              builder: (context, ref, _) {
                final updateAsync = ref.watch(appUpdateServiceProvider);
                return updateAsync.when(
                  data: (update) {
                    final hasUpdate = update['hasUpdate'] == true;
                    final currentVersion =
                        (update['currentVersion'] as String?) ?? '-';
                    final currentBuild =
                        (update['currentBuild'] as String?) ?? '-';

                    return _buildSection('Informasi Aplikasi', [
                      _buildSettingItem(
                        title: 'Versi Aplikasi',
                        subtitle: 'v$currentVersion ($currentBuild)',
                        icon: Icons.info_outline_rounded,
                        onTap: () => ref.refresh(appUpdateServiceProvider),
                      ),
                      if (hasUpdate) _buildUpdateCard(context, ref, update),
                    ]);
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: AppLoading(),
                  ),
                  error: (err, _) => _buildSection('Informasi Aplikasi', [
                    _buildSettingItem(
                      title: 'Cek Update',
                      subtitle: 'Gagal mengecek update: $err',
                      icon: Icons.sync_problem_rounded,
                      onTap: () => ref.refresh(appUpdateServiceProvider),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSection('Informasi Akun', [
              _buildSettingItem(
                title: 'Kode Karyawan',
                subtitle:
                    user?['karyawan']?['kode_karyawan']?.toString() ?? '-',
                icon: Icons.badge_outlined,
              ),
              _buildSettingItem(
                title: 'Username',
                subtitle: user?['username'] ?? '-',
                icon: Icons.alternate_email_rounded,
              ),
              _buildSettingItem(
                title: 'Status Pekerjaan',
                subtitle: user?['karyawan']?['status_karyawan'] ?? 'Aktif',
                icon: Icons.work_outline_rounded,
              ),
              _buildSettingItem(
                title: 'No. WhatsApp',
                subtitle: userPhone,
                icon: Icons.phone_android_rounded,
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _buildSection('Keamanan', [
              _buildSettingItem(
                title: 'Ganti Password',
                subtitle: 'Update keamanan akun Anda',
                icon: Icons.lock_outline_rounded,
                onTap: () => context.push('/change-password'),
                showChevron: true,
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _buildSection('Penyimpanan', [
              _buildSettingItem(
                title: 'Bersihkan Cache Foto',
                subtitle:
                    'Hapus foto bukti kunjungan yang sudah tersinkron dari perangkat',
                icon: Icons.photo_library_outlined,
                onTap: () => _confirmClearPhotoCache(context, ref),
                showChevron: true,
              ),
            ]),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmation(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Keluar Aplikasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  textStyle: AppTextStyles.button.copyWith(
                    color: AppColors.error,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> update,
  ) {
    final status = update['status'] ?? 'idle';
    final progress = update['progress'] ?? '0';
    final isDownloading = status == 'DOWNLOADING';
    final isInstalling = status == 'INSTALLING';
    final isForce = update['isForce'] == true;

    Color statusColor = AppColors.info;
    String statusText = 'Update Tersedia (v${update['versionName']})';

    if (status == 'PERMISSION_NOT_GRANTED_ERROR') {
      statusColor = AppColors.warning;
      statusText = 'Izin Instalasi Ditolak';
    } else if (status == 'DOWNLOAD_ERROR' || status == 'INTERNAL_ERROR') {
      statusColor = AppColors.error;
      statusText = 'Gagal Download/Install';
    } else if (status == 'STARTING' || status == 'STREAM_OPENED') {
      statusText = 'Menyambung ke Server...';
    } else if (isDownloading) {
      statusText = 'Mendownload Update ($progress%)';
    } else if (isInstalling) {
      statusColor = AppColors.success;
      statusText = 'Memulai Instalasi...';
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColors.info.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: AppTextStyles.titleMedium
                            .copyWith(color: statusColor),
                      ),
                      if (isForce)
                        Text(
                          'Update ini wajib diinstal.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (status == 'PERMISSION_NOT_GRANTED_ERROR')
                        Text(
                          'Silakan izinkan "Install Unknown Apps" untuk aplikasi ini.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (update['releaseNotes'] != null &&
                update['releaseNotes'].toString().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Catatan Rilis:',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              Text(
                update['releaseNotes'],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.info,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: (status == 'DOWNLOADING' ||
                          status == 'STARTING' ||
                          status == 'STREAM_OPENED')
                      ? (double.tryParse(progress.toString()) ?? 0) / 100
                      : (isInstalling ? null : 0),
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sedang mendownload: $progress%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.info,
                ),
              ),
            ] else if (isInstalling) ...[
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Siap menginstal. Tunggu sebentar...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ] else ...[
              if (status == 'idle' ||
                  status == 'PERMISSION_NOT_GRANTED_ERROR' ||
                  status.contains('ERROR'))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(appUpdateServiceProvider.notifier)
                        .downloadAndInstall(update['downloadUrl']),
                    icon: Icon(
                      status == 'idle'
                          ? Icons.download_rounded
                          : Icons.refresh_rounded,
                      size: 18,
                    ),
                    label: Text(
                      status == 'idle'
                          ? 'Download & Update Sekarang'
                          : 'Coba Lagi',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          status == 'idle' ? AppColors.info : statusColor,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.md,
          ),
          child: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          shadow: true,
          bordered: false,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.titleMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: showChevron
          ? const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }

  void _confirmClearPhotoCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Bersihkan Cache Foto?'),
        content: const Text(
          'Semua foto bukti kunjungan yang sudah tersinkron ke server akan dihapus dari perangkat. Foto tetap tersimpan di server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Membersihkan cache foto...')),
              );
              try {
                final db = ref.read(appDatabaseProvider);
                final service = ref.read(offlinePhotoServiceProvider);
                final deleted = await service.cleanupOldVisitPhotos(
                  db,
                  maxAgeDays: 0,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      deleted > 0
                          ? '$deleted foto dihapus, ruang disk dibebaskan.'
                          : 'Tidak ada foto cache untuk dihapus.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal bersihkan cache: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Bersihkan', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Anda perlu login kembali untuk mengakses data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Ya, Keluar',
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }
}
