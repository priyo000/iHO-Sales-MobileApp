import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
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
    states[Permission.location] =
        statuses[Permission.location]?.isGranted ??
        _permissionStates[Permission.location]!;
    states[Permission.camera] =
        statuses[Permission.camera]?.isGranted ??
        _permissionStates[Permission.camera]!;

    if (isNewAndroid) {
      states[Permission.storage] =
          statuses[Permission.photos]?.isGranted ??
          _permissionStates[Permission.storage]!;
    } else {
      states[Permission.storage] =
          statuses[Permission.storage]?.isGranted ??
          _permissionStates[Permission.storage]!;
    }

    if (mounted) setState(() => _permissionStates = states);

    final allGranted = states.values.every((isGranted) => isGranted);
    if (allGranted) {
      if (mounted) context.go('/login');
    } else {
      // If some permanently denied, show settings dialog
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Icon(
                Icons.security_outlined,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Izin Aplikasi',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sales Tracker membutuhkan izin berikut agar semua fitur (Absensi, Foto, & Rute) berjalan lancar.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                description: 'Untuk validasi titik check-in & tracking rute.',
                isGranted: _permissionStates[Permission.location] ?? false,
              ),
              const SizedBox(height: 20),
              _PermissionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera',
                description: 'Untuk mengambil foto bukti kunjungan & toko.',
                isGranted: _permissionStates[Permission.camera] ?? false,
              ),
              const SizedBox(height: 20),
              _PermissionTile(
                icon: Icons.folder_outlined,
                title: 'Penyimpanan',
                description: 'Untuk menyimpan data & lampiran aplikasi.',
                isGranted: _permissionStates[Permission.storage] ?? false,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Berikan Semua Izin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted ? Colors.green : AppTheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isGranted ? Colors.green[800] : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            const Icon(Icons.circle_outlined, color: Colors.grey),
        ],
      ),
    );
  }
}
