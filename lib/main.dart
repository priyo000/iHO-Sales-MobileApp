import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_tracker_mobile/core/router/app_router.dart';
import 'package:sales_tracker_mobile/core/theme/app_theme.dart';
import 'package:sales_tracker_mobile/core/services/push_notification_service.dart';
import 'package:sales_tracker_mobile/core/services/connectivity_service.dart';
import 'package:sales_tracker_mobile/core/services/sync_service.dart';
import 'package:sales_tracker_mobile/core/services/background_sync_service.dart';
import 'package:sales_tracker_mobile/core/services/preload_service.dart';
import 'package:sales_tracker_mobile/core/services/offline_photo_service.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/controllers/cart_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Portrait saja
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await initializeDateFormatting('id_ID');

  // ── Parallel Init ──────────────────────────────────────────────────────────
  // Firebase dan Drift database diinisialisasi bersamaan — hemat ~100–300ms startup
  await Firebase.initializeApp();

  // Task 3: Background Worker Init
  BackgroundSyncService.initialize();
  BackgroundSyncService.registerPeriodicSync();

  // Cleanup: hapus data lama yang tidak dibutuhkan (non-blocking)
  unawaited(
    OfflinePhotoService().cleanupOrphanPhotos(),
  );

  runApp(
    const ProviderScope(
      child: SalesTrackerApp(),
    ),
  );
}

class SalesTrackerApp extends ConsumerStatefulWidget {
  const SalesTrackerApp({super.key});

  @override
  ConsumerState<SalesTrackerApp> createState() => _SalesTrackerAppState();
}

class _SalesTrackerAppState extends ConsumerState<SalesTrackerApp>
    with WidgetsBindingObserver {
  bool _preloadTriggered = false;
  bool _pushInitialized = false;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();

    // Register lifecycle observer for foreground sync trigger
    WidgetsBinding.instance.addObserver(this);

    // Kickstart offline services (non-blocking, hanya instantiate provider)
    final connectivity = ref.read(connectivityServiceProvider);
    ref.read(syncServiceProvider);

    // Reconnect-trigger: begitu network kembali online, langsung flush sync queue
    // tanpa nunggu interval Workmanager (15 menit). Hindari double-trigger lewat
    // distinct previous-state check.
    bool wasOnline = connectivity.isOnline;
    _connectivitySub = connectivity.onStatusChange.listen((isOnline) {
      if (isOnline && !wasOnline) {
        debugPrint('[Reconnect] Network back online → flush sync queue');
        try {
          ref.read(syncServiceProvider).syncAll();
        } catch (_) {}
      }
      wasOnline = isOnline;
    });

    // Restore persistent cart dari SQLite (survive app restart / background kill)
    unawaited(ref.read(cartControllerProvider.notifier).loadFromDatabase());

    // ── Defer Push Notification Init ──────────────────────────────────────
    // PushNotificationService.initialize() melakukan Firebase permission request
    // dan setup listener. Kita defer ke setelah frame pertama render supaya
    // UI tidak terblokir.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_pushInitialized && mounted) {
        _pushInitialized = true;
        unawaited(_initPushNotification());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 1. Write sync queue (existing)
      try {
        ref.read(syncServiceProvider).syncAll();
      } catch (e) {
        // Sync gagal, abaikan — WorkManager akan handle nanti
      }

      // 2. Smart pre-fetch: trigger jika data sudah lama tidak di-sync
      _triggerSmartPreFetchIfNeeded();
    }
  }

  /// Smart pre-fetch: trigger jika last_sync > 12 jam atau belum pernah sync hari ini
  void _triggerSmartPreFetchIfNeeded() {
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastSyncStr = prefs.getString('pre_work_sync_time');

        if (lastSyncStr == null) {
          // Belum pernah sync → trigger sekarang
          BackgroundSyncService.triggerPreWorkSyncNow();
          return;
        }

        final lastSync = DateTime.tryParse(lastSyncStr);
        if (lastSync == null) {
          BackgroundSyncService.triggerPreWorkSyncNow();
          return;
        }

        final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
        if (hoursSinceSync >= 12) {
          // Sudah > 12 jam → trigger sync
          BackgroundSyncService.triggerPreWorkSyncNow();
        }
      } catch (e) {
        // Ignore — tidak kritis
      }
    }());
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initPushNotification() async {
    try {
      await PushNotificationService.initialize(
        onForegroundMessage: (_) {
          try {
            ref.invalidate(notificationsControllerProvider);
          } catch (e) {
            debugPrint('[Push] invalidate notifications failed: $e');
          }
        },
      );
    } catch (e) {
      debugPrint('[Push] Init gagal: $e');
    }
  }

  /// Trigger preload sekali saat user sudah terautentikasi.
  /// Berjalan di microtask — tidak blocking UI.
  void _triggerPreloadIfNeeded(Map<String, dynamic>? user) {
    if (user != null && !_preloadTriggered) {
      _preloadTriggered = true;
      Future.microtask(() {
        ref.read(preloadServiceProvider).runIfStale();
      });
    }
    if (user == null) _preloadTriggered = false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _triggerPreloadIfNeeded(user);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sales Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
