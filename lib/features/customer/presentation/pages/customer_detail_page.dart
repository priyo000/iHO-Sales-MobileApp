import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/auth/user_provider.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../../../visit/data/visit_repository.dart';
import '../../../visit/presentation/controllers/visit_controller.dart';
import '../../data/customer_repository.dart';
import '../controllers/customer_controller.dart';
import '../widgets/customer_bottom_bar.dart';
import '../widgets/customer_check_in_helpers.dart';
import '../widgets/customer_contact_section.dart';
import '../widgets/customer_detail_header.dart';
import '../widgets/customer_detail_info_sheet.dart';
import '../widgets/customer_detail_stats_row.dart';
import '../widgets/customer_financial_section.dart';
import '../widgets/customer_last_visit_sheet.dart';
import '../widgets/customer_location_card.dart';

/// Convert CustomersTableData to `Map<String, dynamic>` for UI compatibility.
Map<String, dynamic> _customerDataToMap(CustomersTableData? d) {
  if (d == null) return {};
  return {
    'id': d.serverId ?? d.id,
    'kode_pelanggan': d.kodePelanggan,
    'nama_toko': d.namaToko,
    'nama_pelanggan': d.namaPemilik,
    'nama_pemilik': d.namaPemilik,
    'alamat_usaha': d.alamatUsaha,
    'alamat': d.alamatUsaha,
    'latitude': d.latitude,
    'longitude': d.longitude,
    'status': d.status,
    'foto_toko_url': d.fotoTokoPath,
    'no_hp_pribadi': d.noHpPribadi,
    'kota_usaha': d.kotaUsaha,
    'kecamatan_usaha': d.kecamatanUsaha,
    'provinsi_usaha': d.provinsiUsaha,
    'is_local': d.isLocal == 1,
  };
}

class CustomerDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? visitData;
  const CustomerDetailPage({super.key, this.visitData});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  bool _isCheckedIn = false;
  bool _isCompleted = false;
  dynamic _currentKunjunganId;
  DateTime? _checkInTime;
  final Stopwatch _stopwatch = Stopwatch();
  late final Stream<String> _timerStream;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _pelangganMap;

  // Guard flag: prevents _initData from resetting an active timer session.
  bool _isCheckInInProgress = false;

  // The scheduled date of the visit being viewed (may differ from today)
  String? _visitScheduleDate;

  LatLng _customerLocation = const LatLng(-6.175392, 106.827153);

  @override
  void initState() {
    super.initState();
    _initData();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) {
      return mounted ? _getFormattedDuration() : '';
    }).asBroadcastStream();
  }

  @override
  void didUpdateWidget(covariant CustomerDetailPage oldWidget) {
    if (oldWidget.visitData != widget.visitData) _initData();
    super.didUpdateWidget(oldWidget);
  }

  String _getFormattedDuration() {
    if (!_isCheckedIn) return '00:00:00';
    Duration elapsed = _checkInTime != null
        ? DateTime.now().difference(_checkInTime!)
        : _stopwatch.elapsed;
    if (elapsed.isNegative) elapsed = Duration.zero;
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  dynamic get _idPelanggan =>
      widget.visitData?['id_pelanggan'] ??
      widget.visitData?['pelanggan']?['id'] ??
      widget.visitData?['pelanggan_data']?['id'] ??
      widget.visitData?['id'];

  void _initData() {
    if (_isCheckInInProgress) return;

    final skipVisitStateInit = _isCompleted;
    final hasValidKunjunganId = _isCheckedIn &&
        _currentKunjunganId != null &&
        (_currentKunjunganId is int ||
            (_currentKunjunganId is String && _currentKunjunganId.isNotEmpty));

    final idPelanggan = _idPelanggan;
    if (idPelanggan == null) return;

    _visitScheduleDate =
        widget.visitData?['tanggal_kunjungan'] ?? widget.visitData?['tanggal'];

    final visitMatch = ref.read(scheduleControllerProvider).asData?.value
        .where((s) =>
            (s['id_pelanggan'] ?? s['pelanggan']?['id']).toString() ==
            idPelanggan.toString())
        .firstOrNull;

    final customerItems =
        ref.read(customerControllerProvider).asData?.value.items ??
            const <Map<String, dynamic>>[];
    final customerMatch = customerItems
        .where((c) => c['id'].toString() == idPelanggan.toString())
        .firstOrNull;

    final enriched = customerMatch ?? visitMatch ?? widget.visitData;
    _pelangganMap = enriched?['pelanggan'] ?? enriched ?? {};

    final lat = _pelangganMap?['latitude'];
    final lng = _pelangganMap?['longitude'];
    _customerLocation = (lat != null && lng != null)
        ? LatLng(
            double.tryParse(lat.toString()) ?? 0,
            double.tryParse(lng.toString()) ?? 0,
          )
        : const LatLng(-6.175392, 106.827153);

    if (skipVisitStateInit || hasValidKunjunganId) return;

    final source = visitMatch ?? (!_isCheckedIn ? widget.visitData : null);
    if (source != null) {
      _currentKunjunganId = source['id_kunjungan'];
      final checkInStr = source['waktu_check_in'];
      final checkOutStr = source['waktu_check_out'];
      if (checkInStr != null) {
        _checkInTime = DateTime.tryParse(checkInStr.toString())?.toLocal();
      }
      _isCompleted = checkOutStr != null;
      _isCheckedIn = checkInStr != null && !_isCompleted;
    }

    if (_isCheckedIn) {
      if (!_stopwatch.isRunning) _stopwatch.start();
    } else {
      _stopwatch.stop();
      _stopwatch.reset();
    }
  }

  double _getRadiusTolerance() {
    final radius =
        ref.read(userProvider)?['karyawan']?['divisi']?['radius_toleransi'];
    return radius != null ? (double.tryParse(radius.toString()) ?? 100.0) : 100.0;
  }

  void _snack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _updateFotoToko() async {
    final pelangganId = _pelangganMap?['id'];
    if (pelangganId == null) return;

    final picked = await ImagePickerService.pickImage(
      context: context,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await ref
          .read(customerControllerProvider.notifier)
          .updateCustomerPhoto(id: pelangganId.toString(), photo: picked);
      if (mounted) {
        _snack('Foto toko berhasil diperbarui!', color: AppColors.success);
        ref.invalidate(customerControllerProvider);
        setState(() {});
      }
    } catch (e) {
      _snack('Gagal upload foto: $e', color: AppColors.error);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _toggleCheckIn() async {
    if (_isLoading) return;
    if (_isCheckedIn) {
      await _navigateToCheckout();
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isCompleted) {
        final confirm = await CustomerCheckInHelpers.confirmRevisit(context);
        if (confirm != true) return;
      }
      await _verifyLocationAndCheckIn();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToCheckout() async {
    final idPelanggan = _idPelanggan.toString();
    final scheduleState = ref.read(scheduleControllerProvider).value;
    final latestVisitItem = scheduleState?.firstWhere(
      (s) =>
          (s['id_pelanggan'] ?? s['pelanggan']?['id']).toString() ==
          idPelanggan,
      orElse: () => <String, dynamic>{},
    );

    final effectiveKunjunganId = (latestVisitItem?.isNotEmpty == true &&
            latestVisitItem!['id_kunjungan'] != null)
        ? latestVisitItem['id_kunjungan']
        : (_currentKunjunganId ?? widget.visitData?['id_kunjungan']);

    if (effectiveKunjunganId == null) {
      debugPrint(
        '[CustomerDetail] Error: Kunjungan ID tidak ditemukan untuk pelanggan $idPelanggan',
      );
    }

    if (!mounted) return;
    context.push('/checkout', extra: {
      'kunjunganId': effectiveKunjunganId,
      'pelangganId': idPelanggan,
      'visitData': (latestVisitItem?.isNotEmpty == true)
          ? latestVisitItem
          : widget.visitData,
    });
  }

  Future<void> _verifyLocationAndCheckIn() async {
    final inWindow = CustomerCheckInHelpers.validateSopWindow(
      context: context,
      scheduleDate: _visitScheduleDate,
    );
    if (!inWindow) return;

    try {
      final position = await CustomerCheckInHelpers.resolvePosition();
      double meterDistance = 0;
      if (position != null) {
        meterDistance = const Distance().as(
          LengthUnit.Meter,
          LatLng(position.latitude, position.longitude),
          _customerLocation,
        );
      }

      final tolerance = _getRadiusTolerance();
      final fallbackPos = position ?? CustomerCheckInHelpers.emptyPosition();

      if (position == null || meterDistance <= tolerance) {
        final ok = await _performCheckIn(fallbackPos, meterDistance);
        if (ok) _snack('Berhasil Check-in!', color: AppColors.success);
        return;
      }

      if (!mounted) return;
      final shouldContinue = await CustomerCheckInHelpers.confirmOutOfRange(
        context,
        distance: meterDistance,
        tolerance: tolerance,
      );
      if (shouldContinue == true) {
        final ok = await _performCheckIn(position, meterDistance);
        if (ok) {
          _snack(
            'Check-in dengan PERINGATAN: Melebihi toleransi ${(meterDistance - tolerance).toStringAsFixed(0)}m.',
            color: AppColors.error,
          );
        }
      }
    } catch (e) {
      _snack('Check-in gagal: $e', color: AppColors.error);
    }
  }

  Future<bool> _performCheckIn(Position position, double meterDistance) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isOffDate = _visitScheduleDate != null &&
        _visitScheduleDate != todayStr;
    final jadwalId = isOffDate
        ? null
        : widget.visitData?['id_jadwal']?.toString();
    if (jadwalId == null) {
      debugPrint(
        'Warning: No Schedule ID (id_jadwal), proceeding as unplanned visit.'
        '${isOffDate ? ' [off-date: $_visitScheduleDate vs $todayStr]' : ''}',
      );
    }

    if (!mounted) return false;
    final idPelanggan = _idPelanggan;
    if (idPelanggan == null) {
      _snack('Error: No Pelanggan ID');
      return false;
    }

    try {
      _isCheckInInProgress = true;
      final result = await ref.read(visitControllerProvider.notifier).checkIn(
            jadwalId: jadwalId,
            pelangganId: idPelanggan,
            lat: position.latitude,
            long: position.longitude,
            jarakValidasi: meterDistance,
            scheduledDate: _visitScheduleDate,
            pelangganDataMap: _pelangganMap,
          );

      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _currentKunjunganId = result.kunjunganId;
          _checkInTime = DateTime.now();
          _stopwatch.start();
        });
        if (isOffDate) {
          _snack(
            'Disimpan sebagai kunjungan diluar jadwal hari ini. Jadwal $_visitScheduleDate tetap aktif.',
            color: AppColors.warning,
          );
        } else if (result.isOffline) {
          _snack(
            'Check-in disimpan lokal. Akan dikirim ke server saat online.',
            color: const Color(0xFF1A1A2E),
          );
        }
      }
      return true;
    } catch (e) {
      _isCheckInInProgress = false;
      _snack('Check-in gagal: $e', color: AppColors.error);
      return false;
    }
  }

  Future<void> _refreshFromServer(String customerId) async {
    ref.invalidate(customerDetailStreamProvider(customerId));
    try {
      await ref
          .read(customerRepositoryProvider)
          .syncCustomersToDrift(forceRefresh: true);
      _snack('Data diperbarui dari server');
    } catch (e) {
      _snack('Gagal refresh: $e');
    }
  }

  void _onCartTap() {
    final id = _pelangganMap?['id'];
    if (id == null) {
      _snack(
        'Gagal memuat ID pelanggan. Coba buka ulang halaman ini.',
        color: AppColors.error,
      );
      return;
    }
    context.push('/products', extra: {
      'kunjunganId': _currentKunjunganId,
      'pelangganId': id,
      'pelangganData': _pelangganMap,
    });
  }

  ({Map<String, dynamic> current, Map<String, dynamic> merged,
        Map<String, dynamic>? customerMatch}) _resolveCustomerData(
      String rawId) {
    final streamCustomer =
        ref.watch(customerDetailStreamProvider(rawId)).asData?.value;
    final current = streamCustomer != null
        ? _customerDataToMap(streamCustomer)
        : <String, dynamic>{};

    final scheduleData = ref.watch(scheduleControllerProvider).asData?.value;
    final customerSnap = ref.watch(customerControllerProvider).asData?.value;
    final customerMatch = customerSnap?.items
        .where((c) => c['id']?.toString() == rawId)
        .firstOrNull;
    final visitMatch = scheduleData
        ?.where((s) =>
            (s['id_pelanggan'] ?? s['pelangganId'])?.toString() == rawId)
        .firstOrNull;

    final active = (streamCustomer != null ? current : null) ??
        customerMatch ??
        visitMatch ??
        widget.visitData;
    final merged = active != null
        ? (active is Map<String, dynamic>
            ? active
            : Map<String, dynamic>.from(active as Map))
        : <String, dynamic>{};
    return (current: current, merged: merged, customerMatch: customerMatch);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scheduleControllerProvider, (_, next) {
      if (next.hasValue && mounted) {
        _initData();
        setState(() {});
      }
    });

    final rawId = _idPelanggan;
    if (rawId == null) {
      return const AppScaffold(
        showStatusBar: false,
        body: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Data Pelanggan tidak valid',
        ),
      );
    }

    final customerId = rawId.toString();
    final data = _resolveCustomerData(customerId);
    final headerData =
        data.current.isNotEmpty ? data.current : data.merged;

    return AppScaffold(
      showStatusBar: false,
      safeAreaTop: false,
      safeAreaBottom: false,
      body: RefreshIndicator(
        onRefresh: () => _refreshFromServer(customerId),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CustomerDetailHeader(
              pelanggan: headerData,
              imageUrl: data.merged['foto_toko_url'] as String?,
              isUploadingPhoto: _isUploadingPhoto,
              onUpdatePhotoTap: _updateFotoToko,
              onBackTap: () => context.pop(),
              onShowFullDetailsTap: () =>
                  CustomerDetailInfoSheet.show(context, headerData),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerDetailStatsRow(
                      pelanggan: data.current,
                      fallback: data.customerMatch,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CustomerFinancialSection(pelanggan: data.current),
                    const SizedBox(height: AppSpacing.xl),
                    CustomerContactSection(pelanggan: data.current),
                    const SizedBox(height: AppSpacing.xl),
                    CustomerLocationCard(
                      pelanggan: data.current,
                      onEditTap: _pelangganMap != null
                          ? () {
                              context
                                  .push('/customers/tagging',
                                      extra: _pelangganMap)
                                  .then((_) {
                                if (mounted) setState(() => _initData());
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SizedBox(height: 100), // bottom bar spacer
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomBar: Builder(builder: (context) {
        final lastVisit = ref
            .watch(lastCompletedVisitProvider(customerId))
            .asData
            ?.value;
        return CustomerBottomBar(
          isCheckedIn: _isCheckedIn,
          isCompleted: _isCompleted,
          isLoading: _isLoading,
          timerStream: _timerStream,
          currentDuration: _getFormattedDuration(),
          onCartTap: _onCartTap,
          onCheckInTap: _toggleCheckIn,
          onLastVisitTap: lastVisit != null
              ? () => CustomerLastVisitSheet.show(context, lastVisit)
              : null,
        );
      }),
    );
  }
}
