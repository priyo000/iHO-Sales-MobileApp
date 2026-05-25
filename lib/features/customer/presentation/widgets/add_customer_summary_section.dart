import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/constants/payment.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/widgets/app_gap.dart';
import 'package:sales_tracker_mobile/core/widgets/app_text_field.dart';

/// Section C — "Diisi Oleh Salesman" form (sistem pembayaran, limit kredit,
/// TOP, lain-lain).
class AddCustomerSummarySection extends StatelessWidget {
  const AddCustomerSummarySection({
    super.key,
    required this.kreditAwalController,
    required this.kreditBerjalanController,
    required this.topController,
    required this.lainLainController,
    required this.sistemBayar,
    required this.onSistemBayarChanged,
  });

  final TextEditingController kreditAwalController;
  final TextEditingController kreditBerjalanController;
  final TextEditingController topController;
  final TextEditingController lainLainController;
  final String sistemBayar;
  final ValueChanged<String> onSistemBayarChanged;

  @override
  Widget build(BuildContext context) {
    final isCredit = sistemBayar == PaymentSystem.credit.code;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
          child: Text(
            'Sistem Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: [
            ChoiceChip(
              label: Text(PaymentSystem.cash.code),
              selected: sistemBayar == PaymentSystem.cash.code,
              onSelected: (_) => onSistemBayarChanged(PaymentSystem.cash.code),
            ),
            const AppGap.hsm(),
            ChoiceChip(
              label: Text(PaymentSystem.credit.code),
              selected: sistemBayar == PaymentSystem.credit.code,
              onSelected: (_) =>
                  onSistemBayarChanged(PaymentSystem.credit.code),
            ),
          ],
        ),
        if (isCredit) ...[
          const AppGap.md(),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: kreditAwalController,
                  label: 'Limit Awal (Rp)',
                  type: AppTextFieldType.number,
                ),
              ),
              const AppGap.hmd(),
              Expanded(
                child: AppTextField(
                  controller: kreditBerjalanController,
                  label: 'Limit Berjalan (Rp)',
                  type: AppTextFieldType.number,
                ),
              ),
            ],
          ),
          const AppGap.md(),
          AppTextField(
            controller: topController,
            label: 'Term Of Payment / TOP (Hari)',
            type: AppTextFieldType.number,
          ),
        ],
        const AppGap.md(),
        AppTextField(
          controller: lainLainController,
          label: 'Lain-lain',
          type: AppTextFieldType.multiline,
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }
}
