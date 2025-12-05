import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class KotPage extends StatefulWidget {
  const KotPage({super.key});

  @override
  State<KotPage> createState() => _KotPageState();
}

class _KotPageState extends State<KotPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<dynamic> _pendingOrders = [];
  List<dynamic> _completedOrders = [];
  String? _userRole;
  late TabController _tabController;
  StreamSubscription? _streamSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Set<int> _seenOrderIds = {};
  int _previousPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _getUserRole();
    await _fetchPendingOrders();
    await _fetchCompletedOrders();
    _startOrderStream();
  }

  /// Get user role from SharedPreferences
  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
    });
  }

  /// Play notification sound when new order arrives
  Future<void> _playNotificationSound() async {
    try {
      // Using a simple beep sound - you can replace with your own notification sound
      await _audioPlayer.play(AssetSource('notification.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
      // Fallback: just continue without sound
    }
  }

  /// Start listening to live order stream using SSE
  void _startOrderStream() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final client = http.Client();
      final url = AppConfig.backendUrl;
      final request = http.Request(
        'GET',
        Uri.parse('$url/api/v1/kot/stream'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);
      
      print('Connected to SSE stream');
      
      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        print('SSE Line received: $line'); // Debug log
        
        if (line.isNotEmpty && line.startsWith('data: ')) {
          try {
            final jsonData = line.substring(6); // Remove 'data: ' prefix
            print('Parsing JSON: $jsonData'); // Debug log
            final data = jsonDecode(jsonData);
            
            // Handle array response
            if (data is List) {
              print('Received ${data.length} items from stream'); // Debug log
              _handleNewOrders(data);
            }
          } catch (e) {
            print('Error parsing stream data: $e');
          }
        }
      }, onError: (error) {
        print('Stream error: $error');
        // Attempt to reconnect after a delay
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            print('Attempting to reconnect to stream...');
            _startOrderStream();
          }
        });
      }, onDone: () {
        print('Stream connection closed');
        // Reconnect when stream closes
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            print('Reconnecting to stream...');
            _startOrderStream();
          }
        });
      });
    } catch (e) {
      print('Error starting stream: $e');
      // Retry after delay
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          _startOrderStream();
        }
      });
    }
  }

  /// Handle new orders from stream
  void _handleNewOrders(List<dynamic> newOrders) {
    if (!mounted) return;

    // Group by orderId
    Map<int, List<dynamic>> groupedOrders = {};
    for (var item in newOrders) {
      if (item['completed'] == false) {
        int orderId = item['orderId'];
        if (!groupedOrders.containsKey(orderId)) {
          groupedOrders[orderId] = [];
        }
        groupedOrders[orderId]!.add(item);
      }
    }

    // Check for new orders
    bool hasNewOrders = false;
    for (var orderId in groupedOrders.keys) {
      if (!_seenOrderIds.contains(orderId)) {
        _seenOrderIds.add(orderId);
        hasNewOrders = true;
      }
    }

    if (hasNewOrders) {
      _playNotificationSound();
      _fetchPendingOrders(); // Refresh to get the latest data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New order received!'),
            backgroundColor: Colors.blue.shade500,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
          ),
        );
      }
    }
  }

  /// Fetch pending orders
  Future<void> _fetchPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/kot/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        
        // Group items by orderId and tableNumber
        Map<String, List<dynamic>> groupedOrders = {};
        for (var item in data) {
          if (item['completed'] == false) {
            String key = '${item['orderId']}_${item['tableNumber']}';
            if (!groupedOrders.containsKey(key)) {
              groupedOrders[key] = [];
            }
            groupedOrders[key]!.add(item);
            
            // Track seen order IDs
            if (item['orderId'] != null) {
              _seenOrderIds.add(item['orderId']);
            }
          }
        }

        if (mounted) {
          setState(() {
            _pendingOrders = groupedOrders.entries.map((entry) {
              return {
                'orderId': entry.value[0]['orderId'],
                'tableNumber': entry.value[0]['tableNumber'],
                'items': entry.value,
              };
            }).toList();
            
            // Sort by orderId descending (newest first)
            _pendingOrders.sort((a, b) => b['orderId'].compareTo(a['orderId']));
            
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pending orders: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  /// Fetch completed orders
  Future<void> _fetchCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.get(
        Uri.parse('$url/api/v1/kot/completed'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        
        // Group items by orderId and tableNumber
        Map<String, List<dynamic>> groupedOrders = {};
        for (var item in data) {
          if (item['completed'] == true) {
            String key = '${item['orderId']}_${item['tableNumber']}';
            if (!groupedOrders.containsKey(key)) {
              groupedOrders[key] = [];
            }
            groupedOrders[key]!.add(item);
          }
        }

        if (mounted) {
          setState(() {
            _completedOrders = groupedOrders.entries.map((entry) {
              return {
                'orderId': entry.value[0]['orderId'],
                'tableNumber': entry.value[0]['tableNumber'],
                'items': entry.value,
              };
            }).toList();
            
            // Sort by orderId descending (newest first)
            _completedOrders.sort((a, b) => b['orderId'].compareTo(a['orderId']));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading completed orders: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  /// Show confirmation dialog before marking order as complete
  Future<void> _confirmCompleteOrder(int tableNumber, int orderId) async {
    if (_userRole != 'CHEF') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only chefs can complete orders'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.blue.shade600,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Complete Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark this order as complete?',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Table $tableNumber',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '• Order #$orderId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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
                color: Colors.blue.shade500,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => Navigator.pop(context, true),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      'COMPLETE',
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

    if (confirmed == true) {
      await _markOrderComplete(tableNumber);
    }
  }

  /// Mark order as complete
  Future<void> _markOrderComplete(int tableNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      final url = AppConfig.backendUrl;
      final res = await http.post(
        Uri.parse('$url/api/v1/kot/mark-complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tableNumber': tableNumber}),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as complete!'),
            backgroundColor: Colors.green.shade500,
          ),
        );
        
        // Refresh both lists
        await _fetchPendingOrders();
        await _fetchCompletedOrders();
      } else {
        final json = jsonDecode(res.body);
        throw Exception(json['message'] ?? 'Failed to complete order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  /// Refresh all data
  Future<void> _refreshData() async {
    await Future.wait([
      _fetchPendingOrders(),
      _fetchCompletedOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Kitchen Orders',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pending'),
                  if (_pendingOrders.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingOrders.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade600,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_pendingOrders, isPending: true),
                _buildOrderList(_completedOrders, isPending: false),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.blue.shade600,
        child: ListView(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPending ? Icons.check_circle_outline : Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      isPending ? 'No pending orders' : 'No completed orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      isPending
                          ? 'New orders will appear here'
                          : 'Completed orders will show here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.blue.shade600,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, isPending: isPending);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isPending}) {
    final tableNumber = order['tableNumber'] ?? 'N/A';
    final items = order['items'] as List<dynamic>? ?? [];
    final orderNumber = order['orderId'] ?? '';
    final isChef = _userRole == 'CHEF';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? Colors.blue.shade100 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: (isPending && isChef) 
              ? () => _confirmCompleteOrder(tableNumber, orderNumber)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPending
                        ? [Colors.blue.shade500, Colors.blue.shade600]
                        : [Colors.grey.shade600, Colors.grey.shade700],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Table $tableNumber',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (orderNumber.toString().isNotEmpty)
                              Text(
                                'Order #$orderNumber',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPending ? 'PENDING' : 'COMPLETED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isPending && isChef) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.touch_app,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Items List
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...items.map((item) {
                      final name = item['itemName'] ?? 'Unknown Item';
                      final quantity = item['quantity'] ?? 1;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Center(
                                child: Text(
                                  '$quantity',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Footer hint for chefs
              if (isPending && isChef)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap to mark as complete',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}