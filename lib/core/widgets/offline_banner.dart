import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/connectivity_service.dart';
import '../services/download_status_service.dart';
import '../providers/database_providers.dart';
import 'sync_queue_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Readiness Provider — reads directly from Drift (SSOT)
// ─────────────────────────────────────────────────────────────────────────────

final dataReadinessProvider = FutureProvider<DataReadiness>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);

  final schedule = await db.getScheduleForDate(today);
  final customers = await db.getAllLocalCustomers();
  final products = await db.getAllProducts();

  final prefs = await SharedPreferences.getInstance();
  final lastSyncTime = prefs.getString('pre_work_sync_time');

  return DataReadiness(
    hasSchedule: schedule.isNotEmpty,
    hasCustomers: customers.isNotEmpty,
    hasProducts: products.isNotEmpty,
    lastSyncTime: lastSyncTime,
  );
});

class DataReadiness {
  final bool hasSchedule;
  final bool hasCustomers;
  final bool hasProducts;
  final String? lastSyncTime;

  DataReadiness({
    required this.hasSchedule,
    required this.hasCustomers,
    required this.hasProducts,
    this.lastSyncTime,
  });

  bool get isReady => hasSchedule && hasCustomers && hasProducts;

  String get formattedSyncTime {
    if (lastSyncTime == null) return 'Belum sync';
    try {
      final dt = DateTime.parse(lastSyncTime!);
      final hours = dt.hour.toString().padLeft(2, '0');
      final mins = dt.minute.toString().padLeft(2, '0');
      return '$hours:$mins';
    } catch (_) {
      return 'Belum sync';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NetworkStatusChip
//
// Floating pill indicator yang muncul di dashboard.
// - Offline  → pill merah/orange dengan animasi pulse
// - Syncing  → pill teal dengan spinner & jumlah pending
// - Online   → tidak tampil (invisible)
// ─────────────────────────────────────────────────────────────────────────────

class NetworkStatusChip extends ConsumerStatefulWidget {
  const NetworkStatusChip({super.key});

  @override
  ConsumerState<NetworkStatusChip> createState() => _NetworkStatusChipState();
}

class _NetworkStatusChipState extends ConsumerState<NetworkStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkAsync = ref.watch(isOnlineProvider);
    final totalPending = ref.watch(totalSyncCountProvider);
    final readinessAsync = ref.watch(dataReadinessProvider);

    return networkAsync.when(
      data: (isOnline) {
        // Online + no pending writes → show data readiness badge
        if (isOnline && totalPending == 0) {
          return readinessAsync.when(
            data: (readiness) {
              if (!readiness.isReady) return const SizedBox.shrink();
              return _DataReadyChip(syncTime: readiness.formattedSyncTime);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          );
        }

        if (!isOnline) {
          return GestureDetector(
            onTap: () => SyncQueueDialog.show(context),
            child: _OfflineChip(
              pendingCount: totalPending,
              pulseAnim: _pulseAnim,
            ),
          );
        }

        // Online tapi masih ada pending → syncing
        return _SyncingChip(
          pendingCount: totalPending,
          onSync: () => SyncQueueDialog.show(context),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── Data Ready Chip ──────────────────────────────────────────────────────────

class _DataReadyChip extends StatelessWidget {
  final String syncTime;

  const _DataReadyChip({required this.syncTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            'Data Siap ($syncTime)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offline Chip ──────────────────────────────────────────────────────────────

class _OfflineChip extends StatelessWidget {
  final int pendingCount;
  final Animation<double> pulseAnim;

  const _OfflineChip({required this.pendingCount, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) {
        return Opacity(opacity: pulseAnim.value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(
              pendingCount > 0 ? 'Offline • $pendingCount pending' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Syncing Chip ──────────────────────────────────────────────────────────────

class _SyncingChip extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onSync;

  const _SyncingChip({required this.pendingCount, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Sinkronisasi $pendingCount data...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
