import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_tracker_mobile/core/utils/paginated_state.dart';
import 'package:sales_tracker_mobile/features/customer/data/customer_repository.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/controllers/customer_controller.dart';
import 'package:sales_tracker_mobile/core/services/sync_service.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';

class ProspectController
    extends Notifier<PaginatedState<Map<String, dynamic>>> {
  static const int _perPage = 20;
  String _search = '';
  StreamSubscription? _driftSub;

  String get search => _search;

  @override
  PaginatedState<Map<String, dynamic>> build() {
    _load(1, reset: true);

    // SSOT: Reload when local sync queue settles (prospect mutation synced).
    ref.listen(pendingSyncCountProvider, (previous, next) {
      if (next is AsyncData && !state.isRefreshing) {
        _load(1, reset: true);
      }
    });

    // SSOT: subscribe to Drift stream directly so the page reloads as soon as
    // PreloadService populates the customers table (no manual refresh needed).
    final stream = ref.read(customersByStatusStreamProvider('Prospect'));
    _driftSub?.cancel();
    _driftSub = stream.listen((_) {
      if (!state.isRefreshing) _load(1, reset: true);
    });
    ref.onDispose(() => _driftSub?.cancel());

    return const PaginatedState();
  }

  void setSearch(String search) {
    _search = search;
    _load(1, reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await _load(state.currentPage + 1, reset: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      await ref
          .read(customerRepositoryProvider)
          .syncCustomersFromApi(
            status: 'prospect',
            search: _search.isEmpty ? null : _search,
          );
    } catch (e) {
      debugPrint('[ProspectingList] Refresh sync failed: $e');
    }
    await _load(1, reset: true);
  }

  Future<void> _load(int page, {required bool reset}) async {
    if (reset) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }
    try {
      final user = ref.read(userProvider);
      final employeeId = user?['karyawan']?['id']?.toString();
      final response = await ref
          .read(customerRepositoryProvider)
          .getCustomers(
            status: 'prospect',
            search: _search,
            createdById: employeeId,
            page: page,
            perPage: _perPage,
          );
      final parsed = parsePaginatedResponse(response);

      final mappedItems = parsed.items.map((item) {
        return {
          ...item,
          'nama_toko':
              item['nama_toko'] ??
              item['nama_pelanggan'] ??
              item['nama_pemilik'] ??
              'No Name',
          'status': item['status'] ?? item['status_pelanggan'] ?? 'PROSPECT',
        };
      }).toList();

      state = state.copyWith(
        items: reset ? mappedItems : [...state.items, ...mappedItems],
        currentPage: parsed.currentPage,
        lastPage: parsed.lastPage,
        isLoadingMore: false,
        isRefreshing: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }
}

final prospectControllerProvider =
    NotifierProvider<ProspectController, PaginatedState<Map<String, dynamic>>>(
      ProspectController.new,
    );
