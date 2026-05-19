import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../visit/presentation/controllers/visit_controller.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../../../../core/auth/user_provider.dart';
import '../../../../core/db/app_database.dart';
import '../../data/customer_repository.dart';
import '../controllers/customer_controller.dart';
import '../../../../core/widgets/store_image.dart';
import '../widgets/customer_stat_card.dart';
import '../widgets/customer_contact_section.dart';
import '../widgets/customer_financial_section.dart';
import '../widgets/customer_location_card.dart';
import '../widgets/customer_bottom_bar.dart';

/// Convert CustomersTableData to Map<String, dynamic> for UI compatibility
Map<String, dynamic> _customerDataToMap(CustomersTableData? data) {
  if (data == null) return {};
  return {
    'id': data.serverId ?? data.id,
    'kode_pelanggan': data.kodePelanggan,
    'nama_toko': data.namaToko,
    'nama_pelanggan': data.namaPemilik,
    'nama_pemilik': data.namaPemilik,
    'alamat_usaha': data.alamatUsaha,
    'alamat': data.alamatUsaha,
    'latitude': data.latitude,
    'longitude': data.longitude,
    'status': data.status,
    'foto_toko_url': data.fotoTokoPath,
    'no_hp_pribadi': data.noHpPribadi,
    'kota_usaha': data.kotaUsaha,
    'kecamatan_usaha': data.kecamatanUsaha,
    'provinsi_usaha': data.provinsiUsaha,
    'is_local': data.isLocal == 1,
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
  // Set true right after a fresh check-in; cleared only when session ends.
  bool _isCheckInInProgress = false;

  // The scheduled date of the visit being viewed (may differ from today)
  String? _visitScheduleDate;

  // Use visitData for location
  LatLng _customerLocation = const LatLng(-6.175392, 106.827153);

  @override
  void didUpdateWidget(covariant CustomerDetailPage oldWidget) {
    if (oldWidget.visitData != widget.visitData) {
      _initData();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) {
      if (mounted) return _getFormattedDuration();
      return '';
    }).asBroadcastStream();
  }

  String _getFormattedDuration() {
    if (!_isCheckedIn) return '00:00:00';

    Duration elapsed;
    if (_checkInTime != null) {
      elapsed = DateTime.now().difference(_checkInTime!);
    } else {
      elapsed = _stopwatch.elapsed;
    }
    // Prevent negative duration if server time is slightly ahead
    if (elapsed.isNegative) elapsed = Duration.zero;

    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Color _getStatusColor(dynamic status) {
    if (status == null) return Colors.blueGrey;
    final s = status.toString().toLowerCase();
    switch (s) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'prospect':
        return Colors.blueGrey;
      case 'nonactive':
      case 'rejected':
      default:
        return Colors.red;
    }
  }

  String _formatLastVisitDate(dynamic lastVisitDate) {
    if (lastVisitDate == null) return 'Belum Ada';
    try {
      final date = DateTime.parse(lastVisitDate.toString());
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Belum Ada';
    }
  }

  String _formatDaysAgo(dynamic days) {
    if (days == null) return 'Belum pernah';
    final dayCount = (days is int ? days : int.tryParse(days.toString()) ?? 0)
        .abs();
    if (dayCount == 0) return 'Hari ini';
    if (dayCount == 1) return '1 hari yang lalu';
    if (dayCount < 7) return '$dayCount hari yang lalu';
    if (dayCount < 30) {
      final weeks = (dayCount / 7).floor();
      return '$weeks minggu yang lalu';
    }
    final months = (dayCount / 30).floor();
    return '$months bulan yang lalu';
  }

  String _formatGrowthPercentage(dynamic growth) {
    if (growth == null) return '0%';
    final growthValue = growth is num
        ? growth
        : num.tryParse(growth.toString()) ?? 0;
    final sign = growthValue >= 0 ? '+' : '';
    return '$sign${growthValue.toStringAsFixed(1)}% dari bulan lalu';
  }

  IconData _getGrowthIcon(dynamic growth) {
    if (growth == null) return Icons.trending_flat;
    final growthValue = growth is num
        ? growth
        : num.tryParse(growth.toString()) ?? 0;
    if (growthValue > 0) return Icons.trending_up;
    if (growthValue < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getGrowthColor(dynamic growth) {
    if (growth == null) return Colors.grey;
    final growthValue = growth is num
        ? growth
        : num.tryParse(growth.toString()) ?? 0;
    if (growthValue > 0) return Colors.green;
    if (growthValue < 0) return Colors.red;
    return Colors.grey;
  }

  // Payment System & Method Helpers
  String _getPaymentSystemDisplay(String? sistem) {
    if (sistem == null || sistem.isEmpty) return '-';
    switch (sistem) {
      case 'Cash':
        return 'Cash';
      case 'Kredit':
        return 'Kredit';
      default:
        return sistem;
    }
  }

  String _getPaymentMethodSubtext(String? method) {
    if (method == null || method.isEmpty) return 'Belum diatur';
    switch (method) {
      case 'Tunai':
        return 'Bayar Tunai';
      case 'Transfer':
        return 'Transfer Bank';
      case 'Giro':
        return 'Bayar Giro';
      default:
        return method;
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    if (method == null || method.isEmpty) return Icons.help_outline;
    switch (method) {
      case 'Tunai':
        return Icons.money;
      case 'Transfer':
        return Icons.account_balance;
      case 'Giro':
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final numValue = value is num ? value : num.tryParse(value.toString()) ?? 0;
    // Simple formatting: add thousand separator
    final formatter = numValue.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;
    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }
    return parts.join('.');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateFotoToko() async {
    final pelangganId = _pelangganMap?['id'];
    if (pelangganId == null) return;

    // Pilih: Kamera atau Galeri
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Update Foto Toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppTheme.primary,
              ),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await ref
          .read(customerControllerProvider.notifier)
          .updateCustomerPhoto(id: pelangganId.toString(), photo: File(picked.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto toko berhasil diperbarui!'),
            backgroundColor: AppTheme.success,
          ),
        );
        // Refresh UI without re-calling _initData (avoid re-init late fields)
        ref.invalidate(customerControllerProvider);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _initData() {
    // Guard: Do not reset state if user just checked in (timer is running).
    // This protects ±3-day visits where schedule matches a different date.
    if (_isCheckInInProgress) return;

    // Guard: Jangan reset visit state jika sudah checkout.
    // Skenario: server sync kembali data lama (checkout belum ter-sync karena offline)
    // sehingga _initData() baca waktu_check_out: null → timer jalan lagi.
    // HANYA larang reset visit fields — _pelangganMap tetap harus di-init
    final bool skipVisitStateInit = _isCompleted;

    // Guard: Jangan override kunjunganId yang sudah valid jika sesi kunjungan sedang aktif.
    // Skenario: user check-in Unplanned (dapat server ID), lalu scheduleController di-invalidate,
    // _initData jalan lagi tapi Unplanned belum ada di cache jadwal → visitMatch null →
    // _currentKunjunganId ter-reset jadi null → order tidak bisa dikirim ke server.
    // Use tryParse to handle both String (local_ref) and int (server ID)
    final bool hasValidKunjunganId =
        _isCheckedIn &&
        _currentKunjunganId != null &&
        // Accept both int (server ID) and String (local_ref/client_ref) - don't require numeric
        (_currentKunjunganId is int ||
            (_currentKunjunganId is String && _currentKunjunganId.isNotEmpty));
    final bool skipKunjunganInit = hasValidKunjunganId;

    // 1. Get the most accurate Pelanggan ID.
    //    visitData structure varies by entry point:
    //    - From Schedule     : { 'id_pelanggan': X, 'pelanggan': {...}, 'id_kunjungan': Y, ... }
    //    - From CustomerList : { 'id': X, ... } or { 'pelanggan': { 'id': X, ... } }
    final idPelanggan =
        widget.visitData?['id_pelanggan'] ??
        widget.visitData?['pelanggan']?['id'] ??
        widget.visitData?['pelanggan_data']?['id'] ??
        widget.visitData?['id'];

    if (idPelanggan == null) return;

    // Cache the scheduled date of this visit for cache updates later
    _visitScheduleDate =
        widget.visitData?['tanggal_kunjungan'] ?? widget.visitData?['tanggal'];

    // 2. Try to find the same customer in available global states for enrichment
    //    Search across ANY date in the current schedule state (not just today)
    final currentSchedule = ref.read(scheduleControllerProvider).asData?.value;
    final Map<String, dynamic>? visitMatch = (idPelanggan != null)
        ? currentSchedule
              ?.where(
                (s) =>
                    (s['id_pelanggan'] ?? s['pelanggan']?['id']).toString() ==
                    idPelanggan.toString(),
              )
              .firstOrNull
        : null;

    final custSnap = ref.read(customerControllerProvider).asData?.value;
    final customerItems = custSnap?.items ?? const <Map<String, dynamic>>[];
    final Map<String, dynamic>? customerMatch = (idPelanggan != null)
        ? customerItems
              .where((c) => c['id'].toString() == idPelanggan.toString())
              .firstOrNull
        : null;

    // 3. Determine the best data source for customer payloads.
    // Prefer master customer data when available so downstream order flows
    // get a richer, more stable customer shape, while visit-specific fields
    // still come from schedule data below.
    final enrichedData = customerMatch ?? visitMatch ?? widget.visitData;

    // 4. Extract the actual customer details map — ALWAYS init even for completed visits
    //    This is critical for cart button to have pelangganData for order creation
    _pelangganMap = enrichedData?['pelanggan'] ?? enrichedData ?? {};

    // 5. Initialize location — always (even if completed)
    if (_pelangganMap != null &&
        _pelangganMap!['latitude'] != null &&
        _pelangganMap!['longitude'] != null) {
      _customerLocation = LatLng(
        double.tryParse(_pelangganMap!['latitude'].toString()) ?? 0,
        double.tryParse(_pelangganMap!['longitude'].toString()) ?? 0,
      );
    } else {
      _customerLocation = const LatLng(-6.175392, 106.827153);
    }

    // 6. Initialize Visit-specific fields — skip if already set or completed
    if (skipVisitStateInit || skipKunjunganInit) return;

    // Priority: Use matches from schedule provider if available
    final visitDataSource = visitMatch;

    if (visitDataSource != null) {
      _currentKunjunganId = visitDataSource['id_kunjungan'];

      final checkInStr = visitDataSource['waktu_check_in'];
      final checkOutStr = visitDataSource['waktu_check_out'];
      if (checkInStr != null) {
        _checkInTime = DateTime.tryParse(checkInStr.toString())?.toLocal();
      }

      _isCompleted = checkOutStr != null;
      _isCheckedIn = checkInStr != null && !_isCompleted;
    } else {
      // If no visit match found in schedule, check widget data but only if we don't have active local session
      if (!_isCheckedIn) {
        final checkInStr = widget.visitData?['waktu_check_in'];
        final checkOutStr = widget.visitData?['waktu_check_out'];

        if (checkInStr != null) {
          _checkInTime = DateTime.tryParse(checkInStr.toString())?.toLocal();
          _currentKunjunganId = widget.visitData?['id_kunjungan'];
        }

        _isCompleted = checkOutStr != null;
        _isCheckedIn = checkInStr != null && !_isCompleted;
      }
    }

    if (_isCheckedIn) {
      if (!_stopwatch.isRunning) _stopwatch.start();
    } else {
      _stopwatch.stop();
      _stopwatch.reset();
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

  Future<void> _toggleCheckIn() async {
    if (_isLoading) return;
    if (_isCheckedIn) {
      final String idPelanggan =
          (widget.visitData?['id_pelanggan'] ??
                  widget.visitData?['pelanggan']?['id'] ??
                  widget.visitData?['id'])
              .toString();

      final scheduleState = ref.read(scheduleControllerProvider).value;
      final latestVisitItem = scheduleState?.firstWhere(
        (s) =>
            (s['id_pelanggan'] ?? s['pelanggan']?['id']).toString() ==
            idPelanggan,
        orElse: () => <String, dynamic>{},
      );

      final effectiveKunjunganId =
          (latestVisitItem?.isNotEmpty == true &&
              latestVisitItem!['id_kunjungan'] != null)
          ? latestVisitItem['id_kunjungan']
          : (_currentKunjunganId ?? widget.visitData?['id_kunjungan']);

      if (effectiveKunjunganId == null) {
        debugPrint(
          '[CustomerDetail] Error: Kunjungan ID tidak ditemukan untuk pelanggan $idPelanggan',
        );
      }

      _isCheckInInProgress = false;

      setState(() {
        _isCheckedIn = false;
        _stopwatch.stop();
        _stopwatch.reset();
      });

      context.push(
        '/checkout',
        extra: {
          'kunjunganId': effectiveKunjunganId,
          'pelangganId': idPelanggan,
          'visitData': (latestVisitItem?.isNotEmpty == true)
              ? latestVisitItem
              : widget.visitData,
        },
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isCompleted) {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Re-visit'),
            content: const Text(
              'Anda sudah menyelesaikan kunjungan ini hari ini. Apakah Anda yakin ingin mengunjungi ulang pelanggan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Kunjungi Lagi'),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }
      await _verifyLocationAndCheckIn();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyLocationAndCheckIn() async {
    // 0. SOP Validation: ±3 Days Window
    if (_visitScheduleDate != null) {
      try {
        final scheduleDate = DateTime.parse(_visitScheduleDate!.toString());
        final today = DateTime.now();
        final diffDays = today.difference(scheduleDate).inDays.abs();

        if (diffDays > 3) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('⚠️ Pelanggaran SOP'),
                content: Text(
                  'Sesuai aturan perusahaan, Anda tidak diperbolehkan melakukan Check-in untuk jadwal yang sudah lewat atau yang masih lama (> 3 hari).\n\nTanggal Jadwal: ${scheduleDate.day}/${scheduleDate.month}/${scheduleDate.year}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Mengerti'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('[SOP Check] Error parsing date: $e');
      }
    }

    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      // 2. Get Position — OFFLINE-FIRST with TIMEOUT
      // Kalau GPS lama (>5 detik), tetap proceed check-in dengan posisi terakhir atau 0,0
      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5), // Timeout 5 detik
          ),
        );
      } catch (_) {
        try {
          // Fallback ke medium accuracy
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 3),
            ),
          );
        } catch (_) {
          // GPS gagal semua, proceed check-in dengan 0,0 (akan disync nanti saat online)
          debugPrint('Check-in: GPS failed, using 0,0 position');
        }
      }

      // 3. Calculate Distance (only if position available)
      double meterDistance = 0;
      if (position != null) {
        const Distance distance = Distance();
        meterDistance = distance.as(
          LengthUnit.Meter,
          LatLng(position.latitude, position.longitude),
          _customerLocation,
        );
      }

      // 4. Verify Tolerance
      // Jika GPS gagal (meterDistance=0), tetap proceed check-in
      if (position == null || meterDistance <= _getRadiusTolerance()) {
        // Within range or GPS failed, proceed with check-in
        final success = await _performCheckIn(
          position ??
              Position(
                latitude: 0,
                longitude: 0,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              ),
          meterDistance,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil Check-in!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        // Outside range, show confirmation dialog
        if (mounted) {
          final bool? shouldContinue = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Peringatan Lokasi'),
              content: Text(
                'Anda berada ${(meterDistance).toStringAsFixed(0)}m dari lokasi pelanggan (Batas: ${(_getRadiusTolerance()).toStringAsFixed(0)}m).\n\nApakah Anda ingin melanjutkan check-in?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          );

          if (shouldContinue == true) {
            final success = await _performCheckIn(position, meterDistance);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Check-in dengan PERINGATAN: Melebihi toleransi ${(meterDistance - _getRadiusTolerance()).toStringAsFixed(0)}m.',
                  ),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in gagal: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _performCheckIn(Position position, double meterDistance) async {
    final jadwalId = widget.visitData?['id_jadwal']?.toString();
    if (jadwalId == null) {
      debugPrint(
        'Warning: No Schedule ID (id_jadwal), proceeding as unplanned visit.',
      );
    }

    if (!mounted) return false;

    final double lat = position.latitude;
    final double lng = position.longitude;

    final idPelanggan =
        widget.visitData?['id_pelanggan'] ??
        widget.visitData?['pelanggan']?['id'] ??
        widget.visitData?['id'];
    if (idPelanggan == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error: No Pelanggan ID')));
      }
      return false;
    }

    try {
      // Set guard BEFORE the async call so ref.listen cannot reset the timer
      // while the API request is in flight.
      _isCheckInInProgress = true;

      final result = await ref
          .read(visitControllerProvider.notifier)
          .checkIn(
            jadwalId: jadwalId,
            pelangganId: idPelanggan,
            lat: lat,
            long: lng,
            jarakValidasi: meterDistance,
            scheduledDate: _visitScheduleDate,
            pelangganDataMap: _pelangganMap,
          );

      // Update local state to start the timer
      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _currentKunjunganId = result.kunjunganId;
          _checkInTime = DateTime.now();
          _stopwatch.start();
        });

        // Show offline notice if applicable
        if (result.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check-in disimpan lokal. Akan dikirim ke server saat online.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF1A1A2E),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      return true;
    } catch (e) {
      // Clear guard flag on failure
      _isCheckInInProgress = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _showFullDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detail Lengkap',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailSection('Identitas', [
                      _buildDetailRow('Kode', data['kode_pelanggan']),
                      _buildDetailRow(
                        'Nama Toko',
                        data['nama_toko'] ?? data['nama_pelanggan'],
                      ),
                      _buildDetailRow('Nama Pemilik', data['nama_pemilik']),
                      _buildDetailRow(
                        'Status',
                        data['status_pelanggan'] ?? data['status'],
                      ),
                      _buildDetailRow('NPWP', data['npwp']),
                      _buildDetailRow('NIK Pemilik', data['nik_pemilik']),
                    ]),
                    _buildDetailSection('Kontak', [
                      _buildDetailRow('Telepon', data['telepon']),
                      _buildDetailRow('No HP Pribadi', data['no_hp_pribadi']),
                      _buildDetailRow('No HP Kontak', data['no_hp_kontak']),
                      _buildDetailRow('Fax', data['fax']),
                      _buildDetailRow('Email', data['email']),
                    ]),
                    _buildDetailSection('Alamat', [
                      _buildDetailRow('Alamat', data['alamat']),
                      _buildDetailRow('Alamat Usaha', data['alamat_usaha']),
                      _buildDetailRow(
                        'Alamat Rumah',
                        data['alamat_rumah_pemilik'],
                      ),
                      _buildDetailRow('Kelurahan', data['kelurahan']),
                      _buildDetailRow('Kecamatan', data['kecamatan']),
                      _buildDetailRow('Kota/Kab', data['kota']),
                      _buildDetailRow('Provinsi', data['provinsi']),
                      _buildDetailRow('Kode Pos', data['kode_pos']),
                      if (data['latitude'] != null)
                        _buildDetailRow(
                          'Koordinat',
                          '${data['latitude']}, ${data['longitude']}',
                        ),
                    ]),
                    _buildDetailSection('Finansial', [
                      _buildDetailRow(
                        'Sistem Pembayaran',
                        data['sistem_pembayaran'],
                      ),
                      _buildDetailRow(
                        'Cara Pembayaran',
                        data['cara_pembayaran'],
                      ),
                      _buildDetailRow(
                        'Limit Kredit Awal',
                        data['limit_kredit_awal'] != null
                            ? 'Rp ${_formatCurrency(data['limit_kredit_awal'])}'
                            : null,
                      ),
                      _buildDetailRow(
                        'Limit Kredit Sisa',
                        data['limit_kredit_sisa'] != null
                            ? 'Rp ${_formatCurrency(data['limit_kredit_sisa'])}'
                            : null,
                      ),
                      _buildDetailRow(
                        'TOP (Hari)',
                        data['top_hari'] != null
                            ? '${data['top_hari']} Hari'
                            : null,
                      ),
                    ]),
                    _buildDetailSection('Lainnya', [
                      _buildDetailRow('Hari Kunjungan', data['hari_kunjungan']),
                      _buildDetailRow('Frekuensi', data['frekuensi_kunjungan']),
                      _buildDetailRow(
                        'Last Visit',
                        _formatLastVisitDate(data['last_visit_date']),
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    final validChildren = children.where((c) => c is! SizedBox).toList();

    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: validChildren.asMap().entries.map((entry) {
              final index = entry.key;
              final widget = entry.value;
              final isLast = index == validChildren.length - 1;

              return Container(
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                child: widget,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null ||
        value.toString().isEmpty ||
        value.toString() == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for schedule updates to refresh data (REPLACES unsafe addPostFrameCallback)
    ref.listen(scheduleControllerProvider, (previous, next) {
      if (next.hasValue && mounted) {
        _initData();
        setState(() {});
      }
    });

    // 1. Get current customer ID for lookup
    final rawId =
        widget.visitData?['id_pelanggan'] ??
        widget.visitData?['pelanggan']?['id'] ??
        widget.visitData?['id'];

    if (rawId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Data Pelanggan tidak valid')),
      );
    }

    // 2. Watch specific detail stream provider (Reactive SSOT for this customer)
    final customerId = rawId.toString();
    final customerStream = ref.watch(customerDetailStreamProvider(customerId));

    // Get the currentPelanggan from stream
    final streamCustomer = customerStream.asData?.value;
    final currentPelanggan = streamCustomer != null
        ? _customerDataToMap(streamCustomer)
        : <String, dynamic>{};

    // 3. Fallback logic: prioritaskan data reaktif, tpi tetap aman jika sedang loading/error.
    final scheduleData = ref.watch(scheduleControllerProvider).asData?.value;
    final customerSnap = ref.watch(customerControllerProvider).asData?.value;
    final customerMatch = customerSnap?.items
        .where((c) => c['id']?.toString() == rawId.toString())
        .firstOrNull;

    final visitMatch = scheduleData
        ?.where((s) => (s['id_pelanggan'] ?? s['pelangganId'])?.toString() == rawId.toString())
        .firstOrNull;

    // Source of Truth hierarchy: Stream data > customer Match (List) > visit Match (Schedule) > Initial Data
    final activeDataValue =
        (streamCustomer != null ? currentPelanggan : null) ??
        customerMatch ??
        visitMatch ??
        widget.visitData;
    final mergedPelanggan = activeDataValue != null
        ? (activeDataValue is Map
              ? activeDataValue
              : _customerDataToMap(activeDataValue as CustomersTableData?))
        : <String, dynamic>{};
    final imageUrl = mergedPelanggan['foto_toko_url'];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // SSOT: Invalidate the stream to force re-fetch from Drift
          // The stream will automatically update when data changes
          ref.invalidate(customerDetailStreamProvider(customerId));
          // Also trigger a sync from server to update Drift
          try {
            await ref
                .read(customerRepositoryProvider)
                .syncCustomersToDrift(forceRefresh: true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data diperbarui dari server')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Gagal refresh: $e')));
            }
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Collapsible App Bar with Image
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    StoreImage(
                      url: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fallbackIcon: Icons.store_rounded,
                      fallbackIconSize: 64,
                      fallbackBgColor: Colors.grey[300],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Update Foto Toko button
                    Positioned(
                      bottom: 70,
                      right: 12,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _updateFotoToko,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isUploadingPhoto)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _isUploadingPhoto
                                    ? 'Uploading...'
                                    : 'Update Foto',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  currentPelanggan['kode_pelanggan'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    currentPelanggan['status'] ??
                                        currentPelanggan['status_pelanggan'],
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getStatusColor(
                                        currentPelanggan['status'] ??
                                            currentPelanggan['status_pelanggan'],
                                      ),
                                      radius: 3,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (currentPelanggan['status'] ??
                                              currentPelanggan['status_pelanggan'] ??
                                              'PROSPECT')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentPelanggan['nama_toko'] ??
                                currentPelanggan['nama_pelanggan'] ??
                                currentPelanggan['nama_pemilik'] ??
                                'Unknown Customer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  currentPelanggan['alamat_usaha'] ??
                                      currentPelanggan['alamat'] ??
                                      currentPelanggan['alamat_rumah_pemilik'] ??
                                      'Unknown Address',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _showFullDetails(context, currentPelanggan);
                  },
                  child: const Text(
                    'Lihat Data Lengkap',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomerStatCard(
                            label: 'Kunjungan Terakhir',
                            value: _formatLastVisitDate(
                              currentPelanggan['last_visit_date'] ??
                                  customerMatch?['last_visit_date'],
                            ),
                            subtext: _formatDaysAgo(
                              currentPelanggan['days_since_last_visit'] ??
                                  customerMatch?['days_since_last_visit'],
                            ),
                            subicon: Icons.event,
                            subcolor: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomerStatCard(
                            label: 'Total Pesanan',
                            value:
                                (currentPelanggan['orders_this_month'] ??
                                        customerMatch?['orders_this_month'])
                                    ?.toString() ??
                                '0',
                            subtext: _formatGrowthPercentage(
                              currentPelanggan['growth_percentage'] ??
                                  customerMatch?['growth_percentage'],
                            ),
                            subicon: _getGrowthIcon(
                              currentPelanggan['growth_percentage'] ??
                                  customerMatch?['growth_percentage'],
                            ),
                            subcolor: _getGrowthColor(
                              currentPelanggan['growth_percentage'] ??
                                  customerMatch?['growth_percentage'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CustomerFinancialSection(pelanggan: currentPelanggan),
                    const SizedBox(height: 24),

                    CustomerContactSection(pelanggan: currentPelanggan),
                    const SizedBox(height: 24),

                    CustomerLocationCard(
                      pelanggan: currentPelanggan,
                      onEditTap: _pelangganMap != null
                          ? () {
                              context
                                  .push('/customers/tagging', extra: _pelangganMap)
                                  .then((_) {
                                    if (mounted) setState(() => _initData());
                                  });
                            }
                          : null,
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomerBottomBar(
        isCheckedIn: _isCheckedIn,
        isCompleted: _isCompleted,
        isLoading: _isLoading,
        timerStream: _timerStream,
        currentDuration: _getFormattedDuration(),
        onCallTap: () {
          final phone = currentPelanggan['no_hp_pribadi'] ??
              currentPelanggan['no_hp_kontak'] ??
              currentPelanggan['telepon'];
          if (phone != null) {
            launchUrl(Uri.parse('tel:$phone'));
          }
        },
        onCartTap: () {
          final idPelanggan = _pelangganMap?['id'];
          if (idPelanggan == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memuat ID pelanggan. Coba buka ulang halaman ini.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          context.push('/products', extra: {
            'kunjunganId': _currentKunjunganId,
            'pelangganId': idPelanggan,
            'pelangganData': _pelangganMap,
          });
        },
        onCheckInTap: _toggleCheckIn,
      ),
    );
  }
}

