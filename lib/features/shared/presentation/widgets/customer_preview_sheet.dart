import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerPreviewSheet extends StatelessWidget {
  final Map<String, dynamic> scheduleItem;
  final double? distanceInKm;

  const CustomerPreviewSheet({
    super.key,
    required this.scheduleItem,
    this.distanceInKm,
  });

  @override
  Widget build(BuildContext context) {
    final pelanggan = scheduleItem['pelanggan'] ?? {};
    final String name =
        pelanggan['nama_toko'] ??
        pelanggan['nama_pemilik'] ??
        'Unknown Customer';
    final String address = pelanggan['alamat_usaha'] ?? 'No address provided';
    final String? phone = pelanggan['telepon'];
    final String status = (scheduleItem['status_kunjungan'] ?? 'TERTUNDA')
        .toString()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header: Name & Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PELANGGAN AKTIF',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (distanceInKm != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${distanceInKm!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 24),

          // Address Section
          const Text(
            'ALAMAT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.map_outlined, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions Row (Call, Mail, Maps)
          Row(
            children: [
              _QuickActionCircle(
                icon: Icons.phone_outlined,
                label: 'Telepon',
                onTap: () => _launchPhone(phone),
                isEnabled: phone != null && phone.isNotEmpty,
              ),
              const SizedBox(width: 16),
              _QuickActionCircle(
                icon: Icons.directions_outlined,
                label: 'Rute',
                onTap: () => _launchMaps(
                  pelanggan['latitude'],
                  pelanggan['longitude'],
                  name,
                ),
              ),
              const SizedBox(width: 16),
              _QuickActionCircle(
                icon: Icons.info_outline,
                label: 'Detail',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/customers/detail', extra: scheduleItem);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/customers/detail', extra: scheduleItem);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'MULAI KUNJUNGAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.orange.withValues(alpha: 0.1);
    Color text = Colors.orange;

    if (status == 'DIKUNJUNGI' || status == 'SELESAI') {
      bg = Colors.green.withValues(alpha: 0.1);
      text = Colors.green;
    } else if (status == 'DIBATALKAN') {
      bg = Colors.red.withValues(alpha: 0.1);
      text = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _launchPhone(String? phone) async {
    if (phone == null) return;
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchMaps(dynamic lat, dynamic lng, String name) async {
    if (lat == null || lng == null) return;
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

class _QuickActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEnabled;

  const _QuickActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textDark, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
