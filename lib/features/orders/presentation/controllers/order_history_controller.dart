import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/order_status.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/order_repository.dart';
import '../../data/models/order_view_model.dart';

/// Watch all orders from Drift SSOT - real-time reactive updates.
/// Emits new data whenever the orders table changes (including no_pesanan
/// updates from sync, status changes, etc.).
final allOrdersStreamProvider = StreamProvider<List<OrderViewModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllOrders().asyncMap((orders) async {
    dev.log(
      '[allOrdersStreamProvider] Stream emitted ${orders.length} orders',
    );

    final customers = await db.getAllLocalCustomers();
    final customerMap = <String, CustomerSummary>{};
    for (final c in customers) {
      final summary = CustomerSummary(
        id: c.serverId ?? c.id,
        namaToko: c.namaToko,
        namaPemilik: c.namaPemilik,
        fotoTokoUrl: c.fotoTokoPath,
        alamat: c.alamatUsaha,
      );
      if (c.serverId != null) customerMap[c.serverId!] = summary;
      customerMap[c.id] = summary;
    }

    return orders
        .map((order) => OrderViewModel.fromDriftData(order, customerMap: customerMap))
        .toList();
  });
});

class _OrderFilter {
  final String status;
  final String search;
  const _OrderFilter({this.status = 'All', this.search = ''});
}

class OrderHistoryController extends Notifier<List<Map<String, dynamic>>> {
  _OrderFilter _filter = const _OrderFilter();

  String get searchQuery => _filter.search;
  String get statusFilter => _filter.status;

  @override
  List<Map<String, dynamic>> build() {
    final ordersAsync = ref.watch(allOrdersStreamProvider);

    return ordersAsync.when(
      data: (orders) => _applyFilters(orders),
      loading: () => const [],
      error: (e, s) => state,
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<OrderViewModel> orders) {
    var filtered = orders;

    if (_filter.status != 'All' && _filter.status != 'Semua') {
      final statusMap = {
        'Pending': OrderStatus.pending.code,
        'Tertunda': OrderStatus.pending.code,
        'Proses': 'APPROVED',
        'Sukses': 'COMPLETED',
        'Batal': 'CANCELLED',
      };
      final serverStatus =
          statusMap[_filter.status] ?? _filter.status.toUpperCase();
      filtered = filtered.where((o) {
        final s = o.status.toUpperCase();
        return s == serverStatus || s.contains(serverStatus);
      }).toList();
    }

    if (_filter.search.isNotEmpty) {
      final q = _filter.search.toLowerCase();
      filtered = filtered.where((o) {
        final no = o.clientRef.toLowerCase();
        final noPesanan = o.noPesanan?.toLowerCase() ?? '';
        final namaToko = o.pelanggan?.namaToko?.toLowerCase() ?? '';
        return no.contains(q) || noPesanan.contains(q) || namaToko.contains(q);
      }).toList();
    }

    return filtered.map((o) => o.toMap()).toList();
  }

  void setStatus(String status) {
    _filter = _OrderFilter(status: status, search: _filter.search);
    ref.invalidate(allOrdersStreamProvider);
  }

  void setSearch(String search) {
    _filter = _OrderFilter(status: _filter.status, search: search);
    ref.invalidate(allOrdersStreamProvider);
  }

  Future<void> refresh() async {
    await ref.read(orderRepositoryProvider).syncOrdersFromApi();
    ref.invalidate(allOrdersStreamProvider);
  }
}

final orderHistoryControllerProvider =
    NotifierProvider<OrderHistoryController, List<Map<String, dynamic>>>(
      OrderHistoryController.new,
    );
