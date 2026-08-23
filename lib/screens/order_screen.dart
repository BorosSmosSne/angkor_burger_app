import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/order_model.dart';
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
            showBackButton: false,
            showFavorite: false,
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
    final activeOrders = OrderManager.activeOrders;

    if (activeOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have any active orders right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(1); // Go to Menu
                  } else {
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
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Browse Menu',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        final order = activeOrders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildActiveOrderCard(order: order),
        );
      },
    );
  }

  Widget _buildActiveOrderCard({required OrderModel order}) {
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
              Row(
                children: [
                  Text(
                    order.orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.brandRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandLightRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.serviceMethod,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandRed,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(order.statusIcon, color: order.statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      order.status,
                      style: TextStyle(
                        color: order.statusColor,
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
            order.restaurantName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            order.itemsSummary,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (order.deliveryAddress != null &&
              order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: order.progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(order.statusColor),
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
                    'Est: ${order.estimatedTime}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${order.paymentMethod}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Text(
                '\$${order.totalPrice.toStringAsFixed(2)}',
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
    final pastOrders = OrderManager.pastOrders;

    if (pastOrders.isEmpty) {
      return Center(
        child: Text(
          'No past orders yet',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pastOrders.length,
      itemBuilder: (context, index) {
        final order = pastOrders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: _buildPastOrderCard(order: order),
        );
      },
    );
  }

  Widget _buildPastOrderCard({required OrderModel order}) {
    final formattedDate =
        '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}';

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
                order.orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      order.status,
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
          Text(formattedDate,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            order.itemsSummary,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${order.totalPrice.toStringAsFixed(2)}',
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
                      content:
                          Text('Items from ${order.orderId} added to cart!'),
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
