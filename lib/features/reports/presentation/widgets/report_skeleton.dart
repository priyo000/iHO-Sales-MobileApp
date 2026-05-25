import 'package:flutter/material.dart';

import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';

/// Skeleton loading state for the sales performance report page.
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Total Sales Card Skeleton
        const ShimmerLoading(
          width: double.infinity,
          height: 120,
          borderRadius: AppSpacing.radiusXl,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Grid of percentages Skeleton
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: 1.5,
          children: List.generate(
            2,
            (index) => const ShimmerLoading(
              width: double.infinity,
              height: 80,
              borderRadius: AppSpacing.radiusXl,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Chart Skeleton
        const ShimmerLoading(
          width: double.infinity,
          height: 300,
          borderRadius: AppSpacing.radiusXl,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Visit Details Skeleton
        const ShimmerLoading(
          width: double.infinity,
          height: 200,
          borderRadius: AppSpacing.radiusXl,
        ),
      ],
    );
  }
}
