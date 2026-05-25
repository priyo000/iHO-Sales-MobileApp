import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  double get _height => switch (size) {
        AppButtonSize.sm => 36,
        AppButtonSize.md => 48,
        AppButtonSize.lg => 56,
      };

  EdgeInsetsGeometry get _padding => switch (size) {
        AppButtonSize.sm => const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
        AppButtonSize.md => const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
        AppButtonSize.lg => const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
      };

  double get _iconSize => switch (size) {
        AppButtonSize.sm => 16,
        AppButtonSize.md => 20,
        AppButtonSize.lg => 24,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final colors = _resolveColors(disabled);

    final child = isLoading
        ? SizedBox(
            height: _iconSize,
            width: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: _iconSize, color: colors.foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: colors.foreground,
                    fontSize: size == AppButtonSize.sm ? 13 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: _iconSize, color: colors.foreground),
              ],
            ],
          );

    final button = Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border, width: colors.borderWidth),
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: _height,
          padding: _padding,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: button,
    );
  }

  _ButtonColors _resolveColors(bool disabled) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          background: disabled
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.primary,
          foreground: AppColors.textOnPrimary,
          border: Colors.transparent,
          borderWidth: 0,
        );
      case AppButtonVariant.secondary:
        return _ButtonColors(
          background: AppColors.surface,
          foreground:
              disabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary,
          border:
              disabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary,
          borderWidth: 1.5,
        );
      case AppButtonVariant.destructive:
        return _ButtonColors(
          background: disabled
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.error,
          foreground: AppColors.textOnPrimary,
          border: Colors.transparent,
          borderWidth: 0,
        );
      case AppButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          foreground:
              disabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary,
          border: Colors.transparent,
          borderWidth: 0,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderWidth,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final double borderWidth;
}
