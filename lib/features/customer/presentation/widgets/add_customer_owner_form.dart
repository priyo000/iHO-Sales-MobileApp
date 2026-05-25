import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_gap.dart';
import 'package:sales_tracker_mobile/core/widgets/app_text_field.dart';

/// Section A — "Data Calon Pelanggan" form.
class AddCustomerOwnerForm extends StatelessWidget {
  const AddCustomerOwnerForm({
    super.key,
    required this.namaPemilikController,
    required this.noKtpController,
    required this.tempatLahirController,
    required this.tglLahirController,
    required this.npwpController,
    required this.alamatController,
    required this.kodePosController,
    required this.kotaController,
    required this.hpController,
  });

  final TextEditingController namaPemilikController;
  final TextEditingController noKtpController;
  final TextEditingController tempatLahirController;
  final TextEditingController tglLahirController;
  final TextEditingController npwpController;
  final TextEditingController alamatController;
  final TextEditingController kodePosController;
  final TextEditingController kotaController;
  final TextEditingController hpController;

  Future<void> _pickTglLahir(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      tglLahirController.text =
          '${pickedDate.day}-${pickedDate.month}-${pickedDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const AppGap.hxs(),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Tanda ', style: AppTextStyles.bodySmall),
                      TextSpan(
                        text: '*',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' menandakan field wajib diisi',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        AppTextField(
          controller: namaPemilikController,
          label: 'Nama Pemilik',
          prefixIcon: Icons.person,
          required: true,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Nama pemilik wajib diisi' : null,
        ),
        const AppGap.md(),
        AppTextField(
          controller: noKtpController,
          label: 'No. KTP/SIM/Paspor',
          type: AppTextFieldType.number,
          prefixIcon: Icons.badge,
        ),
        const AppGap.md(),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: tempatLahirController,
                label: 'Tempat Lahir',
                prefixIcon: Icons.location_city,
              ),
            ),
            const AppGap.hmd(),
            Expanded(
              child: AppTextField(
                controller: tglLahirController,
                label: 'Tgl Lahir',
                prefixIcon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _pickTglLahir(context),
              ),
            ),
          ],
        ),
        const AppGap.md(),
        AppTextField(
          controller: npwpController,
          label: 'No. NPWP',
          type: AppTextFieldType.number,
          prefixIcon: Icons.confirmation_number,
        ),
        const AppGap.md(),
        AppTextField(
          controller: alamatController,
          label: 'Alamat Rumah',
          type: AppTextFieldType.multiline,
          maxLines: 3,
          minLines: 1,
          prefixIcon: Icons.home,
        ),
        const AppGap.md(),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: kodePosController,
                label: 'Kode Pos',
                type: AppTextFieldType.number,
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
          controller: hpController,
          label: 'Telp/Hp',
          type: AppTextFieldType.phone,
          prefixIcon: Icons.phone_android,
          required: true,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'No HP wajib diisi' : null,
        ),
      ],
    );
  }
}
