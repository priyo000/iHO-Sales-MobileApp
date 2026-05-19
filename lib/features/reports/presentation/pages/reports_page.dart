import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/reports_controller.dart';
import '../widgets/sales_performance_card.dart';
import '../widgets/effective_call_card.dart';
import '../widgets/chart_widget.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _periods = ['Minggu Ini', 'Bulan Ini', 'Kustom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final period = _periods[_tabController.index];
      ref.read(reportsControllerProvider.notifier).setPeriod(period);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
            Tab(text: 'Kustom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ReportView(), _ReportView(), _CustomDateRangeView()],
      ),
    );
  }
}

class _ReportView extends ConsumerWidget {
  const _ReportView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(reportsControllerProvider.select((s) => s.stats));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SalesPerformanceCard(stats: stats),
          const SizedBox(height: 16),
          EffectiveCallCard(stats: stats),
          const SizedBox(height: 16),
          ChartWidget(data: stats?.chartData ?? []),
        ],
      ),
    );
  }
}

class _CustomDateRangeView extends ConsumerStatefulWidget {
  const _CustomDateRangeView();

  @override
  ConsumerState<_CustomDateRangeView> createState() =>
      _CustomDateRangeViewState();
}

class _CustomDateRangeViewState extends ConsumerState<_CustomDateRangeView> {
  DateTimeRange? _range;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            _range == null
                ? 'Pilih Tanggal'
                : '${_range!.start.toString().substring(0, 10)} - ${_range!.end.toString().substring(0, 10)}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            _range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (_range != null)
              ref
                  .read(reportsControllerProvider.notifier)
                  .loadCustomRange(_range!);
            setState(() {});
          },
        ),
        const Expanded(child: _ReportView()),
      ],
    );
  }
}
