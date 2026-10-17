import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/rest_api.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  static const Color burgundy = Color(0xFF7A1C1C);
  bool _isLoading = true;
  List<dynamic> _dailyReports = [];

  @override
  void initState() {
    super.initState();
    _fetchDailyReports();
  }

  Future<void> _fetchDailyReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${RestApi.baseUrl}/orders/daily-analytics'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _dailyReports = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<dynamic>> _fetchOrdersForDate(String date) async {
    try {
      final response = await http.get(
        Uri.parse('${RestApi.baseUrl}/orders/by-date?date=$date'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  void _showDayDetailsSheet(
      BuildContext context, String date, double totalSales) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: _fetchOrdersForDate(date),
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orders on $date',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: burgundy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Day Total: \$${totalSales.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: burgundy),
                          ),
                        )
                      else if (!snapshot.hasData || snapshot.data!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No orders found for this day.'),
                          ),
                        )
                      else
                        ...snapshot.data!.map((order) {
                          final int id = order['id'] ?? 0;
                          final status = (order['order_status'] ?? 'placed')
                              .toString()
                              .toUpperCase();
                          final total = double.tryParse(
                                  order['total']?.toString() ?? '0') ??
                              0.0;
                          final payment =
                              '${order['payment_method'] ?? 'Cash'} • ${order['payment_status'] ?? 'pending'}';
                          final pickupCode = order['pickup_code'] ?? '#AB-$id';

                          List items = [];
                          if (order['items'] is List) {
                            items = order['items'];
                          } else if (order['items'] is String) {
                            try {
                              items = jsonDecode(order['items']);
                            } catch (_) {
                              items = [];
                            }
                          }

                          final isCancelled = status == 'CANCELLED';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF8F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#AB-$id (Token: $pickupCode)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isCancelled
                                              ? Colors.red.shade700
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  payment,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                if (items.isNotEmpty)
                                  ...items.map((item) {
                                    final name = item['name'] ??
                                        item['product_name'] ??
                                        'Item';
                                    final qty = item['quantity'] ?? 1;
                                    final price = double.tryParse(
                                            item['price']?.toString() ?? '0') ??
                                        0.0;
                                    final size =
                                        item['selected_size'] ?? item['size'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$qty× $name ${size != null ? "($size)" : ""}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            '\$${(price * qty).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '\$${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: burgundy,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      appBar: AppBar(
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        title: const Text(
          'Daily Orders & Sales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: burgundy))
          : _dailyReports.isEmpty
              ? const Center(child: Text('No orders recorded yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dailyReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _dailyReports[index];
                    final date = item['order_date'] ?? '';
                    final totalOrders = item['total_orders'] ?? 0;
                    final totalSales = double.tryParse(
                            item['total_sales']?.toString() ?? '0') ??
                        0.0;
                    final completed = item['completed_count'] ?? 0;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          _showDayDetailsSheet(context, date, totalSales),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: burgundy),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$totalOrders Orders placed ($completed Completed)',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Tap to view receipt details',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.deepOrange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 14,
                                      color: Colors.deepOrange.shade700,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total Sales',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                                Text(
                                  '\$${totalSales.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: burgundy,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
