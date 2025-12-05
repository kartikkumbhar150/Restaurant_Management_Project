import 'package:flutter/material.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/pages/select_table_page.dart';
import 'package:projectx/views/pages/invoice_history.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:projectx/views/widgets/sales_card.dart';
import 'package:projectx/views/widgets/sales_graph_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // ---------------- Add Order Button ----------------
                ButtonTile(
                  label: "Add Order",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelectTablePage()),
                    );
                  },
                  icon: Icons.add_shopping_cart_rounded,
                  bgColor: Colors.blue.shade500,
                  textColor: Colors.white,
                ),

                SizedBox(height: 12),

                // ---------------- Invoice History Button ----------------
                ButtonTile(
                  label: "Invoice History",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceHistory(),
                      ),
                    );
                  },
                  icon: Icons.history_rounded,
                  bgColor: Colors.white,
                  textColor: Colors.grey.shade800,
                  showShadow: true,
                ),

                SizedBox(height: 32),

                // ---------------- Show only if ADMIN ----------------
                ValueListenableBuilder(
                  valueListenable: roleNotifier,
                  builder: (context, role, _) {
                    if (role != "ADMIN") {
                      return SizedBox.shrink(); // Hide if not admin
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Performance",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Today’s Sales
                        SalesCard(
                          title: "Today's Sales",
                          icon: Icons.trending_up_rounded,
                          color: Colors.blue.shade600,
                        ),

                        SizedBox(height: 16),

                        // Last 7 Days Sales
                        SalesCard(
                          title: "Last 7 Days Sales",
                          icon: Icons.bar_chart_rounded,
                          color: Colors.green.shade600,
                        ),

                        SizedBox(height: 24),

                        // Graph Widget
                        SalesGraphWidget(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
