import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PROVIDERS — Reactive SSOT (Preferred)
// Watches Drift table stream for real-time UI updates.
// Use with StreamBuilder in UI pages.
// ─────────────────────────────────────────────────────────────────────────────

final notificationsStreamProvider =
    StreamProvider<List<NotificationEntity>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.watchAll();
});

final unreadNotificationCountStreamProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.watchUnreadCount();
});

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER — For Actions Only (markAsRead, markAllRead, delete, etc.)
// Data fetching is now done via notificationsStreamProvider + StreamBuilder
// ─────────────────────────────────────────────────────────────────────────────

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, void>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<void> {
  @override
  void build() {}

  Future<void> markAsRead(String id) async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.markAsRead(id);
      // State will update via stream subscription
    } catch (e) {
      // Ignore
    }
  }

  Future<void> markAllRead() async {
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.markAllRead();
      // State will update via stream subscription
    } catch (e) {
      // Ignore
    }
  }
}
