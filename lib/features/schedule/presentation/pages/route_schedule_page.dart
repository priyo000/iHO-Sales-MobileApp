import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/controllers/schedule_controller.dart';
import '../../../prospecting/presentation/pages/prospecting_list_page.dart';
import '../../../customer/presentation/controllers/customer_controller.dart'; // For location provider
import '../../../../core/widgets/store_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RouteSchedulePage — shell with TabBar (Jadwal | Prospecting)
// ─────────────────────────────────────────────────────────────────────────────

class RouteSchedulePage extends ConsumerStatefulWidget {
  const RouteSchedulePage({super.key});

  @override
  ConsumerState<RouteSchedulePage> createState() => _RouteSchedulePageState();
}

class _RouteSchedulePageState extends ConsumerState<RouteSchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Kunjungan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ── Tabs (Slim TabBar) ──────────────────────────
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize.label,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Jadwal'),
                        Tab(text: 'Prospecting'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: const [_JadwalTab(), ProspectingListPage()],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JadwalTab — extracted tab content (schedule list + date picker + progress)
// ─────────────────────────────────────────────────────────────────────────────

class _JadwalTab extends ConsumerStatefulWidget {
  const _JadwalTab();

  @override
  ConsumerState<_JadwalTab> createState() => _JadwalTabState();
}

class _JadwalTabState extends ConsumerState<_JadwalTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
  void initState() {
    super.initState();
    _searchController.text = ref.read(scheduleSearchProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final currentPosition = ref.watch(userLocationProvider).asData?.value;

    // SSOT: Watch stream for instant local data (Riverpod-managed StreamProvider)
    final scheduleAsync = ref.watch(scheduleStreamProvider(dateStr));

    return Column(
      children: [
        // ── Search Bar + Date Selector ─────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar - SSOT: no loading spinner, data is instant
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari pelanggan atau alamat...',
                  prefixIcon: const Icon(Icons.search),
                  // No loading spinner - SSOT data is instant
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

              const SizedBox(height: 12),
              // Horizontal Date Selector (hanya ±3 hari dari hari ini)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7, // 3 hari lalu + hari ini + 3 hari depan
                  itemBuilder: (context, index) {
                    final today = DateTime.now();
                    final date = today.add(Duration(days: index - 3));
                    final isSelected =
                        DateFormat('yyyy-MM-dd').format(date) ==
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(ref.watch(selectedDateProvider));
                    final isToday =
                        DateFormat('yyyy-MM-dd').format(date) ==
                        DateFormat('yyyy-MM-dd').format(today);

                    return GestureDetector(
                      onTap: () =>
                          ref.read(selectedDateProvider.notifier).state = date,
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : isToday
                                ? AppTheme.primary.withValues(alpha: 0.4)
                                : Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isToday && !isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Schedule List ─────────────────────────────────────────────
        Expanded(
          child: scheduleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (schedule) {

              if (schedule.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(
                        child: Text('Tidak ada jadwal hari ini.'),
                      ),
                    ),
                  ],
                );
              }

              final List<Map<String, dynamic>> items =
                  List<Map<String, dynamic>>.from(schedule);

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
                      LatLng(
                        currentPosition.latitude,
                        currentPosition.longitude,
                      ),
                      LatLng(lat, lng),
                    );
                    item['_distance_m'] = d.toDouble();
                  } else {
                    item['_distance_m'] = null;
                  }
                }
              }

              // Kategorisasi MUTUALLY EXCLUSIVE (setiap item PASTI masuk ke satu kategori):
              //
              // AKTIF   : Sedang di toko — timer jalan (checkin ada, checkout belum)
              // RIWAYAT : Sudah selesai checkout, dibatalkan, atau dipenuhi di tgl lain
              // PENDING : Semua sisanya (belum dikunjungi hari ini)

              final activeItems = <Map<String, dynamic>>[];
              final historyItems = <Map<String, dynamic>>[];
              final pendingItems = <Map<String, dynamic>>[];

              for (final item in items) {
                final s = item['status_kunjungan']?.toString().toUpperCase();
                final hasCheckIn = item['waktu_check_in'] != null;
                final hasCheckOut = item['waktu_check_out'] != null;

                // KRITIS: Jika tidak ada waktu check-in SAMA SEKALI,
                // toko PASTI belum dikunjungi → selalu masuk PENDING.
                // Ini mencegah data stale/salah dari server lama menaruh
                // toko ke Riwayat padahal sama sekali belum dikunjungi.
                if (!hasCheckIn && !hasCheckOut) {
                  pendingItems.add(item);
                } else if ((s == 'DIKUNJUNGI' || s == 'SELESAI') &&
                    hasCheckIn &&
                    !hasCheckOut) {
                  // Timer lagi jalan (check-in ada, belum check-out)
                  activeItems.add(item);
                } else if (hasCheckOut ||
                    s == 'DIBATALKAN' ||
                    s == 'DIBATAL' ||
                    s == 'DILEWATI') {
                  // Sudah selesai / dibatalkan
                  historyItems.add(item);
                } else {
                  // Fallback: belum dikunjungi
                  pendingItems.add(item);
                }
              }

              // Sorting Riwayat (History) berdasarkan waktu check-in terbaru
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

              // Sorting Pending berdasarkan jarak terdekat
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
                onRefresh: () =>
                    ref.read(scheduleControllerProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (activeItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        'Kunjungan Aktif',
                        Icons.play_circle_fill,
                      ),
                      ...activeItems.map((item) => _buildCard(context, item)),
                      const SizedBox(height: 16),
                    ],
                    if (historyItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        'Riwayat Hari Ini',
                        Icons.history,
                      ),
                      ...historyItems.map((item) => _buildCard(context, item)),
                      const SizedBox(height: 16),
                    ],
                    if (pendingItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        'Rute Mendatang (Terdekat)',
                        Icons.route_outlined,
                      ),
                      ...pendingItems.map((item) => _buildCard(context, item)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> item) {
    final pelanggan = item['pelanggan'] ?? {};
    final status = item['status_kunjungan']?.toString() ?? 'TERTUNDA';
    final distanceM = item['_distance_m'] as double?;
    final distanceKm = distanceM != null ? distanceM / 1000.0 : null;
    final isUnplanned = item['id_jadwal'] == null;

    Color statusColor = Colors.orange; // Default: TERTUNDA
    if (status.toUpperCase() == 'SELESAI' ||
        status.toUpperCase() == 'DIKUNJUNGI') {
      statusColor = Colors.green;
    } else if (status.toUpperCase() == 'DIBATALKAN' ||
        status.toUpperCase() == 'DIBATAL' ||
        status.toUpperCase() == 'DILEWATI') {
      statusColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ScheduleCard(
        imageUrl: pelanggan['foto_toko_url'] ?? pelanggan['foto_toko_local'],
        name:
            pelanggan['nama_pelanggan'] ??
            pelanggan['nama_toko'] ??
            pelanggan['nama_pemilik'] ??
            'Unknown',
        code: pelanggan['kode_pelanggan'] ?? 'ID: ${pelanggan['id'] ?? '-'}',
        address:
            pelanggan['alamat'] ?? pelanggan['alamat_usaha'] ?? 'No Address',
        status: status,
        statusColor: statusColor,
        distance: distanceKm,
        checkIn: item['waktu_check_in'],
        checkOut: item['waktu_check_out'],
        isOffDateFulfilled: item['is_off_date_fulfilled'] == true,
        isUnplanned: isUnplanned,
        onTap: () {
          final selectedDate = ref.read(selectedDateProvider);
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
          final enrichedItem = Map<String, dynamic>.from(item)
            ..['tanggal_kunjungan'] = dateStr;
          context.push('/customers/detail', extra: enrichedItem);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScheduleCard — individual visit card with live timer
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends StatefulWidget {
  final String? checkIn;
  final String? checkOut;
  final String? imageUrl;
  final String name;
  final String code;
  final String address;
  final String status;
  final Color statusColor;
  final double? distance;
  final VoidCallback onTap;
  // Local-only: true when this slot was fulfilled via an off-date visit.
  // Prevents showing the active-timer red border even though status=DIKUNJUNGI.
  final bool isOffDateFulfilled;
  // True when this visit is unplanned (kunjungan diluar jadwal)
  final bool isUnplanned;

  const _ScheduleCard({
    this.checkIn,
    this.checkOut,
    this.imageUrl,
    required this.name,
    required this.code,
    required this.address,
    required this.status,
    required this.statusColor,
    required this.distance,
    required this.onTap,
    this.isOffDateFulfilled = false,
    this.isUnplanned = false,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  String _liveDuration = '';
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(_ScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkIn != widget.checkIn ||
        oldWidget.checkOut != widget.checkOut ||
        oldWidget.status != widget.status) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final bool isActive =
        widget.status.toUpperCase() == 'DIKUNJUNGI' && widget.checkOut == null;

    if (isActive && widget.checkIn != null) {
      final startTime = DateTime.tryParse(widget.checkIn!)?.toLocal();
      if (startTime != null) {
        _updateDuration(startTime);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateDuration(startTime);
        });
      }
    }
  }

  void _updateDuration(DateTime startTime) {
    final diff = DateTime.now().difference(startTime);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    if (mounted) setState(() => _liveDuration = '$h:$m:$s');
  }

  @override
  Widget build(BuildContext context) {
    final bool isVisited =
        widget.status.toUpperCase() == 'DIKUNJUNGI' ||
        widget.status.toUpperCase() == 'SELESAI';
    // isActive: only true if visit is CURRENTLY ongoing (not fulfilled via another date)
    final bool isActive =
        widget.status.toUpperCase() == 'DIKUNJUNGI' &&
        widget.checkOut == null &&
        !widget.isOffDateFulfilled;

    String timeDisplay = 'Belum dikunjungi';
    if (isVisited) {
      String inTime = '--:--';
      if (widget.checkIn != null) {
        final dt = DateTime.tryParse(widget.checkIn!)?.toLocal();
        if (dt != null) inTime = DateFormat('HH:mm').format(dt);
      }
      if (isActive) {
        timeDisplay = _liveDuration;
      } else {
        timeDisplay = 'In: $inTime';
        if (widget.checkOut != null) {
          final dt = DateTime.tryParse(widget.checkOut!)?.toLocal();
          if (dt != null) {
            timeDisplay += ' - Out: ${DateFormat('HH:mm').format(dt)}';
          }
        }
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
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
              StoreImage(
                url: widget.imageUrl,
                width: 100,
                // height unset — IntrinsicHeight parent controls it
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                fallbackIconSize: 40,
              ),
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
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.status.toUpperCase(),
                              style: TextStyle(
                                color: widget.statusColor,
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
                              widget.code,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.isUnplanned) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.deepPurple.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alt_route,
                                    size: 10,
                                    color: Colors.deepPurple[400],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Diluar Jadwal',
                                    style: TextStyle(
                                      color: Colors.deepPurple[400],
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.address,
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
                                if (isActive)
                                  ScaleTransition(
                                    scale: Tween(
                                      begin: 0.8,
                                      end: 1.2,
                                    ).animate(_pulseController!),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                if (isActive) const SizedBox(width: 8),
                                Icon(
                                  isActive
                                      ? Icons.timer_outlined
                                      : isVisited
                                      ? Icons.history
                                      : Icons.access_time,
                                  size: 14,
                                  color: isActive
                                      ? Colors.red
                                      : Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    timeDisplay,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.red
                                          : Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
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
                              if (widget.distance != null) ...[
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: widget.distance! < 1.0
                                      ? Colors.green
                                      : widget.distance! < 5.0
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.distance!.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: widget.distance! < 1.0
                                        ? Colors.green
                                        : widget.distance! < 5.0
                                        ? Colors.orange
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Lokasi tdk diset',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
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
}
