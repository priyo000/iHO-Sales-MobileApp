import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:sales_tracker_mobile/core/services/location_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';
import 'package:sales_tracker_mobile/core/widgets/app_text_field.dart';

import '../controllers/customer_controller.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'SalesTrackerIntiGroup/1.0 (contact@intigroup.co.id)',
    'Accept-Language': 'id,en',
  };

  static Future<Map<String, dynamic>?> reverseGeocode(
    double lat,
    double lon,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/reverse?lat=$lat&lon=$lon&format=jsonv2&addressdetails=1',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      log('[Nominatim] Reverse geocode gagal: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        '$_baseUrl/search?q=${Uri.encodeComponent(query)}'
        '&format=jsonv2&addressdetails=1&limit=6&countrycodes=id',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      log('[Nominatim] Search gagal: $e');
    }
    return [];
  }

  static Map<String, String> extractAddress(Map<String, dynamic> data) {
    final addr = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final displayName = data['display_name']?.toString() ?? '';

    final components = <String>[];
    for (final key in [
      'road',
      'neighbourhood',
      'hamlet',
      'suburb',
      'village',
    ]) {
      final val = addr[key]?.toString();
      if (val != null && val.isNotEmpty) components.add(val);
    }
    final alamat = components.isNotEmpty
        ? components.join(', ')
        : displayName.split(',').take(3).join(',').trim();

    final kecamatan = addr['subdistrict']?.toString() ??
        addr['suburb']?.toString() ??
        addr['county']?.toString() ??
        '';
    final kota = addr['city']?.toString() ??
        addr['town']?.toString() ??
        addr['regency']?.toString() ??
        addr['county']?.toString() ??
        '';
    final provinsi = addr['state']?.toString() ?? '';

    return {
      'alamat': alamat,
      'kecamatan': kecamatan,
      'kota': kota,
      'provinsi': provinsi,
    };
  }
}

class CustomerTaggingPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerTaggingPage({super.key, required this.customer});

  @override
  ConsumerState<CustomerTaggingPage> createState() =>
      _CustomerTaggingPageState();
}

class _CustomerTaggingPageState extends ConsumerState<CustomerTaggingPage> {
  late final MapController _mapController;
  LatLng? _selectedLocation;

  bool _isLoading = false;
  bool _isGeocoding = false;
  bool _isSaving = false;

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  bool _showSearchResults = false;

  final _alamatController = TextEditingController();
  final _kotaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _provinsiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final lat = double.tryParse(widget.customer['latitude']?.toString() ?? '');
    final lng = double.tryParse(widget.customer['longitude']?.toString() ?? '');
    if (lat != null && lng != null) {
      _selectedLocation = LatLng(lat, lng);
    }

