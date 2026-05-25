import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

class AppGap extends StatelessWidget {
  const AppGap.xs({super.key})
      : _size = AppSpacing.xs,
        _horizontal = false;
  const AppGap.sm({super.key})
      : _size = AppSpacing.sm,
        _horizontal = false;
  const AppGap.md({super.key})
      : _size = AppSpacing.md,
        _horizontal = false;
  const AppGap.lg({super.key})
      : _size = AppSpacing.lg,
        _horizontal = false;
  const AppGap.xl({super.key})
      : _size = AppSpacing.xl,
        _horizontal = false;
  const AppGap.xxl({super.key})
      : _size = AppSpacing.xxl,
        _horizontal = false;
  const AppGap.xxxl({super.key})
      : _size = AppSpacing.xxxl,
        _horizontal = false;

  const AppGap.hxs({super.key})
      : _size = AppSpacing.xs,
        _horizontal = true;
  const AppGap.hsm({super.key})
      : _size = AppSpacing.sm,
        _horizontal = true;
  const AppGap.hmd({super.key})
      : _size = AppSpacing.md,
        _horizontal = true;
  const AppGap.hlg({super.key})
      : _size = AppSpacing.lg,
        _horizontal = true;
  const AppGap.hxl({super.key})
      : _size = AppSpacing.xl,
        _horizontal = true;
  const AppGap.hxxl({super.key})
      : _size = AppSpacing.xxl,
        _horizontal = true;

  final double _size;
  final bool _horizontal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _horizontal ? _size : null,
      height: _horizontal ? null : _size,
    );
  }
}
