import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';
import '../../../customer/presentation/controllers/customer_controller.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/auth/user_provider.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, Map<String, dynamic>>(
      DashboardController.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// DashboardController — SSOT Reactive (NO SWR)
//
// Data comes directly from Drift tables which are already populated
// by PreloadService during app startup. No cache needed.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardController extends AsyncNotifier<Map<String, dynamic>> {
  @override
  FutureOr<Map<String, dynamic>> build() async {
    ref.watch(userLocationProvider);

    // SSOT: Auto refresh dashboard when sync queue changes
    ref.listen(pendingSyncCountProvider, (previous, next) {
      if (next is AsyncData && !state.isLoading) {
        refresh();
      }
    });

    // SSOT: Read directly from Drift via repository
    return _loadFromDrift();
  }

  Future<Map<String, dynamic>> _loadFromDrift() async {
    final repository = ref.read(dashboardRepositoryProvider);
    final user = ref.read(userProvider);
    final employeeId = user?['karyawan']?['id']?.toString();
    log('[Dashboard] Loading from Drift SSOT...');

    try {
      final stats = await repository.getDashboardStats(employeeId: employeeId);
      if (stats.isNotEmpty) {
        log('[Dashboard] ✅ Loaded from Drift');
        return stats;
      }
    } catch (e) {
      log('[Dashboard] ❌ Error loading from Drift: $e');
    }

    return {};
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final user = ref.read(userProvider);
      final employeeId = user?['karyawan']?['id']?.toString();
      final stats = await repository.getDashboardStats(employeeId: employeeId);
      state = AsyncValue.data(stats);
      log('[Dashboard] ✅ Refreshed from Drift');
    } catch (e, st) {
      log('[Dashboard] ❌ Refresh failed: $e');
      state = AsyncValue.error(e, st);
    }
  }
}
