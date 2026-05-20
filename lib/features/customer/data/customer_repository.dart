import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/mutation_queue_service.dart';
import '../../../../core/services/last_sync_service.dart';
import '../../../../core/services/offline_photo_service.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    ref.watch(appDatabaseProvider),
    ref.read(dioClientProvider),
    ref.read(connectivityServiceProvider),
    ref.read(syncServiceProvider),
    ref.read(offlinePhotoServiceProvider),
    ref.read(mutationQueueServiceProvider),
    ref.read(lastSyncServiceProvider),
  );
});

class CustomerRepository {
  final AppDatabase _db;
  final DioClient _dioClient;
  final ConnectivityService _connectivity;
  final SyncService _sync;
  final OfflinePhotoService _photoStorage;
  final MutationQueueService _mutations;
  final LastSyncService _lastSync;

  CustomerRepository(
    this._db,
    this._dioClient,
    this._connectivity,
    this._sync,
    this._photoStorage,
    this._mutations,
    this._lastSync,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE STREAMS — For Real-Time UI Updates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all customers - auto-updates when table changes
  Stream<List<CustomersTableData>> watchAllCustomers() {
    return _db.watchAllCustomers();
  }

  /// Watch customers by status (active/pending/prospect)
  Stream<List<CustomersTableData>> watchCustomersByStatus(String status) {
    return _db.watchCustomersByStatus(status);
  }

  /// Watch customers with search - instant SQL filtering, no loading state
  Stream<List<CustomersTableData>> watchSearchCustomers(String query) {
    if (query.isEmpty) {
      return _db.watchAllCustomers();
    }
    return _db.watchSearchCustomers(query);
  }

  /// Watch pending customers (offline-created, not yet synced)
  Stream<List<CustomersTableData>> watchPendingCustomers() {
    return _db.watchPendingCustomers();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC — Download from API, Save to Local Drift Table
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync customers from server to local Drift table
  /// After sync completes, all stream watchers auto-update
  bool _isSyncingCustomers = false;
  Future<void> syncCustomersToDrift({bool forceRefresh = false}) async {
    if (_isSyncingCustomers) return;
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) return;
    _isSyncingCustomers = true;

    try {
      // Build pending IDs set once (SSOT guard)
      final pendingIds = await _buildPendingCustomerIds();

      String? since;
      if (!forceRefresh) {
        since = await _lastSync.getLastModified(SyncResource.customers);
      }

      // Paginated sync: fetch 500 per batch to handle 4000-5000 customers
      const batchSize = 500;
      int page = 1;
      bool hasMore = true;
      int totalSaved = 0;

      while (hasMore) {
        final queryParams = <String, String>{
          'status': 'active,pending,prospect',
          'per_page': batchSize.toString(),
          'page': page.toString(),
        };
        if (since != null) queryParams['since'] = since;

        final uri = Uri.parse(ApiConstants.pelanggan)
            .replace(queryParameters: queryParams);

        final response = await _dioClient.get(
          uri.toString(),
          options: Options(receiveTimeout: const Duration(seconds: 60)),
        );

        List<Map<String, dynamic>>? customerList;
        if (response is Map && response['data'] is List) {
          customerList = (response['data'] as List)
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
        } else if (response is List) {
          customerList = response
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
        }

        if (customerList == null || customerList.isEmpty) {
          hasMore = false;
          break;
        }

        // Filter out customers with pending mutations
        final filtered = customerList.where((c) {
          final id = c['id']?.toString();
          if (id == null) return true;
          if (pendingIds.contains(id)) {
            debugPrint('[Customer SSOT] Skip overwrite: $id has pending mutation');
            return false;
          }
          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          await _db.saveCustomers(filtered);
          totalSaved += filtered.length;
        }

        // Check if there are more pages
        final meta = response is Map ? response['meta'] : null;
        if (meta is Map && meta['hasMore'] == true) {
          page++;
        } else if (customerList.length < batchSize) {
          hasMore = false;
        } else {
          page++;
        }
      }

      debugPrint('[Customer SSOT] Sync complete: $totalSaved customers saved');
      await _lastSync.setLastSync(
        SyncResource.customers,
        lastModified: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Customer SSOT] Sync failed: $e');
    } finally {
      _isSyncingCustomers = false;
    }
  }

  Future<Set<String>> _buildPendingCustomerIds() async {
    final pendingIds = <String>{};
    final pendingTypes = const [
      'update_pelanggan',
      'update_customer_photo',
      'create_pelanggan',
      'create_prospect',
    ];
    final endpointRegex = RegExp(r'/pelanggan/([^/?]+)');
    for (final type in pendingTypes) {
      final pendings = await _sync.getPendingByType(type);
      for (final p in pendings) {
        final endpoint = p['endpoint'] as String?;
        if (endpoint != null) {
          final m = endpointRegex.firstMatch(endpoint);
          if (m != null) pendingIds.add(m.group(1)!);
        }
        final payload = p['payload'];
        if (payload is Map) {
          final driftId = payload['_drift_record_id']?.toString();
          if (driftId != null) pendingIds.add(driftId);
          final clientRef = payload['client_ref']?.toString();
          if (clientRef != null) pendingIds.add(clientRef);
        }
      }
    }
    return pendingIds;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY METHODS — Keep existing cache logic for complex offline scenarios
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // SSOT READ METHODS — Read from Drift directly (no cache)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all customers - reads from Drift (SSOT)
  ///
  /// DEPRECATED: Use watchAllCustomers() + StreamBuilder instead.
  /// This method exists for backward compatibility.
  @Deprecated('Use watchAllCustomers() + StreamBuilder for reactive UI')
  Future<dynamic> getCustomers({
    String? search,
    String? status,
    String? createdById,
    int page = 1,
    int perPage = 20,
  }) async {
    // SSOT: Always read from local Drift table first (offline-first)
    log('[Customer SSOT] Reading from Drift SSOT');

    // Get all customers from Drift
    List<CustomersTableData> customers;

    if (search != null && search.isNotEmpty) {
      // Use search stream if query provided
      customers = await _db.watchSearchCustomers(search).first;
    } else if (status != null && status.toLowerCase() != 'all') {
      // Filter by status
      customers = await _db.watchCustomersByStatus(status).first;
    } else {
      // Get all
      customers = await _db.getAllLocalCustomers();
    }

    // Filter by createdById (per-user scope) — only customer yang dibuat user ini
    // atau yang masih offline (isLocal=1, belum sync sehingga createdById null).
    if (createdById != null) {
      customers = customers.where((c) {
        if (c.createdById != null) return c.createdById == createdById;
        return c.isLocal == 1;
      }).toList();
    }

    // Sort by namaToko asc (consistency with watchAllCustomers DB query)
    final start = (page - 1) * perPage;
    final end = start + perPage;
    final paginated = customers.sublist(
      start,
      end > customers.length ? customers.length : end,
    );

    // Convert to map format for backward compatibility
    final data = paginated.map((c) => _customerToMap(c)).toList();

    return {
      'data': data,
      'current_page': page,
      'last_page': (customers.length / perPage).ceil(),
    };
  }

  /// Get cached data - now reads from Drift (SSOT)
  ///
  /// DEPRECATED: Use stream methods instead.
  @Deprecated('Use watchAllCustomers() stream instead')
  Future<dynamic> getCached({String status = 'all'}) async {
    final customers = status.toLowerCase() == 'all'
        ? await _db.getAllLocalCustomers()
        : await _db.watchCustomersByStatus(status).first;
    return {'data': customers.map((c) => _customerToMap(c)).toList()};
  }

  /// Get single customer by ID - now reads from Drift (SSOT)
  ///
  /// DEPRECATED: Use watchAllCustomers() stream + filter in UI instead.
  @Deprecated('Use watchAllCustomers() + find in stream for reactive UI')
  Future<Map<String, dynamic>> getCustomer(int id) async {
    // SSOT: Read directly from Drift
    final customer = await _db.getCustomer(id.toString());
    if (customer != null) {
      return _customerToMap(customer);
    }
    return {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY SYNC METHODS — Deprecated, kept for compatibility
  // ═══════════════════════════════════════════════════════════════════════════

  /// DEPRECATED: Use syncCustomersToDrift() instead.
  /// This method still writes to cache for backward compatibility.
  @Deprecated('Use syncCustomersToDrift() for SSOT sync')
  Future<void> syncCustomersFromApi({
    String? search,
    String? status,
    int page = 1,
    int perPage = -1,
    bool forceRefresh = false,
  }) async {
    // For now, delegate to the new SSOT sync method
    // This maintains API compatibility while using new SSOT storage
    await syncCustomersToDrift(forceRefresh: forceRefresh);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert CustomersTableData to Map for backward compatibility
  Map<String, dynamic> _customerToMap(CustomersTableData c) {
    // Try to parse dataJson for additional fields
    Map<String, dynamic> extraData = {};
    if (c.dataJson != null && c.dataJson!.isNotEmpty) {
      try {
        extraData = Map<String, dynamic>.from(jsonDecode(c.dataJson!) as Map);
      } catch (e) {
        debugPrint('[CustomerRepo] Failed to parse dataJson for customer ${c.id}: $e');
      }
    }

    return {
      'id': c.serverId ?? c.id,
      'local_ref': c.id,
      'kode_pelanggan': c.kodePelanggan,
      'nama_toko': c.namaToko,
      'nama_pelanggan': c.namaPemilik,
      'no_hp_pribadi': c.noHpPribadi,
      'alamat_usaha': c.alamatUsaha,
      'latitude': c.latitude,
      'longitude': c.longitude,
      'status': c.status,
      'foto_toko_url': c.fotoTokoPath,
      'foto_ktp_path': c.fotoKtpPath,
      'is_local': c.isLocal == 1,
      'created_at': c.createdAt,
      ...extraData,
    };
  }

  /// Registers a new customer / prospect via the SSOT mutation path.
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
    return _mutations.createCustomer(
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
  }

  /// Update customer fields (location, address, etc.)
  /// Uses SSOT: writes to Drift first, then queues sync
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

    // SSOT: write to Drift FIRST (instant UI update via stream), then enqueue sync.
    final existing = await _db.getCustomer(id);
    if (existing != null) {
      await _db.saveCustomer(
        id: existing.id,
        serverId: existing.serverId ?? id,
        namaToko: namaToko ?? existing.namaToko,
        namaPemilik: namaPemilik ?? existing.namaPemilik,
        noHpPribadi: noHpPribadi ?? existing.noHpPribadi,
        alamatUsaha: alamatUsaha ?? existing.alamatUsaha,
        latitude: latitude ?? existing.latitude,
        longitude: longitude ?? existing.longitude,
        status: status ?? existing.status,
        kotaUsaha: kotaUsaha ?? existing.kotaUsaha,
        kecamatanUsaha: kecamatanUsaha ?? existing.kecamatanUsaha,
        provinsiUsaha: provinsiUsaha ?? existing.provinsiUsaha,
      );
    }

    final localRef = await _sync.enqueueUpdatePelanggan(
      endpoint: '${ApiConstants.pelanggan}/$id',
      payload: fields,
    );

    log('[Customer] 💾 Update queued via sync. ref: $localRef');
    return {'data': fields, 'is_offline': true, 'local_ref': localRef};
  }

  /// Upload foto toko baru ke server. Mendukung offline fallback.
  Future<Map<String, dynamic>> updateCustomerPhoto({
    required String id,
    required File photo,
  }) async {
    final isOnline = await _connectivity.checkNow();

    if (isOnline) {
      try {
        final bytes = await _photoStorage.compressImage(photo);
        if (bytes == null) throw 'Gagal memproses foto';

        final formData = FormData.fromMap({
          'foto_toko': MultipartFile.fromBytes(
            bytes,
            filename: 'foto_toko_$id.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        });

        final response = await _dioClient.uploadFile(
          '${ApiConstants.pelanggan}/$id',
          formData: formData,
        );

        final data = (response ?? {}) as Map<String, dynamic>;
        final pelangganData = data['data'] as Map<String, dynamic>? ?? data;

        final existing = await _db.getCustomer(id);
        if (existing != null) {
          await _db.saveCustomer(
            id: existing.id,
            serverId: existing.serverId,
            fotoTokoPath: pelangganData['foto_toko_url'],
          );
        }

        log('[Customer] ✅ Foto toko berhasil diupdate');
        return pelangganData;
      } catch (e) {
        log('[Customer] ⚠️ Error upload foto online ($e). Fallback ke offline.');
      }
    }

    final savedPhotoPaths = await _photoStorage.savePhotos({
      'foto_toko': photo,
    }, 'customer_update');

    final localRef = await _sync.enqueueUpdateCustomerPhoto(
      endpoint: '${ApiConstants.pelanggan}/$id',
      payload: {'_photo_paths': savedPhotoPaths},
    );

    log('[Customer] 💾 Update foto di-queue (offline). ref: $localRef');

    // Update local Drift temporarily with local path
    final existing = await _db.getCustomer(id.toString());
    if (existing != null) {
      await _db.saveCustomer(
        id: existing.id,
        serverId: existing.serverId,
        fotoTokoPath: savedPhotoPaths['foto_toko'],
      );
    }

    return {
      'data': {'foto_toko_local': savedPhotoPaths['foto_toko']},
      'is_offline': true,
      'local_ref': localRef,
    };
  }
}
