import 'package:flutter/material.dart';
import 'package:projectx/config.dart';
import 'package:projectx/views/widgets/invoice_list_item.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class InvoiceHistory extends StatefulWidget {
  const InvoiceHistory({super.key});

  @override
  State<InvoiceHistory> createState() => _InvoiceHistoryState();
}

class _InvoiceHistoryState extends State<InvoiceHistory> {
  late Future<List<Map<String, dynamic>>> _invoicesFuture;
  List<Map<String, dynamic>> _allInvoices = [];
  List<Map<String, dynamic>> _filteredInvoices = [];

  // Filter states
  String _sortOrder = 'Recent First';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _invoicesFuture = _fetchInvoices();
  }

  /// Helper to parse combined date + time into a DateTime
  DateTime _parseDateTime(Map<String, dynamic> invoice) {
    try {
      final String combined = "${invoice['date']} ${invoice['time']}";
      final format = DateFormat("yyyy-MM-dd hh:mm a");
      return format.parse(combined);
    } catch (e) {
      return DateTime(1970); // fallback
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final urlBackend = AppConfig.backendUrl;
    final url = Uri.parse("$urlBackend/api/v1/invoices");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        setState(() {
          _allInvoices = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _applyFilters();
        });
        return _allInvoices;
      } else {
        throw Exception("Failed to load invoices. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch invoices: $e");
    }
  }

  void _applyFilters() {
  List<Map<String, dynamic>> filtered = List.from(_allInvoices);

  if (_dateRange != null) {
    // Extend end date to include the whole day
    final start = DateTime(
      _dateRange!.start.year,
      _dateRange!.start.month,
      _dateRange!.start.day,
      0,
      0,
      0,
    );

    final end = DateTime(
      _dateRange!.end.year,
      _dateRange!.end.month,
      _dateRange!.end.day,
      23,
      59,
      59,
    );

    filtered = filtered.where((invoice) {
      final invoiceDate = _parseDateTime(invoice);
      return invoiceDate.isAtSameMomentAs(start) ||
             invoiceDate.isAtSameMomentAs(end) ||
             (invoiceDate.isAfter(start) && invoiceDate.isBefore(end));
    }).toList();
  }

  // Apply sorting
  if (_sortOrder == 'Recent First') {
    filtered.sort((a, b) {
      final dateA = _parseDateTime(a);
      final dateB = _parseDateTime(b);
      return dateB.compareTo(dateA);
    });
  } else {
    filtered.sort((a, b) {
      final dateA = _parseDateTime(a);
      final dateB = _parseDateTime(b);
      return dateA.compareTo(dateB);
    });
  }

  setState(() {
    _filteredInvoices = filtered;
  });
}


  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue.shade600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateRange = null;
    });
    _applyFilters();
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filters & Sort",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Sort Order Dropdown
          DropdownButtonFormField<String>(
            value: _sortOrder,
            decoration: InputDecoration(
              labelText: 'Sort Order',
              prefixIcon: Icon(
                Icons.sort_rounded,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
            items: ['Recent First', 'Older First'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _sortOrder = newValue;
                });
                _applyFilters();
              }
            },
          ),

          const SizedBox(height: 16),

          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _showDateRangePicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dateRange == null
                                    ? 'Select Date Range'
                                    : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _dateRange == null
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _clearDateFilter,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.clear_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (_dateRange != null || _allInvoices.length != _filteredInvoices.length) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Showing ${_filteredInvoices.length} of ${_allInvoices.length} invoices',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Invoice History",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.grey.shade800,
            ),
            onPressed: () {
              setState(() {
                _invoicesFuture = _fetchInvoices();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _invoicesFuture,
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Failed to load invoices",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
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
            } else if (!snapshot.hasData || _allInvoices.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Invoices Found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Invoices will appear here once you create them",
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
            }

            return Column(
              children: [
                _buildFilterSection(),
                Expanded(
                  child: _filteredInvoices.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_off_rounded,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No invoices match your filters",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Try adjusting your date range or sort order",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return InvoiceListItem(
                              invoiceNumber: invoice['invoiceNumber'] as int,
                              customerName: invoice['customerName'] as String,
                              date: invoice['date'] as String,
                              time: invoice['time'] as String,
                              grandTotal: (invoice['grandTotal'] as num).toDouble(),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
