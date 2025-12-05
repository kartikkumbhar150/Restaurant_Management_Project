import 'package:flutter/material.dart';

class SingleItem extends StatelessWidget {
  final String itemName;
  final int price;
  final VoidCallback? onTap;
  final IconData leadingIcon;

  const SingleItem({
    super.key,
    required this.itemName,
    required this.price,
    this.onTap,
    this.leadingIcon = Icons.fastfood, // default icon
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.blue.shade500.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 22,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    itemName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "₹$price",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}