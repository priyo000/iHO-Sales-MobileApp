import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/app_update_service.dart';
import '../services/download_status_service.dart';
import 'sync_queue_dialog.dart';
import 'status_bar/update_banner.dart';
import 'status_bar/preloading_banner.dart';
import 'status_bar/sync_failed_banner.dart';
import 'status_bar/syncing_banner.dart';
import 'status_bar/offline_banner.dart';
import 'status_bar/failed_items_sheet.dart';

class UnifiedStatusBar extends ConsumerWidget {
  const UnifiedStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final failedAsync = ref.watch(failedSyncItemsProvider);
    final totalPending = ref.watch(totalSyncCountProvider);
    final updateAsync = ref.watch(appUpdateServiceProvider);
    final downloadTasks = ref.watch(downloadStatusProvider);

    return isOnlineAsync.maybeWhen(
      data: (isOnline) {
        final activeDownloads = downloadTasks
            .where((t) => !t.isCompleted)
            .toList();
        if (activeDownloads.isNotEmpty) {
          final totalTasks = downloadTasks.length;
          final completedTasks = totalTasks - activeDownloads.length;
          return PreloadingBanner(
            completed: completedTasks,
            total: totalTasks,
            currentLabel: activeDownloads.first.label,
          );
        }

        if (updateAsync.value != null &&
            updateAsync.value!['hasUpdate'] == true) {
          return UpdateBanner(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
          );
        }

        final failedItems = failedAsync.value ?? [];
        if (failedItems.isNotEmpty) {
          return SyncFailedBanner(
            count: failedItems.length,
            onTap: () => _showFailedItemsSheet(context, ref, failedItems),
          );
        }

        if (isOnline && totalPending > 0) {
          return SyncingBanner(
            pending: totalPending,
            downloading: downloadTasks.where((t) => !t.isCompleted).length,
            onTap: () => SyncQueueDialog.show(context),
          );
        }

        if (!isOnline) {
          return OfflineBanner(
            pending: totalPending,
            onTap: () => SyncQueueDialog.show(context),
          );
        }

        return const SizedBox.shrink();
      },
      orElse: () {
        final activeDownloads = downloadTasks
            .where((t) => !t.isCompleted)
            .toList();
        if (activeDownloads.isNotEmpty) {
          final totalTasks = downloadTasks.length;
          final completedTasks = totalTasks - activeDownloads.length;
          return PreloadingBanner(
            completed: completedTasks,
            total: totalTasks,
            currentLabel: activeDownloads.first.label,
          );
        }

        final failedItems = failedAsync.value ?? [];
        if (failedItems.isNotEmpty) {
          return SyncFailedBanner(
            count: failedItems.length,
            onTap: () => _showFailedItemsSheet(context, ref, failedItems),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showFailedItemsSheet(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FailedItemsSheet(items: items, ref: ref),
    );
  }
}
