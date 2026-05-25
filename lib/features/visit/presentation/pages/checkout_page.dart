import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/services/location_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/widgets/app_gap.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

import '../../../orders/presentation/controllers/order_controller.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../controllers/visit_controller.dart';
import '../widgets/checkout_customer_card.dart';
import '../widgets/checkout_evidence_grid.dart';
import '../widgets/checkout_outcome_section.dart';
import '../widgets/checkout_submit_bar.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final dynamic kunjunganId; // dynamic to support int or local_ref String
  final dynamic pelangganId; // Added for robust reactive lookup
  final Map<String, dynamic>? visitData;

  const CheckoutPage({
    super.key,
    this.kunjunganId,
    this.pelangganId,
    this.visitData,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _ordersExist = false;
  String? _noOrderReason;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isSubmitting = false;

  // Evidence Photos State
  final Map<String, File?> _evidencePhotos = {
    'main_entry': null,
    'shelf_view': null,
    'side_view': null,
    'additional': null,
  };
  final ImagePicker _picker = ImagePicker();

  // Actual customer location from visitData
  late LatLng _customerLocation;

  final List<Map<String, String>> _noOrderReasons = const [
    {'id': 'closed', 'label': 'Toko Tutup'},
    {'id': 'owner_unavailable', 'label': 'Pemilik Tidak Ada'},
    {'id': 'stock_full', 'label': 'Stok Masih Penuh'},
    {'id': 'other', 'label': 'Alasan Lain (Sebutkan)'},
  ];

  double? _currentDistance;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _customerLocation = _parseLocation();
    _fetchLocation();
  }

  LatLng _parseLocation() {
    final pelanggan = widget.visitData?['pelanggan'] ?? widget.visitData;
    if (pelanggan != null &&
        pelanggan['latitude'] != null &&
        pelanggan['longitude'] != null) {
      return LatLng(
        double.tryParse(pelanggan['latitude'].toString()) ?? 0,
        double.tryParse(pelanggan['longitude'].toString()) ?? 0,
      );
    }
    return const LatLng(-6.175392, 106.827153);
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final Position position = await LocationService.getCurrentWithPermission();

      const Distance distance = Distance();
      final double meterDistance = distance.as(
        LengthUnit.Meter,
        LatLng(position.latitude, position.longitude),
        _customerLocation,
      );

      if (mounted) {
        setState(() {
          _currentDistance = meterDistance;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  double _getRadiusTolerance() {
    final user = ref.read(userProvider);
    final radius = user?['karyawan']?['divisi']?['radius_toleransi'];
    if (radius != null) {
      return double.tryParse(radius.toString()) ?? 100.0;
    }
    return 100.0;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence(String type) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _evidencePhotos[type] = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (_isSubmitting) return;

    // 1. Validation for No Order Reason
    if (!_ordersExist && _noOrderReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Silakan pilih alasan tidak ada orderan')),
      );
      return;
    }

    // 2. Validation for 'Other' Reason
    if (!_ordersExist &&
        _noOrderReason == 'other' &&
        _otherReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi detail alasan lainnya')),
      );
      return;
    }

    // 3. Validation for Photo Evidence (Mandatory: at least 1)
    final hasPhoto = _evidencePhotos.values.any((file) => file != null);
    if (!hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib melampirkan minimal 1 foto bukti kunjungan'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Dapatkan Pelanggan ID sebagai kunci utama pencarian (Search Key)
      final String searchId = (widget.pelangganId ??
              widget.visitData?['id_pelanggan'] ??
              widget.visitData?['pelanggan']?['id'] ??
              widget.visitData?['id'])
          .toString();

      // 2. Ambil data terbaru dari Provider (Real-time Reality)
      final scheduleList = ref.read(scheduleControllerProvider).value;
      final reactiveData = scheduleList?.firstWhere(
        (item) =>
            (item['id_pelanggan'] ?? item['pelanggan']?['id']).toString() ==
            searchId,
        orElse: () => <String, dynamic>{},
      );

      // 3. Tentukan Kunjungan ID yang valid (Transaction ID)
      // Simplified resolution: reactive data > widget param > initial data
      final effectiveKunjunganId = (reactiveData?.isNotEmpty == true &&
              reactiveData!['id_kunjungan'] != null)
          ? reactiveData['id_kunjungan']
          : (widget.kunjunganId ?? widget.visitData?['id_kunjungan']);

      if (effectiveKunjunganId == null) {
        throw 'ID Kunjungan tidak ditemukan. Mohon pastikan sudah Check-in '
            'dengan benar (id_pelanggan: $searchId).';
      }

      final coords = await _resolveCheckoutLocation();

      // Determine alasanTidakOrder and detailAlasan
      final String? alasanTidakOrder;
      final String? detailAlasan;
      if (_noOrderReason == 'other') {
        alasanTidakOrder = 'other';
        detailAlasan = _otherReasonController.text;
      } else {
        alasanTidakOrder = _noOrderReason;
        detailAlasan = null;
      }

      // Call Controller
      await ref.read(visitControllerProvider.notifier).checkOut(
            kunjunganId: effectiveKunjunganId,
            lat: coords.$1,
            long: coords.$2,
            statusTransaksi: _ordersExist,
            alasanTidakOrder: alasanTidakOrder,
            detailAlasan: detailAlasan,
            catatan: _notesController.text,
            photos: _evidencePhotos,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout Berhasil!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Checkout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Resolve current GPS — OFFLINE-FIRST with TIMEOUT + smart fallback.
  ///
  /// Tries high-accuracy → medium-accuracy → last known → (0, 0) with toast.
  Future<(double, double)> _resolveCheckoutLocation() async {
    double? lat;
    double? lng;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            lat = lastKnown.latitude;
            lng = lastKnown.longitude;
            debugPrint('Checkout: Using last known position');
          }
        } catch (e) {
          debugPrint('Checkout: getLastKnownPosition failed: $e');
        }

        if (lat == null || lng == null) {
          debugPrint(
              'Checkout: GPS completely unavailable, proceeding without coordinates');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Lokasi tidak tersedia. Checkout dilanjutkan tanpa koordinat GPS.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          lat = 0;
          lng = 0;
        }
      }
    }
    return (lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final searchPelangganId = (widget.pelangganId ??
            widget.visitData?['id_pelanggan'] ??
            widget.visitData?['pelanggan']?['id'] ??
            widget.visitData?['id'])
        .toString();

    // SSOT: detect orders from local Drift, not from server pesanan_count.
    // Works offline — newly created order in cart sync queue counts immediately.
    final orderCountAsync =
        ref.watch(todayOrdersByPelangganProvider(searchPelangganId));
    _ordersExist = (orderCountAsync.value ?? 0) > 0;

    final scheduleList = ref.watch(scheduleControllerProvider).value;
    final scheduleItem = scheduleList?.firstWhere(
      (item) =>
          (item['id_pelanggan'] ?? item['pelanggan']?['id']).toString() ==
          searchPelangganId,
      orElse: () => <String, dynamic>{},
    );

    // Use schedule item if it has customer name, otherwise fallback to widget.visitData.
    final upToDateVisitData = (scheduleItem != null &&
            scheduleItem.isNotEmpty &&
            (scheduleItem['pelanggan']?['nama_toko'] != null ||
                scheduleItem['pelanggan']?['nama_pelanggan'] != null))
        ? scheduleItem
        : (widget.visitData ?? {});

    final pelanggan = (upToDateVisitData['pelanggan'] ?? upToDateVisitData)
        as Map<String, dynamic>;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Check Out'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckoutCustomerCard(
              pelanggan: pelanggan,
              isLocationLoading: _isLocationLoading,
              currentDistance: _currentDistance,
              radiusTolerance: _getRadiusTolerance(),
            ),
            const AppGap.sm(),
            CheckoutOutcomeSection(
              ordersExist: _ordersExist,
              noOrderReasons: _noOrderReasons,
              selectedReason: _noOrderReason,
              otherReasonController: _otherReasonController,
              onReasonSelected: (id) =>
                  setState(() => _noOrderReason = id),
            ),
            const AppGap.xxl(),
            CheckoutEvidenceGrid(
              evidencePhotos: _evidencePhotos,
              onPick: _pickEvidence,
            ),
            const AppGap.xxl(),
          ],
        ),
      ),
      bottomBar: CheckoutSubmitBar(
        isSubmitting: _isSubmitting,
        onSubmit: _submitCheckout,
      ),
    );
  }
}
