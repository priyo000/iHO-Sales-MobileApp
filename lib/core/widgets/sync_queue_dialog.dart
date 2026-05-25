import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../providers/database_providers.dart';
import '../services/sync_service.dart';
import '../services/download_status_service.dart';

class SyncQueueDialog extends ConsumerWidget {
  const SyncQueueDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SyncQueueDialog(),
    );
  }

  static String _getOpLabel(String op) {
    switch (op) {
      case 'check_in':
        return 'Check-In';
      case 'check_out':
        return 'Check-Out';
      case 'create_order':
        return 'Pesanan Baru';
      case 'create_pelanggan':
      case 'create_prospect':
        return 'Pelanggan Baru';
      case 'update_order_status':
        return 'Update Status Pesanan';
      default:
        return op;
    }
  }

  static IconData _getOpIcon(String op) {
    switch (op) {
      case 'check_in':
        return Icons.login_rounded;
      case 'check_out':
        return Icons.logout_rounded;
      case 'create_order':
        return Icons.shopping_cart_rounded;
      case 'create_pelanggan':
      case 'create_prospect':
        return Icons.person_add_rounded;
      default:
        return Icons.sync_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadTasks = ref.watch(downloadStatusProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Text(
                      'Antrean Sinkronisasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (downloadTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sedang memperbarui ${downloadTasks.length} data master...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Unified List (Downloads + Uploads)
          Expanded(
            child: FutureBuilder<List<SyncQueueTableData>>(
              future: ref.read(appDatabaseProvider).getAllQueueItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    downloadTasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final uploadItems = snapshot.data ?? [];

                if (uploadItems.isEmpty && downloadTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Semua data sudah tersinkronisasi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // ── Summary & Group by Type ─────────────────────────────
                final int totalUpload = uploadItems.length;
                final int totalDownload = downloadTasks
                    .where((t) => !t.isCompleted)
                    .length;
                final int totalPending = totalUpload + totalDownload;
                final int failedCount = uploadItems
                    .where(
                      (i) =>
                          i.status == 'failed' ||
                          i.status == 'failed_permanently',
                    )
                    .length;

                // Group upload items by operation type
                final Map<String, List<SyncQueueTableData>> grouped = {};
                for (final item in uploadItems) {
                  final op = item.operation;
                  grouped.putIfAbsent(op, () => []).add(item);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$totalPending data menunggu sinkronisasi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final entry in grouped.entries)
                                _SummaryChip(
                                  label: _getOpLabel(entry.key),
                                  icon: _getOpIcon(entry.key),
                                  count: entry.value.length,
                                  hasFailed: entry.value.any(
                                    (i) =>
                                        i.status == 'failed' ||
                                        i.status == 'failed_permanently',
                                  ),
                                ),
                              if (totalDownload > 0)
                                _SummaryChip(
                                  label: 'Download',
                                  icon: Icons.cloud_download_rounded,
                                  count: totalDownload,
                                  color: AppColors.primary,
                                ),
                              if (failedCount > 0)
                                _SummaryChip(
                                  label: 'Gagal',
                                  icon: Icons.error_outline_rounded,
                                  count: failedCount,
                                  color: Colors.red,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inbound Sync (Downloads)
                    if (downloadTasks.isNotEmpty) ...[
                      const _SectionHeader(title: 'Download Data Master'),
                      for (final task in downloadTasks) ...[
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_download_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            task.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Sedang mengambil data terbaru'),
                          trailing: task.isCompleted
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                        const Divider(),
                      ],
                      const SizedBox(height: 8),
                    ],

                    // Outbound Sync (Uploads) — grouped by type
                    const _SectionHeader(title: 'Upload ke Server'),
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          '${_getOpLabel(entry.key)} (${entry.value.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      for (var i = 0; i < entry.value.length; i++) ...[
                        _buildUploadItem(context, ref, entry.value[i]),
                        if (i < entry.value.length - 1) const Divider(),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ],
                );
              },
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final syncService = ref.read(syncServiceProvider);
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Memulai sinkronisasi...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  try {
                    await syncService.syncAll();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Sinkronisasi selesai'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Sinkronisasi gagal: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Sinkronkan Sekarang'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadItem(
    BuildContext context,
    WidgetRef ref,
    SyncQueueTableData item,
  ) {
    final op = item.operation;
    final status = item.status;
    final retryCount = item.retryCount;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      item.createdAt,
    );
    final errorMessage = item.errorMessage;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(_getOpIcon(op), color: AppColors.primary, size: 20),
      ),
      title: Text(
        _getOpLabel(op),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ref: ${item.localRef}'),
          Text(
            'Waktu: ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12),
          ),
          if ((status == 'failed' || status == 'failed_permanently')) ...[
            Text(
              status == 'failed_permanently'
                  ? 'Gagal permanen (manual retry)'
                  : 'Gagal (Retrying $retryCount/5)',
              style: TextStyle(
                color: status == 'failed_permanently'
                    ? Colors.red[700]
                    : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (errorMessage != null && errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
          ],
        ],
      ),
      trailing: status == 'syncing'
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ((status == 'failed' || status == 'failed_permanently')
                ? PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'retry') {
                        await ref
                            .read(syncServiceProvider)
                            .retryFailed(item.localRef);
                        ref.read(syncServiceProvider).syncAll();
                      } else if (value == 'discard') {
                        await ref
                            .read(syncServiceProvider)
                            .discardFailed(item.localRef);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'retry',
                        child: Text('Coba Lagi'),
                      ),
                      const PopupMenuItem(
                        value: 'discard',
                        child: Text('Hapus Antrean'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  )
                : const Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.orange,
                  )),
    );
  }
}

// ── Summary Chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final Color? color;
  final bool hasFailed;

  const _SummaryChip({
    required this.label,
    required this.icon,
    required this.count,
    this.color,
    this.hasFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = hasFailed ? Colors.red : (color ?? AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
