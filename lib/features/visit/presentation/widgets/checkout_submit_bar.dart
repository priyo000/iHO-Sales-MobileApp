import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// Bottom-anchored submit bar for the checkout page.
///
/// Wraps an `AppButton.primary` in a SafeArea + top-bordered container so the
/// button stays visible above the system inset.
class CheckoutSubmitBar extends StatelessWidget {
  const CheckoutSubmitBar({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton.primary(
            label: isSubmitting
                ? 'Mengirim Data...'
                : 'Kirim Laporan (Checkout)',
            leadingIcon:
                isSubmitting ? null : Icons.check_circle_outline,
            size: AppButtonSize.lg,
            isFullWidth: true,
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : onSubmit,
          ),
        ),
      ),
    );
  }
}
