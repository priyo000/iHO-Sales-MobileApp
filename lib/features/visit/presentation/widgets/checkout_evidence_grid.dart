import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_gap.dart';

/// Photo evidence section for the checkout page.
///
/// Renders the section header (with the "MAKSIMAL 4 FOTO" badge), a 2x2 grid
/// of `_EvidenceCard`s for each evidence slot, and the trailing info note.
class CheckoutEvidenceGrid extends StatelessWidget {
  const CheckoutEvidenceGrid({
    super.key,
    required this.evidencePhotos,
    required this.onPick,
  });

  final Map<String, File?> evidencePhotos;
  final ValueChanged<String> onPick;

  static const _slots = <Map<String, String>>[
    {'key': 'main_entry', 'label': 'TAMPAK DEPAN'},
    {'key': 'shelf_view', 'label': 'DISPLAY RAK'},
    {'key': 'side_view', 'label': 'TAMPAK SAMPING'},
    {'key': 'additional', 'label': 'FOTO LAINNYA'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'BUKTI KUNJUNGAN *',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.error,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const AppBadge(
              label: 'MAKSIMAL 4 FOTO',
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const AppGap.lg(),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          children: _slots.map((slot) {
            final key = slot['key']!;
            return _EvidenceCard(
              label: slot['label']!,
              image: evidencePhotos[key],
              onTap: () => onPick(key),
            );
          }).toList(),
        ),
        const AppGap.xl(),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          borderColor: AppColors.info.withValues(alpha: 0.2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: AppColors.info, size: 20),
              const AppGap.hmd(),
              Expanded(
                child: Text(
                  'Pastikan foto menunjukkan tampak depan toko atau stok '
                  'barang dengan jelas untuk keperluan audit.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.label,
    required this.image,
    required this.onTap,
  });

  final String label;
  final File? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          image: image != null
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  const AppGap.sm(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
