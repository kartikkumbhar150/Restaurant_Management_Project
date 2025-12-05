import 'package:flutter/material.dart';

class TableBox extends StatelessWidget {
  final int id;
  final bool occupied;
  final VoidCallback? onTap; 

  const TableBox({
    super.key,
    required this.id,
    required this.occupied,
    this.onTap, 
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //  Use the onTap callback passed from the parent page.
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: occupied ? Colors.red.shade400 : Colors.green.shade400,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          "$id",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}