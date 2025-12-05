import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/data/notifiers.dart';

class PdfGenerator {
  // Generates a thermal-style receipt PDF and returns it as a Uint8List.
  static Future<Uint8List> _generatePdf({
    required Map<String, dynamic> invoiceData,
    required String businessName,
    required String businessAddress,
    required String gst,
    required String fssai,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoMonoRegular();
    final boldFont = await PdfGoogleFonts.robotoMonoBold();
    final indianFormat = NumberFormat.decimalPattern("en_IN");

    // Get logo from notifier and download from network if available
    Uint8List? logoBytes;
    if (businessLogoNotifier.value.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(businessLogoNotifier.value));
        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
        }
      } catch (e) {
        // If loading fails, logoBytes remains null
        print('Failed to load logo: $e');
      }
    }

    const pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm, // Width
      double.infinity, // Height
      marginLeft: 5 * PdfPageFormat.mm,
      marginRight: 5 * PdfPageFormat.mm,
      marginTop: 5 * PdfPageFormat.mm,
      marginBottom: 5 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              pw.SizedBox(height: 10),
              // Business Logo
              if (logoBytes != null)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    width: 40,
                    height: 40,
                  ),
                ),
              if (logoBytes != null) pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  businessName,
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  businessAddress,
                  style: pw.TextStyle(font: font, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('GST: $gst', style: pw.TextStyle(font: font, fontSize: 9))),
              pw.Center(child: pw.Text('FSSAI: $fssai', style: pw.TextStyle(font: font, fontSize: 9))),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Invoice: #INV-${invoiceData["invoiceNumber"]}',
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Customer: ${invoiceData["customerName"] ?? "-"}',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Date: ${invoiceData["date"]} ${invoiceData["time"]}',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
              pw.Text(
                'Table No: ${invoiceData["tableNumber"] ?? "-"}',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // --- Items Section ---
              _buildItemsTable(font, boldFont, indianFormat, invoiceData),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // --- Totals Section ---
              _buildTotalsSection(font, boldFont, indianFormat, invoiceData),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              pw.SizedBox(height: 15),

              // --- Footer Section ---
              pw.Center(
                child: pw.Text(
                  'Thank you for your order!',
                  style: pw.TextStyle(font: font, fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ),
              pw.SizedBox(height: 5),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Helper to build a text-based table for items
  static pw.Widget _buildItemsTable(
    pw.Font font,
    pw.Font boldFont,
    NumberFormat indianFormat,
    Map<String, dynamic> invoiceData,
  ) {
    const tableHeaders = ['Item', 'Qty', 'Price', 'Total'];

    return pw.TableHelper.fromTextArray(
      headers: tableHeaders,
      data: (invoiceData['items'] as List<dynamic>).map((item) {
        final price = item['price'] ?? 0;
        final quantity = item['quantity'] ?? 0;
        final subtotal = price * quantity;
        return [
          item['itemName'] ?? item['name'] ?? '',
          quantity.toString(),
          indianFormat.format(price),
          indianFormat.format(subtotal),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
      cellStyle: pw.TextStyle(font: font, fontSize: 9),
      headerAlignment: pw.Alignment.center,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2.5),
      },
      border: null,
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 0),
    );
  }

  /// Totals Section with Subtotal, SGST, CGST, Grand Total
  static pw.Widget _buildTotalsSection(
    pw.Font font,
    pw.Font boldFont,
    NumberFormat indianFormat,
    Map<String, dynamic> invoiceData,
  ) {
    final subtotal = invoiceData["subTotal"] ?? 0;
    final sgst = invoiceData["sgst"] ?? 0;
    final cgst = invoiceData["cgst"] ?? 0;
    final grandTotal = invoiceData["grandTotal"] ?? subtotal + sgst + cgst;

    return pw.Column(
      children: [
        _row("Subtotal", "Rs ${indianFormat.format(subtotal)}", font, boldFont),
        _row("SGST (${invoiceData["sgstPercent"] ?? 0}%)", "Rs ${indianFormat.format(sgst)}", font, boldFont),
        _row("CGST (${invoiceData["cgstPercent"] ?? 0}%)", "Rs ${indianFormat.format(cgst)}", font, boldFont),
        pw.Divider(),
        _row("Grand Total", "Rs ${indianFormat.format(grandTotal)}", font, boldFont, isBold: true),
      ],
    );
  }

  static pw.Widget _row(String label, String value, pw.Font font, pw.Font boldFont, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: isBold ? boldFont : font, fontSize: 9)),
        pw.Text(value, style: pw.TextStyle(font: isBold ? boldFont : font, fontSize: 9)),
      ],
    );
  }

  // --- PUBLIC FUNCTIONS ---
  static Future<void> generateAndShareInvoice({
    required Map<String, dynamic> invoiceData,
    required String businessName,
    required String businessAddress,
    required String gst,
    required String fssai,
  }) async {
    final pdfBytes = await _generatePdf(
      invoiceData: invoiceData,
      businessName: businessName,
      businessAddress: businessAddress,
      gst: gst,
      fssai: fssai,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'receipt-${invoiceData["invoiceNumber"]}.pdf',
    );
  }

  static Future<void> generateAndPrintInvoice({
    required Map<String, dynamic> invoiceData,
    required String businessName,
    required String businessAddress,
    required String gst,
    required String fssai,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) => _generatePdf(
        invoiceData: invoiceData,
        businessName: businessName,
        businessAddress: businessAddress,
        gst: gst,
        fssai: fssai,
      ),
    );
  }
}