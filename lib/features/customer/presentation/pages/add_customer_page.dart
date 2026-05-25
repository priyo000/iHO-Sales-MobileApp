import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/utils/formatters.dart';
import 'package:sales_tracker_mobile/core/widgets/app_button.dart';
import 'package:sales_tracker_mobile/core/widgets/app_gap.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';

import '../../../../core/constants/customer_status.dart';
import '../../../../core/constants/payment.dart';
import '../../data/customer_repository.dart';
import '../../../visit/presentation/controllers/visit_controller.dart';
import '../controllers/customer_controller.dart';
import '../widgets/add_customer_business_form.dart';
import '../widgets/add_customer_location_picker.dart';
import '../widgets/add_customer_owner_form.dart';
import '../widgets/add_customer_photo_picker.dart';
import '../widgets/add_customer_summary_section.dart';

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
  final _calonHpController = TextEditingController();
  final _calonKotaController = TextEditingController();

  // B. Data Tempat Usaha
  final _usahaNamaOutletController = TextEditingController();
  final _usahaNoNpwpController = TextEditingController();
  final _usahaNamaNpwpController = TextEditingController();
  String? _usahaKlasifikasi;
  final _usahaJenisProdukController = TextEditingController();
  final _usahaBerdiriSejakController = TextEditingController();
  final _usahaAlamatController = TextEditingController();
  final _usahaKecamatanController = TextEditingController();
  final _usahaKotaController = TextEditingController();
  final _usahaProvinsiController = TextEditingController();

  // Location
  LatLng _currentLocation = const LatLng(-6.2088, 106.8456);

  // Photos
  File? _storePhoto;
  File? _ktpPhoto;

  final _usahaKontakPersonController = TextEditingController();
  final _usahaKontakNoKtpController = TextEditingController();
  final _usahaKontakHpController = TextEditingController();
  final _usahaAlamatGudangController = TextEditingController();
  final _usahaGudangTelpController = TextEditingController();
  final _usahaGudangKotaController = TextEditingController();
  String _usahaCaraBayar = PaymentMethod.tunai.code;
  final _usahaBankNamaController = TextEditingController();
  final _usahaBankCabangController = TextEditingController();
  final _usahaBankNoRekController = TextEditingController();
  final _usahaBankAtasNamaController = TextEditingController();

  // C. Diisi oleh salesman
  final _salesKreditAwalController = TextEditingController();
  final _salesKreditBerjalanController = TextEditingController();
  String _salesSistemBayar = PaymentSystem.cash.code;
  final _salesTopController = TextEditingController();
  final _salesLainLainController = TextEditingController();

  static const List<String> _categories = [
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
    final initial = widget.initialData;
    if (initial != null) {
      _calonNamaPemilikController.text = initial['contactName'] ?? '';
      _usahaNamaOutletController.text = initial['storeName'] ?? '';
      _usahaKecamatanController.text = initial['kecamatan'] ?? '';
      _usahaKotaController.text = initial['kota'] ?? '';
      _usahaProvinsiController.text = initial['provinsi'] ?? '';

      if (initial['latitude'] != null && initial['longitude'] != null) {
        final lat = initial['latitude'] as double;
        final lng = initial['longitude'] as double;
        _currentLocation = LatLng(lat, lng);

        if (initial['address'] != null) {
          _usahaAlamatController.text = initial['address'];
        }
      }

      if (initial['storePhotoPath'] != null) {
        _storePhoto = File(initial['storePhotoPath']);
      }
      if (initial['ktpPhotoPath'] != null) {
        _ktpPhoto = File(initial['ktpPhotoPath']);
      }
    }
  }

  @override
  void dispose() {
    _calonNamaPemilikController.dispose();
    _calonNoKtpController.dispose();
    _calonTempatLahirController.dispose();
    _calonTglLahirController.dispose();
    _calonNpwpController.dispose();
    _calonAlamatController.dispose();
    _calonKodePosController.dispose();
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
    _usahaKontakPersonController.dispose();
    _usahaKontakNoKtpController.dispose();
    _usahaKontakHpController.dispose();
    _usahaAlamatGudangController.dispose();
    _usahaGudangTelpController.dispose();
    _usahaGudangKotaController.dispose();
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
        status: CustomerStatus.pending.code,
        storePhoto: _storePhoto,
        ktpPhoto: _ktpPhoto,
      );

      ref.invalidate(customerControllerProvider);
      if (!mounted) return;
      _showSnack('Data pelanggan berhasil disimpan. Memulai kunjungan...',
          color: AppColors.success);
      await _handleAfterCustomerCreated(response);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _handleAfterCustomerCreated(Map<String, dynamic> response) async {
    final customerData = response['data'] as Map<String, dynamic>? ?? {};
    final isOffline = response['is_offline'] == true;
    final serverId = response['server_id'];
    final localRef = response['local_ref'] ?? customerData['local_ref'];
    final pelangganId = isOffline ? localRef : (serverId ?? localRef);

    if (pelangganId == null) {
      if (!mounted) return;
      _showSnack('Pelanggan berhasil disimpan.', color: AppColors.success);
      context.go('/home');
      return;
    }

    final namaToko =
        customerData['nama_toko'] ?? _usahaNamaOutletController.text;
    final namaPemilik =
        customerData['nama_pemilik'] ?? _calonNamaPemilikController.text;
    final alamatUsaha =
        customerData['alamat_usaha'] ?? _usahaAlamatController.text;
    final noHpPribadi =
        customerData['no_hp_pribadi'] ?? _calonHpController.text;

    final pelangganDataMap = {
      'nama_toko': namaToko,
      'nama_pemilik': namaPemilik,
      'alamat_usaha': alamatUsaha,
      'no_hp_pribadi': noHpPribadi,
      'is_offline': isOffline,
    };

    try {
      final kunjunganId = await ref
          .read(visitControllerProvider.notifier)
          .checkIn(
            jadwalId: null,
            pelangganId: pelangganId,
            lat: _currentLocation.latitude,
            long: _currentLocation.longitude,
            jarakValidasi: 0.0,
            pelangganDataMap: pelangganDataMap,
          );

      if (!mounted) return;
      _showSnack(
        isOffline
            ? 'Pelanggan disimpan offline. Check-in akan otomatis tersinkron.'
            : 'Pelanggan berhasil ditambahkan dan dikunjungi.',
        color: AppColors.success,
      );

      final pelangganForDetail = {
        ...customerData,
        'id': pelangganId,
        'nama_toko': namaToko,
        'nama_pemilik': namaPemilik,
        'alamat_usaha': alamatUsaha,
        'no_hp_pribadi': noHpPribadi,
      };

      context.go('/schedule');
      Future.microtask(() {
        if (!mounted) return;
        context.push('/customers/detail', extra: {
          'pelanggan': pelangganForDetail,
          'id_kunjungan': kunjunganId.kunjunganId,
          'waktu_check_in': Formatters.nowServerIso(),
          'is_offline': isOffline,
        });
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Check-in otomatis gagal: $e');
      context.go('/home');
    }
  }

  void _copyFromCalonPelanggan() {
    setState(() {
      _usahaKontakPersonController.text = _calonNamaPemilikController.text;
      _usahaKontakNoKtpController.text = _calonNoKtpController.text;
      _usahaKontakHpController.text = _calonHpController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data Kontak Person berhasil disalin!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary),
          ),
          const AppGap.xs(),
          Container(height: 2, width: 40, color: AppColors.primary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Input Data Pelanggan'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('A. Data Calon Pelanggan'),
              AddCustomerOwnerForm(
                namaPemilikController: _calonNamaPemilikController,
                noKtpController: _calonNoKtpController,
                tempatLahirController: _calonTempatLahirController,
                tglLahirController: _calonTglLahirController,
                npwpController: _calonNpwpController,
                alamatController: _calonAlamatController,
                kodePosController: _calonKodePosController,
                kotaController: _calonKotaController,
                hpController: _calonHpController,
              ),
              const AppGap.lg(),
              _sectionHeader('B. Data Tempat Usaha'),
              AddCustomerBusinessForm(
                namaOutletController: _usahaNamaOutletController,
                noNpwpController: _usahaNoNpwpController,
                namaNpwpController: _usahaNamaNpwpController,
                jenisProdukController: _usahaJenisProdukController,
                berdiriSejakController: _usahaBerdiriSejakController,
                alamatController: _usahaAlamatController,
                kecamatanController: _usahaKecamatanController,
                kotaController: _usahaKotaController,
                provinsiController: _usahaProvinsiController,
                kontakPersonController: _usahaKontakPersonController,
                kontakNoKtpController: _usahaKontakNoKtpController,
                kontakHpController: _usahaKontakHpController,
                alamatGudangController: _usahaAlamatGudangController,
                bankNamaController: _usahaBankNamaController,
                bankCabangController: _usahaBankCabangController,
                bankNoRekController: _usahaBankNoRekController,
                bankAtasNamaController: _usahaBankAtasNamaController,
                categories: _categories,
                klasifikasi: _usahaKlasifikasi,
                onKlasifikasiChanged: (v) =>
                    setState(() => _usahaKlasifikasi = v),
                caraBayar: _usahaCaraBayar,
                onCaraBayarChanged: (v) =>
                    setState(() => _usahaCaraBayar = v),
                isContactSameAsOwner: _isContactSameAsOwner,
                onContactSameAsOwnerChanged: (v) {
                  setState(() => _isContactSameAsOwner = v);
                  if (v) _copyFromCalonPelanggan();
                },
                locationPicker: AddCustomerLocationPicker(
                  initialLocation: _currentLocation,
                  onLocationChanged: (p) =>
                      setState(() => _currentLocation = p),
                  alamatController: _usahaAlamatController,
                  kecamatanController: _usahaKecamatanController,
                  kotaController: _usahaKotaController,
                  provinsiController: _usahaProvinsiController,
                ),
              ),
              const AppGap.lg(),
              _sectionHeader('C. Diisi Oleh Salesman'),
              AddCustomerSummarySection(
                kreditAwalController: _salesKreditAwalController,
                kreditBerjalanController: _salesKreditBerjalanController,
                topController: _salesTopController,
                lainLainController: _salesLainLainController,
                sistemBayar: _salesSistemBayar,
                onSistemBayarChanged: (v) =>
                    setState(() => _salesSistemBayar = v),
              ),
              const AppGap.xl(),
              AddCustomerPhotoPicker(
                title: 'Data Foto Toko',
                photo: _storePhoto,
                onPhotoChanged: (f) => setState(() => _storePhoto = f),
                placeholderIcon: Icons.add_a_photo,
                placeholderText: 'Tap untuk ambil foto toko',
              ),
              AddCustomerPhotoPicker(
                title: 'Data Foto KTP',
                photo: _ktpPhoto,
                onPhotoChanged: (f) => setState(() => _ktpPhoto = f),
                placeholderIcon: Icons.badge_outlined,
                placeholderText: 'Tap untuk ambil foto KTP',
              ),
            ],
          ),
        ),
      ),
      bottomBar: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: AppButton.primary(
              label:
                  _isSaving ? 'Menyimpan...' : 'Simpan Data Pelanggan',
              leadingIcon: Icons.save_alt,
              size: AppButtonSize.lg,
              isFullWidth: true,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveCustomer,
            ),
          ),
        ),
      ),
    );
  }
}
