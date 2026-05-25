import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.bordered = true,
    this.borderColor,
    this.borderRadius,
    this.elevation = 0,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool bordered;
  final Color? borderColor;
  final BorderRadiusGeometry? borderRadius;
  final double elevation;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    final bg = backgroundColor ?? AppColors.surface;

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius is BorderRadius ? radius : null,
        child: content,
      );
    }

    final decoration = BoxDecoration(
      color: bg,
      borderRadius: radius,
      border: bordered
          ? Border.all(color: borderColor ?? AppColors.border)
          : null,
      boxShadow: shadow
          ? [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
