import 'package:flutter/material.dart';
import '../controllers/reports_controller.dart';

class SalesPerformanceCard extends StatelessWidget {
  final ReportStats? stats;
  const SalesPerformanceCard({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performa Penjualan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Box(
                  label: 'Total Kunjungan',
                  value: '${stats?.totalVisit ?? 0}',
                ),
                _Box(label: 'Order', value: '${stats?.totalOrder ?? 0}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Box(
                  label: 'Nilai Order',
                  value: 'Rp ${(stats?.orderValue ?? 0).toStringAsFixed(0)}',
                ),
                _Box(
                  label: 'Effective Rate',
                  value:
                      '${((stats?.effectiveRate ?? 0) * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String label;
  final String value;
  const _Box({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
