import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/menu_screen.dart';
import 'package:angkor_burger_app/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems ?? [];
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _totalCartItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void _updateCartQuantity(CartItem item, int newQuantity) {
    setState(() {
      final index = _cartItems.indexOf(item);
      if (index != -1) {
        if (newQuantity <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index].quantity = newQuantity;
        }
      }
    });
    widget.onUpdateCartQuantity?.call(item, newQuantity);
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cartItems.remove(item);
    });
    widget.onRemoveCartItem?.call(item);
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
    widget.onClearCart?.call();
  }

  void _navigateToCart() {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(2);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          onUpdateQuantity: _updateCartQuantity,
          onRemoveItem: _removeFromCart,
          onClearCart: _clearCart,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _onBottomNavTapped(int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(index);
      return;
    }
    if (index == 0) {
      // Home Tab
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (index == 1) {
      // Menu Tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            cartItems: _cartItems,
            onAddToCart: widget.onAddToCart,
            onUpdateCartQuantity: widget.onUpdateCartQuantity,
            onRemoveCartItem: widget.onRemoveCartItem,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    } else if (index == 2) {
      // Cart Tab
      _navigateToCart();
    } else if (index == 3) {
      // Already on Orders
    } else if (index == 4) {
      // User Profile Tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            cartItems: _cartItems,
            onAddToCart: widget.onAddToCart,
            onUpdateCartQuantity: widget.onUpdateCartQuantity,
            onRemoveCartItem: widget.onRemoveCartItem,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: 3, // 3 is Orders
              cartItemCount: _totalCartItems,
              onItemTapped: _onBottomNavTapped,
            )
          : null,
      body: Column(
        children: [
          // Header
          AngkorAppBar(
            title: 'MY ORDERS',
            totalCartItems: _totalCartItems,
            showBackButton: false,
            onCartPressed: _navigateToCart,
            onProfilePressed: () {
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(4);
              }
            },
          ),

          // Tab Bar
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
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Active Orders'),
                Tab(text: 'Past Orders'),
              ],
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOrdersTab(),
                _buildPastOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildActiveOrderCard(
          orderId: '#AB-9021',
          restaurantName: 'Angkor Burger - Riverside',
          itemsSummary: '2x Truffle Wagyu Deluxe, 1x Coca-Cola',
          totalPrice: 28.50,
          status: 'Preparing Food',
          statusColor: Colors.orange.shade800,
          statusIcon: Icons.outdoor_grill_outlined,
          progress: 0.45,
          estimatedTime: '15-20 mins',
        ),
        const SizedBox(height: 16),
        _buildActiveOrderCard(
          orderId: '#AB-8942',
          restaurantName: 'Angkor Burger - BKK1',
          itemsSummary: '1x Crispy Chicken Burger, 1x Fries',
          totalPrice: 14.20,
          status: 'Driver on the way',
          statusColor: Colors.blue.shade700,
          statusIcon: Icons.delivery_dining_outlined,
          progress: 0.85,
          estimatedTime: '5-8 mins',
        ),
      ],
    );
  }

  Widget _buildActiveOrderCard({
    required String orderId,
    required String restaurantName,
    required String itemsSummary,
    required double totalPrice,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required double progress,
    required String estimatedTime,
  }) {
    return Container(
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
                orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.brandRed,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            restaurantName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            itemsSummary,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Est. Arrival: $estimatedTime',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildPastOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPastOrderCard(
          orderId: '#AB-7712',
          date: 'Yesterday, 7:30 PM',
          itemsSummary: '1x Double Cheeseburger, 1x Milkshake',
          totalPrice: 18.00,
          delivered: true,
        ),
        const SizedBox(height: 14),
        _buildPastOrderCard(
          orderId: '#AB-6530',
          date: '18 Aug 2026, 1:15 PM',
          itemsSummary: '3x Classic Angkor Burger, 2x French Fries',
          totalPrice: 32.50,
          delivered: true,
        ),
        const SizedBox(height: 14),
        _buildPastOrderCard(
          orderId: '#AB-5419',
          date: '12 Aug 2026, 8:45 PM',
          itemsSummary: '1x BBQ Bacon Burger, 1x Iced Lemon Tea',
          totalPrice: 15.75,
          delivered: true,
        ),
      ],
    );
  }

  Widget _buildPastOrderCard({
    required String orderId,
    required String date,
    required String itemsSummary,
    required double totalPrice,
    required bool delivered,
  }) {
    return Container(
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
                orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Delivered',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(date,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            itemsSummary,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandRed,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Items from $orderId added to cart!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandRed,
                  side: const BorderSide(color: AppColors.brandRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                child: const Text('Reorder',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}