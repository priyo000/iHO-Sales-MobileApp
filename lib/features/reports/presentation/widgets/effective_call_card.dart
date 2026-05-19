import 'package:flutter/material.dart';
import '../controllers/reports_controller.dart';

class EffectiveCallCard extends StatelessWidget {
  final ReportStats? stats;
  const EffectiveCallCard({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final rate = (stats?.effectiveRate ?? 0) * 100;
    Color c = rate >= 80 ? Colors.green : rate >= 50 ? Colors.orange : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Effective Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: stats?.effectiveRate ?? 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(c),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 16),
              Text('${rate.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 18)),
            ]),
            const SizedBox(height: 8),
            Text('${stats?.effectiveCall ?? 0} dari ${stats?.totalVisit ?? 0} kunjungan menghasilkan order', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
