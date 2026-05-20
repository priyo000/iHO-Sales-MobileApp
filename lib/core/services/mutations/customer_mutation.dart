import 'dart:io';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';
import '../../db/app_database.dart';
import '../../constants/api_constants.dart';
import '../sync_service.dart';
import '../offline_photo_service.dart';
import '../connectivity_service.dart';

class CustomerMutation {
  final AppDatabase _db;
  final SyncService _sync;
  final OfflinePhotoService _photoStorage;
  final ConnectivityService _connectivity;
  final String Function(String) generateLocalRef;
  final Future<void> Function() triggerSync;

  CustomerMutation(
    this._db,
    this._sync,
    this._photoStorage,
    this._connectivity, {
    required this.generateLocalRef,
    required this.triggerSync,
  });

  String get _endpointPelanggan => ApiConstants.pelanggan;

  Future<Map<String, dynamic>> createCustomer({
    required String namaToko,
    required String namaPemilik,
    required String noHpPribadi,
    required String alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    String? noKtpPemilik,
    String? tempatLahirPemilik,
    String? tanggalLahirPemilik,
    String? noNpwpPribadi,
    String? alamatRumahPemilik,
    String? kodePosRumah,
    String? kotaRumah,
    String? noNpwpUsaha,
    String? namaNpwpUsaha,
    String? klasifikasiOutlet,
    String? jenisProdukIndustri,
    int? tahunBerdiri,
    String? kotaUsaha,
    String? kecamatanUsaha,
    String? provinsiUsaha,
    String? namaKontakPerson,
    String? noKtpKontak,
    String? noHpKontak,
    String? alamatGudang,
    String? kotaGudang,
    String? noTelpGudang,
    String? sistemPembayaran,
    String? caraPembayaran,
    String? namaBank,
    String? cabangBank,
    String? noRekening,
    String? atasNamaRekening,
    int? topHari,
    double? limitKreditAwal,
    String? catatanLain,
    File? storePhoto,
    File? ktpPhoto,
  }) async {
    return _mutateCreate(
      namaToko: namaToko,
      namaPemilik: namaPemilik,
      noHpPribadi: noHpPribadi,
      alamatUsaha: alamatUsaha,
      latitude: latitude,
      longitude: longitude,
      status: status,
      noKtpPemilik: noKtpPemilik,
      tempatLahirPemilik: tempatLahirPemilik,
      tanggalLahirPemilik: tanggalLahirPemilik,
      noNpwpPribadi: noNpwpPribadi,
      alamatRumahPemilik: alamatRumahPemilik,
      kodePosRumah: kodePosRumah,
      kotaRumah: kotaRumah,
      noNpwpUsaha: noNpwpUsaha,
      namaNpwpUsaha: namaNpwpUsaha,
      klasifikasiOutlet: klasifikasiOutlet,
      jenisProdukIndustri: jenisProdukIndustri,
      tahunBerdiri: tahunBerdiri,
      kotaUsaha: kotaUsaha,
      kecamatanUsaha: kecamatanUsaha,
      provinsiUsaha: provinsiUsaha,
      namaKontakPerson: namaKontakPerson,
      noKtpKontak: noKtpKontak,
      noHpKontak: noHpKontak,
      alamatGudang: alamatGudang,
      kotaGudang: kotaGudang,
      noTelpGudang: noTelpGudang,
      sistemPembayaran: sistemPembayaran,
      caraPembayaran: caraPembayaran,
      namaBank: namaBank,
      cabangBank: cabangBank,
      noRekening: noRekening,
      atasNamaRekening: atasNamaRekening,
      topHari: topHari,
      limitKreditAwal: limitKreditAwal,
      catatanLain: catatanLain,
      photoPaths: {'foto_toko': storePhoto, 'foto_ktp': ktpPhoto},
    );
  }

  Future<Map<String, dynamic>> createProspect({
    required String namaToko,
    required String namaPemilik,
    required String noHpPribadi,
    required String alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    Map<String, File?>? photoPaths,
  }) async {
    return _mutateCreate(
      namaToko: namaToko,
      namaPemilik: namaPemilik,
      noHpPribadi: noHpPribadi,
      alamatUsaha: alamatUsaha,
      latitude: latitude,
      longitude: longitude,
      status: status ?? 'prospect',
      photoPaths: photoPaths,
    );
  }

