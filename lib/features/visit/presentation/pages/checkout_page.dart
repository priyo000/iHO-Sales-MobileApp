import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sales_tracker_mobile/core/services/location_service.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/controllers/visit_controller.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../../../orders/presentation/controllers/order_controller.dart';
import '../../../../core/auth/user_provider.dart';
import '../../../../core/widgets/store_image.dart';

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

  final List<Map<String, String>> _noOrderReasons = [
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
    // Initial state setup
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (_isSubmitting) return;

    // 1. Validation for No Order Reason
    if (!_ordersExist && _noOrderReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih alasan tidak ada orderan')),
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
      final String searchId =
          (widget.pelangganId ??
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
      final effectiveKunjunganId =
          (reactiveData?.isNotEmpty == true && reactiveData!['id_kunjungan'] != null)
              ? reactiveData['id_kunjungan']
              : (widget.kunjunganId ?? widget.visitData?['id_kunjungan']);

      if (effectiveKunjunganId == null) {
        throw 'ID Kunjungan tidak ditemukan. Mohon pastikan sudah Check-in dengan benar (id_pelanggan: $searchId).';
      }

      // Get Location — OFFLINE-FIRST with TIMEOUT + smart fallback
      double? checkoutLat;
      double? checkoutLong;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        checkoutLat = position.latitude;
        checkoutLong = position.longitude;
      } catch (_) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 3),
            ),
          );
          checkoutLat = position.latitude;
          checkoutLong = position.longitude;
        } catch (_) {
          // GPS gagal, coba posisi terakhir yang diketahui
          try {
            final lastKnown = await Geolocator.getLastKnownPosition();
            if (lastKnown != null) {
              checkoutLat = lastKnown.latitude;
              checkoutLong = lastKnown.longitude;
              debugPrint('Checkout: Using last known position');
            }
          } catch (_) {
            // Posisi terakhir juga gagal
          }

          // Jika semua gagal, tampilkan warning tapi tetap izinkan checkout
          if (checkoutLat == null || checkoutLong == null) {
            debugPrint('Checkout: GPS completely unavailable, proceeding without coordinates');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Lokasi tidak tersedia. Checkout dilanjutkan tanpa koordinat GPS.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            checkoutLat = 0;
            checkoutLong = 0;
          }
        }
      }

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
      await ref
          .read(visitControllerProvider.notifier)
          .checkOut(
            kunjunganId: effectiveKunjunganId,
            lat: checkoutLat,
            long: checkoutLong,
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
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Checkout: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

    // Use schedule item if it has customer name, otherwise fallback to widget.visitData
    final upToDateVisitData = (scheduleItem != null &&
            scheduleItem.isNotEmpty &&
            (scheduleItem['pelanggan']?['nama_toko'] != null ||
                scheduleItem['pelanggan']?['nama_pelanggan'] != null))
        ? scheduleItem
        : (widget.visitData ?? {});

    final pelanggan = upToDateVisitData['pelanggan'] ?? upToDateVisitData;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        StoreImage(
                          url: pelanggan['foto_toko_url'],
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(12),
                          fallbackIconSize: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pelanggan['nama_toko'] ??
                                    pelanggan['nama_pelanggan'] ??
                                    pelanggan['nama_pemilik'] ??
                                    'Unknown Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                pelanggan['alamat_usaha'] ??
                                    pelanggan['alamat'] ??
                                    pelanggan['alamat_rumah_pemilik'] ??
                                    'Unknown Address',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AKTIF',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Distance Info
                  if (_isLocationLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Menghitung jarak...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (_currentDistance != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (_currentDistance! > _getRadiusTolerance()
                                    ? AppTheme.error
                                    : Colors.green)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              (_currentDistance! > _getRadiusTolerance()
                                      ? AppTheme.error
                                      : Colors.green)
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _currentDistance! > _getRadiusTolerance()
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                            color: _currentDistance! > _getRadiusTolerance()
                                ? AppTheme.error
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentDistance! > _getRadiusTolerance()
                                  ? 'Peringatan: Jarak Anda ${_currentDistance!.toStringAsFixed(0)}m (Batas: ${_getRadiusTolerance().toStringAsFixed(0)}m)'
                                  : 'Lokasi Akurat: ${_currentDistance!.toStringAsFixed(0)}m dari lokasi',
                              style: TextStyle(
                                color: _currentDistance! > _getRadiusTolerance()
                                    ? AppTheme.error
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Visit Outcome
                  const Text(
                    'HASIL KUNJUNGAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_ordersExist)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checkout dengan Order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Catatan order terdeteksi pada kunjungan ini.',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.remove_shopping_cart,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tidak Ada Order',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Mohon pilih alasan tidak ada pesanan.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),
                          Text(
                            'ALASAN TIDAK ORDER *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._noOrderReasons.map((reason) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _noOrderReason == reason['id']
                                      ? AppTheme.primary
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: _noOrderReason == reason['id']
                                    ? AppTheme.primary.withValues(alpha: 0.05)
                                    : null,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _noOrderReason = reason['id'];
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _noOrderReason == reason['id']
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: _noOrderReason == reason['id']
                                            ? AppTheme.primary
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        reason['label']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              _noOrderReason == reason['id']
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Custom Reason Input
                          if (_noOrderReason == 'other') ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _otherReasonController,
                              decoration: InputDecoration(
                                hintText: 'Ketikkan alasan spesifik...',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Visit Evidence Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'BUKTI KUNJUNGAN *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MAKSIMAL 4 FOTO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: [
                      _EvidenceCard(
                        label: 'TAMPAK DEPAN',
                        image: _evidencePhotos['main_entry'],
                        onTap: () => _pickEvidence('main_entry'),
                      ),
                      _EvidenceCard(
                        label: 'DISPLAY RAK',
                        image: _evidencePhotos['shelf_view'],
                        onTap: () => _pickEvidence('shelf_view'),
                      ),
                      _EvidenceCard(
                        label: 'TAMPAK SAMPING',
                        image: _evidencePhotos['side_view'],
                        onTap: () => _pickEvidence('side_view'),
                      ),
                      _EvidenceCard(
                        label: 'FOTO LAINNYA',
                        image: _evidencePhotos['additional'],
                        onTap: () => _pickEvidence('additional'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Info Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan foto menunjukkan tampak depan toko atau stok barang dengan jelas untuk keperluan audit.',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Submit Button
          SafeArea(
            bottom: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting
                        ? 'Mengirim Data...'
                        : 'Kirim Laporan (Checkout)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final String label;
  final File? image;
  final VoidCallback onTap;

  const _EvidenceCard({
    required this.label,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            // Use solid border instead of dashed to avoid runtime errors if package missing
            style: BorderStyle.solid,
          ),
          image: image != null
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

