import 'package:flutter/material.dart';
import 'package:projectx/views/widgets/order_item_tile.dart';

class OrderListSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final void Function(int index)? onAdd;
  final void Function(int index)? onRemove;

  const OrderListSection({
    super.key,
    required this.title,
    required this.items,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade500,
                Colors.blue.shade600,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade500.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: OrderItemTile(
              name: item['name'],
              quantity: item['quantity'],
              price: item['price'],
            ),
          );
        }),
      ],
    );
  }
}