import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/status_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/store_image.dart';

/// Collapsible SliverAppBar with store photo, status badges, name and address.
class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
    required this.pelanggan,
    required this.imageUrl,
    required this.isUploadingPhoto,
    required this.onUpdatePhotoTap,
    required this.onBackTap,
    required this.onShowFullDetailsTap,
  });

  final Map<String, dynamic> pelanggan;
  final String? imageUrl;
  final bool isUploadingPhoto;
  final VoidCallback onUpdatePhotoTap;
  final VoidCallback onBackTap;
  final VoidCallback onShowFullDetailsTap;

  static String _displayKodePelanggan(dynamic kode) {
    if (kode == null || kode.toString().isEmpty) return 'MENUNGGU SINKRONISASI';
    final str = kode.toString();
    if (str.startsWith('create_pelanggan_') || str.startsWith('local_')) {
      return 'MENUNGGU SINKRONISASI';
    }
    return str;
  }

  static String _statusLabel(String? status) {
    final s = (status ?? 'PROSPECT').toUpperCase();
    return switch (s) {
      'ACTIVE' => 'AKTIF',
      'PENDING' => 'TERTUNDA',
      'PROSPECT' => 'PROSPEK',
      'NONACTIVE' => 'NONAKTIF',
      'REJECTED' => 'DITOLAK',
      _ => s,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = pelanggan['status'] ?? pelanggan['status_pelanggan'];
    final name = pelanggan['nama_toko'] ??
        pelanggan['nama_pelanggan'] ??
        pelanggan['nama_pemilik'] ??
        'Pelanggan Tidak Dikenal';
    final address = pelanggan['alamat_usaha'] ??
        pelanggan['alamat'] ??
        pelanggan['alamat_rumah_pemilik'] ??
        'Alamat Tidak Tersedia';

    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.surface),
        onPressed: onBackTap,
      ),
      actions: [
        TextButton(
          onPressed: onShowFullDetailsTap,
          child: Text(
            'Lihat Data Lengkap',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            StoreImage(
              url: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fallbackIcon: Icons.store_rounded,
              fallbackIconSize: 64,
              fallbackBgColor: AppColors.border,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 70,
              right: AppSpacing.md,
              child: _UpdatePhotoButton(
                isUploading: isUploadingPhoto,
                onTap: onUpdatePhotoTap,
              ),
            ),
            Positioned(
              bottom: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AppBadge(
                          label: _displayKodePelanggan(
                            pelanggan['kode_pelanggan'],
                          ),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: AppBadge(
                          label: _statusLabel(status?.toString()),
                          color: StatusStyles.customerColor(status?.toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    name.toString(),
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.surface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          address.toString(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdatePhotoButton extends StatelessWidget {
  const _UpdatePhotoButton({
    required this.isUploading,
    required this.onTap,
  });

  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          border: Border.all(
            color: AppColors.surface.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUploading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: AppColors.surface,
                  strokeWidth: 1.5,
                ),
              )
            else
              const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.surface,
                size: 14,
              ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              isUploading ? 'Mengunggah...' : 'Update Foto',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
