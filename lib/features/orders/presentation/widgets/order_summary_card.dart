import 'package:flutter/material.dart';

class OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double diskon;
  final double total;
  const OrderSummaryCard({super.key, required this.subtotal, required this.diskon, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('Rp ${subtotal.toStringAsFixed(0)}')]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(color: Colors.green)), Text('-Rp ${diskon.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green))]),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          ],
        ),
      ),
    );
  }
}
