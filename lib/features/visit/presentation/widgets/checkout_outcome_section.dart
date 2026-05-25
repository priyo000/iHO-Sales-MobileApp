import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Section that renders the visit outcome.
///
/// When `ordersExist` is true it shows a small "Checkout dengan Order" success
/// panel. When false it shows the no-order form with the reason radio list and
/// a free-text input that appears when the user picks "Lainnya".
class CheckoutOutcomeSection extends StatelessWidget {
  const CheckoutOutcomeSection({
    super.key,
    required this.ordersExist,
    required this.noOrderReasons,
    required this.selectedReason,
    required this.otherReasonController,
    required this.onReasonSelected,
  });

  final bool ordersExist;
  final List<Map<String, String>> noOrderReasons;
  final String? selectedReason;
  final TextEditingController otherReasonController;
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HASIL KUNJUNGAN',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const AppGap.md(),
        if (ordersExist)
          const _WithOrderPanel()
        else
          _NoOrderForm(
            noOrderReasons: noOrderReasons,
            selectedReason: selectedReason,
            otherReasonController: otherReasonController,
            onReasonSelected: onReasonSelected,
          ),
      ],
    );
  }
}

class _WithOrderPanel extends StatelessWidget {
  const _WithOrderPanel();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      backgroundColor: AppColors.success.withValues(alpha: 0.1),
      borderColor: AppColors.success.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: AppColors.surface,
              size: 16,
            ),
          ),
          const AppGap.hmd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout dengan Order',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Catatan order terdeteksi pada kunjungan ini.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoOrderForm extends StatelessWidget {
  const _NoOrderForm({
    required this.noOrderReasons,
    required this.selectedReason,
    required this.otherReasonController,
    required this.onReasonSelected,
  });

  final List<Map<String, String>> noOrderReasons;
  final String? selectedReason;
  final TextEditingController otherReasonController;
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.remove_shopping_cart,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const AppGap.hmd(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tidak Ada Order',
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Mohon pilih alasan tidak ada pesanan.',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(height: 1),
          ),
          Text(
            'ALASAN TIDAK ORDER *',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const AppGap.md(),
          ...noOrderReasons.map(
            (reason) => _ReasonOption(
              reason: reason,
              isSelected: selectedReason == reason['id'],
              onTap: () => onReasonSelected(reason['id']!),
            ),
          ),
          if (selectedReason == 'other') ...[
            const AppGap.sm(),
            AppTextField(
              controller: otherReasonController,
              hint: 'Ketikkan alasan spesifik...',
              type: AppTextFieldType.multiline,
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, String> reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const AppGap.hmd(),
              Expanded(
                child: Text(
                  reason['label']!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
