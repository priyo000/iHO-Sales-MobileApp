import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sales_tracker_mobile/core/db/app_database.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';
import 'package:sales_tracker_mobile/core/utils/formatters.dart';
import 'package:sales_tracker_mobile/features/orders/data/order_repository.dart';

class CustomerLastVisitSheet extends ConsumerWidget {
  final VisitsTableData visit;

  const CustomerLastVisitSheet({super.key, required this.visit});

  static Future<void> show(BuildContext context, VisitsTableData visit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Riwayat Kunjungan Terakhir',
                        style: AppTextStyles.headingMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
                  ),
                  child: CustomerLastVisitSheet(visit: visit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInLocal = _parseToLocal(visit.waktuCheckIn);
    final checkOutLocal = _parseToLocal(visit.waktuCheckOut);
    final duration = (checkInLocal != null && checkOutLocal != null)
        ? checkOutLocal.difference(checkInLocal)
        : null;
    final isUnplanned = visit.scheduleId == null;
    final dateLabel = checkInLocal != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(checkInLocal)
        : '-';

    final orders = ref.watch(ordersForVisitProvider(visit)).asData?.value ??
        const <OrdersTableData>[];

    if (orders.isEmpty && (visit.pelangganId?.isNotEmpty ?? false)) {
      final allForCustomer = ref
              .watch(ordersByPelangganProvider(visit.pelangganId!))
              .asData
              ?.value ??
          const <OrdersTableData>[];
      if (allForCustomer.isNotEmpty) {
        debugPrint(
          '[LastVisitSheet] No order match — visit.id=${visit.id} '
          'serverId=${visit.serverId} pelanggan=${visit.pelangganId} '
          'window=${visit.waktuCheckIn}..${visit.waktuCheckOut}; '
          'customer has ${allForCustomer.length} orders with kunjunganIds='
          '${allForCustomer.map((o) => o.kunjunganId).toList()}',
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusChip(isUnplanned: isUnplanned, hasOrder: visit.alasanTidak == null),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Tanggal Kunjungan',
          icon: Icons.calendar_today_outlined,
          child: Text(dateLabel, style: AppTextStyles.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _TimeCard(
                label: 'Check-in',
                time: checkInLocal,
                icon: Icons.login_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _TimeCard(
                label: 'Check-out',
                time: checkOutLocal,
                icon: Icons.logout_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        if (duration != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DurationCard(duration: duration),
        ],
        if (orders.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Pesanan dari Kunjungan Ini',
            icon: Icons.shopping_cart_outlined,
            child: Column(
              children: [
                for (final order in orders) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _OrderBadge(
                    order: order,
                    onTap: () => context.push('/orders/detail',
                        extra: _orderToMap(order)),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_parsePhotoPaths(visit.localPhotoPaths).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Foto Bukti Kunjungan',
            icon: Icons.photo_library_outlined,
            child: _PhotoThumbnailRow(
              paths: _parsePhotoPaths(visit.localPhotoPaths),
            ),
          ),
        ],
        if (visit.alasanTidak != null && visit.alasanTidak!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Alasan Tidak Order',
            icon: Icons.info_outline_rounded,
            child: Text(visit.alasanTidak!, style: AppTextStyles.bodyMedium),
          ),
        ],
        if (visit.catatan != null && visit.catatan!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Catatan',
            icon: Icons.note_alt_outlined,
            child: Text(visit.catatan!, style: AppTextStyles.bodyMedium),
          ),
        ],
        if (visit.photosPending > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${visit.photosPending} foto bukti menunggu sinkronisasi',
                  style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static DateTime? _parseToLocal(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static List<MapEntry<String, String>> _parsePhotoPaths(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      return decoded.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => MapEntry(e.key.toString(), e.value.toString()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, dynamic> _orderToMap(OrdersTableData order) => {
        'id': order.id,
        'server_id': order.serverId,
        'local_ref': order.clientRef,
        'no_pesanan': order.noPesanan,
        'pelanggan_id': order.pelangganId,
        'kunjungan_id': order.kunjunganId,
        'status': order.status,
        'total_tagihan': order.totalTagihan,
        'tanggal_transaksi': order.tanggalTransaksi,
      };
}

class _OrderBadge extends StatelessWidget {
  final OrdersTableData order;
  final VoidCallback onTap;
  const _OrderBadge({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = order.noPesanan ?? 'Pesanan ${order.id.substring(0, 6)}';
    final total = Formatters.currency(order.totalTagihan);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      '${order.status} · $total',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isUnplanned;
  final bool hasOrder;
  const _StatusChip({required this.isUnplanned, required this.hasOrder});

  @override
  Widget build(BuildContext context) {
    final label = isUnplanned ? 'Unplanned' : 'Terjadwal';
    final orderLabel = hasOrder ? 'Dengan Order' : 'Tanpa Order';
    final orderColor = hasOrder ? AppColors.success : AppColors.warning;
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: orderColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(orderLabel,
              style: AppTextStyles.caption
                  .copyWith(color: orderColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(title,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final DateTime? time;
  final IconData icon;
  final Color color;
  const _TimeCard({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        time != null ? DateFormat('HH:mm:ss').format(time!) : '-';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(timeLabel,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final Duration duration;
  const _DurationCard({required this.duration});

  @override
  Widget build(BuildContext context) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    final label = h > 0
        ? '${h}j ${m}m ${s}d'
        : (m > 0 ? '${m}m ${s}d' : '${s}d');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text('Durasi kunjungan: ',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PhotoThumbnailRow extends StatelessWidget {
  final List<MapEntry<String, String>> paths;
  const _PhotoThumbnailRow({required this.paths});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (ctx, i) {
          final entry = paths[i];
          return GestureDetector(
            onTap: () => _showFullScreen(ctx, entry.value, entry.key),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.file(
                File(entry.value),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 96,
                  height: 96,
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreen(BuildContext context, String path, String label) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 64),
                ),
              ),
            ),
            Positioned(
              top: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
