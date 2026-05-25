import 'dart:io';

import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/services/image_picker_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_gap.dart';

/// Reusable photo capture tile used for store / KTP photo on the
/// add-customer page.
class AddCustomerPhotoPicker extends StatelessWidget {
  const AddCustomerPhotoPicker({
    super.key,
    required this.title,
    required this.photo,
    required this.onPhotoChanged,
    required this.placeholderIcon,
    required this.placeholderText,
  });

  final String title;
  final File? photo;
  final ValueChanged<File?> onPhotoChanged;
  final IconData placeholderIcon;
  final String placeholderText;

  Future<void> _pick(BuildContext context) async {
    final file = await ImagePickerService.pickImage(context: context);
    if (file != null) {
      onPhotoChanged(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const AppGap.xs(),
              Container(height: 2, width: 40, color: AppColors.primary),
            ],
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
                image: photo != null
                    ? DecorationImage(
                        image: FileImage(photo!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placeholderIcon,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        const AppGap.sm(),
                        Text(
                          placeholderText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
