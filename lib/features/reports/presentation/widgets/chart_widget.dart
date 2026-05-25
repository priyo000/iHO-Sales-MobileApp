import 'package:flutter/material.dart';
import '../controllers/reports_controller.dart';

class ChartWidget extends StatelessWidget {
  final List<ChartData> data;
  const ChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tidak ada data', style: TextStyle(color: Colors.grey)))));
    }
    final max = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grafik 5 Bulan Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(d.value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
                        const SizedBox(height: 4),
                        Container(height: (d.value / max * 150).clamp(4.0, 150.0), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 4),
                        Text(d.label, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
