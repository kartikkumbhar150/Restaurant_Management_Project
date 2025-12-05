import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/data/notifiers.dart';
import 'dart:convert';
import 'package:projectx/services/invoice_pdf_service.dart';
import 'package:projectx/views/widget_tree.dart';
import 'package:intl/intl.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoicePage extends StatefulWidget {
  final int invoiceId;

  const InvoicePage({required this.invoiceId, super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late Future<Map<String, dynamic>> _invoiceFuture;

  @override
  void initState() {
    super.initState();
    _invoiceFuture = _fetchInvoiceDetails();
  }

  Future<Map<String, dynamic>> _fetchInvoiceDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final urlBackend = AppConfig.backendUrl;
    final url = Uri.parse(
      "$urlBackend/api/v1/invoices/${widget.invoiceId}",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'];
      } else {
        throw Exception(
          'Failed to load invoice. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Invoice Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const WidgetTree()),
              (Route<dynamic> route) => false,
            );
          },
          icon: Icon(
            Icons.home_rounded,
            color: Colors.grey.shade800,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade600,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Error loading invoice",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final invoiceDataFromApi = snapshot.data!;

            final String businessName =
                invoiceDataFromApi['businessName'] ?? 'N/A';
            final String businessAddress =
                invoiceDataFromApi['businessAddress'] ?? 'N/A';
            final String gst = invoiceDataFromApi['businessGstNumber'] ?? 'N/A';
            final String fssai = invoiceDataFromApi['businessFssai'] ?? 'N/A';

            // Adapt API response into UI structure
            final Map<String, dynamic> invoiceDataForUi = {
              "invoiceNumber": invoiceDataFromApi['invoiceNumber'],
              "date": invoiceDataFromApi['date'],
              "time": invoiceDataFromApi['time'],
              "customerName": invoiceDataFromApi['customerName'],
              "tableNumber": invoiceDataFromApi['tableNumber'],
              "items": (invoiceDataFromApi['items'] as List).map((item) {
                return {
                  "itemName": item['name'] ?? '',
                  "price": (item['price'] ?? 0).toDouble(),
                  "quantity": item['quantity'] ?? 0,
                  "subtotal": (item['total'] ?? 0).toDouble(),
                };
              }).toList(),
              "subTotal": (invoiceDataFromApi['subTotal'] ?? 0).toDouble(),
              "sgst": (invoiceDataFromApi['sgst'] ?? 0).toDouble(),
              "cgst": (invoiceDataFromApi['cgst'] ?? 0).toDouble(),
              "sgstPercent": (invoiceDataFromApi['sgstPercent'] ?? 0)
                  .toDouble(),
              "cgstPercent": (invoiceDataFromApi['cgstPercent'] ?? 0)
                  .toDouble(),
              "grandTotal": (invoiceDataFromApi['grandTotal'] ?? 0).toDouble(),
            };

            final date = invoiceDataForUi["date"];
            final time = invoiceDataForUi["time"];
            final indianFormat = NumberFormat.decimalPattern("en_IN");
            final num total = invoiceDataFromApi['subTotal'];
            final num sgstPercent = invoiceDataFromApi['sgstPercent'];
            final sgst = indianFormat.format(invoiceDataFromApi['sgst']);
            final num cgstPercent = invoiceDataFromApi['cgstPercent'];
            final cgst = indianFormat.format(invoiceDataFromApi['cgst']);
            final formattedTotal = indianFormat.format(total);
            final grandTotal = indianFormat.format(
              invoiceDataFromApi['grandTotal'],
            );
            final invoiceId = invoiceDataForUi["invoiceNumber"];
            final tableNumber = invoiceDataFromApi['tableNumber'];

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Business Header
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.blue.shade800,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    businessName,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    businessAddress,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "GST: $gst",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "FSSAI: $fssai",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // Invoice Info
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade600,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "INV-$invoiceId",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        "$date • $time",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Customer",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "${invoiceDataForUi['customerName']}",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Table",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "T$tableNumber",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // Items Header
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 24, child: Text(
                                    'Sr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  )),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Item',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  SizedBox(width: 40, child: Text(
                                    'Qty',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  )),
                                  SizedBox(width: 16),
                                  SizedBox(width: 60, child: Text(
                                    'Price',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                  )),
                                  SizedBox(width: 16),
                                  SizedBox(width: 70, child: Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                  )),
                                ],
                              ),
                            ),

                            // Items List
                            ...invoiceDataForUi["items"]
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key + 1;
                                  final item = entry.value;
                                  final itemName = item["itemName"];
                                  final quantity = item["quantity"];
                                  final price = item["price"];
                                  final subtotal = item["subtotal"];
                                  final formattedPrice = indianFormat.format(price);
                                  final formattedSubtotal = indianFormat.format(subtotal);

                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 24, child: Text(
                                          '$index',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        )),
                                        SizedBox(width: 16),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '$itemName',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        SizedBox(width: 40, child: Text(
                                          '$quantity',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                        )),
                                        SizedBox(width: 16),
                                        SizedBox(width: 60, child: Text(
                                          '₹$formattedPrice',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.right,
                                        )),
                                        SizedBox(width: 16),
                                        SizedBox(width: 70, child: Text(
                                          '₹$formattedSubtotal',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.right,
                                        )),
                                      ],
                                    ),
                                  );
                                }),

                            SizedBox(height: 24),

                            // Totals Section
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildTotalRow("Subtotal", "₹$formattedTotal", false),
                                  SizedBox(height: 8),
                                  _buildTotalRow("SGST ($sgstPercent%)", "₹$sgst", false),
                                  SizedBox(height: 8),
                                  _buildTotalRow("CGST ($cgstPercent%)", "₹$cgst", false),
                                  SizedBox(height: 12),
                                  Container(
                                    height: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  SizedBox(height: 12),
                                  _buildTotalRow("Grand Total", "₹$grandTotal", true),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Thank you for your order!",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Action Buttons
                      Column(
                        children: [
                          ButtonTile(
                            label: "Print Invoice",
                            onTap: () {
                              PdfGenerator.generateAndPrintInvoice(
                                invoiceData: invoiceDataForUi,
                                businessName: businessName,
                                businessAddress: businessAddress,
                                gst: gst,
                                fssai: fssai,
                              );
                            },
                            icon: Icons.print_rounded,
                            bgColor: Colors.blue.shade500,
                            textColor: Colors.white,
                          ),
                          SizedBox(height: 12),
                          ButtonTile(
                            label: "Download Invoice",
                            onTap: () {
                              PdfGenerator.generateAndShareInvoice(
                                invoiceData: invoiceDataForUi,
                                businessName: businessName,
                                businessAddress: businessAddress,
                                gst: gst,
                                fssai: fssai,
                              );
                            },
                            icon: Icons.download_rounded,
                            bgColor: Colors.white,
                            textColor: Colors.grey.shade800,
                            showShadow: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }
          return Center(
            child: Container(
              padding: EdgeInsets.all(32),
              child: Text(
                "No invoice data found.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalRow(String label, String amount, bool isGrandTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 16 : 14,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
            color: isGrandTotal ? Colors.grey.shade800 : Colors.grey.shade600,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isGrandTotal ? Colors.blue.shade600 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}