import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../customer/presentation/controllers/customer_controller.dart';
import '../controllers/schedule_controller.dart';
import 'schedule_date_selector.dart';
import 'schedule_empty_state.dart';
import 'schedule_visit_card.dart';

/// Body of the Jadwal tab: search bar, date picker, schedule list.
class ScheduleJadwalTab extends ConsumerStatefulWidget {
  const ScheduleJadwalTab({super.key});

  @override
  ConsumerState<ScheduleJadwalTab> createState() => _ScheduleJadwalTabState();
}

class _ScheduleJadwalTabState extends ConsumerState<ScheduleJadwalTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(scheduleSearchProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(scheduleSearchProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final currentPosition = ref.watch(userLocationProvider).asData?.value;
    final scheduleAsync = ref.watch(filteredScheduleProvider(dateStr));

    return Column(
      children: [
        _buildSearchAndDateHeader(selectedDate),
        Expanded(
          child: scheduleAsync.when(
            loading: () => const AppLoading(),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Error: $e',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (schedule) =>
                _buildScheduleList(schedule, currentPosition, dateStr),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndDateHeader(DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Cari pelanggan atau alamat...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ScheduleDateSelector(
            selectedDate: selectedDate,
            onDateSelected: (date) =>
                ref.read(selectedDateProvider.notifier).state = date,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(
    List<Map<String, dynamic>> schedule,
    dynamic currentPosition,
    String dateStr,
  ) {
    if (schedule.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(scheduleControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const ScheduleEmptyState(),
            ),
          ],
        ),
      );
    }

    final items = List<Map<String, dynamic>>.from(schedule);

    if (currentPosition != null) {
      const distanceCalc = Distance();
      for (var item in items) {
        final rawLat = item['pelanggan']?['latitude'];
        final rawLng = item['pelanggan']?['longitude'];
        final double? lat = rawLat is double
            ? rawLat
            : double.tryParse(rawLat?.toString() ?? '');
        final double? lng = rawLng is double
            ? rawLng
            : double.tryParse(rawLng?.toString() ?? '');

        if (lat != null && lng != null) {
          final d = distanceCalc.as(
            LengthUnit.Meter,
            LatLng(currentPosition.latitude, currentPosition.longitude),
            LatLng(lat, lng),
          );
          item['_distance_m'] = d.toDouble();
        } else {
          item['_distance_m'] = null;
        }
      }
    }

    final activeItems = <Map<String, dynamic>>[];
    final historyItems = <Map<String, dynamic>>[];
    final pendingItems = <Map<String, dynamic>>[];

    for (final item in items) {
      final s = item['status_kunjungan']?.toString().toUpperCase();
      final hasCheckIn = item['waktu_check_in'] != null;
      final hasCheckOut = item['waktu_check_out'] != null;

      // KRITIS: Jika tidak ada waktu check-in SAMA SEKALI,
      // toko PASTI belum dikunjungi -> selalu masuk PENDING.
      if (!hasCheckIn && !hasCheckOut) {
        pendingItems.add(item);
      } else if ((s == 'DIKUNJUNGI' || s == 'SELESAI') &&
          hasCheckIn &&
          !hasCheckOut) {
        activeItems.add(item);
      } else if (hasCheckOut ||
          s == 'DIBATALKAN' ||
          s == 'DIBATAL' ||
          s == 'DILEWATI') {
        historyItems.add(item);
      } else {
        pendingItems.add(item);
      }
    }

    historyItems.sort((a, b) {
      final timeA = a['waktu_check_in'] != null
          ? DateTime.tryParse(a['waktu_check_in'].toString())
          : null;
      final timeB = b['waktu_check_in'] != null
          ? DateTime.tryParse(b['waktu_check_in'].toString())
          : null;
      if (timeA != null && timeB != null) {
        return timeB.compareTo(timeA);
      }
      return 0;
    });

    if (currentPosition != null) {
      pendingItems.sort((a, b) {
        final distA = a['_distance_m'] as double?;
        final distB = b['_distance_m'] as double?;
        if (distA == null && distB == null) return 0;
        if (distA == null) return 1;
        if (distB == null) return -1;
        return distA.compareTo(distB);
      });
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (activeItems.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Kunjungan Aktif',
              icon: Icons.play_circle_fill,
            ),
            ...activeItems.map((item) => _buildCard(item, dateStr)),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (historyItems.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Riwayat Hari Ini',
              icon: Icons.history,
            ),
            ...historyItems.map((item) => _buildCard(item, dateStr)),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (pendingItems.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Rute Mendatang (Terdekat)',
              icon: Icons.route_outlined,
            ),
            ...pendingItems.map((item) => _buildCard(item, dateStr)),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, String dateStr) {
    final pelanggan = item['pelanggan'] ?? {};
    final status = item['status_kunjungan']?.toString() ?? 'TERTUNDA';
    final distanceM = item['_distance_m'] as double?;
    final distanceKm = distanceM != null ? distanceM / 1000.0 : null;
    final isUnplanned = item['id_jadwal'] == null;

    Color statusColor = AppColors.warning; // Default: TERTUNDA
    final upper = status.toUpperCase();
    if (upper == 'SELESAI' || upper == 'DIKUNJUNGI') {
      statusColor = AppColors.success;
    } else if (upper == 'DIBATALKAN' ||
        upper == 'DIBATAL' ||
        upper == 'DILEWATI') {
      statusColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ScheduleVisitCard(
        imageUrl: pelanggan['foto_toko_url'] ?? pelanggan['foto_toko_local'],
        name: pelanggan['nama_pelanggan'] ??
            pelanggan['nama_toko'] ??
            pelanggan['nama_pemilik'] ??
            'Unknown',
        code: pelanggan['kode_pelanggan'] ?? 'ID: ${pelanggan['id'] ?? '-'}',
        address:
            pelanggan['alamat'] ?? pelanggan['alamat_usaha'] ?? 'Alamat tidak tersedia',
        status: status,
        statusColor: statusColor,
        distance: distanceKm,
        checkIn: item['waktu_check_in'],
        checkOut: item['waktu_check_out'],
        isOffDateFulfilled: item['is_off_date_fulfilled'] == true,
        isUnplanned: isUnplanned,
        onTap: () {
          final enrichedItem = Map<String, dynamic>.from(item)
            ..['tanggal_kunjungan'] = dateStr;
          context.push('/customers/detail', extra: enrichedItem);
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
