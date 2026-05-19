import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../data/customer_repository.dart';
import '../controllers/customer_controller.dart';
import '../../../visit/presentation/controllers/visit_controller.dart';
import 'package:sales_tracker_mobile/core/map/cached_tile_provider.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddCustomerPage({super.key, this.initialData});

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isContactSameAsOwner = false;
  bool _isSaving = false;

  // A. Data Calon Pelanggan
  final _calonNamaPemilikController = TextEditingController();
  final _calonNoKtpController = TextEditingController();
  final _calonTempatLahirController = TextEditingController();
  final _calonTglLahirController = TextEditingController();
  final _calonNpwpController = TextEditingController();
  final _calonAlamatController = TextEditingController();
  final _calonKodePosController = TextEditingController();
  final _calonTelpController = TextEditingController();
  final _calonHpController = TextEditingController();
  final _calonKotaController = TextEditingController();

  // B. Data Tempat Usaha
  final _usahaNamaOutletController = TextEditingController();
  final _usahaNoNpwpController = TextEditingController();
  final _usahaNamaNpwpController = TextEditingController();
  String? _usahaKlasifikasi; // Selected Category
  final _usahaJenisProdukController = TextEditingController();
  final _usahaBerdiriSejakController = TextEditingController();
  final _usahaAlamatController = TextEditingController();
  final _usahaKecamatanController = TextEditingController();
  final _usahaKotaController = TextEditingController();
  final _usahaProvinsiController = TextEditingController();

  // Location vars
  LatLng _currentLocation = const LatLng(-6.2088, 106.8456); // Jakarta Default
  final MapController _mapController = MapController();

  // Store & KTP Photo
  File? _storePhoto;
  File? _ktpPhoto;
  final ImagePicker _picker = ImagePicker();

  final _usahaTelpController = TextEditingController();
  final _usahaHpController = TextEditingController();
  final _usahaKontakPersonController = TextEditingController();
  final _usahaKontakNoKtpController = TextEditingController();
  final _usahaKontakHpController =
      TextEditingController(); // Added Contact Person HP
  final _usahaAlamatGudangController = TextEditingController();
  final _usahaGudangKotaController = TextEditingController();
  final _usahaGudangTelpController = TextEditingController();
  final _usahaGudangHpController = TextEditingController();
  final _usahaKontakGudangController = TextEditingController();
  String _usahaCaraBayar = 'Tunai'; // Tunai, Giro, Transfer
  final _usahaBankNamaController = TextEditingController();
  final _usahaBankCabangController = TextEditingController();
  final _usahaBankNoRekController = TextEditingController();
  final _usahaBankAtasNamaController = TextEditingController();

  // C. Diisi oleh salesman
  final _salesKreditAwalController = TextEditingController();
  final _salesKreditBerjalanController = TextEditingController();
  String _salesSistemBayar = 'Cash'; // Cash / Kredit
  final _salesTopController = TextEditingController();
  final _salesLainLainController = TextEditingController();

  final List<String> _categories = [
    'Modern Bakery',
    'Big Industry',
    'Medium Industry',
    'Home Industry',
    'P & D',
    'Toko Bahan Kue',
    'Grosir',
    'Retailer',
    'Mini Market',
    'Supermarket',
    'Restoran',
    'Hotel',
    'Kafe',
    'Catering',
    'Lain-lain',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if initialData exists (simplified mapping)
    if (widget.initialData != null) {
      _calonNamaPemilikController.text =
          widget.initialData?['contactName'] ?? '';
      _usahaNamaOutletController.text = widget.initialData?['storeName'] ?? '';
      _usahaKecamatanController.text = widget.initialData?['kecamatan'] ?? '';
      _usahaKotaController.text = widget.initialData?['kota'] ?? '';
      _usahaProvinsiController.text = widget.initialData?['provinsi'] ?? '';

      // Handle Location & Address
      if (widget.initialData?['latitude'] != null &&
          widget.initialData?['longitude'] != null) {
        final lat = widget.initialData!['latitude'] as double;
        final lng = widget.initialData!['longitude'] as double;
        _currentLocation = LatLng(lat, lng);

        if (widget.initialData?['address'] != null) {
          _usahaAlamatController.text = widget.initialData!['address'];
        } else {
          _updateAddressFromLocation(_currentLocation);
        }
      }

      // Handle Photos
      if (widget.initialData?['storePhotoPath'] != null) {
        _storePhoto = File(widget.initialData!['storePhotoPath']);
      }
      if (widget.initialData?['ktpPhotoPath'] != null) {
        _ktpPhoto = File(widget.initialData!['ktpPhotoPath']);
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _calonNamaPemilikController.dispose();
    _calonNoKtpController.dispose();
    _calonTempatLahirController.dispose();
    _calonTglLahirController.dispose();
    _calonNpwpController.dispose();
    _calonAlamatController.dispose();
    _calonKodePosController.dispose();
    _calonTelpController.dispose();
    _calonHpController.dispose();
    _calonKotaController.dispose();

    _usahaNamaOutletController.dispose();
    _usahaNoNpwpController.dispose();
    _usahaNamaNpwpController.dispose();
    _usahaJenisProdukController.dispose();
    _usahaBerdiriSejakController.dispose();
    _usahaAlamatController.dispose();
    _usahaKecamatanController.dispose();
    _usahaKotaController.dispose();
    _usahaProvinsiController.dispose();
    _usahaTelpController.dispose();
    _usahaHpController.dispose();
    _usahaKontakPersonController.dispose();
    _usahaKontakNoKtpController.dispose();
    _usahaKontakHpController.dispose();
    _usahaAlamatGudangController.dispose();
    _usahaGudangKotaController.dispose();
    _usahaGudangTelpController.dispose();
    _usahaGudangHpController.dispose();
    _usahaKontakGudangController.dispose();
    _usahaBankNamaController.dispose();
    _usahaBankCabangController.dispose();
    _usahaBankNoRekController.dispose();
    _usahaBankAtasNamaController.dispose();

    _salesKreditAwalController.dispose();
    _salesKreditBerjalanController.dispose();
    _salesTopController.dispose();
    _salesLainLainController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      final response = await repo.createCustomer(
        namaToko: _usahaNamaOutletController.text,
        namaPemilik: _calonNamaPemilikController.text,
        noHpPribadi: _calonHpController.text,
        alamatUsaha: _usahaAlamatController.text,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        noKtpPemilik: _calonNoKtpController.text,
        tempatLahirPemilik: _calonTempatLahirController.text,
        tanggalLahirPemilik: _calonTglLahirController.text,
        noNpwpPribadi: _calonNpwpController.text,
        alamatRumahPemilik: _calonAlamatController.text,
        kodePosRumah: _calonKodePosController.text,
        kotaRumah: _calonKotaController.text,

        noNpwpUsaha: _usahaNoNpwpController.text,
        namaNpwpUsaha: _usahaNamaNpwpController.text,
        klasifikasiOutlet: _usahaKlasifikasi,
        jenisProdukIndustri: _usahaJenisProdukController.text,
        tahunBerdiri: int.tryParse(_usahaBerdiriSejakController.text),

        kotaUsaha: _usahaKotaController.text,
        kecamatanUsaha: _usahaKecamatanController.text,
        provinsiUsaha: _usahaProvinsiController.text,

        namaKontakPerson: _usahaKontakPersonController.text,
        noKtpKontak: _usahaKontakNoKtpController.text,
        noHpKontak: _usahaKontakHpController.text,

        alamatGudang: _usahaAlamatGudangController.text,
        kotaGudang: _usahaGudangKotaController.text,
        noTelpGudang: _usahaGudangTelpController.text,

        sistemPembayaran: _salesSistemBayar,
        caraPembayaran: _usahaCaraBayar,
        namaBank: _usahaBankNamaController.text,
        cabangBank: _usahaBankCabangController.text,
        noRekening: _usahaBankNoRekController.text,
        atasNamaRekening: _usahaBankAtasNamaController.text,
        topHari: int.tryParse(_salesTopController.text),
        limitKreditAwal: double.tryParse(_salesKreditAwalController.text),
        catatanLain: _salesLainLainController.text,

        status: 'pending', // Mark as pending initially or active if allowed
        storePhoto: _storePhoto,
        ktpPhoto: _ktpPhoto,
      );

      // Invalidate customer list so the new entry appears right away
      ref.invalidate(customerControllerProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data pelanggan berhasil disimpan. Memulai kunjungan...',
          ),
          backgroundColor: AppTheme.success,
        ),
      );

      // Auto check-in to the new customer
      final customerData = response['data'];
      final isOffline = response['is_offline'] == true;

      // Strategy:
      // - Online: response['server_id'] contains the server ID (int)
      // - Offline: response['local_ref'] contains the local_ref (string)
      // Use server_id for online (prevents double-listing in visits)
      // Use local_ref for offline (will be patched after sync)
      final serverId = response['server_id'];
      final localRef = response['local_ref'] ?? customerData?['local_ref'];

      if (serverId != null || localRef != null) {
        // Determine which ID to use: server_id (online) or local_ref (offline)
        final pelangganId = serverId ?? localRef;

        // Prepare customer data for check-in
        final pelangganDataMap = {
          'nama_toko': customerData?['nama_toko'] ?? '',
          'nama_pemilik': customerData?['nama_pemilik'] ?? '',
          'alamat_usaha': customerData?['alamat_usaha'] ?? '',
          'no_hp_pribadi': customerData?['no_hp_pribadi'] ?? '',
          'is_offline': isOffline,
        };

        try {
          final kunjunganId = await ref
              .read(visitControllerProvider.notifier)
              .checkIn(
                jadwalId: null, // Unplanned visit
                pelangganId:
                    pelangganId, // String (local_ref) or int (server ID)
                lat: _currentLocation.latitude,
                long: _currentLocation.longitude,
                jarakValidasi: 0.0, // Because they are right there
                pelangganDataMap: pelangganDataMap,
              );

          if (mounted) {
            // Show appropriate message based on online/offline
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isOffline
                      ? 'Pelanggan disimpan offline. Check-in akan otomatis tersinkron.'
                      : 'Pelanggan berhasil ditambahkan dan dikunjugi.',
                ),
                backgroundColor: AppTheme.success,
              ),
            );

            context.go('/schedule'); // Sets the back stack base

            // Allow go routing to settle before push
            Future.microtask(() {
              if (mounted) {
                context.push(
                  '/customers/detail',
                  extra: {
                    'pelanggan': customerData,
                    'id_kunjungan': kunjunganId.kunjunganId,
                    'waktu_check_in': DateTime.now().toIso8601String(),
                    'is_offline': isOffline,
                  },
                );
              }
            });
          }
        } catch (e) {
          // Checkin failed for some reason
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Check-in otomatis gagal: $e')),
            );
            context.go('/home');
          }
        }
      } else {
        // No ID available - redirect home
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pelanggan berhasil disimpan.'),
              backgroundColor: AppTheme.success,
            ),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // NOTE: In a real app, use a Geocoding API (Google Maps, OpenCage, etc.)
  // to get the address from coordinates.
  Future<void> _updateAddressFromLocation(LatLng point) async {
    setState(() {
      _currentLocation = point;
    });

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

        if (data['display_name'] != null) {
          setState(() {
            _usahaAlamatController.text = data['display_name'];
            if (address != null) {
              _usahaKecamatanController.text =
                  address['suburb'] ??
                  address['district'] ??
                  address['village'] ??
                  '';
              _usahaKotaController.text =
                  address['city'] ??
                  address['city_district'] ??
                  address['regency'] ??
                  '';
              _usahaProvinsiController.text =
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng newPos = LatLng(position.latitude, position.longitude);
    _mapController.move(newPos, 15);
    _updateAddressFromLocation(newPos);
  }

  void _copyFromCalonPelanggan() {
    setState(() {
      _usahaKontakPersonController.text = _calonNamaPemilikController.text;
      _usahaKontakNoKtpController.text = _calonNoKtpController.text;
      // Also copy phone/hp to contact person phone/hp if available
      // Assuming we add a contact person phone field (which is requested)
      // For now I'll map it to a new field I'll create
      _usahaKontakHpController.text = _calonHpController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data Kontak Person berhasil disalin!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isStore) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() {
        if (isStore) {
          _storePhoto = File(photo.path);
        } else {
          _ktpPhoto = File(photo.path);
        }
      });
    }
  }

  void _showImagePickerOptions({bool isStore = true}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isStore);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isStore);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 40, color: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isDate = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        readOnly: isDate,
        onTap: isDate
            ? () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1990),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  controller.text =
                      "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                }
              }
            : null,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Input Data Pelanggan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. DATA CALON PELANGGAN
                    _buildSectionHeader('A. Data Calon Pelanggan'),

                    // Keterangan wajib
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tanda ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Text(
                            '*',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' menandakan field wajib diisi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildTextField(
                      label: 'Nama Pemilik',
                      controller: _calonNamaPemilikController,
                      icon: Icons.person,
                      isRequired: true,
                      validator: (v) =>
                          v!.isEmpty ? 'Nama pemilik wajib diisi' : null,
                    ),
                    _buildTextField(
                      label: 'No. KTP/SIM/Paspor',
                      controller: _calonNoKtpController,
                      inputType: TextInputType.number,
                      icon: Icons.badge,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Tempat Lahir',
                            controller: _calonTempatLahirController,
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Tgl Lahir',
                            controller: _calonTglLahirController,
                            icon: Icons.calendar_today,
                            isDate: true,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      label: 'No. NPWP',
                      controller: _calonNpwpController,
                      inputType: TextInputType.number,
                      icon: Icons.confirmation_number,
                    ),
                    _buildTextField(
                      label: 'Alamat Rumah',
                      controller: _calonAlamatController,
                      maxLines: 3,
                      icon: Icons.home,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Kode Pos',
                            controller: _calonKodePosController,
                            inputType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Kota',
                            controller: _calonKotaController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Telp/Hp',
                            controller: _calonHpController,
                            inputType: TextInputType.phone,
                            icon: Icons.phone_android,
                            isRequired: true,
                            validator: (v) =>
                                v!.isEmpty ? 'No HP wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),

                    // B. DATA TEMPAT USAHA
                    const SizedBox(height: 16),
                    _buildSectionHeader('B. Data Tempat Usaha'),

                    _buildTextField(
                      label: 'Nama Outlet Usaha',
                      controller: _usahaNamaOutletController,
                      icon: Icons.storefront,
                      isRequired: true,
                      validator: (v) =>
                          v!.isEmpty ? 'Nama outlet wajib diisi' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'No. NPWP Usaha',
                            controller: _usahaNoNpwpController,
                            inputType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Nama NPWP',
                            controller: _usahaNamaNpwpController,
                          ),
                        ),
                      ],
                    ),

                    DropdownButtonFormField<String>(
                      initialValue: _usahaKlasifikasi,
                      decoration: InputDecoration(
                        label: RichText(
                          text: TextSpan(
                            text: 'Klasifikasi Outlet (Kategori)',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _usahaKlasifikasi = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Wajib dipilih' : null,
                    ),
                    if (_usahaKlasifikasi == 'Big Industry' ||
                        _usahaKlasifikasi == 'Medium Industry') ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Jenis Produk Industri',
                        controller: _usahaJenisProdukController,
                      ),
                    ],
                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Berdiri Sejak',
                      controller: _usahaBerdiriSejakController,
                      inputType: TextInputType.number,
                      icon: Icons.verified_user,
                    ),

                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Row(
                        children: [
                          Text(
                            'Lokasi Usaha (Pinpoint)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _currentLocation,
                                initialZoom: 13.0,
                                onTap: (_, point) =>
                                    _updateAddressFromLocation(point),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.sales_tracker.mobile',
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
                                        color: Colors.red,
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
                                heroTag: "btn_loc",
                                onPressed: _getCurrentLocation,
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.my_location,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Alamat Usaha',
                      controller: _usahaAlamatController,
                      maxLines: 3,
                      icon: Icons.business,
                      isRequired: true,
                      validator: (v) =>
                          v!.isEmpty ? 'Alamat usaha wajib diisi' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Kecamatan',
                            controller: _usahaKecamatanController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Kota',
                            controller: _usahaKotaController,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Provinsi',
                            controller: _usahaProvinsiController,
                          ),
                        ),
                      ],
                    ),

                    // Checkbox for copying owner data
                    Row(
                      children: [
                        Checkbox(
                          value: _isContactSameAsOwner,
                          activeColor: AppTheme.primary,
                          onChanged: (bool? value) {
                            setState(() {
                              _isContactSameAsOwner = value ?? false;
                              if (_isContactSameAsOwner) {
                                _copyFromCalonPelanggan();
                              } else {
                                // Optional: Clear fields when unchecked? keeping data is safer.
                                // _usahaKontakPersonController.clear();
                                // _usahaKontakNoKtpController.clear();
                                // _usahaKontakHpController.clear();
                              }
                            });
                          },
                        ),
                        const Text(
                          'Samakan dengan data Pemilik',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Kontak Person',
                            controller: _usahaKontakPersonController,
                            icon: Icons.person_pin,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'No KTP (Kontak)',
                            controller: _usahaKontakNoKtpController,
                            inputType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'No HP/Telp',
                            controller: _usahaKontakHpController,
                            inputType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      label: 'Alamat Gudang (Jika beda)',
                      controller: _usahaAlamatGudangController,
                      maxLines: 2,
                      icon: Icons.warehouse,
                    ),

                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        'Cara Pembayaran',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: ['Tunai', 'Giro', 'Transfer'].map((type) {
                        return ChoiceChip(
                          label: Text(type),
                          selected: _usahaCaraBayar == type,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _usahaCaraBayar = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    if (_usahaCaraBayar != 'Tunai') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bank Yang Digunakan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              label: 'Nama Bank',
                              controller: _usahaBankNamaController,
                            ),
                            _buildTextField(
                              label: 'Cabang',
                              controller: _usahaBankCabangController,
                            ),
                            _buildTextField(
                              label: 'No. Rekening',
                              controller: _usahaBankNoRekController,
                              inputType: TextInputType.number,
                            ),
                            _buildTextField(
                              label: 'Atas Nama',
                              controller: _usahaBankAtasNamaController,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // C. DIISI OLEH SALESMAN
                    const SizedBox(height: 16),
                    _buildSectionHeader('C. Diisi Oleh Salesman'),

                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
                      child: Text(
                        'Sistem Pembayaran',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: _salesSistemBayar == 'Cash',
                          onSelected: (selected) =>
                              setState(() => _salesSistemBayar = 'Cash'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Kredit'),
                          selected: _salesSistemBayar == 'Kredit',
                          onSelected: (selected) =>
                              setState(() => _salesSistemBayar = 'Kredit'),
                        ),
                      ],
                    ),
                    if (_salesSistemBayar == 'Kredit')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Limit Awal (Rp)',
                                    controller: _salesKreditAwalController,
                                    inputType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Limit Berjalan (Rp)',
                                    controller: _salesKreditBerjalanController,
                                    inputType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            _buildTextField(
                              label: 'Term Of Payment / TOP (Hari)',
                              controller: _salesTopController,
                              inputType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Lain-lain',
                      controller: _salesLainLainController,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Data Foto Toko'),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImagePickerOptions(isStore: true),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: _storePhoto != null
                                ? DecorationImage(
                                    image: FileImage(_storePhoto!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _storePhoto == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap untuk ambil foto toko',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),

                    _buildSectionHeader('Data Foto KTP'),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImagePickerOptions(isStore: false),
                        child: Container(
                          width: double.infinity,
                          height: 200, // Same height for consistency
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: _ktpPhoto != null
                                ? DecorationImage(
                                    image: FileImage(_ktpPhoto!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _ktpPhoto == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap untuk ambil foto KTP',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Data Pelanggan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