  Future<Map<String, dynamic>> updateCustomer({
    required String id,
    String? namaToko,
    String? namaPemilik,
    String? noHpPribadi,
    String? alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    String? kotaUsaha,
    String? kecamatanUsaha,
    String? provinsiUsaha,
  }) async {
    final fields = <String, dynamic>{
      'nama_toko': ?namaToko,
      'nama_pemilik': ?namaPemilik,
      'no_hp_pribadi': ?noHpPribadi,
      'alamat_usaha': ?alamatUsaha,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'status': ?status,
      'kota_usaha': ?kotaUsaha,
      'kecamatan_usaha': ?kecamatanUsaha,
      'provinsi_usaha': ?provinsiUsaha,
    };

    final existing = await _db.getCustomer(id);
    await _db.saveCustomer(
      id: id,
      serverId: existing?.serverId ?? id,
      namaToko: namaToko,
      namaPemilik: namaPemilik,
      noHpPribadi: noHpPribadi,
      alamatUsaha: alamatUsaha,
      latitude: latitude,
      longitude: longitude,
      status: status,
      kotaUsaha: kotaUsaha,
      kecamatanUsaha: kecamatanUsaha,
      provinsiUsaha: provinsiUsaha,
    );

    final syncRef = await _sync.enqueueUpdatePelanggan(
      endpoint: '$_endpointPelanggan/$id',
      payload: fields,
    );

    dev.log('[CustomerMutation] Update queued. id=$id');
    triggerSync();

    return {'data': fields, 'is_offline': true, 'local_ref': syncRef};
  }

