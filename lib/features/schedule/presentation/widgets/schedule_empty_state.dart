import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';

/// Empty state shown when no schedule items exist for the selected date.
class ScheduleEmptyState extends StatelessWidget {
  const ScheduleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.event_busy_outlined,
      title: 'Tidak ada jadwal hari ini',
      message: 'Jadwal kunjungan untuk tanggal ini belum tersedia.',
    );
  }
}
