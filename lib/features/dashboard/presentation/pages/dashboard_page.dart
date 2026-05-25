import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/services/download_status_service.dart';
import 'package:sales_tracker_mobile/core/services/preload_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/utils/formatters.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';
import 'package:sales_tracker_mobile/features/notifications/presentation/controllers/notifications_controller.dart';

import '../controllers/dashboard_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatDate(DateTime date) =>
      Formatters.date(date, pattern: 'EEEE, d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    final userName =
        user?['karyawan']?['nama_lengkap'] ?? user?['username'] ?? 'User';
    final userRole = user?['peran']?.toString() == 'super_admin'
        ? 'Super Admin'
        : 'Sales Lapangan';

    return AppScaffold(
      body: dashboardState.when(
        skipLoadingOnRefresh: true,
        loading: () => const _DashboardSkeleton(),
        error: (err, stack) => AppErrorView(
          message: 'Gagal memuat dashboard: $err',
          onRetry: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
        data: (data) {
          final targetKunjungan = data['target_kunjungan'] ?? 0;
          final kunjunganRuteSelesai = data['kunjungan_rute_selesai'] ?? 0;
          final luarRute = data['luar_rute'] ?? 0;
          final pelangganBaruBulanIni = data['pelanggan_baru_hari_ini'] ?? 0;
          final prospekHariIni = data['prospek_hari_ini'] ?? 0;
          final totalOrderHariIni = data['total_order_hari_ini'] ?? 0;
          final hitRatePercentage = data['hit_rate_percentage'] ?? 0;

          final targetProgress = targetKunjungan > 0
              ? (kunjunganRuteSelesai / targetKunjungan)
              : 0.0;

          final orderGrowthText = "$hitRatePercentage% Effective Call";
          final orderGrowthColor =
              hitRatePercentage > 0 ? AppColors.success : AppColors.textMuted;

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, userName, userRole),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _formatDate(DateTime.now()),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _PreloadStatusCard(),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        title: 'Kunjungan Rute',
                        value: '$kunjunganRuteSelesai/$targetKunjungan',
                        icon: Icons.checklist_rtl_rounded,
                        iconColor: AppColors.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              child: LinearProgressIndicator(
                                value: targetProgress,
                                minHeight: 4,
                                backgroundColor: AppColors.divider,
                                color: targetProgress > 0
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${(targetProgress * 100).toInt()}% Actual Call',
                              style: AppTextStyles.caption.copyWith(
                                color: targetProgress > 0
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatCard(
                        title: 'Luar Rute',
                        value: luarRute.toString(),
                        icon: Icons.flash_on_rounded,
                        iconColor: AppColors.warning,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            'Kunjungan Ekstra',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      _StatCard(
                        title: 'Pelanggan Baru',
                        value: pelangganBaruBulanIni.toString(),
                        icon: Icons.person_add_rounded,
                        iconColor: Colors.purple,
                        child: Text(
                          '$prospekHariIni Potensi Pelanggan Baru',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      _StatCard(
                        title: 'Total Order',
                        value: totalOrderHariIni.toString(),
                        icon: Icons.shopping_bag_rounded,
                        iconColor: AppColors.success,
                        child: Text(
                          orderGrowthText,
                          style: AppTextStyles.caption.copyWith(
                            color: orderGrowthColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (data['rute_hari_ini'] != null) ...[
                    Text('Rute Hari Ini', style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.lg),
                    _RouteCard(data: data['rute_hari_ini']),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, String userRole) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Hero(
            tag: 'profile_avatar',
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(
                userName.isNotEmpty
                    ? userName.substring(0, 1).toUpperCase()
                    : '?',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName',
                  style: AppTextStyles.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                Consumer(
                  builder: (context, ref, _) {
                    final unreadAsync =
                        ref.watch(unreadNotificationCountStreamProvider);
                    final count = unreadAsync.asData?.value ?? 0;
                    if (count > 0) {
                      return Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textOnPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreloadStatusCard extends ConsumerWidget {
  const _PreloadStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preloadTimeAsync = ref.watch(_lastPreloadTimeProvider);
    final downloadTasks = ref.watch(downloadStatusProvider);
    final isPreloading = downloadTasks.any((t) => !t.isCompleted);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            isPreloading ? Icons.sync_rounded : Icons.cloud_done_rounded,
            color: isPreloading ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPreloading
                      ? 'Memperbarui data...'
                      : 'Data terakhir diperbarui',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                preloadTimeAsync.when(
                  data: (time) {
                    final timeStr = time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : 'Belum pernah';
                    return Text(
                      isPreloading ? 'Mohon tunggu...' : timeStr,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isPreloading
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) =>
                      Text('-', style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: isPreloading
                  ? null
                  : () async {
                      await ref
                          .read(preloadServiceProvider)
                          .forceRefreshAll();
                      ref.invalidate(_lastPreloadTimeProvider);
                    },
              icon: Icon(
                isPreloading
                    ? Icons.hourglass_bottom
                    : Icons.refresh_rounded,
                size: 16,
              ),
              label: Text(
                isPreloading ? 'Memperbarui' : 'Perbarui',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                disabledBackgroundColor: AppColors.divider,
                disabledForegroundColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      shadow: true,
      bordered: false,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusXl),
                topRight: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.textOnPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Rute',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        data['keterangan'] ?? '-',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textOnPrimary
                              .withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.25),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxl),
                  ),
                  child: Text(
                    'AKTIF',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RouteInfo(
                      icon: Icons.location_on,
                      value: '${data['total_titik'] ?? 0}',
                      label: 'Total Titik',
                    ),
                    _RouteInfo(
                      icon: Icons.check_circle_outline,
                      value: '${data['dikunjungi'] ?? 0}',
                      label: 'Selesai',
                    ),
                    _RouteInfo(
                      icon: Icons.pending_actions,
                      value: '${data['sisa'] ?? 0}',
                      label: 'Sisa',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/schedule'),
                    icon: const Icon(Icons.directions_car_rounded, size: 20),
                    label: const Text('Mulai Perjalanan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md + 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  const _RouteInfo({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(value, style: AppTextStyles.titleMedium),
          ],
        ),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.child,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadow: true,
      bordered: false,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 22,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ShimmerLoading(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(width: 120, height: 18),
                  SizedBox(height: AppSpacing.xs),
                  ShimmerLoading(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const ShimmerLoading(width: 150, height: 14),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 1.4,
            children: List.generate(
              4,
              (index) => const ShimmerLoading(
                width: double.infinity,
                height: 80,
                borderRadius: 20,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const ShimmerLoading(width: 100, height: 20),
          const SizedBox(height: AppSpacing.lg),
          const ShimmerLoading(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}

final _lastPreloadTimeProvider = FutureProvider<DateTime?>((ref) async {
  return ref.read(preloadServiceProvider).getLastPreloadTime();
});
