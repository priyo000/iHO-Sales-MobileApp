import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';

/// Model untuk melacak status unduhan (Get Data)
class DownloadTask {
  final String id;
  final String label;
  final double progress;
  final bool isCompleted;

  DownloadTask({
    required this.id,
    required this.label,
    this.progress = 0.0,
    this.isCompleted = false,
  });

  DownloadTask copyWith({String? label, double? progress, bool? isCompleted}) {
    return DownloadTask(
      id: id,
      label: label ?? this.label,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Controller untuk mengelola antrean unduhan di memori
class DownloadStatusNotifier extends Notifier<List<DownloadTask>> {
  @override
  List<DownloadTask> build() => [];

  void addTask(String id, String label) {
    if (state.any((t) => t.id == id)) return;
    state = [...state, DownloadTask(id: id, label: label)];
  }

  final Map<String, Timer> _pendingRemovals = {};

  void completeTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(isCompleted: true, progress: 1.0)
        else
          task,
    ];

    _pendingRemovals[id]?.cancel();
    _pendingRemovals[id] = Timer(const Duration(milliseconds: 1500), () {
      _pendingRemovals.remove(id);
      if (state.any((t) => t.id == id)) {
        removeTask(id);
      }
    });
  }

  void removeTask(String id) {
    state = state.where((task) => task.id != id).toList();
  }
}

final downloadStatusProvider =
    NotifierProvider<DownloadStatusNotifier, List<DownloadTask>>(
      DownloadStatusNotifier.new,
    );

/// Provider gabungan untuk menghitung total antrean (In + Out)
final totalSyncCountProvider = Provider<int>((ref) {
  final outCount = ref.watch(pendingSyncCountProvider).value ?? 0;
  final inCount = ref.watch(downloadStatusProvider).length;
  return outCount + inCount;
});
