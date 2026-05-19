import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/auth/auth_controller.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/services/app_update_service.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userName =
        user?['karyawan']?['nama_lengkap'] ?? user?['username'] ?? 'User';
    final userPhone =
        user?['karyawan']?['no_hp'] ??
        user?['no_hp'] ??
        user?['karyawan']?['no_telepon'] ??
        '-';
    final userRole = user?['peran']?.toString() == 'super_admin'
        ? 'Super Admin'
        : 'Sales Lapangan';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userRole,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Informasi Aplikasi Section (Moved Up)
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

                    return _buildSection(context, 'Informasi Aplikasi', [
                      _buildSettingItem(
                        context,
                        title: 'Versi Aplikasi',
                        subtitle: 'v$currentVersion ($currentBuild)',
                        icon: Icons.info_outline_rounded,
                        onTap: () => ref.refresh(appUpdateServiceProvider),
                      ),
                      if (hasUpdate) _buildUpdateCard(context, ref, update),
                    ]);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) =>
                      _buildSection(context, 'Informasi Aplikasi', [
                        _buildSettingItem(
                          context,
                          title: 'Cek Update',
                          subtitle: 'Gagal mengecek update: $err',
                          icon: Icons.sync_problem_rounded,
                          onTap: () => ref.refresh(appUpdateServiceProvider),
                        ),
                      ]),
                );
              },
            ),

            const SizedBox(height: 24),

            // Akun Section
            _buildSection(context, 'Informasi Akun', [
              _buildSettingItem(
                context,
                title: 'Kode Karyawan',
                subtitle:
                    user?['karyawan']?['kode_karyawan']?.toString() ?? '-',
                icon: Icons.badge_outlined,
              ),
              _buildSettingItem(
                context,
                title: 'Username',
                subtitle: user?['username'] ?? '-',
                icon: Icons.alternate_email_rounded,
              ),
              _buildSettingItem(
                context,
                title: 'Status Pekerjaan',
                subtitle: user?['karyawan']?['status_karyawan'] ?? 'Aktif',
                icon: Icons.work_outline_rounded,
              ),
              _buildSettingItem(
                context,
                title: 'No. WhatsApp',
                subtitle: userPhone,
                icon: Icons.phone_android_rounded,
              ),
            ]),

            // Keamanan Section
            _buildSection(context, 'Keamanan', [
              _buildSettingItem(
                context,
                title: 'Ganti Password',
                subtitle: 'Update keamanan akun Anda',
                icon: Icons.lock_outline_rounded,
                onTap: () => context.push('/change-password'),
                showChevron: true,
              ),
            ]),

            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showLogoutConfirmation(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Keluar Aplikasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 48),
            // Logo or branding can go here
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

    // Status color mapping
    Color statusColor = Colors.blue;
    String statusText = 'Update Tersedia (v${update['versionName']})';

    if (status == 'PERMISSION_NOT_GRANTED_ERROR') {
      statusColor = Colors.orange;
      statusText = 'Izin Instalasi Ditolak';
    } else if (status == 'DOWNLOAD_ERROR' || status == 'INTERNAL_ERROR') {
      statusColor = Colors.red;
      statusText = 'Gagal Download/Install';
    } else if (status == 'STARTING' || status == 'STREAM_OPENED') {
      statusColor = Colors.blue;
      statusText = 'Menyambung ke Server...';
    } else if (isDownloading) {
      statusColor = Colors.blue;
      statusText = 'Mendownload Update ($progress%)';
    } else if (isInstalling) {
      statusColor = Colors.green;
      statusText = 'Memulai Instalasi...';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update_rounded, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (isForce)
                        const Text(
                          'Update ini wajib diinstal.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (status == 'PERMISSION_NOT_GRANTED_ERROR')
                        const Text(
                          'Silakan izinkan "Install Unknown Apps" untuk aplikasi ini.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
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
              const SizedBox(height: 12),
              Text(
                'Catatan Rilis:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              Text(
                update['releaseNotes'],
                style: TextStyle(fontSize: 12, color: Colors.blue[800]),
              ),
            ],
            const SizedBox(height: 16),
            if (isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      (status == 'DOWNLOADING' ||
                          status == 'STARTING' ||
                          status == 'STREAM_OPENED')
                      ? (double.tryParse(progress.toString()) ?? 0) / 100
                      : (isInstalling ? null : 0),
                  backgroundColor: Colors.blue[100],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sedang mendownload: $progress%',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ] else if (isInstalling) ...[
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Siap menginstal. Tunggu sebentar...',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ] else ...[
              // Only show Button if idle or fatal error
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
                      backgroundColor: status == 'idle'
                          ? Colors.blue
                          : statusColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else
                // Don't show button while active
                const SizedBox.shrink(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppTheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
