import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/utils/formatters.dart';
import 'package:sales_tracker_mobile/core/utils/status_styles.dart';
import 'package:sales_tracker_mobile/core/widgets/app_badge.dart';
import 'package:sales_tracker_mobile/core/widgets/app_card.dart';
import 'package:sales_tracker_mobile/core/widgets/app_empty_state.dart';
import 'package:sales_tracker_mobile/core/widgets/app_error_view.dart';
import 'package:sales_tracker_mobile/core/widgets/app_scaffold.dart';
import 'package:sales_tracker_mobile/core/widgets/shimmer_loading.dart';
import 'package:sales_tracker_mobile/features/prospecting/presentation/controllers/prospect_controller.dart';

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
    _searchController.text =
        ref.read(prospectControllerProvider.notifier).search;
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

    return AppScaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari prospect...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: state.isRefreshing && state.items.isEmpty
                ? const ListSkeleton()
                : state.error != null && state.items.isEmpty
                    ? AppErrorView(
                        message: 'Gagal memuat prospect: ${state.error}',
                        onRetry: () => ref
                            .read(prospectControllerProvider.notifier)
                            .refresh(),
                      )
                    : state.items.isEmpty && !state.isRefreshing
                        ? RefreshIndicator(
                            onRefresh: () => ref
                                .read(prospectControllerProvider.notifier)
                                .refresh(),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.7,
                                  child: AppEmptyState(
                                    icon: Icons.storefront_outlined,
                                    title: 'Belum ada prospect',
                                    message:
                                        'Mulai perjalanan hari ini dengan menambah\nprospect toko baru.',
                                    actionLabel: 'Tambah Prospect',
                                    onAction: () =>
                                        context.push('/prospecting'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(prospectControllerProvider.notifier)
                                .refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: state.items.length +
                                  (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: Text(
          'Tambah Prospect',
          style: AppTextStyles.button,
        ),
      ),
    );
  }
}

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

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.store_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
                          color: AppColors.warning,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        namaToko,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontSize: 15),
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
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        namaPemilik,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        alamat,
                        style: AppTextStyles.bodySmall,
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
              AppBadge(
                label: isOffline ? 'TERTUNDA' : 'PROSPEK',
                color: isOffline
                    ? StatusStyles.customerColor('PENDING')
                    : StatusStyles.customerColor('PROSPECT'),
              ),
              const SizedBox(height: 6),
              Text(
                createdAt,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final asInt = int.tryParse(raw);
    final dt = asInt != null
        ? DateTime.fromMillisecondsSinceEpoch(asInt).toLocal()
        : DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return Formatters.date(dt, pattern: 'HH:mm, d MMM yyyy');
  }
}
