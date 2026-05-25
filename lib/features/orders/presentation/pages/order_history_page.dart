import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/widgets/app_chip.dart';
import 'package:sales_tracker_mobile/core/widgets/app_empty_state.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';

import '../../presentation/widgets/order_card.dart';
import '../controllers/order_history_controller.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Tertunda', 'Proses', 'Sukses', 'Batal'];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref
        .read(orderHistoryControllerProvider.notifier)
        .searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(orderHistoryControllerProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersStreamProvider);
    final filteredOrders = ref.watch(orderHistoryControllerProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return AppScaffold(
      appBar: AppBar(title: const Text('Riwayat Order')),
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari no. pesanan atau nama toko...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ordersAsync.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: AppChip(
                      label: filter,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        ref
                            .read(orderHistoryControllerProvider.notifier)
                            .setStatus(filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(orderHistoryControllerProvider.notifier).refresh(),
              child: ordersAsync.when(
                data: (_) {
                  final filtered = filteredOrders;
                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: AppSpacing.xxxl),
                        AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Belum ada pesanan',
                          message:
                              'Pesanan yang sudah disinkronisasi\nakan muncul di sini',
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: OrderCard(
                          key: ValueKey(filtered[index]['id']),
                          order: filtered[index],
                          currencyFormat: currencyFormat,
                          dateFormat: dateFormat,
                          onTap: (order) =>
                              context.push('/orders/detail', extra: order),
                        ),
                      );
                    },
                  );
                },
                loading: () => const ListSkeleton(),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    AppErrorView(
                      message: 'Gagal memuat riwayat order: $error',
                      onRetry: () => ref
                          .read(orderHistoryControllerProvider.notifier)
                          .refresh(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
