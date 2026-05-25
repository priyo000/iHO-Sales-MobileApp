import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import '../../db/app_database.dart';
import '../../constants/api_constants.dart';
import '../../constants/order_status.dart';
import '../../utils/formatters.dart';
import '../sync_service.dart';

class OrderMutation {
  final AppDatabase _db;
  final SyncService _sync;
  final String Function(String) generateLocalRef;
  final Future<void> Function() triggerSync;

  OrderMutation(
    this._db,
    this._sync, {
    required this.generateLocalRef,
    required this.triggerSync,
  });

  String get _endpointPesanan => ApiConstants.pesanan;

  Future<Map<String, dynamic>> mutateCreateOrder({
    dynamic kunjunganId,
    dynamic pelangganId,
    Map<String, dynamic>? pelangganData,
    required List<Map<String, dynamic>> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
    String? clientRef,
  }) async {
    try {
      final localRef = generateLocalRef('create_order');
      final stableClientRef = clientRef ??
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond.toRadixString(16)}';

      final itemsJson = _encodeJson(items);
      final promosJson =
          promosApplied?.isNotEmpty == true ? _encodeJson(promosApplied) : null;

      final double totalTagihan = _calcOrderTotal(items, promosApplied, hadiahDitebus);

      final orderItems = items
          .map((item) => {
                'id_produk': item['id_produk'],
                'jumlah': item['jumlah'],
                'harga_satuan': item['harga_satuan'],
                if (item['id_satuan'] != null) 'id_satuan': item['id_satuan'],
              })
          .toList();

      final String? validPelangganId = (pelangganId != null &&
              pelangganId.toString().isNotEmpty &&
              pelangganId.toString() != 'null')
          ? pelangganId.toString()
          : null;

      await _db.saveOrder(
        id: localRef,
        kunjunganId: kunjunganId?.toString(),
        pelangganId: validPelangganId,
        status: OrderStatus.pending.code,
        itemsJson: itemsJson,
        notes: notes,
        promosJson: promosJson,
        totalTagihan: totalTagihan,
        clientRef: stableClientRef,
      );

      await _sync.enqueueCreateOrder(
        endpoint: _endpointPesanan,
        payload: {
          'id_kunjungan': ?kunjunganId,
          'id_pelanggan': ?pelangganId,
          'client_ref': stableClientRef,
          'pelanggan': ?pelangganData,
          if (notes?.isNotEmpty == true) 'catatan': notes,
          'items': orderItems,
          if (promosApplied?.isNotEmpty == true) 'promos_applied': promosApplied,
          if (hadiahDitebus?.isNotEmpty == true) 'hadiah_ditebus': hadiahDitebus,
        },
      );

      dev.log('[OrderMutation] Order queued. ref=$localRef');
      triggerSync();

      return {
        'id': null,
        'local_ref': localRef,
        'client_ref': stableClientRef,
        'no_pesanan': null,
        'status': OrderStatus.pending.code,
        'is_offline': true,
        'total_tagihan': totalTagihan,
        'nama_promo': promosApplied?.isNotEmpty == true
            ? promosApplied!.first['nama_promo']
            : null,
        'diskon_total': _calcPromoDiscount(promosApplied),
        'promos': (promosApplied ?? [])
            .map((p) => {
                  'id': null,
                  'id_pesanan': null,
                  'id_promo_campaign': p['id_campaign'],
                  'nama_promo': p['nama_promo'],
                  'jenis': p['jenis'],
                  'id_produk': p['id_produk'],
                  'diskon_amount': p['diskon_amount'] ?? 0,
                })
            .toList(),
        'created_at': Formatters.nowServerIso(),
      };
    } catch (e, st) {
      dev.log('[OrderMutation] mutateCreateOrder failed: $e');
      debugPrint('[OrderMutation] Stack: $st');
      rethrow;
    }
  }

  Future<bool> mutateUpdatePendingOrder({
    required String localRef,
    required List<Map<String, dynamic>> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  }) async {
    final queued = await _sync.getPendingItem(localRef);
    if (queued == null) return false;

    final operation = queued['operation']?.toString();
    if (operation != 'create_order') return false;

    final currentPayload = Map<String, dynamic>.from(
      queued['payload'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    currentPayload['items'] = items;
    if (notes != null) {
      currentPayload['catatan'] = notes;
    } else {
      currentPayload.remove('catatan');
    }

    if (promosApplied?.isNotEmpty == true) {
      currentPayload['promos_applied'] = promosApplied;
    } else {
      currentPayload.remove('promos_applied');
    }

    if (hadiahDitebus?.isNotEmpty == true) {
      currentPayload['hadiah_ditebus'] = hadiahDitebus;
    } else {
      currentPayload.remove('hadiah_ditebus');
    }

    await _sync.updatePendingPayload(localRef, currentPayload);
    dev.log('[OrderMutation] Pending order updated. localRef=$localRef');
    triggerSync();
    return true;
  }

  Future<bool> mutateCancelPendingOrder({required String localRef}) async {
    final queued = await _sync.getPendingItem(localRef);
    if (queued == null) return false;
    if (queued['operation']?.toString() != 'create_order') return false;

    await _sync.removePendingItem(localRef);
    dev.log('[OrderMutation] Pending order cancelled. localRef=$localRef');
    return true;
  }

  Future<void> mutateUpdateOrder({
    required String orderId,
    required String localOrderId,
    required List<Map<String, dynamic>> items,
    String? notes,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  }) async {
    final endpoint = '${ApiConstants.pesanan}/$orderId';

    final existing = await _db.getOrderByServerId(orderId)
        ?? await _db.getOrder(localOrderId);
    if (existing != null) {
      final newTotal = _calcOrderTotal(items, promosApplied, hadiahDitebus);
      await _db.saveOrder(
        id: existing.id,
        kunjunganId: existing.kunjunganId,
        pelangganId: existing.pelangganId,
        status: existing.status,
        itemsJson: _encodeJson(items),
        notes: notes ?? existing.notes,
        promosJson: promosApplied?.isNotEmpty == true
            ? _encodeJson(promosApplied)
            : existing.promosJson,
        totalTagihan: newTotal,
        serverId: existing.serverId,
        clientRef: existing.clientRef,
        noPesanan: existing.noPesanan,
        tanggalTransaksi: existing.tanggalTransaksi,
      );
      dev.log('[OrderMutation] Drift updated optimistically. id=${existing.id}');
    }

    await _sync.enqueue(
      operation: 'update_order',
      endpoint: endpoint,
      method: 'PUT',
      payload: {
        'catatan': ?notes,
        'items': items,
        if (promosApplied?.isNotEmpty == true) 'promos_applied': promosApplied,
        if (hadiahDitebus?.isNotEmpty == true) 'hadiah_ditebus': hadiahDitebus,
        '_local_order_id': existing?.id ?? localOrderId,
      },
      triggerSync: true,
    );

    dev.log('[OrderMutation] Order update queued. orderId=$orderId');
    triggerSync();
  }

  Future<void> mutateUpdateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final endpoint = '${ApiConstants.pesanan}/$orderId/status';

    final existing = await _db.getOrderByServerId(orderId);
    if (existing != null) {
      await _db.saveOrder(
        id: existing.id,
        kunjunganId: existing.kunjunganId,
        pelangganId: existing.pelangganId,
        status: status,
        itemsJson: existing.itemsJson,
        notes: existing.notes,
        promosJson: existing.promosJson,
        totalTagihan: existing.totalTagihan,
        serverId: existing.serverId,
        clientRef: existing.clientRef,
        noPesanan: existing.noPesanan,
        tanggalTransaksi: existing.tanggalTransaksi,
      );
      dev.log('[OrderMutation] Drift status updated optimistically. id=${existing.id}, status=$status');
    }

    await _sync.enqueue(
      operation: 'update_order_status',
      endpoint: endpoint,
      method: 'PUT',
      payload: {
        'status': status,
        if (existing != null) '_local_order_id': existing.id,
      },
      triggerSync: true,
    );

    dev.log('[OrderMutation] Order status update queued. orderId=$orderId');
    triggerSync();
  }

  String _encodeJson(dynamic data) {
    if (data is String) return data;
    return jsonEncode(data);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double _calcOrderTotal(
    List<Map<String, dynamic>> items,
    List<Map<String, dynamic>>? promosApplied,
    List<Map<String, dynamic>>? hadiahDitebus,
  ) {
    double subtotal = items.fold(
      0,
      (s, i) => s + (_toDouble(i['harga_satuan']) * _toDouble(i['jumlah'])),
    );
    final diskonTotal = _calcPromoDiscount(promosApplied);
    final totalHadiah = (hadiahDitebus ?? []).fold<double>(
      0,
      (s, h) => s + (_toDouble(h['qty']) * _toDouble(h['harga_tebus'])),
    );
    return (subtotal + totalHadiah - diskonTotal).clamp(0, double.infinity);
  }

  double _calcPromoDiscount(List<Map<String, dynamic>>? promosApplied) {
    if (promosApplied == null || promosApplied.isEmpty) return 0;
    return promosApplied.fold<double>(
      0,
      (s, p) => s + _toDouble(p['diskon_amount']),
    );
  }
}
