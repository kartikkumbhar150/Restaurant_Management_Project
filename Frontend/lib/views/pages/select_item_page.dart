import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'dart:convert';

import 'package:projectx/views/widgets/single_item.dart'; // Assuming you have this widget
import 'package:shared_preferences/shared_preferences.dart';

class SelectItemPage extends StatefulWidget {
  final int tableNumber;
  final int prevItems;
  const SelectItemPage({super.key, required this.tableNumber, required this.prevItems});

  @override
  State<SelectItemPage> createState() => _SelectItemPageState();
}

class _SelectItemPageState extends State<SelectItemPage> {
  bool isLoading = true;
  List<dynamic> _allItems = []; // To store all items fetched from the API
  List<Map<String, dynamic>> _filteredGroupedItems = []; // To display in the UI
  List<String> _categories = ['All Categories']; // For the filter dropdown
  
  String? _selectedCategory = 'All Categories';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _searchController.addListener(_filterItems); // Add listener to react to search text changes
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up the controller
    super.dispose();
  }

  /// Adds a selected item to an order.
  /// Creates a new order (POST) if prevItems is 0, otherwise updates an existing one (PUT).
  Future<void> _addItem(int productId, int quantity) async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final urlBackend = AppConfig.backendUrl;
    final url = widget.prevItems == 0
        ? Uri.parse('$urlBackend/api/v1/orders')
        : Uri.parse('$urlBackend/api/v1/orders/${widget.tableNumber}');

    final body = jsonEncode({
      "tableNumber": widget.tableNumber,
      "items": [
        {"productId": productId, "quantity": quantity}
      ]
    });

    try {
      final res = widget.prevItems == 0
          ? await http.post(url, headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            }, body: body)
          : await http.put(url, headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            }, body: body);

      final json = jsonDecode(res.body);
      if ((res.statusCode == 201 || res.statusCode == 200) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Item added successfully!"),
            backgroundColor: Colors.blue.shade500,
          ),
        );
      } else {
        throw Exception(json['message'] ?? 'Failed to add item');
      }
    } catch (e) {
      // Rethrow the exception to be caught in the modal's try-catch block
      rethrow;
    }
  }

  /// Fetches items from the API and sets up the initial state.
  Future<void> _fetchItems() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final json = jsonDecode(res.body);
      if (json['status'] == 'success' && mounted) {
        final List<dynamic> data = json['data'];
        _allItems = data;
        
        // Extract unique categories for the filter dropdown
        final uniqueCategories = data.map((item) => item['category'] as String?).toSet();
        _categories = ['All Categories', ...uniqueCategories.whereType<String>()];
        
        _filterItems(); // Apply initial filtering (which shows all items)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load items: ${json['message']}"),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading items: $e"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Filters and groups items based on search query and selected category.
  void _filterItems() {
    List<dynamic> filteredList = List.from(_allItems);

    // 1. Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All Categories') {
      filteredList = filteredList.where((item) => item['category'] == _selectedCategory).toList();
    }

    // 2. Filter by search query
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        final itemName = item['name']?.toString().toLowerCase() ?? '';
        return itemName.contains(searchQuery);
      }).toList();
    }

    _groupItemsByCategory(filteredList);
  }

  /// Groups a list of items by category and updates the state.
  void _groupItemsByCategory(List<dynamic> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in items) {
      final category = item['category'] ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      // Ensure item is of the correct type before adding
      if (item is Map<String, dynamic>) {
        grouped[category]!.add(item);
      }
    }

    if(mounted) {
      setState(() {
        _filteredGroupedItems = grouped.entries.map((entry) {
          return {
            'category': entry.key,
            'items': entry.value,
          };
        }).toList();
      });
    }
  }

  /// Shows a dialog with a counter to select the quantity for an item.
  Future<void> _showQuantityModal(Map<String, dynamic> item) async {
    int quantity = 1; // Initial quantity

    // Using a separate variable to track loading state within the dialog
    bool isAddingItem = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage the state of the counter within the dialog
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              title: Text(
                'Select Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "₹${item['price'].toString()}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decrement Button
                        Container(
                          decoration: BoxDecoration(
                            color: quantity > 1 ? Colors.blue.shade500 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: quantity > 1 ? () => setState(() => quantity--) : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: quantity > 1 ? Colors.white : Colors.grey.shade500,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Quantity Display
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(
                            '$quantity',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        // Increment Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => setState(() => quantity++),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isAddingItem ? Colors.grey.shade400 : Colors.blue.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: isAddingItem ? null : () async {
                        setState(() => isAddingItem = true);
                        try {
                          await _addItem(item['id'] as int, quantity);
                          if (mounted) Navigator.pop(context, {'item': item, 'quantity': quantity});
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red.shade400,
                              ),
                            );
                          }
                        } finally {
                           if (mounted) {
                             setState(() => isAddingItem = false);
                           }
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: isAddingItem 
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'ADD TO ORDER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // After the dialog closes, you can handle the result.
    if (result != null && mounted) {
      print('Item selected: ${result['item']['name']}, Quantity: ${result['quantity']}');
      Navigator.pop(context, true); // This sends 'true' back to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Select Item',
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
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.blue.shade600,
                ),
              )
            : Column(
                children: [
                  _buildControls(), // Search and Filter UI
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchItems,
                      color: Colors.blue.shade600,
                      child: _filteredGroupedItems.isEmpty
                          ? Center(
                              child: Container(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No items found",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Try adjusting your search or filter",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(24),
                              itemCount: _filteredGroupedItems.length,
                              itemBuilder: (context, index) {
                                final categoryGroup = _filteredGroupedItems[index];
                                final categoryName = categoryGroup['category'];
                                final items = categoryGroup['items'] as List<Map<String, dynamic>>;

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
                                        categoryName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    ...items.map((item) => Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: SingleItem(
                                            itemName: item["name"],
                                            price: item["price"],
                                            onTap: () => _showQuantityModal(item),
                                          ),
                                    )),
                                    SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Builds the search bar and category filter dropdown.
  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Find Items",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for items...',
              prefixIcon: Icon(
                Icons.search_rounded,
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          // Category Filter Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Filter by category',
              prefixIcon: Icon(
                Icons.category_rounded,
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
              _filterItems(); // Re-filter the list when a new category is selected
            },
          ),
        ],
      ),
    );
  }
}