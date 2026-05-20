import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import '../controllers/dashboard_controller.dart';
import 'package:sales_tracker_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';

import 'package:sales_tracker_mobile/core/widgets/unified_status_bar.dart';
import 'package:sales_tracker_mobile/core/services/preload_service.dart';
import 'package:sales_tracker_mobile/core/services/download_status_service.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            const UnifiedStatusBar(), // Peringatan data gagal sync
            Expanded(
              child: dashboardState.when(
                skipLoadingOnRefresh: true,
                loading: () => const _DashboardSkeleton(),
                error: (err, stack) => AppErrorView(
                  message: 'Gagal memuat dashboard: $err',
                  onRetry: () =>
                      ref.read(dashboardControllerProvider.notifier).refresh(),
                ),
                data: (data) {
                  final targetKunjungan = data['target_kunjungan'] ?? 0;
                  final kunjunganRuteSelesai =
                      data['kunjungan_rute_selesai'] ?? 0;
                  final luarRute = data['luar_rute'] ?? 0;
                  final pelangganBaruBulanIni =
                      data['pelanggan_baru_hari_ini'] ?? 0;
                  final prospekHariIni = data['prospek_hari_ini'] ?? 0;
                  final totalOrderHariIni = data['total_order_hari_ini'] ?? 0;
                  final hitRatePercentage = data['hit_rate_percentage'] ?? 0;

                  final targetProgress = targetKunjungan > 0
                      ? (kunjunganRuteSelesai / targetKunjungan)
                      : 0.0;

                  // Stats logic orders
                  final String orderGrowthText =
                      "$hitRatePercentage% Effective Call";
                  final Color orderGrowthColor = hitRatePercentage > 0
                      ? Colors.green
                      : Colors.grey;



                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(dashboardControllerProvider.notifier)
                        .refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Section
                          Row(
                            children: [
                              // Avatar + Greeting
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Hero(
                                  tag: 'profile_avatar',
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primary,
                                    child: Text(
                                      userName.isNotEmpty
                                          ? userName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Halo, $userName',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      userRole,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Notification bell
                              InkWell(
                                onTap: () => context.push('/notifications'),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.notifications_none),
                                      Consumer(
                                        builder: (context, ref, _) {
                                          final unreadAsync = ref.watch(
                                            unreadNotificationCountStreamProvider,
                                          );
                                          final count = unreadAsync.asData?.value ?? 0;
                                          if (count > 0) {
                                            return Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration:
                                                    const BoxDecoration(
                                                      color: Colors.red,
                                                      shape:
                                                          BoxShape.circle,
                                                    ),
                                                child: Text(
                                                  count > 9
                                                      ? '9+'
                                                      : count.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                  textAlign:
                                                      TextAlign.center,
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
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatDate(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Preload Status Card
                          Consumer(
                            builder: (context, ref, _) {
                              final preloadTimeAsync = ref.watch(
                                _lastPreloadTimeProvider,
                              );
                              final downloadTasks = ref.watch(
                                downloadStatusProvider,
                              );
                              final isPreloading = downloadTasks.any(
                                (t) => !t.isCompleted,
                              );

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPreloading
                                          ? Icons.sync_rounded
                                          : Icons.cloud_done_rounded,
                                      color: isPreloading
                                          ? AppTheme.primary
                                          : Colors.grey[500],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isPreloading
                                                ? 'Memperbarui data...'
                                                : 'Data terakhir diperbarui',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          preloadTimeAsync.when(
                                            data: (time) {
                                              final timeStr = time != null
                                                  ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                                                  : 'Belum pernah';
                                              return Text(
                                                isPreloading
                                                    ? 'Mohon tunggu...'
                                                    : timeStr,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPreloading
                                                      ? AppTheme.primary
                                                      : Colors.grey[800],
                                                ),
                                              );
                                            },
                                            loading: () => const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            error: (_, _) => Text(
                                              '-',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 32,
                                      child: ElevatedButton.icon(
                                        onPressed: isPreloading
                                            ? null
                                            : () async {
                                                await ref
                                                    .read(
                                                      preloadServiceProvider,
                                                    )
                                                    .forceRefreshAll();
                                                // Invalidate provider so UI shows new timestamp
                                                ref.invalidate(
                                                  _lastPreloadTimeProvider,
                                                );
                                              },
                                        icon: Icon(
                                          isPreloading
                                              ? Icons.hourglass_bottom
                                              : Icons.refresh_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          isPreloading
                                              ? 'Memperbarui'
                                              : 'Perbarui',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                          disabledForegroundColor:
                                              Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // 2. Stats Grid Section
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio:
                                1.4, // Adjusted to prevent overflow
                            children: [
                              _StatCard(
                                title: 'Kunjungan Rute',
                                value: '$kunjunganRuteSelesai/$targetKunjungan',
                                icon: Icons.checklist_rtl_rounded,
                                iconColor: AppTheme.primary,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min, // Compact
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: targetProgress,
                                        minHeight: 4, // Thinner progress bar
                                        backgroundColor: Colors.grey[50],
                                        color: targetProgress > 0
                                            ? AppTheme.primary
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(targetProgress * 100).toInt()}% Actual Call',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: targetProgress > 0
                                            ? AppTheme.primary
                                            : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatCard(
                                title: 'Luar Rute',
                                value: luarRute.toString(),
                                icon: Icons.flash_on_rounded,
                                iconColor: Colors.orange,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Kunjungan Ekstra',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
                                  style: const TextStyle(
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
                                iconColor: Colors.green,
                                child: Text(
                                  orderGrowthText,
                                  style: TextStyle(
                                    color: orderGrowthColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 3. Today's Route Section
                          if (data['rute_hari_ini'] != null) ...[
                            const Text(
                              "Rute Hari Ini",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Beautiful Gradient Header
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primary,
                                          AppTheme.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.map_outlined,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['rute_hari_ini']['name'] ??
                                                    'Rute',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                data['rute_hari_ini']['keterangan'] ??
                                                    '-',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'AKTIF',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Info Section
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildRouteInfo(
                                              Icons.location_on,
                                              '${data['rute_hari_ini']['total_titik'] ?? 0}',
                                              'Total Titik',
                                            ),
                                            _buildRouteInfo(
                                              Icons.check_circle_outline,
                                              '${data['rute_hari_ini']['dikunjungi'] ?? 0}',
                                              'Selesai',
                                            ),
                                            _buildRouteInfo(
                                              Icons.pending_actions,
                                              '${data['rute_hari_ini']['sisa'] ?? 0}',
                                              'Sisa',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                context.go('/schedule'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.directions_car_rounded,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Mulai Perjalanan',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],


                        ],
                      ),
                    ),
                  );
                },
              ),
            ), // Expanded
          ],
        ), // Column
      ), // SafeArea
      floatingActionButton: null,
    );
  }

  Widget _buildRouteInfo(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget? child;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11, // Slightly smaller
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6), // Reduced icon padding
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ), // Slightly smaller icon
              ),
            ],
          ),

          const Spacer(),

          // Value & Subtitle
          Text(
            value,
            style: const TextStyle(
              fontSize: 22, // Smaller Value
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4), // Reduced gap
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            children: [
              const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLoading(width: 120, height: 18),
                  SizedBox(height: 4),
                  ShimmerLoading(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerLoading(width: 150, height: 14),
          const SizedBox(height: 24),

          // Stats Grid Skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
          const SizedBox(height: 32),

          // Route Skeleton
          const ShimmerLoading(width: 100, height: 20),
          const SizedBox(height: 16),
          const ShimmerLoading(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
          const SizedBox(height: 32),

          // Upcoming Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerLoading(width: 150, height: 20),
              ShimmerLoading(width: 80, height: 30),
            ],
          ),
          const SizedBox(height: 16),
          const ListSkeleton(
            count: 3,
            itemHeight: 100,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Preload Time Provider ────────────────────────────────────────────────────
final _lastPreloadTimeProvider = FutureProvider<DateTime?>((ref) async {
  return ref.read(preloadServiceProvider).getLastPreloadTime();
});
