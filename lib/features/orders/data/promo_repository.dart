import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/last_sync_service.dart';
import 'models/promo_model.dart';

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  return PromoRepository(
    ref.watch(appDatabaseProvider),
    ref.read(dioClientProvider),
    ref.read(connectivityServiceProvider),
    ref.read(lastSyncServiceProvider),
  );
});

class PromoRepository {
  final AppDatabase _db;
  final DioClient _dioClient;
  final ConnectivityService _connectivity;
  final LastSyncService _lastSync;

  PromoRepository(
    this._db,
    this._dioClient,
    this._connectivity,
    this._lastSync,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE STREAMS — For Real-Time UI Updates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch active promos - auto-updates when table changes
  Stream<List<PromoTableData>> watchActivePromos() {
    return _db.watchActivePromos();
  }

  /// Watch promos by type (cluster/grosir/aturan_harga/hadiah)
  Stream<List<PromoTableData>> watchPromosByType(String jenis) {
    return _db.watchPromosByType(jenis);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC — Download from API, Save to Local Drift Table
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync promos from server and save to Drift table.
  /// SSOT: Each campaign saved as one row with idPelanggan for reactive streams.
  /// Returns void — UI must read via [watchPromosForPelanggan] (Drift stream),
  /// not from this method's return value.
  Future<void> syncFromApi(String idPelanggan) async {
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) return;

    try {
      log('[Promo] 📡 Fetching promos for pelanggan $idPelanggan from: ${ApiConstants.promoAvailable}');
      final raw = await _dioClient.get(
        '${ApiConstants.promoAvailable}?id_pelanggan=$idPelanggan',
      );

      if (raw == null || raw is! Map<String, dynamic>) {
        log('[Promo] ❌ Response tidak valid untuk $idPelanggan: $raw');
        return;
      }

      log('[Promo] 📥 Promo response data received: ${raw.keys.toList()}');
      final promos = AvailablePromos.fromJson(raw).withActiveOnly();
      log('[Promo] 🔍 Parsed: ${promos.aturanHarga.length} aturan_harga, ${promos.grosir.length} grosir, ${promos.hadiah.length} hadiah');

      // Clear old promos for this pelanggan first (clean slate)
      await _db.deletePromosForPelanggan(idPelanggan.toString());

      // Save each campaign as ONE row with its campaign-specific data
      // NOT the full AvailablePromos for every item - that's wasteful
      int promoCount = 0;

      // Aturan Harga campaigns
      for (final promo in promos.aturanHarga) {
        final campaignJson = {
          'id_campaign': promo.idCampaign,
          'nama_promo': promo.namaPromo,
          'jenis': 'aturan_harga',
          'tanggal_mulai': promo.tanggalMulai,
          'tanggal_akhir': promo.tanggalAkhir,
          'items': promo.items.map((i) => {
            'id_produk': i.idProduk,
            'nama_produk': i.namaProduk,
            'harga_normal': i.hargaNormal,
            'harga_manual': i.hargaManual,
            'diskon_persen': i.diskonPersen,
          }).toList(),
        };
        await _db.savePromo(
          id: promo.idCampaign,
          idPelanggan: idPelanggan.toString(),
          namaCampaign: promo.namaPromo,
          jenis: 'aturan_harga',
          dataJson: jsonEncode(campaignJson),
          startDate: promo.tanggalMulai != null
              ? DateTime.tryParse(promo.tanggalMulai!) ?? DateTime.now()
              : DateTime.now(),
          endDate: promo.tanggalAkhir != null
              ? DateTime.tryParse(promo.tanggalAkhir!) ?? DateTime.now()
              : DateTime.now(),
        );
        promoCount++;
      }

      // Grosir campaigns
      for (final promo in promos.grosir) {
        final campaignJson = {
          'id_campaign': promo.idCampaign,
          'nama_promo': promo.namaPromo,
          'jenis': 'grosir',
          'tanggal_mulai': promo.tanggalMulai,
          'tanggal_akhir': promo.tanggalAkhir,
          'items': promo.items.map((i) => {
            'id_produk': i.idProduk,
            'nama_produk': i.namaProduk,
            'harga_normal': i.hargaNormal,
            'tiers': i.tiers.map((t) => {
              'min_qty': t.minQty,
              'harga_spesial': t.hargaSpesial,
              'diskon_persen': t.diskonPersen,
            }).toList(),
          }).toList(),
        };
        await _db.savePromo(
          id: promo.idCampaign,
          idPelanggan: idPelanggan,
          namaCampaign: promo.namaPromo,
          jenis: 'grosir',
          dataJson: jsonEncode(campaignJson),
          startDate: promo.tanggalMulai != null
              ? DateTime.tryParse(promo.tanggalMulai!) ?? DateTime.now()
              : DateTime.now(),
          endDate: promo.tanggalAkhir != null
              ? DateTime.tryParse(promo.tanggalAkhir!) ?? DateTime.now()
              : DateTime.now(),
        );
        promoCount++;
      }

      // Hadiah campaigns
      for (final promo in promos.hadiah) {
        final campaignJson = {
          'id_campaign': promo.idCampaign,
          'nama_promo': promo.namaPromo,
          'jenis': 'hadiah',
          'tanggal_mulai': promo.tanggalMulai,
          'tanggal_akhir': promo.tanggalAkhir,
          'items': promo.items.map((i) => {
            'id': i.id,
            'jenis_pemicu': i.jenisPemicu,
            'id_produk_pemicu': i.idProdukPemicu,
            'nama_produk_pemicu': i.namaProdukPemicu,
            'min_qty_pemicu': i.minQtyPemicu,
            'min_amount_pemicu': i.minAmountPemicu,
            'produk_hadiah': {
              'id': i.produkHadiah.id,
              'nama_produk': i.produkHadiah.namaProduk,
            },
            'qty_hadiah': i.qtyHadiah,
            'harga_tebus': i.hargaTebus,
          }).toList(),
        };
        await _db.savePromo(
          id: promo.idCampaign,
          idPelanggan: idPelanggan,
          namaCampaign: promo.namaPromo,
          jenis: 'hadiah',
          dataJson: jsonEncode(campaignJson),
          startDate: promo.tanggalMulai != null
              ? DateTime.tryParse(promo.tanggalMulai!) ?? DateTime.now()
              : DateTime.now(),
          endDate: promo.tanggalAkhir != null
              ? DateTime.tryParse(promo.tanggalAkhir!) ?? DateTime.now()
              : DateTime.now(),
        );
        promoCount++;
      }

      log(
        '[Promo] ✅ Synced $promoCount promos to Drift for pelanggan $idPelanggan',
      );
    } catch (e) {
      log('[Promo] Sync failed ($e). Mengabaikan pembaruan...');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK SYNC — Download promos for ALL pelanggan in ONE request
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync promos for multiple pelanggan in a single HTTP request.
  /// Replaces N individual syncFromApi() calls with 1 bulk call.
  ///
  /// Response format: { "data": { "123": { aturan_harga, grosir, hadiah }, ... } }
  Future<int> syncBulkFromApi(List<String> pelangganIds, {bool forceRefresh = false}) async {
    if (pelangganIds.isEmpty) return 0;

    final isOnline = await _connectivity.checkNow();
    if (!isOnline) return 0;

    try {
      final idsParam = pelangganIds.join(',');
      final queryParams = <String, String>{'ids': idsParam};

      if (!forceRefresh) {
        final lastModified = await _lastSync.getLastModified(SyncResource.promos);
        if (lastModified != null) {
          queryParams['since'] = lastModified;
        }
      }

      final url = Uri.parse(ApiConstants.promoAvailableBulk)
          .replace(queryParameters: queryParams)
          .toString();

      debugPrint('[Promo] 📡 Bulk fetching promos for ${pelangganIds.length} pelanggan (since=${queryParams['since'] ?? 'all'})');

      final raw = await _dioClient.get(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (raw == null || raw is! Map<String, dynamic>) {
        log('[Promo] ❌ Bulk response tidak valid: ${raw?.runtimeType}');
        return 0;
      }

      final dataMap = raw['data'];
      if (dataMap == null || dataMap is! Map) {
        log('[Promo] ❌ Bulk response["data"] bukan Map: ${dataMap?.runtimeType}');
        return 0;
      }

      int totalSaved = 0;

      for (final entry in dataMap.entries) {
        final idPelanggan = entry.key.toString();
        if (idPelanggan.isEmpty) continue;

        final promoData = entry.value as Map<String, dynamic>? ?? {};

        // Parse into AvailablePromos using existing model
        final promos = AvailablePromos.fromJson({
          'synced_at': raw['synced_at'],
          ...promoData,
        }).withActiveOnly();

        // Clear old promos for this pelanggan
        await _db.deletePromosForPelanggan(idPelanggan);

        // Save using same logic as syncFromApi
        int count = 0;

        for (final promo in promos.aturanHarga) {
          final campaignJson = {
            'id_campaign': promo.idCampaign,
            'nama_promo': promo.namaPromo,
            'jenis': 'aturan_harga',
            'tanggal_mulai': promo.tanggalMulai,
            'tanggal_akhir': promo.tanggalAkhir,
            'items': promo.items.map((i) => {
              'id_produk': i.idProduk,
              'nama_produk': i.namaProduk,
              'harga_normal': i.hargaNormal,
              'harga_manual': i.hargaManual,
              'diskon_persen': i.diskonPersen,
            }).toList(),
          };
          await _db.savePromo(
            id: promo.idCampaign,
            idPelanggan: idPelanggan,
            namaCampaign: promo.namaPromo,
            jenis: 'aturan_harga',
            dataJson: jsonEncode(campaignJson),
            startDate: promo.tanggalMulai != null
                ? DateTime.tryParse(promo.tanggalMulai!) ?? DateTime.now()
                : DateTime.now(),
            endDate: promo.tanggalAkhir != null
                ? DateTime.tryParse(promo.tanggalAkhir!) ?? DateTime.now()
                : DateTime.now(),
          );
          count++;
        }

        for (final promo in promos.grosir) {
          final campaignJson = {
            'id_campaign': promo.idCampaign,
            'nama_promo': promo.namaPromo,
            'jenis': 'grosir',
            'tanggal_mulai': promo.tanggalMulai,
            'tanggal_akhir': promo.tanggalAkhir,
            'items': promo.items.map((i) => {
              'id_produk': i.idProduk,
              'nama_produk': i.namaProduk,
              'harga_normal': i.hargaNormal,
              'tiers': i.tiers.map((t) => {
                'min_qty': t.minQty,
                'harga_spesial': t.hargaSpesial,
                'diskon_persen': t.diskonPersen,
              }).toList(),
            }).toList(),
          };
          await _db.savePromo(
            id: promo.idCampaign,
            idPelanggan: idPelanggan,
            namaCampaign: promo.namaPromo,
            jenis: 'grosir',
            dataJson: jsonEncode(campaignJson),
            startDate: promo.tanggalMulai != null
                ? DateTime.tryParse(promo.tanggalMulai!) ?? DateTime.now()
                : DateTime.now(),
            endDate: promo.tanggalAkhir != null
                ? DateTime.tryParse(promo.tanggalAkhir!) ?? DateTime.now()
                : DateTime.now(),
          );
          count++;
        }

        for (final promo in promos.hadiah) {
          final campaignJson = {
            'id_campaign': promo.idCampaign,
            'nama_promo': promo.namaPromo,
            'jenis': 'hadiah',
            'tanggal_mulai': promo.tanggalMulai,
            'tanggal_akhir': promo.tanggalAkhir,
            'items': promo.items.map((i) => {
              'id': i.id,
              'jenis_pemicu': i.jenisPemicu,
              'id_produk_pemicu': i.idProdukPemicu,
              'nama_produk_pemicu': i.namaProdukPemicu,
              'min_qty_pemicu': i.minQtyPemicu,
              'min_amount_pemicu': i.minAmountPemicu,
              'produk_hadiah': {
                'id': i.produkHadiah.id,
                'nama_produk': i.produkHadiah.namaProduk,
              },
              'qty_hadiah': i.qtyHadiah,
              'harga_tebus': i.hargaTebus,
            }).toList(),
          };
          await _db.savePromo(
            id: promo.idCampaign,
            idPelanggan: idPelanggan,
            namaCampaign: promo.namaPromo,
            jenis: 'hadiah',
            dataJson: jsonEncode(campaignJson),
            startDate: promo.tanggalMulai != null
                ? DateTime.tryParse(promo.tanggalMulai!) ?? DateTime.now()
                : DateTime.now(),
            endDate: promo.tanggalAkhir != null
                ? DateTime.tryParse(promo.tanggalAkhir!) ?? DateTime.now()
                : DateTime.now(),
          );
          count++;
        }

        totalSaved += count;
      }

      await _lastSync.setLastSync(
        SyncResource.promos,
        lastModified: DateTime.now(),
      );

      debugPrint('[Promo] ✅ Bulk synced $totalSaved promos for ${pelangganIds.length} pelanggan');
      return totalSaved;
    } catch (e) {
      log('[Promo] ❌ Bulk sync failed: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SSOT STREAM PROVIDERS — Reactive Reads
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch promos for specific pelanggan - PRIMARY SSOT STREAM
  Stream<List<PromoTableData>> watchPromosForPelanggan(String idPelanggan) {
    return _db.watchPromosForPelanggan(idPelanggan);
  }

  /// Watch promos by type for specific pelanggan
  Stream<List<PromoTableData>> watchPromosByTypeForPelanggan(
    String idPelanggan,
    String jenis,
  ) {
    return _db.watchPromosByTypeForPelanggan(idPelanggan, jenis);
  }

  /// Parse PromoTableData rows back to AvailablePromos (for stream consumption)
  AvailablePromos promosFromTableData(List<PromoTableData> rows) {
    final aturanHarga = <PromoAturanHarga>[];
    final grosir = <PromoGrosir>[];
    final hadiah = <PromoHadiah>[];

    for (final row in rows) {
      try {
        final json = jsonDecode(row.dataJson) as Map<String, dynamic>;
        json['id_campaign'] = row.id;
        json['nama_promo'] = row.namaCampaign;
        json['jenis'] = row.jenis;

        switch (row.jenis) {
          case 'aturan_harga':
            aturanHarga.add(PromoAturanHarga.fromJson(json));
            break;
          case 'grosir':
            grosir.add(PromoGrosir.fromJson(json));
            break;
          case 'hadiah':
            hadiah.add(PromoHadiah.fromJson(json));
            break;
        }
      } catch (e) {
        log('[Promo] Failed to parse promo row ${row.id}: $e');
      }
    }

    return AvailablePromos(
      syncedAt: DateTime.now().toIso8601String(),
      aturanHarga: aturanHarga,
      grosir: grosir,
      hadiah: hadiah,
    );
  }

  /// Get promos for specific pelanggan from Drift (non-reactive)
  Future<List<PromoTableData>> getPromosForPelanggan(String idPelanggan) async {
    return await _db.getPromosForPelanggan(idPelanggan);
  }

}
