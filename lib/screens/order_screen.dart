import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/user_profile_manager.dart'; // ✅ Added import
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/menu_screen.dart';
import 'package:angkor_burger_app/screens/user_profile_screen.dart';
import 'package:angkor_burger_app/services/rest_api.dart';

class OrderScreen extends StatefulWidget {
  final List<CartItem>? cartItems;
  final Function(CartItem item)? onAddToCart;
  final Function(CartItem item, int newQuantity)? onUpdateCartQuantity;
  final Function(CartItem item)? onRemoveCartItem;
  final VoidCallback? onClearCart;
  final bool showBottomNav;
  final Function(int tabIndex)? onNavigateToTab;

  const OrderScreen({
    super.key,
    this.cartItems,
    this.onAddToCart,
    this.onUpdateCartQuantity,
    this.onRemoveCartItem,
    this.onClearCart,
    this.showBottomNav = true,
    this.onNavigateToTab,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late List<CartItem> _cartItems;
  late TabController _tabController;

  List<dynamic> _activeOrders = [];
  List<dynamic> _pastOrders = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems ?? [];
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
    // Poll every 5 seconds to sync kitchen state changes live
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchOrders(silent: true),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      // ✅ Pass current user's email or user_id to isolate order history
      final currentEmail = UserProfileManager.profileNotifier.value.email
          .trim();
      final currentUserId = RestApi.currentUserId;

      final Uri uri = Uri.parse(
        '${RestApi.baseUrl}/orders?user_id=$currentUserId&email=${Uri.encodeComponent(currentEmail)}',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List all = decoded is List ? decoded : (decoded['data'] ?? []);

        final active = <dynamic>[];
        final past = <dynamic>[];

        for (final item in all) {
          final status = (item['order_status'] ?? 'placed')
              .toString()
              .toLowerCase();
          if (status == 'completed' || status == 'cancelled') {
            past.add(item);
          } else {
            active.add(item);
          }
        }

        if (mounted) {
          setState(() {
            _activeOrders = active;
            _pastOrders = past;
            _isLoading = false;
          });
        }
      } else {
        if (mounted && !silent) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  int get _totalCartItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void _onBottomNavTapped(int index) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(index);
      return;
    }
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuScreen(
            cartItems: _cartItems,
            onAddToCart: widget.onAddToCart,
            onUpdateCartQuantity: widget.onUpdateCartQuantity,
            onRemoveCartItem: widget.onRemoveCartItem,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CartScreen(
            cartItems: _cartItems,
            onUpdateQuantity: (item, qty) =>
                setState(() => item.quantity = qty),
            onRemoveItem: (item) => setState(() => _cartItems.remove(item)),
            onClearCart: () => setState(() => _cartItems.clear()),
          ),
        ),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
      );
    }
  }

  void _showOrderDetailSheet(Map<String, dynamic> order) {
    List<dynamic> items = [];
    final rawItems = order['items'] ?? order['order_items'];

    if (rawItems is List) {
      items = rawItems;
    } else if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) items = decoded;
      } catch (_) {
        items = [];
      }
    }

    final id = order['id'];
    final status = (order['order_status'] ?? 'placed').toString().toUpperCase();
    final pickupTime = order['pickup_time_slot'] ?? 'ASAP';
    final pickupCode = order['pickup_code'] ?? '#AB-$id';
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
    final payment =
        '${order['payment_method'] ?? 'Cash'} • ${order['payment_status'] ?? 'pending'}';

    // 1. Calculate Items Subtotal
    double calculatedSubtotal = 0.0;
    for (final item in items) {
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
      calculatedSubtotal += (price * qty);
    }

    // 2. Calculate 8% Tax
    double taxAmount = 0.0;
    if (calculatedSubtotal > 0) {
      taxAmount = (total - calculatedSubtotal) > 0
          ? (total - calculatedSubtotal)
          : calculatedSubtotal * 0.08;
    } else {
      calculatedSubtotal = total / 1.08;
      taxAmount = total - calculatedSubtotal;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
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
                      Text(
                        '#AB-$id Details',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandRed,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'COMPLETED'
                              ? Colors.green.shade50
                              : (status == 'CANCELLED'
                                    ? Colors.red.shade50
                                    : const Color(0xFFFDEEEC)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: status == 'COMPLETED'
                                ? Colors.green.shade700
                                : (status == 'CANCELLED'
                                      ? Colors.red.shade700
                                      : AppColors.brandRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pickup: $pickupTime | $payment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Token: $pickupCode',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  const Text(
                    'Ordered Items',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No item breakdown available for this order.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...items.map((item) {
                      final itemMap = Map<String, dynamic>.from(item);
                      final name =
                          itemMap['name'] ??
                          itemMap['product_name'] ??
                          'Selected Product';
                      final qty = itemMap['quantity'] ?? 1;
                      final price =
                          double.tryParse(
                            itemMap['price']?.toString() ?? '0',
                          ) ??
                          0.0;
                      final size = itemMap['selected_size'] ?? itemMap['size'];
                      final notes =
                          itemMap['notes'] ?? itemMap['special_instructions'];

                      List addOnsList = [];
                      if (itemMap['selected_add_ons'] is List) {
                        addOnsList = itemMap['selected_add_ons'];
                      } else if (itemMap['selected_addons'] is List) {
                        addOnsList = itemMap['selected_addons'];
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF8F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$qty×  $name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${(price * qty).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandRed,
                                  ),
                                ),
                              ],
                            ),
                            if (size != null && size.toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Size: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '$size',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (addOnsList.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add-ons: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      addOnsList.join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (notes != null &&
                                notes.toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Note: "$notes"',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                  const Divider(height: 22),

                  // 🧾 Bill Summary (Subtotal + Tax only)
                  _buildReceiptRow(
                    label: 'Subtotal',
                    value: '\$${calculatedSubtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),
                  _buildReceiptRow(
                    label: 'Tax (VAT 8%)',
                    value: '\$${taxAmount.toStringAsFixed(2)}',
                  ),

                  const Divider(height: 20),

                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Paid / Due',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: 3,
              cartItemCount: _totalCartItems,
              onItemTapped: _onBottomNavTapped,
            )
          : null,
      body: Column(
        children: [
          const AngkorAppBar(
            title: 'MY ORDERS',
            showBackButton: false,
            showFavorite: false,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.brandRed,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Active Orders'),
                Tab(text: 'Past Orders'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandRed),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [_buildActiveOrdersTab(), _buildPastOrdersTab()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No orders in preparation.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) =>
          _buildActiveOrderCard(_activeOrders[index]),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final status = (order['order_status'] ?? 'placed').toString().toLowerCase();
    final pickupCode = order['pickup_code'] ?? '#AB-${order['id']}';
    final pickupTime = order['pickup_time_slot'] ?? 'ASAP';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showOrderDetailSheet(order), // 👈 Open item detail on click
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#AB-${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.brandRed,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Pickup: $pickupTime',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTimelineStepper(status),
            if (status == 'ready_to_pickup')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready at Counter!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Show token to collect meal',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pickupCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order['payment_method'] ?? 'ABA KHQR'} • ${order['payment_status'] ?? 'paid'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  '\$${double.tryParse(order['total'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStepper(String status) {
    final steps = [
      {'key': 'placed', 'title': 'Order Placed'},
      {'key': 'cooking', 'title': 'Accepted & Preparing'},
      {'key': 'ready_to_pickup', 'title': 'Ready to Pick Up'},
      {'key': 'completed', 'title': 'Finish'},
    ];

    int currentIndex = 0;
    if (status == 'accepted' || status == 'cooking') {
      currentIndex = 1;
    } else if (status == 'ready_to_pickup') {
      currentIndex = 2;
    } else if (status == 'completed') {
      currentIndex = 3;
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF7A1C1C)
                        : Colors.grey.shade300,
                    border: isCurrent
                        ? Border.all(color: Colors.amber, width: 2.5)
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: index < currentIndex
                        ? const Color(0xFF7A1C1C)
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Text(
                  steps[index]['title']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isDone ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPastOrdersTab() {
    if (_pastOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Past Orders Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed and cancelled orders will show here.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pastOrders.length,
      itemBuilder: (context, index) {
        final order = _pastOrders[index];
        final isCancelled = order['order_status'] == 'cancelled';
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetailSheet(order), // 👈 Open on click
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#AB-${order['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCancelled ? 'Cancelled' : 'Completed',
                        style: TextStyle(
                          color: isCancelled
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${double.tryParse(order['total'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandRed,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
