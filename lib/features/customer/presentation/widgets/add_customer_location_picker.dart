import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:sales_tracker_mobile/core/map/cached_tile_provider.dart';
import 'package:sales_tracker_mobile/core/services/location_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';

/// Map + GPS button + reverse-geocode picker for the new customer's
/// store location.
///
/// Auto-fills [alamatController], [kecamatanController], [kotaController],
/// and [provinsiController] when the location changes (via tap or GPS).
class AddCustomerLocationPicker extends StatefulWidget {
  const AddCustomerLocationPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
    required this.alamatController,
    required this.kecamatanController,
    required this.kotaController,
    required this.provinsiController,
  });

  final LatLng initialLocation;
  final ValueChanged<LatLng> onLocationChanged;
  final TextEditingController alamatController;
  final TextEditingController kecamatanController;
  final TextEditingController kotaController;
  final TextEditingController provinsiController;

  @override
  State<AddCustomerLocationPicker> createState() =>
      _AddCustomerLocationPickerState();
}

class _AddCustomerLocationPickerState extends State<AddCustomerLocationPicker> {
  late final MapController _mapController;
  late LatLng _currentLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialLocation;
  }

  Future<void> _updateAddressFromLocation(LatLng point) async {
    setState(() => _currentLocation = point);
    widget.onLocationChanged(point);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.sales_tracker.mobile'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (data['display_name'] != null && mounted) {
          setState(() {
            widget.alamatController.text = data['display_name'];
            if (address != null) {
              widget.kecamatanController.text = address['suburb'] ??
                  address['district'] ??
                  address['village'] ??
                  '';
              widget.kotaController.text = address['city'] ??
                  address['city_district'] ??
                  address['regency'] ??
                  '';
              widget.provinsiController.text =
                  address['state'] ?? address['province'] ?? '';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    final Position position;
    try {
      position = await LocationService.getCurrentWithPermission();
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    }
    final newPos = LatLng(position.latitude, position.longitude);
    _mapController.move(newPos, 15);
    await _updateAddressFromLocation(newPos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                'Lokasi Usaha (Pinpoint)',
                style: AppTextStyles.titleMedium,
              ),
              Text(
                ' *',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    onTap: (_, point) => _updateAddressFromLocation(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sales_tracker.mobile',
                      tileProvider: CachedTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
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
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'btn_loc',
                    onPressed: _getCurrentLocation,
                    backgroundColor: AppColors.surface,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
