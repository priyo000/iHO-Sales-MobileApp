import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:sales_tracker_mobile/core/map/cached_tile_provider.dart';
import 'package:sales_tracker_mobile/core/services/location_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';
import 'package:sales_tracker_mobile/core/widgets/app_text_field.dart';
import 'package:sales_tracker_mobile/features/customer/data/customer_repository.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/pages/customer_tagging_page.dart';

class QuickProspectingPage extends ConsumerStatefulWidget {
  /// When [embeddedInTab] is true the AppBar is hidden — the page is rendered
  /// inside a TabBarView so it already has a visible navigation context.
  final bool embeddedInTab;

  const QuickProspectingPage({super.key, this.embeddedInTab = false});

  @override
  ConsumerState<QuickProspectingPage> createState() =>
      _QuickProspectingPageState();
}

class _QuickProspectingPageState extends ConsumerState<QuickProspectingPage> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinsiController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();

  File? _storePhoto;
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  String? _selectedRejectionReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _contactNameController.dispose();
    _addressController.dispose();
    _provinsiController.dispose();
    _kotaController.dispose();
    _kecamatanController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() => _storePhoto = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService.getCurrentWithPermission();
      setState(() => _currentLocation = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      _getAddressFromNominatim(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getAddressFromNominatim(double lat, double lng) async {
    try {
      final data = await NominatimService.reverseGeocode(lat, lng);
      if (data != null && mounted) {
        final extracted = NominatimService.extractAddress(data);
        setState(() {
          _addressController.text = extracted['alamat'] ?? '';
          _kecamatanController.text = extracted['kecamatan'] ?? '';
          _kotaController.text = extracted['kota'] ?? '';
          _provinsiController.text = extracted['provinsi'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('[Prospecting] Nominatim error: $e');
    }
  }

  void _handleRejection() {
    if (_storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter store name')),
      );
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture location first (Pin Location)'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.xl,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporkan Penolakan', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Mengapa penawaran ditolak?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    'Tidak Tertarik',
                    'Harga terlalu mahal',
                    'Kontrak Kompetitor',
                    'Pemilik tidak ada',
                  ].map((reason) {
                    final selected = _selectedRejectionReason == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: selected,
                      onSelected: (s) => setStateModal(
                        () => _selectedRejectionReason = s ? reason : null,
                      ),
                      selectedColor: AppColors.error.withValues(alpha: 0.1),
                      labelStyle: AppTextStyles.bodyMedium.copyWith(
                        color: selected
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        side: BorderSide(
                          color: selected ? AppColors.error : AppColors.border,
                        ),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.destructive(
                  label: 'Kirim Penolakan',
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitRejection(context, setStateModal),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitRejection(
    BuildContext modalContext,
    StateSetter setStateModal,
  ) async {
    if (_selectedRejectionReason == null) {
      ScaffoldMessenger.of(modalContext).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setStateModal(() => _isSubmitting = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      await repo.createCustomer(
        namaToko: _storeNameController.text,
        namaPemilik: _contactNameController.text.isNotEmpty
            ? _contactNameController.text
            : '-',
        noHpPribadi: '-',
        alamatUsaha: _addressController.text.isNotEmpty
            ? _addressController.text
            : '-',
        kecamatanUsaha: _kecamatanController.text,
        kotaUsaha: _kotaController.text,
        provinsiUsaha: _provinsiController.text,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        status: 'prospect',
        catatanLain: 'Alasan Penolakan: $_selectedRejectionReason',
        storePhoto: _storePhoto,
      );

      if (modalContext.mounted) {
        Navigator.pop(modalContext);
        modalContext.pop();
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(content: Text('Penolakan berhasil dilaporkan')),
        );
      }
    } catch (e) {
      if (modalContext.mounted) {
        ScaffoldMessenger.of(modalContext).showSnackBar(
          SnackBar(content: Text('Failed to report: $e')),
        );
      }
    } finally {
      setStateModal(() => _isSubmitting = false);
    }
  }

  void _handleRegistration() {
    if (_storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter store name')),
      );
      return;
    }

    context.push(
      '/add-customer',
      extra: {
        'storeName': _storeNameController.text,
        'contactName': _contactNameController.text,
        'storePhotoPath': _storePhoto?.path,
        'latitude': _currentLocation?.latitude,
        'longitude': _currentLocation?.longitude,
        'address': _addressController.text,
        'kecamatan': _kecamatanController.text,
        'kota': _kotaController.text,
        'provinsi': _provinsiController.text,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.embeddedInTab
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
              title: const Text('Prospect Cepat'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {},
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoCapture(),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('Nama Toko (Wajib)'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _storeNameController,
                    hint: 'e.g. Downtown Coffee Shop',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('Nama Kontak/Pemilik (Opsional)'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _contactNameController,
                    hint: 'Enter name',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('Alamat (Otomatis)'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _addressController,
                    hint: 'Tap pin location to auto-fill',
                    type: AppTextFieldType.multiline,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLocationHeader(),
                  const SizedBox(height: AppSpacing.md),
                  _buildMap(),
                  if (_currentLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                AppButton.secondary(
                  label: 'Laporkan Penolakan',
                  leadingIcon: Icons.thumb_down,
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  onPressed: _handleRejection,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Daftarkan jadi Pelanggan',
                  leadingIcon: Icons.person_add,
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  onPressed: _handleRegistration,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCapture() {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: _storePhoto != null ? Colors.transparent : AppColors.primary,
        strokeWidth: 1.5,
        dashWidth: 6,
        dashSpace: 4,
        radius: AppSpacing.radiusXl,
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _storePhoto != null
              ? null
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          image: _storePhoto != null
              ? DecorationImage(
                  image: FileImage(_storePhoto!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: _storePhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 28,
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Capture Store Photo',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Current Location', style: AppTextStyles.titleLarge),
        TextButton.icon(
          onPressed: _getCurrentLocation,
          icon: _isLoadingLocation
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 18),
          label: Text(
            _currentLocation != null ? 'Update Pin' : 'Pin Location',
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: Stack(
          children: [
            ColoredBox(
              color: AppColors.divider,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation != null
                      ? LatLng(
                          _currentLocation!.latitude,
                          _currentLocation!.longitude,
                        )
                      : const LatLng(-6.200000, 106.816666),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sales_tracker.mobile',
                    tileProvider: CachedTileProvider(),
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentLocation!.latitude,
                            _currentLocation!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.error,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (_currentLocation == null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: AppColors.surface.withValues(alpha: 0.7),
                  child: Text(
                    "Tap 'Pin Location' to activate map",
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.titleMedium);
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    canvas.drawPath(_createDashedPath(path, dashWidth, dashSpace), paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final path = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        path.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}
