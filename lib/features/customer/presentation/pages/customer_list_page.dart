import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/store_image.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/db/app_database.dart';
import '../controllers/customer_controller.dart';

/// Convert CustomersTableData to `Map<String, dynamic>` for UI
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
  final List<String> _filters = ['All', 'Active', 'Pending'];
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

  /// Calculates distance (meters) between user and a customer using Geolocator.
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

    // SSOT: Use stream based on search or status filter
    final customersStream = searchQuery.isEmpty
        ? ref.watch(customersByStatusStreamProvider(selectedFilter))
        : ref.watch(customerSearchStreamProvider(searchQuery));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Daftar Pelanggan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: userPosition == null
                            ? null
                            : () => setState(
                                () => _sortByDistance = !_sortByDistance,
                              ),
                        child: Tooltip(
                          message: _sortByDistance
                              ? 'Urutkan: Terdekat'
                              : 'Urutkan: Default',
                          child: Icon(
                            _sortByDistance
                                ? Icons.near_me
                                : Icons.near_me_outlined,
                            color: _sortByDistance
                                ? AppTheme.primary
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => context.push('/add-customer'),
                        child: const Icon(
                          Icons.person_add_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari pelanggan...',
                      prefixIcon: const Icon(Icons.search),
                      // SSOT: No loading spinner - data is instant from local DB
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter Chips ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(customerStatusFilterProvider.notifier)
                                .setStatus(filter);
                          }
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── List ───────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<CustomersTableData>>(
                stream: customersStream,
                builder: (context, snapshot) {
                  // SSOT: Data is instant from Drift - show skeleton only on first load
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ListSkeleton();
                  }

                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }

                  final customers = snapshot.data ?? [];

                  // Convert to Maps for UI compatibility
                  final displayItems = customers.map(_customerToMap).toList();

                  // Sort by distance if enabled
                  final sortedItems = (_sortByDistance && userPosition != null)
                      ? (List.of(displayItems)..sort(
                          (a, b) => _distanceTo(
                            a,
                            userPosition,
                          ).compareTo(_distanceTo(b, userPosition)),
                        ))
                      : displayItems;

                  if (sortedItems.isEmpty) return _buildEmpty();

                  return ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedItems.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada pelanggan ditemukan',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return AppErrorView(
      message: error,
      onRetry: () => ref.read(customerControllerProvider.notifier).refresh(),
    );
  }
}

// ─── CustomerCard (unchanged from before) ─────────────────────────────────────

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
    final String name =
        customer['nama_toko'] ??
        customer['nama_pelanggan'] ??
        customer['nama_pemilik'] ??
        'Unknown';
    final String address =
        customer['alamat_usaha'] ??
        customer['alamat'] ??
        customer['alamat_rumah_pemilik'] ??
        'No Address';
    final bool isOffline = customer['is_offline'] == true;
    final String status = isOffline
        ? 'PENDING'
        : (customer['status'] ?? customer['status_pelanggan'] ?? 'ACTIVE');
    final String code = isOffline
        ? 'OFFLINE SYNC'
        : (customer['kode_pelanggan'] ?? '-');
    final String? lastVisit = customer['last_visit_date'];

    Color statusColor = Colors.green;
    if (status.toUpperCase() == 'PROSPECT') statusColor = Colors.blueGrey;
    if (status.toUpperCase() == 'PENDING') statusColor = Colors.orange;
    if (status.toUpperCase() == 'NONACTIVE' ||
        status.toUpperCase() == 'REJECTED') {
      statusColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              StoreImage(
                url: customer['foto_toko_url'],
                width: 100,
                // height unset — IntrinsicHeight parent controls it
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                fallbackIcon: status.toUpperCase() == 'PROSPECT'
                    ? Icons.store_outlined
                    : Icons.store,
                fallbackIconSize: 40,
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isOffline)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lastVisit != null
                                        ? 'Last: ${_formatDate(lastVisit)}'
                                        : 'Belum dikunjungi',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
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
                              const SizedBox(width: 4),
                              Text(
                                _getDistanceText(),
                                style: TextStyle(
                                  color: _getDistanceColor(),
                                  fontSize: 12,
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
    );
  }

  Color _getDistanceColor() {
    if (userPosition == null) return Colors.grey;
    final lat = double.tryParse(customer['latitude']?.toString() ?? '');
    final lng = double.tryParse(customer['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return Colors.grey;
    final d = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      lat,
      lng,
    );
    if (d < 1000) return Colors.green;
    if (d < 5000) return Colors.orange;
    return Colors.red;
  }

  String _getDistanceText() {
    if (userPosition == null) return 'Tap for details';
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
