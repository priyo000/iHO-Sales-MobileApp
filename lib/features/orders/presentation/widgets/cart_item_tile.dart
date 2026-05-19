import 'package:flutter/material.dart';
import '../../data/models/cart_item_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(int) onQtyChanged;
  final VoidCallback onRemove;
  final Function(String productId)? onDiskonRecalculate;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onRemove,
    this.onDiskonRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.product.namaProduk),
        subtitle: Text('Rp ${item.price.toStringAsFixed(0)}${item.selectedUnitName != null ? ' / ${item.selectedUnitName}' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onRemove,
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (item.quantity > 1) {
                  onQtyChanged(item.quantity - 1);
                  onDiskonRecalculate?.call(item.product.id);
                }
              },
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                onQtyChanged(item.quantity + 1);
                onDiskonRecalculate?.call(item.product.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
