import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/constants/payment.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_gap.dart';
import 'package:sales_tracker_mobile/core/widgets/app_text_field.dart';

/// Section B — "Data Tempat Usaha" form.
///
/// The map / GPS picker lives in the middle of this section but is owned
/// by the parent so it can share controllers and notify on location
/// changes. It is passed in via [locationPicker].
class AddCustomerBusinessForm extends StatelessWidget {
  const AddCustomerBusinessForm({
    super.key,
    required this.namaOutletController,
    required this.noNpwpController,
    required this.namaNpwpController,
    required this.jenisProdukController,
    required this.berdiriSejakController,
    required this.alamatController,
    required this.kecamatanController,
    required this.kotaController,
    required this.provinsiController,
    required this.kontakPersonController,
    required this.kontakNoKtpController,
    required this.kontakHpController,
    required this.alamatGudangController,
    required this.bankNamaController,
    required this.bankCabangController,
    required this.bankNoRekController,
    required this.bankAtasNamaController,
    required this.categories,
    required this.klasifikasi,
    required this.onKlasifikasiChanged,
    required this.caraBayar,
    required this.onCaraBayarChanged,
    required this.isContactSameAsOwner,
    required this.onContactSameAsOwnerChanged,
    required this.locationPicker,
  });

  final TextEditingController namaOutletController;
  final TextEditingController noNpwpController;
  final TextEditingController namaNpwpController;
  final TextEditingController jenisProdukController;
  final TextEditingController berdiriSejakController;
  final TextEditingController alamatController;
  final TextEditingController kecamatanController;
  final TextEditingController kotaController;
  final TextEditingController provinsiController;
  final TextEditingController kontakPersonController;
  final TextEditingController kontakNoKtpController;
  final TextEditingController kontakHpController;
  final TextEditingController alamatGudangController;
  final TextEditingController bankNamaController;
  final TextEditingController bankCabangController;
  final TextEditingController bankNoRekController;
  final TextEditingController bankAtasNamaController;

  final List<String> categories;
  final String? klasifikasi;
  final ValueChanged<String?> onKlasifikasiChanged;
  final String caraBayar;
  final ValueChanged<String> onCaraBayarChanged;
  final bool isContactSameAsOwner;
  final ValueChanged<bool> onContactSameAsOwnerChanged;

  /// The map / GPS picker rendered between "Berdiri Sejak" and "Alamat Usaha".
  final Widget locationPicker;

  bool get _showJenisProduk =>
      klasifikasi == 'Big Industry' || klasifikasi == 'Medium Industry';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: namaOutletController,
          label: 'Nama Outlet Usaha',
          prefixIcon: Icons.storefront,
          required: true,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Nama outlet wajib diisi' : null,
        ),
        const AppGap.md(),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: noNpwpController,
                label: 'No. NPWP Usaha',
                type: AppTextFieldType.number,
              ),
            ),
            const AppGap.hmd(),
            Expanded(
              child: AppTextField(
                controller: namaNpwpController,
                label: 'Nama NPWP',
              ),
            ),
          ],
        ),
        const AppGap.md(),
        DropdownButtonFormField<String>(
          initialValue: klasifikasi,
          decoration: const InputDecoration(
            labelText: 'Klasifikasi Outlet (Kategori) *',
          ),
          items: categories
              .map(
                (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
              )
              .toList(),
          onChanged: onKlasifikasiChanged,
          validator: (value) => value == null ? 'Wajib dipilih' : null,
        ),
        if (_showJenisProduk) ...[
          const AppGap.md(),
          AppTextField(
            controller: jenisProdukController,
            label: 'Jenis Produk Industri',
          ),
        ],
        const AppGap.md(),
        AppTextField(
          controller: berdiriSejakController,
          label: 'Berdiri Sejak',
          type: AppTextFieldType.number,
          prefixIcon: Icons.verified_user,
        ),
        locationPicker,
        const AppGap.md(),
        AppTextField(
          controller: alamatController,
          label: 'Alamat Usaha',
          type: AppTextFieldType.multiline,
          maxLines: 3,
          minLines: 1,
          prefixIcon: Icons.business,
          required: true,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Alamat usaha wajib diisi' : null,
        ),
        const AppGap.md(),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: kecamatanController,
                label: 'Kecamatan',
              ),
            ),
            const AppGap.hmd(),
            Expanded(
              child: AppTextField(
                controller: kotaController,
                label: 'Kota',
              ),
            ),
          ],
        ),
        const AppGap.md(),
        AppTextField(
          controller: provinsiController,
          label: 'Provinsi',
        ),
        const AppGap.sm(),
        Row(
          children: [
            Checkbox(
              value: isContactSameAsOwner,
              activeColor: AppColors.primary,
              onChanged: (v) => onContactSameAsOwnerChanged(v ?? false),
            ),
            Expanded(
              child: Text(
                'Samakan dengan data Pemilik',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const AppGap.sm(),
        AppTextField(
          controller: kontakPersonController,
          label: 'Kontak Person',
          prefixIcon: Icons.person_pin,
        ),
        const AppGap.md(),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: kontakNoKtpController,
                label: 'No KTP (Kontak)',
                type: AppTextFieldType.number,
              ),
            ),
            const AppGap.hmd(),
            Expanded(
              child: AppTextField(
                controller: kontakHpController,
                label: 'No HP/Telp',
                type: AppTextFieldType.phone,
              ),
            ),
          ],
        ),
        const AppGap.md(),
        AppTextField(
          controller: alamatGudangController,
          label: 'Alamat Gudang (Jika beda)',
          type: AppTextFieldType.multiline,
          maxLines: 2,
          minLines: 1,
          prefixIcon: Icons.warehouse,
        ),
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            'Cara Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: PaymentMethod.values.map((method) {
            return ChoiceChip(
              label: Text(method.code),
              selected: caraBayar == method.code,
              onSelected: (selected) {
                if (selected) onCaraBayarChanged(method.code);
              },
            );
          }).toList(),
        ),
        if (caraBayar != PaymentMethod.tunai.code) ...[
          const AppGap.md(),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Yang Digunakan',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const AppGap.sm(),
                AppTextField(
                  controller: bankNamaController,
                  label: 'Nama Bank',
                ),
                const AppGap.md(),
                AppTextField(
                  controller: bankCabangController,
                  label: 'Cabang',
                ),
                const AppGap.md(),
                AppTextField(
                  controller: bankNoRekController,
                  label: 'No. Rekening',
                  type: AppTextFieldType.number,
                ),
                const AppGap.md(),
                AppTextField(
                  controller: bankAtasNamaController,
                  label: 'Atas Nama',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