    _alamatController.text = widget.customer['alamat_usaha'] ?? '';
    _kotaController.text = widget.customer['kota_usaha'] ?? '';
    _kecamatanController.text = widget.customer['kecamatan_usaha'] ?? '';
    _provinsiController.text = widget.customer['provinsi_usaha'] ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _alamatController.dispose();
    _kotaController.dispose();
    _kecamatanController.dispose();
    _provinsiController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    setState(() => _isGeocoding = true);
    try {
      final result = await NominatimService.reverseGeocode(
        latlng.latitude,
        latlng.longitude,
      );
      if (result != null && mounted) {
        final extracted = NominatimService.extractAddress(result);
        setState(() {
          if (extracted['alamat']!.isNotEmpty) {
            _alamatController.text = extracted['alamat']!;
          }
          if (extracted['kecamatan']!.isNotEmpty) {
            _kecamatanController.text = extracted['kecamatan']!;
          }
          if (extracted['kota']!.isNotEmpty) {
            _kotaController.text = extracted['kota']!;
          }
          if (extracted['provinsi']!.isNotEmpty) {
            _provinsiController.text = extracted['provinsi']!;
          }
        });
        _showInfoSnack('Alamat terdeteksi dari lokasi peta');
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isSearching = true);
      final results = await NominatimService.search(value);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    if (lat == null || lon == null) return;

    final newLoc = LatLng(lat, lon);
    final extracted = NominatimService.extractAddress(result);

    setState(() {
      _selectedLocation = newLoc;
      _showSearchResults = false;
      _searchController.text = result['display_name']
              ?.toString()
              .split(',')
              .take(2)
              .join(',')
              .trim() ??
          '';
      if (extracted['alamat']!.isNotEmpty) {
        _alamatController.text = extracted['alamat']!;
      }
      if (extracted['kecamatan']!.isNotEmpty) {
        _kecamatanController.text = extracted['kecamatan']!;
      }
      if (extracted['kota']!.isNotEmpty) {
        _kotaController.text = extracted['kota']!;
      }
      if (extracted['provinsi']!.isNotEmpty) {
        _provinsiController.text = extracted['provinsi']!;
      }
    });

    _mapController.move(newLoc, 17);
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await LocationService.getCurrentWithPermission();
      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = newLoc);
      _mapController.move(newLoc, 17);
      await _reverseGeocode(newLoc);
    } catch (e) {
      if (mounted) _showErrorSnack('Gagal mengambil lokasi GPS: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapTap(TapPosition _, LatLng latlng) async {
    setState(() {
      _selectedLocation = latlng;
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
    await _reverseGeocode(latlng);
  }

  Future<void> _save() async {
    if (_selectedLocation == null) {
      _showErrorSnack('Silakan tentukan titik lokasi toko di peta');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result =
          await ref.read(customerControllerProvider.notifier).updateCustomer(
                id: widget.customer['id'].toString(),
                latitude: _selectedLocation!.latitude,
                longitude: _selectedLocation!.longitude,
                alamatUsaha: _alamatController.text.trim(),
                kotaUsaha: _kotaController.text.trim(),
                kecamatanUsaha: _kecamatanController.text.trim(),
                provinsiUsaha: _provinsiController.text.trim(),
              );

      if (!mounted) return;

      final isOffline = result['is_offline'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'Tersimpan lokal, akan sync saat online'
                : 'Lokasi & Alamat berhasil diperbarui',
          ),
          backgroundColor:
              isOffline ? AppColors.warning : AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) _showErrorSnack('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showInfoSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Tagging Lokasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showSearchResults) _buildSearchResults(),
          Expanded(flex: 5, child: _buildMap()),
          Expanded(flex: 5, child: _buildForm()),
        ],
      ),
      bottomBar: _buildBottomBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onTap: () {
          if (_searchResults.isNotEmpty) {
            setState(() => _showSearchResults = true);
          }
        },
        decoration: InputDecoration(
          hintText: 'Cari alamat atau nama tempat...',
          prefixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _showSearchResults = false;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      color: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: AppSpacing.lg),
        itemBuilder: (context, i) {
          final item = _searchResults[i];
          final name = item['display_name']?.toString() ?? '';
          final parts = name.split(',');
          final primary = parts.first.trim();
          final secondary = parts.skip(1).take(3).join(',').trim();
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            title: Text(
              primary,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
            ),
            subtitle: secondary.isNotEmpty
                ? Text(
                    secondary,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                  )
                : null,
            onTap: () => _selectSearchResult(item),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                _selectedLocation ?? const LatLng(-6.175392, 106.827153),
            initialZoom: _selectedLocation != null ? 16 : 12,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.inti_group.sales_tracker',
            ),
            if (_selectedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation!,
                    width: 50,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 42,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (_isGeocoding)
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Material(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Text(
                      'Mendeteksi alamat dari lokasi...',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_selectedLocation == null)
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: IgnorePointer(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 2,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Ketuk peta atau gunakan GPS untuk menentukan lokasi toko',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: FloatingActionButton.small(
            heroTag: 'gps_btn',
            onPressed: _isLoading ? null : _useCurrentLocation,
            backgroundColor: AppColors.surface,
            tooltip: 'Gunakan Lokasi Saya',
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
        if (_selectedLocation != null)
          Positioned(
            left: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.surface,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return AppCard(
      padding: EdgeInsets.zero,
      shadow: true,
      bordered: false,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_location_alt,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Detail Alamat Usaha',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (_isGeocoding)
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mendeteksi...',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  )
                else
                  Text(
                    'Otomatis dari peta',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              height: 2,
              width: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _alamatController,
              label: 'Alamat Lengkap',
              type: AppTextFieldType.multiline,
              maxLines: 2,
              prefixIcon: Icons.home_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _kecamatanController,
                    label: 'Kecamatan',
                    prefixIcon: Icons.map_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _kotaController,
                    label: 'Kota/Kabupaten',
                    prefixIcon: Icons.location_city_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _provinsiController,
              label: 'Provinsi',
              prefixIcon: Icons.flag_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton.primary(
            label: _selectedLocation == null
                ? 'Tentukan lokasi di peta dahulu'
                : 'Simpan Lokasi & Alamat',
            leadingIcon: Icons.save_outlined,
            size: AppButtonSize.lg,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: (_isSaving || _selectedLocation == null) ? null : _save,
          ),
        ),
      ),
    );
  }
}
