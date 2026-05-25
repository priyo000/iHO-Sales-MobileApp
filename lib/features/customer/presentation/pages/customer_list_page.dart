import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/status_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/store_image.dart';
import '../../../../core/db/app_database.dart';
import '../controllers/customer_controller.dart';

Map<String, dynamic> _customerToMap(CustomersTableData row) {
  return {
    'id': row.serverId ?? row.id,
    'kode_pelanggan': row.kodePelanggan,
    'nama_toko': row.namaToko,
    'nama_pelanggan': row.namaPemilik,
    'alamat_usaha': row.alamatUsaha,
    'alamat': row.alamatUsaha,
    'latitude': row.latitude,
    'longitude': row.longitude,
    'status': row.status,
    'foto_toko_url': row.fotoTokoPath,
    'no_hp_pribadi': row.noHpPribadi,
    'kota_usaha': row.kotaUsaha,
    'kecamatan_usaha': row.kecamatanUsaha,
    'provinsi_usaha': row.provinsiUsaha,
  };
}

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final List<String> _filters = ['Semua', 'Aktif', 'Tertunda'];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _sortByDistance = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.text = ref.read(customerSearchProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(customerSearchProvider.notifier).setQuery(query);
    });
  }

  double _distanceTo(Map<String, dynamic> customer, Position userPos) {
    final lat = double.tryParse(customer['latitude']?.toString() ?? '');
    final lng = double.tryParse(customer['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return double.maxFinite;
    return Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      lat,
      lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(customerStatusFilterProvider);
    final searchQuery = ref.watch(customerSearchProvider);
    final userPosition = ref.watch(userLocationProvider).asData?.value;

    final customersStream = searchQuery.isEmpty
        ? ref.watch(customersByStatusStreamProvider(selectedFilter))
        : ref.watch(customerSearchStreamProvider(searchQuery));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
        actions: [
          IconButton(
            onPressed: userPosition == null
                ? null
                : () => setState(() => _sortByDistance = !_sortByDistance),
            tooltip: _sortByDistance
                ? 'Urutkan: Terdekat'
                : 'Urutkan: Default',
            icon: Icon(
              _sortByDistance ? Icons.near_me : Icons.near_me_outlined,
              color: _sortByDistance
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ),
          IconButton(
            onPressed: () => context.push('/add-customer'),
            tooltip: 'Tambah Pelanggan',
            icon: const Icon(
              Icons.person_add_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(selectedFilter),
          Expanded(
            child: StreamBuilder<List<CustomersTableData>>(
              stream: customersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const ListSkeleton();
                }

                if (snapshot.hasError) {
                  return AppErrorView(
                    message: snapshot.error.toString(),
                    onRetry: () =>
                        ref.read(customerControllerProvider.notifier).refresh(),
                  );
                }

                final customers = snapshot.data ?? [];
                final displayItems = customers.map(_customerToMap).toList();

                final sortedItems = (_sortByDistance && userPosition != null)
                    ? (List.of(displayItems)..sort(
                        (a, b) => _distanceTo(a, userPosition)
                            .compareTo(_distanceTo(b, userPosition)),
                      ))
                    : displayItems;

                if (sortedItems.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const AppEmptyState(
                          icon: Icons.people_outline,
                          title: 'Tidak ada pelanggan ditemukan',
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: sortedItems.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final customer = sortedItems[index];
                    return _CustomerCard(
                      customer: customer,
                      userPosition: userPosition,
                      onTap: () => context.push(
                        '/customers/detail',
                        extra: {'pelanggan': customer},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Cari pelanggan...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(String selectedFilter) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: filter,
                  selected: isSelected,
                  onTap: () => ref
                      .read(customerStatusFilterProvider.notifier)
                      .setStatus(filter),
                ),
              );
          }).toList(),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final Position? userPosition;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    this.userPosition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = customer['nama_toko'] ??
        customer['nama_pelanggan'] ??
        customer['nama_pemilik'] ??
        'Unknown';
    final String address = customer['alamat_usaha'] ??
        customer['alamat'] ??
        customer['alamat_rumah_pemilik'] ??
        'Alamat tidak tersedia';
    final bool isOffline = customer['is_offline'] == true;
    final String status = isOffline
        ? 'PENDING'
        : (customer['status'] ?? customer['status_pelanggan'] ?? 'ACTIVE');
    final String code = isOffline
        ? 'MENUNGGU SINKRONISASI'
        : (customer['kode_pelanggan'] ?? '-');
    final String? lastVisit = customer['last_visit_date'];

    final statusUpper = status.toUpperCase();
    final statusColor = StatusStyles.customerColor(statusUpper);
    final statusLabel = switch (statusUpper) {
      'ACTIVE' => 'AKTIF',
      'PENDING' => 'TERTUNDA',
      'PROSPECT' => 'PROSPEK',
      'NONACTIVE' => 'NONAKTIF',
      'REJECTED' => 'DITOLAK',
      _ => statusUpper,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StoreImage(
                  url: customer['foto_toko_url'],
                  width: 100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusXl),
                    bottomLeft: Radius.circular(AppSpacing.radiusXl),
                  ),
                  fallbackIcon: statusUpper == 'PROSPECT'
                      ? Icons.store_outlined
                      : Icons.store,
                  fallbackIconSize: 40,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (isOffline) ...[
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppBadge(
                              label: statusLabel,
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppBadge(
                          label: code,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          address,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      lastVisit != null
                                          ? 'Terakhir: ${_formatDate(lastVisit)}'
                                          : 'Belum dikunjungi',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: _getDistanceColor(),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _getDistanceText(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: _getDistanceColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDistanceColor() {
    if (userPosition == null) return AppColors.textMuted;
    final lat = double.tryParse(customer['latitude']?.toString() ?? '');
    final lng = double.tryParse(customer['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return AppColors.textMuted;
    final d = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      lat,
      lng,
    );
    if (d < 1000) return AppColors.success;
    if (d < 5000) return AppColors.warning;
    return AppColors.error;
  }

  String _getDistanceText() {
    if (userPosition == null) return 'Lihat detail';
    final lat = double.tryParse(customer['latitude']?.toString() ?? '');
    final lng = double.tryParse(customer['longitude']?.toString() ?? '');
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return 'N/A';
    final d = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      lat,
      lng,
    );
    return d >= 1000
        ? '${(d / 1000).toStringAsFixed(1)} km'
        : '${d.toStringAsFixed(0)} m';
  }

  String _formatDate(String dateStr) =>
      Formatters.dateFromString(dateStr, pattern: 'd MMM yyyy');
}
