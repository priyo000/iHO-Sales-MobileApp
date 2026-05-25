import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';

/// Inline status banner for the report screen.
///
/// Surfaces two cases:
///  - [isEmpty] true  → offline + no cached data warning (warning palette).
///  - [isCached] true → showing cached data (info palette).
class ReportOfflineBanner extends StatelessWidget {
  const ReportOfflineBanner({
    super.key,
    required this.isEmpty,
    required this.isCached,
    this.emptyMessage =
        'Offline & belum ada cache. Buka laporan saat online dulu.',
    this.cachedMessage = 'Menampilkan data terakhir dari cache lokal.',
  });

  final bool isEmpty;
  final bool isCached;
  final String emptyMessage;
  final String cachedMessage;

  @override
  Widget build(BuildContext context) {
    if (!isEmpty && !isCached) return const SizedBox.shrink();

    final accent = isEmpty ? AppColors.warning : AppColors.info;
    final icon =
        isEmpty ? Icons.wifi_off_rounded : Icons.history_rounded;
    final message = isEmpty ? emptyMessage : cachedMessage;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}
