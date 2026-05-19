import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/last_sync_service.dart';
import '../domain/notification_entity.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dioClient = ref.watch(dioClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final lastSync = ref.watch(lastSyncServiceProvider);
  return NotificationsRepository(db, dioClient, connectivity, lastSync);
});

class NotificationsRepository {
  final AppDatabase _db;
  final DioClient _dioClient;
  final ConnectivityService _connectivity;
  final LastSyncService _lastSync;

  NotificationsRepository(this._db, this._dioClient, this._connectivity, this._lastSync);

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC: Fetch notifications from API and save to local Drift
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync notifications from API to local Drift table (delta sync)
  Future<void> syncFromApi({bool forceRefresh = false}) async {
    final isOnline = await _connectivity.checkNow();
    if (!isOnline) {
      log('[NotificationsRepo] Offline, skip sync');
      return;
    }

    try {
      log('[NotificationsRepo] Syncing notifications from API...');

      String url = ApiConstants.notifikasi;
      if (!forceRefresh) {
        final since = await _lastSync.getLastModified(SyncResource.notifications);
        if (since != null) {
          url += '?since=$since';
        }
      }

      final data = await _dioClient.get(url);

      if (data is Map && data['data'] is List) {
        final notificationList = data['data'] as List;
        if (notificationList.isNotEmpty) {
          await _db.saveNotifications(
            notificationList.map((n) => Map<String, dynamic>.from(n as Map)).toList(),
          );
          log('[NotificationsRepo] ✅ Synced ${notificationList.length} notifications to Drift');
        }
      } else if (data is List) {
        // Handle case where API returns List directly
        if (data.isNotEmpty) {
          await _db.saveNotifications(
            data.map((n) => Map<String, dynamic>.from(n as Map)).toList(),
          );
          log('[NotificationsRepo] ✅ Synced ${data.length} notifications to Drift');
        }
      }

      await _lastSync.setLastSync(
        SyncResource.notifications,
        lastModified: DateTime.now(),
      );
    } catch (e) {
      log('[NotificationsRepo] ❌ Sync failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTIVE STREAMS — For Real-Time UI Updates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Watch all notifications - auto-updates when table changes
  Stream<List<NotificationEntity>> watchAll() {
    return _db.watchAllNotifications().map(
      (list) => list.map(_entityFromData).toList(),
    );
  }

  /// Watch unread notifications only
  Stream<List<NotificationEntity>> watchUnread() {
    return _db.watchUnreadNotifications().map(
      (list) => list.map(_entityFromData).toList(),
    );
  }

  /// Watch unread count - for badge updates
  Stream<int> watchUnreadCount() {
    return _db.watchUnreadNotificationCount();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    await _db.markNotificationRead(id);
  }

  /// Mark all notifications as read
  Future<void> markAllRead() async {
    await _db.markAllNotificationsRead();
  }

  /// Delete notification
  Future<void> delete(String id) async {
    await _db.deleteNotification(id);
  }

  /// Delete all read notifications
  Future<void> deleteRead() async {
    await _db.deleteReadNotifications();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    return await _db.getUnreadNotificationCount();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  NotificationEntity _entityFromData(NotificationsTableData data) {
    return NotificationEntity(
      id: data.id,
      judul: data.judul,
      pesan: data.isi,
      isRead: data.isRead,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data.createdAt,
      ).toIso8601String(),
    );
  }
}
