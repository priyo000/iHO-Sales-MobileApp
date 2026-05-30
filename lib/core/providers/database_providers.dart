// ─────────────────────────────────────────────────────────────────────────────
// Database & Network Providers
//
// Provides singleton instances of AppDatabase, DioClient, and TokenStorage
// using Riverpod for dependency injection.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../db/app_database.dart';
import '../db/daos/daos.dart';
import '../network/dio_client.dart';

// ─── Token Storage Provider ─────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

// ─── Database Provider ──────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final localDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(appDatabaseProvider);
});

// ─── DAO Providers ──────────────────────────────────────────────────────────

final cacheDaoProvider = Provider<CacheDao>((ref) {
  return ref.watch(appDatabaseProvider).cacheDao;
});

final cartDaoProvider = Provider<CartDao>((ref) {
  return ref.watch(appDatabaseProvider).cartDao;
});

final customerDaoProvider = Provider<CustomerDao>((ref) {
  return ref.watch(appDatabaseProvider).customerDao;
});

final notificationDaoProvider = Provider<NotificationDao>((ref) {
  return ref.watch(appDatabaseProvider).notificationDao;
});

final orderDaoProvider = Provider<OrderDao>((ref) {
  return ref.watch(appDatabaseProvider).orderDao;
});

final productDaoProvider = Provider<ProductDao>((ref) {
  return ref.watch(appDatabaseProvider).productDao;
});

final promoDaoProvider = Provider<PromoDao>((ref) {
  return ref.watch(appDatabaseProvider).promoDao;
});

final reportsDaoProvider = Provider<ReportsDao>((ref) {
  return ref.watch(appDatabaseProvider).reportsDao;
});

final scheduleDaoProvider = Provider<ScheduleDao>((ref) {
  return ref.watch(appDatabaseProvider).scheduleDao;
});

final syncDaoProvider = Provider<SyncDao>((ref) {
  return ref.watch(appDatabaseProvider).syncDao;
});

final visitDaoProvider = Provider<VisitDao>((ref) {
  return ref.watch(appDatabaseProvider).visitDao;
});

// ─── Dio Client Provider ────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return DioClient(
    tokenStorage: tokenStorage,
    onAuthFailure: () {
      ref.read(authProvider.notifier).logoutDueToSessionExpired();
    },
  );
});

// ─── Network Provider Alias ─────────────────────────────────────────────────

final apiClientProvider = Provider<DioClient>((ref) {
  return ref.watch(dioClientProvider);
});

