import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'customer_contact_tile.dart';

class CustomerContactSection extends StatelessWidget {
  final Map<dynamic, dynamic> pelanggan;

  const CustomerContactSection({super.key, required this.pelanggan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Kontak',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              CustomerContactTile(
                icon: Icons.person,
                title: pelanggan['nama_toko'] as String? ??
                    pelanggan['nama_pelanggan'] as String? ??
                    pelanggan['nama_pemilik'] as String? ??
                    'Unknown',
                subtitle: 'Nama Toko/Customer',
              ),
              const Divider(height: 1, indent: 64),
              CustomerContactTile(
                icon: Icons.tag,
                title: pelanggan['kode_pelanggan'] as String? ?? '--',
                subtitle: 'Kode Toko / Pelanggan',
              ),
              const Divider(height: 1, indent: 64),
              CustomerContactTile(
                icon: Icons.phone_android,
                title: pelanggan['no_hp_pribadi'] as String? ??
                    pelanggan['no_hp_kontak'] as String? ??
                    pelanggan['telepon'] as String? ??
                    '--',
                subtitle: 'Nomor Telepon (Tap untuk hubungi)',
                onTap: () {
                  final phone = pelanggan['no_hp_pribadi'] ??
                      pelanggan['no_hp_kontak'] ??
                      pelanggan['telepon'];
                  if (phone != null) {
                    launchUrl(Uri.parse('tel:$phone'));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
