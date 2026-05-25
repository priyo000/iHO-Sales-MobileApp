import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppBadgeSize { sm, md }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.size = AppBadgeSize.sm,
    this.outlined = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final AppBadgeSize size;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    final fg = outlined ? base : AppColors.textOnPrimary;
    final bg = outlined ? base.withValues(alpha: 0.08) : base;

    final padding = size == AppBadgeSize.sm
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2)
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs);
    final iconSize = size == AppBadgeSize.sm ? 12.0 : 14.0;
    final textStyle = (size == AppBadgeSize.sm
            ? AppTextStyles.caption
            : AppTextStyles.bodySmall)
        .copyWith(color: fg, fontWeight: FontWeight.w600);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: outlined ? Border.all(color: base) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
