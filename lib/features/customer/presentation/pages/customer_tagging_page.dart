import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/customer_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nominatim Service — Reverse & Forward Geocoding (OpenStreetMap)
// ─────────────────────────────────────────────────────────────────────────────

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'SalesTrackerIntiGroup/1.0 (contact@intigroup.co.id)',
    'Accept-Language': 'id,en',
  };

  /// Reverse geocoding: koordinat → data alamat
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

  /// Forward geocoding: query teks → daftar hasil
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

  /// Ekstrak field alamat dari response Nominatim
  static Map<String, String> extractAddress(Map<String, dynamic> data) {
    final addr = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final displayName = data['display_name']?.toString() ?? '';

    // Susun alamat lengkap dari komponen Nominatim
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

    final kecamatan =
        addr['subdistrict']?.toString() ??
        addr['suburb']?.toString() ??
        addr['county']?.toString() ??
        '';
    final kota =
        addr['city']?.toString() ??
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

// ─────────────────────────────────────────────────────────────────────────────
// CustomerTaggingPage
// ─────────────────────────────────────────────────────────────────────────────

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

  // Search
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  bool _showSearchResults = false;

  // Form
  final _alamatController = TextEditingController();
  final _kotaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _provinsiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Inisialisasi koordinat & form dari data pelanggan
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

  // ── Reverse Geocoding ────────────────────────────────────────────────────

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
        _showGeocodingSnack('📍 Alamat terdeteksi dari lokasi peta');
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  // ── Forward Search ───────────────────────────────────────────────────────

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
      _searchController.text =
          result['display_name']
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

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final newLoc = LatLng(position.latitude, position.longitude);

      setState(() => _selectedLocation = newLoc);
      _mapController.move(newLoc, 17);

      // Auto reverse geocode after GPS
      await _reverseGeocode(newLoc);
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Gagal mengambil lokasi GPS: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Map Tap ──────────────────────────────────────────────────────────────

  Future<void> _onMapTap(TapPosition _, LatLng latlng) async {
    setState(() => _selectedLocation = latlng);
    FocusScope.of(context).unfocus();
    setState(() => _showSearchResults = false);
    // Auto reverse geocode on map tap
    await _reverseGeocode(latlng);
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_selectedLocation == null) {
      _showErrorSnack('Silakan tentukan titik lokasi toko di peta');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(customerControllerProvider.notifier)
          .updateCustomer(
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
                ? '📦 Tersimpan lokal, akan sync saat online'
                : '✅ Lokasi & Alamat berhasil diperbarui!',
          ),
          backgroundColor: isOffline ? Colors.orange[700] : AppTheme.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) _showErrorSnack('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Snack Helpers ────────────────────────────────────────────────────────

  void _showGeocodingSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primary,
        ),
      );
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tagging Lokasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────
          _buildSearchBar(),

          // ── Search Results Dropdown ───────────────────────────────────
          if (_showSearchResults) _buildSearchResults(),

          // ── Map ───────────────────────────────────────────────────────
          Expanded(flex: 5, child: _buildMap()),

          // ── Form ──────────────────────────────────────────────────────
          Expanded(flex: 5, child: _buildForm()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.white,
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
                  padding: EdgeInsets.all(12),
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
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
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
              color: AppTheme.primary,
              size: 20,
            ),
            title: Text(
              primary,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: secondary.isNotEmpty
                ? Text(
                    secondary,
                    style: const TextStyle(fontSize: 11),
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
                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 42),
                        SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Geocoding loading indicator
        if (_isGeocoding)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(8),
              elevation: 3,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Mendeteksi alamat dari lokasi...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Hint label bila belum ada pin
        if (_selectedLocation == null)
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ketuk peta atau gunakan GPS untuk menentukan lokasi toko',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // GPS Button
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'gps_btn',
            onPressed: _isLoading ? null : _useCurrentLocation,
            backgroundColor: Colors.white,
            tooltip: 'Gunakan Lokasi Saya',
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: AppTheme.primary),
          ),
        ),

        // Koordinat badge
        if (_selectedLocation != null)
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.edit_location_alt,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Detail Alamat Usaha',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isGeocoding)
                  const Row(
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Mendeteksi...',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  )
                else
                  Text(
                    'Otomatis dari peta',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTextField(
              label: 'Alamat Lengkap',
              controller: _alamatController,
              maxLines: 2,
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Kecamatan',
                    controller: _kecamatanController,
                    icon: Icons.map_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    label: 'Kota/Kabupaten',
                    controller: _kotaController,
                    icon: Icons.location_city_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Provinsi',
              controller: _provinsiController,
              icon: Icons.flag_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey[500])
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0x1A000000))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_isSaving || _selectedLocation == null) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSaving
                  ? 'Menyimpan...'
                  : _selectedLocation == null
                  ? 'Tentukan lokasi di peta dahulu'
                  : 'Simpan Lokasi & Alamat',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
