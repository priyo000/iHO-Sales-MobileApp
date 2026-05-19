import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/utils/paginated_state.dart';
import 'package:sales_tracker_mobile/features/customer/data/customer_repository.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/controllers/customer_controller.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';
import 'package:sales_tracker_mobile/core/services/sync_service.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';

// ─── Controller ───────────────────────────────────────────────────────────────

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

      // Map items to ensure consistent keys that _ProspectCard expects
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

// ─── Page ─────────────────────────────────────────────────────────────────────

class ProspectingListPage extends ConsumerStatefulWidget {
  const ProspectingListPage({super.key});

  @override
  ConsumerState<ProspectingListPage> createState() =>
      _ProspectingListPageState();
}

class _ProspectingListPageState extends ConsumerState<ProspectingListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.text = ref
        .read(prospectControllerProvider.notifier)
        .search;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(prospectControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(prospectControllerProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prospectControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari prospect...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: state.isRefreshing && state.items.isEmpty
                ? const ListSkeleton()
                : state.error != null && state.items.isEmpty
                ? AppErrorView(
                    message: 'Gagal memuat prospect: ${state.error}',
                    onRetry: () =>
                        ref.read(prospectControllerProvider.notifier).refresh(),
                  )
                : state.items.isEmpty && !state.isRefreshing
                ? RefreshIndicator(
                    onRefresh: () =>
                        ref.read(prospectControllerProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _EmptyView(
                            onAdd: () => context.push('/prospecting'),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(prospectControllerProvider.notifier).refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.items.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _ProspectCard(data: state.items[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/prospecting');
          ref.read(prospectControllerProvider.notifier).refresh();
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Prospect',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── _ProspectCard (unchanged) ────────────────────────────────────────────────

class _ProspectCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProspectCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final namaToko = data['nama_toko'] ?? data['nama_pemilik'] ?? '-';
    final namaPemilik = data['nama_pemilik'] ?? '-';
    final alamat = data['alamat_usaha'] ?? '-';
    final kode = data['kode_pelanggan'] ?? '';
    final bool isOffline = data['is_offline'] == true;
    final createdAt = data['created_at'] != null
        ? _formatDate(data['created_at'].toString())
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_outlined,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isOffline)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          namaToko,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (kode.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      kode,
                      style: TextStyle(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          namaPemilik,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          alamat,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (isOffline ? Colors.orange : Colors.amber)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOffline ? 'PENDING' : 'PROSPECT',
                    style: TextStyle(
                      color: isOffline ? Colors.orange : Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  createdAt,
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      DateTime dt;
      final asInt = int.tryParse(raw);
      if (asInt != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(asInt).toLocal();
      } else {
        dt = DateTime.parse(raw).toLocal();
      }
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ─── Empty & Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada prospect',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai perjalanan hari ini dengan menambah\nprospect toko baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Tambah Prospect',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
