import 'package:flutter/material.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/utils/formatters.dart';

class CustomerDetailInfoSheet extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  final ScrollController? scrollController;

  const CustomerDetailInfoSheet({
    super.key,
    required this.data,
    this.scrollController,
  });

  /// Display the customer info as a draggable bottom sheet.
  static Future<void> show(BuildContext context, Map<dynamic, dynamic> data) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Detail Lengkap', style: AppTextStyles.headingMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomerDetailInfoSheet(
                  data: data,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildSection('Identitas', [
          _buildRow('Kode', data['kode_pelanggan']),
          _buildRow('Nama Toko', data['nama_toko'] ?? data['nama_pelanggan']),
          _buildRow('Nama Pemilik', data['nama_pemilik']),
          _buildRow('Status', data['status_pelanggan'] ?? data['status']),
          _buildRow('NPWP', data['npwp']),
          _buildRow('NIK Pemilik', data['nik_pemilik']),
        ]),
        _buildSection('Kontak', [
          _buildRow('Telepon', data['telepon']),
          _buildRow('No HP Pribadi', data['no_hp_pribadi']),
          _buildRow('No HP Kontak', data['no_hp_kontak']),
          _buildRow('Fax', data['fax']),
          _buildRow('Email', data['email']),
        ]),
        _buildSection('Alamat', [
          _buildRow('Alamat', data['alamat']),
          _buildRow('Alamat Usaha', data['alamat_usaha']),
          _buildRow('Alamat Rumah', data['alamat_rumah_pemilik']),
          _buildRow('Kelurahan', data['kelurahan']),
          _buildRow('Kecamatan', data['kecamatan']),
          _buildRow('Kota/Kab', data['kota']),
          _buildRow('Provinsi', data['provinsi']),
          _buildRow('Kode Pos', data['kode_pos']),
          if (data['latitude'] != null)
            _buildRow('Koordinat', '${data['latitude']}, ${data['longitude']}'),
        ]),
        _buildSection('Finansial', [
          _buildRow('Sistem Pembayaran', data['sistem_pembayaran']),
          _buildRow('Cara Pembayaran', data['cara_pembayaran']),
          _buildRow(
            'Limit Kredit Awal',
            data['limit_kredit_awal'] != null
                ? 'Rp ${Formatters.number(data['limit_kredit_awal'])}'
                : null,
          ),
          _buildRow(
            'Limit Kredit Sisa',
            data['limit_kredit_sisa'] != null
                ? 'Rp ${Formatters.number(data['limit_kredit_sisa'])}'
                : null,
          ),
          _buildRow(
            'TOP (Hari)',
            data['top_hari'] != null ? '${data['top_hari']} Hari' : null,
          ),
        ]),
        _buildSection('Lainnya', [
          _buildRow('Hari Kunjungan', data['hari_kunjungan']),
          _buildRow('Frekuensi', data['frekuensi_kunjungan']),
          _buildRow('Kunjungan Terakhir', _formatLastVisitDate(data['last_visit_date'])),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  String? _formatLastVisitDate(dynamic value) {
    if (value == null) return null;
    return Formatters.dateFromString(value.toString());
  }

  Widget _buildSection(String title, List<Widget> children) {
    final validChildren = children.where((c) => c is! SizedBox).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: validChildren.asMap().entries.map((entry) {
              final index = entry.key;
              final widget = entry.value;
              final isLast = index == validChildren.length - 1;
              return DecoratedBox(
                decoration: isLast
                    ? const BoxDecoration()
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                child: widget,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRow(String label, dynamic value) {
    if (value == null ||
        value.toString().isEmpty ||
        value.toString() == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
