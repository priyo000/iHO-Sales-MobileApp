import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../providers/database_providers.dart';
import '../network/dio_client.dart' show DioAuthException;
import 'sync_service.dart';
import 'offline_photo_service.dart';
import 'connectivity_service.dart';
import 'mutations/visit_mutation.dart';
import 'mutations/order_mutation.dart';
import 'mutations/customer_mutation.dart';

final mutationQueueServiceProvider = Provider<MutationQueueService>((ref) {
  final appDb = ref.read(appDatabaseProvider);
  final syncService = ref.read(syncServiceProvider);
  final photoStorage = ref.read(offlinePhotoServiceProvider);
  final connectivity = ref.read(connectivityServiceProvider);
  return MutationQueueService(appDb, syncService, photoStorage, connectivity);
});

/// Facade that delegates mutations to domain-specific classes.
/// Shared helpers (ref generation, sync trigger) live here.
class MutationQueueService {
  static final _random = Random();

  final AppDatabase _db;
  final SyncService _sync;
  final OfflinePhotoService _photoStorage;
  final ConnectivityService _connectivity;

  Timer? _syncDebounce;

  late final VisitMutation _visit;
  late final OrderMutation _order;
  late final CustomerMutation _customer;

  MutationQueueService(
    this._db,
    this._sync,
    this._photoStorage,
    this._connectivity,
  ) {
    _visit = VisitMutation(
      _db, _sync, _photoStorage,
      generateLocalRef: _generateLocalRef,
      triggerSync: _triggerSync,
    );
    _order = OrderMutation(
      _db, _sync,
      generateLocalRef: _generateLocalRef,
      triggerSync: _triggerSync,
    );
    _customer = CustomerMutation(
      _db, _sync, _photoStorage, _connectivity,
      generateLocalRef: _generateLocalRef,
      triggerSync: _triggerSync,
    );
  }

  // ── Visit Delegation ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> mutateCheckIn({
    dynamic jadwalId,
    required dynamic pelangganId,
    required double lat,
    required double long,
    double? jarakValidasi,
    String? scheduledDate,
    Map<String, dynamic>? pelangganDataMap,
  }) => _visit.mutateCheckIn(
    jadwalId: jadwalId?.toString(),
    pelangganId: pelangganId,
    lat: lat,
    long: long,
    jarakValidasi: jarakValidasi,
    scheduledDate: scheduledDate,
    pelangganDataMap: pelangganDataMap,
  );

  Future<void> mutateCheckOut({
    required dynamic kunjunganId,
    required double lat,
    required double long,
    required bool statusTransaksi,
    String? alasanTidakOrder,
    String? detailAlasan,
    String? catatan,
    Map<String, File?>? photos,
  }) => _visit.mutateCheckOut(
    kunjunganId: kunjunganId,
    lat: lat,
    long: long,
    statusTransaksi: statusTransaksi,
    alasanTidakOrder: alasanTidakOrder,
    detailAlasan: detailAlasan,
    catatan: catatan,
    photos: photos?.cast<String, dynamic>(),
  );

  // ── Order Delegation ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> mutateCreateOrder({
    dynamic kunjunganId,
    dynamic pelangganId,
    Map<String, dynamic>? pelangganData,
    required List<Map<String, dynamic>> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
    String? clientRef,
  }) => _order.mutateCreateOrder(
    kunjunganId: kunjunganId,
    pelangganId: pelangganId,
    pelangganData: pelangganData,
    items: items,
    notes: notes,
    promosApplied: promosApplied,
    hadiahDitebus: hadiahDitebus,
    clientRef: clientRef,
  );

  Future<bool> mutateUpdatePendingOrder({
    required String localRef,
    required List<Map<String, dynamic>> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  }) => _order.mutateUpdatePendingOrder(
    localRef: localRef,
    items: items,
    notes: notes,
    promosApplied: promosApplied,
    hadiahDitebus: hadiahDitebus,
  );

  Future<bool> mutateCancelPendingOrder({required String localRef}) =>
      _order.mutateCancelPendingOrder(localRef: localRef);

  Future<void> mutateUpdateOrder({
    required String orderId,
    required String localOrderId,
    required List<Map<String, dynamic>> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  }) => _order.mutateUpdateOrder(
    orderId: orderId,
    localOrderId: localOrderId,
    items: items,
    notes: notes,
    promosApplied: promosApplied,
    hadiahDitebus: hadiahDitebus,
  );

  Future<void> mutateUpdateOrderStatus({
    required String orderId,
    required String status,
  }) => _order.mutateUpdateOrderStatus(orderId: orderId, status: status);

  // ── Customer Delegation ─────────────────────────────────────────────────────

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
  }) => _customer.createCustomer(
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
    storePhoto: storePhoto,
    ktpPhoto: ktpPhoto,
  );

  Future<Map<String, dynamic>> createProspect({
    required String namaToko,
    required String namaPemilik,
    required String noHpPribadi,
    required String alamatUsaha,
    double? latitude,
    double? longitude,
    String? status,
    Map<String, File?>? photoPaths,
  }) => _customer.createProspect(
    namaToko: namaToko,
    namaPemilik: namaPemilik,
    noHpPribadi: noHpPribadi,
    alamatUsaha: alamatUsaha,
    latitude: latitude,
    longitude: longitude,
    status: status,
    photoPaths: photoPaths,
  );

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
  }) => _customer.updateCustomer(
    id: id,
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

  // ── Notification ────────────────────────────────────────────────────────────

  Future<void> mutateReadNotification({required String endpoint}) async {
    await _sync.enqueueReadNotification(endpoint: endpoint);
    _triggerSync();
  }

  // ── Shared Helpers ──────────────────────────────────────────────────────────

  String _generateLocalRef(String operation) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(99999).toString().padLeft(5, '0');
    return '${operation}_${now}_$rand'.replaceAll('-', '_');
  }

  Future<void> _triggerSync() async {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _sync.syncAll();
      } on DioAuthException catch (e) {
        dev.log('[MutationQueue] Auth failure during sync — token expired/invalid: $e');
      } catch (e) {
        dev.log('[MutationQueue] Sync trigger failed: $e');
      }
    });
  }

  void dispose() {
    _syncDebounce?.cancel();
  }
}