  Future<Map<String, dynamic>> _mutateCreate({
    required String namaToko,
    required String namaPemilik,
    required String noHpPribadi,
    required String alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    String? noKtpPemilik,
    String? tempatLahirPemilik,
    String? tanggalLahirPemilik,
    String? noNpwpPribadi,
    String? alamatRumahPemilik,
    String? kodePosRumah,
    String? kotaRumah,
    String? noNpwpUsaha,
    String? namaNpwpUsaha,
    String? klasifikasiOutlet,
    String? jenisProdukIndustri,
    int? tahunBerdiri,
    String? kotaUsaha,
    String? kecamatanUsaha,
    String? provinsiUsaha,
    String? namaKontakPerson,
    String? noKtpKontak,
    String? noHpKontak,
    String? alamatGudang,
    String? kotaGudang,
    String? noTelpGudang,
    String? sistemPembayaran,
    String? caraPembayaran,
    String? namaBank,
    String? cabangBank,
    String? noRekening,
    String? atasNamaRekening,
    int? topHari,
    double? limitKreditAwal,
    String? catatanLain,
    Map<String, File?>? photoPaths,
  }) async {
    final localRef = generateLocalRef('create_pelanggan');
    final resolvedStatus = status ?? 'prospect';

    // Read employeeId from session for dashboard prospect count
    String? employeeId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        employeeId = userMap['employeeId']?.toString() ??
            userMap['employee_id']?.toString() ??
            userMap['id_karyawan']?.toString();
      }
    } catch (_) {}

    final savedPhotoPaths = photoPaths?.isNotEmpty == true
        ? await _photoStorage.savePhotos(photoPaths!, 'pelanggan')
        : <String, String>{};

    final payload = <String, dynamic>{
      'nama_toko': namaToko,
      'nama_pemilik': namaPemilik,
      'no_hp_pribadi': noHpPribadi,
      'alamat_usaha': alamatUsaha,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      'status': resolvedStatus,
      'client_ref': localRef,
      if (noKtpPemilik?.isNotEmpty == true) 'no_ktp_pemilik': noKtpPemilik,
      if (tempatLahirPemilik?.isNotEmpty == true) 'tempat_lahir_pemilik': tempatLahirPemilik,
      if (tanggalLahirPemilik?.isNotEmpty == true) 'tanggal_lahir_pemilik': tanggalLahirPemilik,
      if (noNpwpPribadi?.isNotEmpty == true) 'no_npwp_pribadi': noNpwpPribadi,
      if (alamatRumahPemilik?.isNotEmpty == true) 'alamat_rumah_pemilik': alamatRumahPemilik,
      if (kodePosRumah?.isNotEmpty == true) 'kode_pos_rumah': kodePosRumah,
      if (kotaRumah?.isNotEmpty == true) 'kota_rumah': kotaRumah,
      if (noNpwpUsaha?.isNotEmpty == true) 'no_npwp_usaha': noNpwpUsaha,
      if (namaNpwpUsaha?.isNotEmpty == true) 'nama_npwp_usaha': namaNpwpUsaha,
      if (klasifikasiOutlet?.isNotEmpty == true) 'klasifikasi_outlet': klasifikasiOutlet,
      if (jenisProdukIndustri?.isNotEmpty == true) 'jenis_produk_industri': jenisProdukIndustri,
      if (tahunBerdiri != null) 'tahun_berdiri': tahunBerdiri.toString(),
      if (kotaUsaha?.isNotEmpty == true) 'kota_usaha': kotaUsaha,
      if (kecamatanUsaha?.isNotEmpty == true) 'kecamatan_usaha': kecamatanUsaha,
      if (provinsiUsaha?.isNotEmpty == true) 'provinsi_usaha': provinsiUsaha,
      if (namaKontakPerson?.isNotEmpty == true) 'nama_kontak_person': namaKontakPerson,
      if (noKtpKontak?.isNotEmpty == true) 'no_ktp_kontak': noKtpKontak,
      if (noHpKontak?.isNotEmpty == true) 'no_hp_kontak': noHpKontak,
      if (alamatGudang?.isNotEmpty == true) 'alamat_gudang': alamatGudang,
      if (kotaGudang?.isNotEmpty == true) 'kota_gudang': kotaGudang,
      if (noTelpGudang?.isNotEmpty == true) 'no_telp_gudang': noTelpGudang,
      if (sistemPembayaran?.isNotEmpty == true) 'sistem_pembayaran': sistemPembayaran,
      if (caraPembayaran?.isNotEmpty == true) 'cara_pembayaran': caraPembayaran,
      if (namaBank?.isNotEmpty == true) 'nama_bank': namaBank,
      if (cabangBank?.isNotEmpty == true) 'cabang_bank': cabangBank,
      if (noRekening?.isNotEmpty == true) 'no_rekening': noRekening,
      if (atasNamaRekening?.isNotEmpty == true) 'atas_nama_rekening': atasNamaRekening,
      if (topHari != null) 'top_hari': topHari.toString(),
      if (limitKreditAwal != null) 'limit_kredit_awal': limitKreditAwal.toString(),
      if (catatanLain?.isNotEmpty == true) 'catatan_lain': catatanLain,
    };

    if (savedPhotoPaths.isNotEmpty) {
      payload['_photo_paths'] = savedPhotoPaths;
    }

    await _db.saveCustomer(
      id: localRef,
      namaToko: namaToko,
      namaPemilik: namaPemilik,
      noHpPribadi: noHpPribadi,
      alamatUsaha: alamatUsaha,
      latitude: latitude,
      longitude: longitude,
      status: resolvedStatus,
      fotoTokoPath: savedPhotoPaths['foto_toko'],
      fotoKtpPath: savedPhotoPaths['foto_ktp'],
      noKtpPemilik: noKtpPemilik,
      kotaUsaha: kotaUsaha,
      kecamatanUsaha: kecamatanUsaha,
      provinsiUsaha: provinsiUsaha,
      sistemPembayaran: sistemPembayaran,
      caraPembayaran: caraPembayaran,
      namaBank: namaBank,
      cabangBank: cabangBank,
      noRekening: noRekening,
      atasNamaRekening: atasNamaRekening,
      topHari: topHari,
      limitKreditAwal: limitKreditAwal,
      createdById: employeeId,
    );

    final isOnline = await _connectivity.checkNow();

    if (isOnline) {
      try {
        final serverResponse = await _sync.syncCreateCustomerNow(
          endpoint: _endpointPelanggan,
          payload: payload,
        );

        final serverData = serverResponse is Map
            ? (serverResponse['data'] ?? serverResponse) as Map<String, dynamic>
            : <String, dynamic>{};
        final serverId = serverData['id'];

        if (serverId != null) {
          await _db.saveCustomer(
            id: localRef,
            serverId: serverId.toString(),
            kodePelanggan: serverData['kode_pelanggan'] as String?,
            namaToko: serverData['nama_toko'] as String? ?? namaToko,
            namaPemilik: serverData['nama_pemilik'] as String? ?? namaPemilik,
            noHpPribadi: serverData['no_hp_pribadi'] as String? ?? noHpPribadi,
            alamatUsaha: serverData['alamat_usaha'] as String? ?? alamatUsaha,
            status: serverData['status'] as String? ?? resolvedStatus,
            fotoTokoPath: savedPhotoPaths['foto_toko'],
            fotoKtpPath: savedPhotoPaths['foto_ktp'],
          );

          dev.log('[CustomerMutation] Synced. server_id=$serverId');
          return {'data': serverData, 'server_id': serverId, 'is_offline': false};
        }
      } catch (e) {
        dev.log('[CustomerMutation] Online create failed: $e, falling back to queue');
      }
    }

    payload['_drift_record_id'] = localRef;
    await _sync.enqueueCreatePelanggan(
      endpoint: _endpointPelanggan,
      payload: payload,
    );

    dev.log('[CustomerMutation] Customer queued. ref=$localRef');
    triggerSync();

    return {
      'data': {
        'id': localRef,
        'nama_toko': namaToko,
        'nama_pemilik': namaPemilik,
        'no_hp_pribadi': noHpPribadi,
        'alamat_usaha': alamatUsaha,
        'status': resolvedStatus,
        'local_ref': localRef,
      },
      'local_ref': localRef,
      'is_offline': true,
    };
  }
}
