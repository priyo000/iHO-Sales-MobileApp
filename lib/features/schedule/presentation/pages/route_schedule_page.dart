import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../prospecting/presentation/pages/prospecting_list_page.dart';
import '../widgets/schedule_jadwal_tab.dart';

class RouteSchedulePage extends ConsumerStatefulWidget {
  const RouteSchedulePage({super.key});

  @override
  ConsumerState<RouteSchedulePage> createState() => _RouteSchedulePageState();
}

class _RouteSchedulePageState extends ConsumerState<RouteSchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Kunjungan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Jadwal'),
            Tab(text: 'Prospecting'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ScheduleJadwalTab(),
          ProspectingListPage(),
        ],
      ),
    );
  }
}
