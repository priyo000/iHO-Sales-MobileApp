import 'dart:convert';
import 'dart:developer' as dev;
import '../../../../core/db/app_database.dart';

class CustomerSummary {
  final String id;
  final String? namaToko;
  final String? namaPemilik;
  final String? fotoTokoUrl;
  final String? alamat;

  const CustomerSummary({
    required this.id,
    this.namaToko,
    this.namaPemilik,
    this.fotoTokoUrl,
    this.alamat,
  });

  factory CustomerSummary.fromMap(Map<String, dynamic> map) {
    return CustomerSummary(
      id: (map['id'] ?? '').toString(),
      namaToko: map['nama_toko'] as String?,
      namaPemilik: map['nama_pemilik'] as String?,
      fotoTokoUrl: map['foto_toko_url'] as String?,
      alamat: map['alamat'] as String?,
    );
  }
}

class OrderItemViewModel {
  final String idProduk;
  final String? namaProduk;
  final int jumlah;
  final double hargaSatuan;
  final String? unitId;
  final String? unitName;
  final double subtotal;

  const OrderItemViewModel({
    required this.idProduk,
    this.namaProduk,
    required this.jumlah,
    required this.hargaSatuan,
    this.unitId,
    this.unitName,
    required this.subtotal,
  });

  factory OrderItemViewModel.fromMap(Map<String, dynamic> map) {
    final jumlah = (map['jumlah'] ?? map['qty'] ?? 0) as num;
    final harga = (map['harga_satuan'] ?? map['harga'] ?? 0) as num;
    return OrderItemViewModel(
      idProduk: (map['id_produk'] ?? map['produk_id'] ?? '').toString(),
      namaProduk: map['nama_produk'] as String? ?? (map['produk'] is Map ? map['produk']['nama_produk'] : null),
      jumlah: jumlah.toInt(),
      hargaSatuan: harga.toDouble(),
      unitId: map['id_satuan'] as String?,
      unitName: map['nama_satuan'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? (jumlah * harga).toDouble(),
    );
  }
}

class OrderViewModel {
  final String id;
  final String? serverId;
  final String clientRef;
  final String? noPesanan;
  final String? pelangganId;
  final CustomerSummary? pelanggan;
  final String status;
  final List<OrderItemViewModel> items;
  final List<Map<String, dynamic>> promos;
  final double totalTagihan;
  final int? tanggalTransaksi;
  final String? notes;
  final bool isLocal;
  final int createdAt;
  final int updatedAt;
  final String? kunjunganId;

  const OrderViewModel({
    required this.id,
    this.serverId,
    required this.clientRef,
    this.noPesanan,
    this.pelangganId,
    this.pelanggan,
    required this.status,
    this.items = const [],
    this.promos = const [],
    required this.totalTagihan,
    this.tanggalTransaksi,
    this.notes,
    this.isLocal = false,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.kunjunganId,
  });

  factory OrderViewModel.fromDriftData(
    OrdersTableData order, {
    Map<String, CustomerSummary>? customerMap,
  }) {
    List<OrderItemViewModel> items = [];
    if (order.itemsJson.isNotEmpty) {
      try {
        final parsed = jsonDecode(order.itemsJson) as List;
        items = parsed
            .map((e) => OrderItemViewModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (e) {
        dev.log('[OrderViewModel] Failed to parse itemsJson for order ${order.id}: $e');
      }
    }

    List<Map<String, dynamic>> promos = [];
    if (order.promosJson != null && order.promosJson!.isNotEmpty) {
      try {
        promos = List<Map<String, dynamic>>.from(
          jsonDecode(order.promosJson!) as List,
        );
      } catch (e) {
        dev.log('[OrderViewModel] Failed to parse promosJson for order ${order.id}: $e');
      }
    }

    CustomerSummary? pelanggan;
    if (order.pelangganId != null && customerMap != null) {
      pelanggan = customerMap[order.pelangganId];
    }

    return OrderViewModel(
      id: order.id,
      serverId: order.serverId,
      clientRef: order.clientRef ?? order.id,
      noPesanan: order.noPesanan,
      pelangganId: order.pelangganId,
      pelanggan: pelanggan,
      status: order.status,
      items: items,
      promos: promos,
      totalTagihan: order.totalTagihan,
      tanggalTransaksi: order.tanggalTransaksi,
      notes: order.notes,
      isLocal: order.isLocal == 1,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      kunjunganId: order.kunjunganId,
    );
  }

  /// Convert back to Map for backward compatibility with existing widgets
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'client_ref': clientRef,
      'local_ref': clientRef,
      'no_pesanan': noPesanan,
      'id_pelanggan': pelangganId,
      'id_kunjungan': kunjunganId,
      'pelanggan': pelanggan != null
          ? {
              'id': pelanggan!.id,
              'nama_toko': pelanggan!.namaToko,
              'nama_pemilik': pelanggan!.namaPemilik,
              'foto_toko_url': pelanggan!.fotoTokoUrl,
              'alamat': pelanggan!.alamat,
            }
          : <String, dynamic>{},
      'status': status,
      'items': items
          .map((i) => {
                'id_produk': i.idProduk,
                'nama_produk': i.namaProduk,
                'jumlah': i.jumlah,
                'harga_satuan': i.hargaSatuan,
                'id_satuan': i.unitId,
                'nama_satuan': i.unitName,
                'subtotal': i.subtotal,
              })
          .toList(),
      'promos': promos,
      'total_tagihan': totalTagihan,
      'tanggal_transaksi': tanggalTransaksi,
      'notes': notes,
      'is_local': isLocal,
      'is_offline': isLocal,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
