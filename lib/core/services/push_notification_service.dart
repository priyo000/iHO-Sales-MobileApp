import 'dart:async';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sales_tracker_mobile/core/router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static void Function(RemoteMessage message)? _onForegroundMessage;
  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  /// Initialize FCM + local notifications.
  ///
  /// [onForegroundMessage] is invoked for every foreground message before
  /// the local notification is shown. Feature layers can use this to
  /// invalidate their data (e.g. notifications controller) without this
  /// service needing to import them.
  static Future<void> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _onForegroundMessage = onForegroundMessage;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted notification permission');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationClick(details.payload);
      },
    );

    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      try {
        _onForegroundMessage?.call(message);
      } catch (e) {
        log('Error in onForegroundMessage callback: $e');
      }

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification clicked from background!');
      _handleNotificationClickFromMessage(message);
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      log('Notification clicked from terminated state!');
      _handleNotificationClickFromMessage(initialMessage);
    }
  }

  static void _handleNotificationClickFromMessage(RemoteMessage message) {
    final type = message.data['type'];
    final relatedId = message.data['id'];
    _navigate(type, relatedId);
  }

  static void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length >= 2) {
      _navigate(parts[0], parts[1]);
    } else {
      _navigate('general', null);
    }
  }

  static void _navigate(String? type, String? id) {
    log('Navigating for type: $type, id: $id');

    if (type == 'gamifikasi') {
      appRouter.push('/dashboard');
    } else if (type == 'order' && id != null) {
      appRouter.push('/orders/$id');
    } else {
      appRouter.push('/notifications');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final type = message.data['type'] ?? 'general';
    final id = message.data['id'] ?? '';
    final payload = "$type|$id";

    // FIXED: Using named parameters correctly
    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
