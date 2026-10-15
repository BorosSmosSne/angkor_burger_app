import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/rest_api.dart';

class StaffKitchenScreen extends StatefulWidget {
  final bool showAppBar;

  const StaffKitchenScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<StaffKitchenScreen> createState() => _StaffKitchenScreenState();
}

class _StaffKitchenScreenState extends State<StaffKitchenScreen> {
  static const Color burgundy = Color(0xFF7A1C1C);
  List<dynamic> _kitchenOrders = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // ✅ FIX 2: Fetch orders immediately on mount so you never have to click reload!
    _fetchKitchenOrders(silent: false);

    // Poll every 4 seconds to keep orders updated automatically
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchKitchenOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchKitchenOrders({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('${RestApi.baseUrl}/kitchen/orders'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List orders = decoded is List ? decoded : (decoded['data'] ?? []);

        if (mounted) {
          setState(() {
            _kitchenOrders = orders;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching kitchen orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('${RestApi.baseUrl}/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        _fetchKitchenOrders(silent: true);
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  bool _isCookingOverdue(Map<String, dynamic> order) {
    final status = (order['order_status'] ?? 'placed').toString().toLowerCase();
    if (status == 'ready_to_pickup' ||
        status == 'completed' ||
        status == 'cancelled') {
      return false;
    }
    final createdStr = order['created_at']?.toString();
    if (createdStr == null) return false;
    final created = DateTime.tryParse(createdStr);
    if (created == null) return false;
    return DateTime.now().difference(created).inMinutes > 15;
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      color: burgundy,
      onRefresh: () => _fetchKitchenOrders(silent: false),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: burgundy))
          : _kitchenOrders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 220),
                    Center(
                      child: Text(
                        'No active kitchen orders.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _kitchenOrders.length,
                  itemBuilder: (context, index) {
                    final order =
                        Map<String, dynamic>.from(_kitchenOrders[index]);
                    return _buildKitchenCard(order);
                  },
                ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      appBar: AppBar(
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        title: const Text(
          'Kitchen & Orders Display',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchKitchenOrders(silent: false),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildKitchenCard(Map<String, dynamic> order) {
    final status = (order['order_status'] ?? 'placed').toString().toLowerCase();
    final pickupTime = order['pickup_time_slot'] ?? 'ASAP';
    final isOverdue = _isCookingOverdue(order);
    final int id = order['id'] is int
        ? order['id']
        : int.tryParse(order['id'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFFF1F1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? Colors.red
              : (status == 'ready_to_pickup'
                  ? Colors.green
                  : const Color(0xFFE5E7EB)),
          width: isOverdue || status == 'ready_to_pickup' ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text('OVERDUE ORDER',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#AB-$id',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pickup: $pickupTime',
                  style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Token: ${order['pickup_code'] ?? "#AB-$id"} | Method: ${order['payment_method'] ?? "ABA"}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${status.toUpperCase().replaceAll('_', ' ')}',
            style: TextStyle(
              color: status == 'ready_to_pickup'
                  ? Colors.green
                  : (status == 'cooking' ? Colors.orange.shade800 : burgundy),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Divider(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (status == 'completed' || status == 'cancelled')
                      ? null
                      : () => _updateOrderStatus(id, 'cancelled'),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        status == 'cooking' ? Colors.grey : burgundy,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: status == 'placed'
                      ? () => _updateOrderStatus(id, 'cooking')
                      : null,
                  label: Text(
                    status == 'cooking' ? 'Preparing...' : 'Accept',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined,
                      size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (status == 'cooking' ||
                          status == 'accepted' ||
                          status == 'placed')
                      ? () => _updateOrderStatus(id, 'ready_to_pickup')
                      : null,
                  label: const Text(
                    'Ready for Pick Up',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon:
                      const Icon(Icons.done_all, size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222222),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: status == 'ready_to_pickup'
                      ? () => _updateOrderStatus(id, 'completed')
                      : null,
                  label: const Text(
                    'Finish',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
