import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:angkor_burger_app/services/rest_api.dart';

class StaffKitchenScreen extends StatefulWidget {
  const StaffKitchenScreen();

  @override
  State<StaffKitchenScreen> createState() => _StaffKitchenScreenState();
}

class _StaffKitchenScreenState extends State<StaffKitchenScreen> {
  static const Color burgundy = Color(0xFF7A1C1C);
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<dynamic> _kitchenOrders = [];
  final Set<int> _seenOrderIds = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchKitchenOrders();
    _refreshTimer = Timer.periodic(
        const Duration(seconds: 4), (_) => _fetchKitchenOrders(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playChime() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/order_bell.mp3'));
    } catch (_) {}
  }

  Future<void> _fetchKitchenOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${RestApi.baseUrl}/kitchen/orders'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List orders = decoded['data'] ?? [];

        // Check if a brand-new placed order arrived
        for (final o in orders) {
          final id = o['id'] as int;
          if (o['order_status'] == 'placed' && !_seenOrderIds.contains(id)) {
            _playChime();
            break;
          }
        }

        _seenOrderIds.addAll(orders.map<int>((e) => e['id'] as int));

        if (mounted) {
          setState(() {
            _kitchenOrders = orders;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _isLoading = false);
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
      } else {
        final body = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(body['message'] ?? 'Failed to update order')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  bool _isCookingOverdue(Map<String, dynamic> order) {
    if (order['order_status'] != 'cooking') return false;
    final createdAtStr = order['created_at'];
    if (createdAtStr == null) return false;
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return false;

    final slot = order['pickup_time_slot'] ?? '15';
    final slotMinutes =
        int.tryParse(RegExp(r'\d+').firstMatch(slot)?.group(0) ?? '15') ?? 15;
    return DateTime.now().difference(createdAt).inMinutes > (slotMinutes + 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Kitchen & Orders Display',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: burgundy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _fetchKitchenOrders(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: burgundy))
          : _kitchenOrders.isEmpty
              ? const Center(child: Text('No active kitchen orders.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _kitchenOrders.length,
                  itemBuilder: (context, index) =>
                      _buildKitchenCard(_kitchenOrders[index]),
                ),
    );
  }

  // Widget _buildKitchenCard(Map<String, dynamic> order) {
  //   final status = order['order_status'] ?? 'placed';
  //   final pickupTime = order['pickup_time_slot'] ?? 'ASAP';
  //   final isOverdue = _isCookingOverdue(order);
  //   final int id = order['id'];

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: isOverdue ? const Color(0xFFFFF1F1) : Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: isOverdue
  //             ? Colors.red
  //             : (status == 'ready_to_pickup' ? Colors.green : const Color(0xFFE5E7EB)),
  //         width: isOverdue || status == 'ready_to_pickup' ? 2.0 : 1.0,
  //       ),
  //       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         if (isOverdue)
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  //             margin: const EdgeInsets.only(bottom: 8),
  //             decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
  //             child: const Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
  //                 SizedBox(width: 4),
  //                 Text('OVERDUE ORDER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
  //               ],
  //             ),
  //           ),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text('#AB-$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFFFFF3E0),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Text('Pickup: $pickupTime', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 11)),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Token: ${order['pickup_code'] ?? "#AB-$id"} | Method: ${order['payment_method'] ?? "ABA"}',
  //           style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
  //         ),
  //         const Divider(height: 20),
  //         Row(
  //           children: [
  //             if (status == 'placed' || status == 'accepted')
  //               TextButton(
  //                 onPressed: () => _updateOrderStatus(id, 'cancelled'),
  //                 child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
  //               ),
  //             const Spacer(),
  //             if (status == 'placed')
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: burgundy),
  //                 onPressed: () => _updateOrderStatus(id, 'accepted'),
  //                 child: const Text('Accept', style: TextStyle(color: Colors.white)),
  //               )
  //             else if (status == 'accepted')
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
  //                 onPressed: () => _updateOrderStatus(id, 'cooking'),
  //                 child: const Text('Cooking...', style: TextStyle(color: Colors.white)),
  //               )
  //             else if (status == 'cooking')
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
  //                 onPressed: () => _updateOrderStatus(id, 'ready_to_pickup'),
  //                 child: const Text('Ready for Pick Up', style: TextStyle(color: Colors.white)),
  //               )
  //             else if (status == 'ready_to_pickup')
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222222)),
  //                 onPressed: () => _updateOrderStatus(id, 'completed'),
  //                 child: const Text('Finish', style: TextStyle(color: Colors.white)),
  //               ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildKitchenCard(Map<String, dynamic> order) {
    final status = (order['order_status'] ?? 'placed').toString().toLowerCase();
    final pickupTime = order['pickup_time_slot'] ?? 'ASAP';
    final isOverdue = _isCookingOverdue(order);
    final int id = order['id'];

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

          // Header
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
                  : (status == 'cooking'
                      ? Colors.orange.shade800
                      : const Color(0xFF7A1C1C)),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          const Divider(height: 20),

          // -----------------------------------------------------------------
          // ALL ACTION BUTTONS DISPLAYED SIDE-BY-SIDE SIMULTANEOUSLY
          // -----------------------------------------------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // 1. CANCEL BUTTON
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

                // 2. ACCEPT & AUTO-COOK BUTTON (Advances straight to cooking)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'cooking'
                        ? Colors.grey
                        : const Color(0xFF7A1C1C),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  // Clicking Accept automatically moves it into 'cooking'
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

                // 3. READY FOR PICK UP BUTTON
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

                // 4. FINISH BUTTON
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
