import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/store_image.dart';

/// Customer summary card shown at the top of the checkout page.
///
/// Displays store image, store/owner name, address, and an "AKTIF" badge.
/// Below it (when distance is loaded) shows a colored distance pill that warns
/// when the salesperson is outside the configured radius tolerance.
class CheckoutCustomerCard extends StatelessWidget {
  const CheckoutCustomerCard({
    super.key,
    required this.pelanggan,
    required this.isLocationLoading,
    required this.currentDistance,
    required this.radiusTolerance,
  });

  final Map<String, dynamic> pelanggan;
  final bool isLocationLoading;
  final double? currentDistance;
  final double radiusTolerance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Row(
            children: [
              StoreImage(
                url: pelanggan['foto_toko_url'],
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                fallbackIconSize: 24,
              ),
              const AppGap.hmd(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pelanggan['nama_toko'] ??
                          pelanggan['nama_pelanggan'] ??
                          pelanggan['nama_pemilik'] ??
                          'Unknown Customer',
                      style: AppTextStyles.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pelanggan['alamat_usaha'] ??
                          pelanggan['alamat'] ??
                          pelanggan['alamat_rumah_pemilik'] ??
                          'Unknown Address',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const AppGap.hsm(),
              const AppBadge(
                label: 'AKTIF',
                color: AppColors.success,
              ),
            ],
          ),
        ),
        const AppGap.lg(),
        _DistanceInfo(
          isLoading: isLocationLoading,
          currentDistance: currentDistance,
          radiusTolerance: radiusTolerance,
        ),
      ],
    );
  }
}

class _DistanceInfo extends StatelessWidget {
  const _DistanceInfo({
    required this.isLoading,
    required this.currentDistance,
    required this.radiusTolerance,
  });

  final bool isLoading;
  final double? currentDistance;
  final double radiusTolerance;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Text(
          'Menghitung jarak...',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    if (currentDistance == null) {
      return const SizedBox.shrink();
    }

    final isOutOfRange = currentDistance! > radiusTolerance;
    final color = isOutOfRange ? AppColors.error : AppColors.success;
    final icon =
        isOutOfRange ? Icons.warning_amber : Icons.check_circle_outline;
    final message = isOutOfRange
        ? 'Peringatan: Jarak Anda ${currentDistance!.toStringAsFixed(0)}m '
            '(Batas: ${radiusTolerance.toStringAsFixed(0)}m)'
        : 'Lokasi Akurat: ${currentDistance!.toStringAsFixed(0)}m dari lokasi';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const AppGap.hmd(),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
