import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catalog_page.dart';

class OrderFlowPage extends ConsumerWidget {
  final int? customerId;
  const OrderFlowPage({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Step(label: 'Katalog', step: 0),
                _Step(label: 'Keranjang', step: 1),
                _Step(label: 'Review', step: 2),
              ],
            ),
          ),
          Expanded(child: CatalogPage(customerId: customerId)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final int step;
  const _Step({required this.label, required this.step});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
