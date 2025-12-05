import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String valuePrefix;
  final String valueSuffix;

  const SalesCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    this.valuePrefix = '₹',
    this.valueSuffix = '/-',
  }) : super(key: key);

  @override
  State<SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<SalesCard> {
  double? _value;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadCachedValue();
    _fetchTodaySales();
  }

  Future<void> _loadCachedValue() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getDouble('cached_today_sales');
    if (cached != null) {
      setState(() {
        _value = cached;
      });
    }
  }

  Future<void> _fetchTodaySales() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      debugPrint("No auth token found, skipping API call");
      return;
    }

    setState(() {
      _isFetching = true;
    });

    try {
      final url = AppConfig.backendUrl;
      final response = await http.get(
        Uri.parse("$url/api/v1/sales/today"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final double? newValue = double.tryParse(response.body.trim());
        if (newValue != null) {
          setState(() {
            _value = newValue;
            _isFetching = false;
          });
          await prefs.setDouble('cached_today_sales', newValue);
        }
      } else {
        debugPrint("API error: ${response.statusCode} - ${response.body}");
        setState(() {
          _isFetching = false;
        });
      }
    } catch (e) {
      debugPrint("Exception while fetching sales: $e");
      setState(() {
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 👈 tap to refresh
      onTap: _fetchTodaySales,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    _value == null
                        ? Text(
                            "No data",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                "${widget.valuePrefix}${_value!.toStringAsFixed(2)}${widget.valueSuffix}",
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (_isFetching) ...[
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: widget.color,
                                  ),
                                ),
                              ]
                            ],
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
