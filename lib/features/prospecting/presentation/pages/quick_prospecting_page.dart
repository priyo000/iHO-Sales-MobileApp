import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'dart:ui';

import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_tracker_mobile/features/customer/data/customer_repository.dart';
import 'package:sales_tracker_mobile/core/map/cached_tile_provider.dart';
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

  // New State Variables
  File? _storePhoto;
  Position? _currentLocation;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinsiController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;
  final ImagePicker _picker = ImagePicker();

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
        imageQuality: 85, // Good balance
        maxWidth: 1920, // Reasonable max width
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() {
          _storePhoto = File(photo.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to capture photo: $e')));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Check Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // 2. Check Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // 3. Get Position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() => _currentLocation = position);

      // Move map & Get Address
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      _getAddressFromNominatim(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() => _isLoadingLocation = false);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter store name')));
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
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporkan Penolakan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mengapa penawaran ditolak?',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'Tidak Tertarik',
                            'Harga terlalu mahal',
                            'Kontrak Kompetitor',
                            'Pemilik tidak ada',
                          ]
                          .map(
                            (reason) => ChoiceChip(
                              label: Text(reason),
                              selected: _selectedRejectionReason == reason,
                              onSelected: (selected) {
                                setStateModal(() {
                                  _selectedRejectionReason = selected
                                      ? reason
                                      : null;
                                });
                              },
                              selectedColor: AppTheme.error.withValues(
                                alpha: 0.1,
                              ),
                              labelStyle: TextStyle(
                                color: _selectedRejectionReason == reason
                                    ? AppTheme.error
                                    : Colors.grey[700],
                                fontWeight: _selectedRejectionReason == reason
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _selectedRejectionReason == reason
                                      ? AppTheme.error
                                      : Colors.grey.shade300,
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_selectedRejectionReason == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a reason'),
                                ),
                              );
                              return;
                            }

                            setStateModal(() => _isSubmitting = true);
                            try {
                              final repo = ref.read(customerRepositoryProvider);
                              await repo.createCustomer(
                                namaToko: _storeNameController.text,
                                namaPemilik:
                                    _contactNameController.text.isNotEmpty
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
                                catatanLain:
                                    'Alasan Penolakan: $_selectedRejectionReason',
                                storePhoto: _storePhoto,
                              );

                              if (context.mounted) {
                                Navigator.pop(context); // close bottom sheet
                                context.pop(); // go back
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Penolakan berhasil dilaporkan',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to report: $e'),
                                  ),
                                );
                              }
                            } finally {
                              setStateModal(() => _isSubmitting = false);
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Kirim Penolakan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleRegistration() {
    if (_storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter store name')));
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.embeddedInTab
          ? null // header already provided by the parent TabBar
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Prospect Cepat',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.black87),
                  onPressed: () {},
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashed Photo Capture Area
                    CustomPaint(
                      painter: _DashedRectPainter(
                        color: _storePhoto != null
                            ? Colors.transparent
                            : AppTheme.primary,
                        strokeWidth: 1.5,
                        dashWidth: 6,
                        dashSpace: 4,
                        radius: 16,
                      ),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _storePhoto != null
                              ? null
                              : AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
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
                            borderRadius: BorderRadius.circular(16),
                            child: _storePhoto == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 28,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Capture Store Photo',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Store Name
                    const Text(
                      'Nama Toko (Wajib)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _storeNameController,
                      hint: 'e.g. Downtown Coffee Shop',
                    ),
                    const SizedBox(height: 20),

                    // Contact Name
                    const Text(
                      'Nama Kontak/Pemilik (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _contactNameController,
                      hint: 'Enter name',
                    ),
                    const SizedBox(height: 20),

                    // Address (Auto-filled)
                    const Text(
                      'Alamat (Otomatis)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hint: 'Tap pin location to auto-fill',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(
                            _currentLocation != null
                                ? 'Update Pin'
                                : 'Pin Location',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 250, // Increased height for Map
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _currentLocation != null
                                    ? LatLng(
                                        _currentLocation!.latitude,
                                        _currentLocation!.longitude,
                                      )
                                    : const LatLng(
                                        -6.200000,
                                        106.816666,
                                      ), // Default Jakarta
                                initialZoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.sales_tracker.mobile',
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
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            // Helper text overlay if no location
                            if (_currentLocation == null)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.white.withValues(alpha: 0.7),
                                  child: Text(
                                    "Tap 'Pin Location' to activate map",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_currentLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleRejection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[800],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.thumb_down, size: 20),
                      label: const Text(
                        'Laporkan Penolakan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0, // Flat look as per typically modern UI
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text(
                        'Daftarkan jadi Pelanggan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// (Removed _ReasonChip since we moved it to ChoiceChip inline in bottom sheet)

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
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path path = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
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
