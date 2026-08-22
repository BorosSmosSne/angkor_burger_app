import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/menu_screen.dart';
import 'package:angkor_burger_app/screens/order_screen.dart';
import 'package:angkor_burger_app/screens/user_profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(CartItem item, int newQuantity) onUpdateQuantity;
  final Function(CartItem item) onRemoveItem;
  final VoidCallback onClearCart;
  final bool showBottomNav;
  final bool showBackButton;
  final Function(int tabIndex)? onNavigateToTab;
  final VoidCallback? onContinueShopping;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onClearCart,
    this.showBottomNav = true,
    this.showBackButton = true,
    this.onNavigateToTab,
    this.onContinueShopping,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color _brandRed = const Color(0xFF8B1D1D);
  final Color _bgColor = const Color(0xFFFCF5F0);
  final Color _brandYellow = const Color(0xFFF3C755);

  final TextEditingController _promoController = TextEditingController();
  double _discountPercent = 0.0;
  String? _appliedPromoCode;
  String? _promoError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  double get _discountAmount {
    return _subtotal * _discountPercent;
  }

  double get _deliveryFee {
    if (widget.cartItems.isEmpty) return 0.0;
    return _subtotal > 25.0 ? 0.0 : 1.50;
  }

  double get _taxAmount {
    return widget.cartItems.isEmpty ? 0.0 : (_subtotal * 0.08);
  }

  double get _totalPrice {
    return (_subtotal - _discountAmount + _deliveryFee + _taxAmount)
        .clamp(0.0, double.infinity);
  }

  int get _totalItemCount {
    return widget.cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      if (code == 'ANGKOR10' || code == 'FLASH50' || code == 'BURGER20') {
        _discountPercent =
            code == 'FLASH50' ? 0.50 : (code == 'BURGER20' ? 0.20 : 0.10);
        _appliedPromoCode = code;
        _promoError = null;
      } else if (code.isEmpty) {
        _promoError = 'Please enter a promo code';
      } else {
        _promoError = 'Invalid code. Try "ANGKOR10" or "FLASH50"';
      }
    });
  }

  void _showCheckoutDialog() {
    if (widget.cartItems.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text(
                'Order Placed!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thank you for your order at Angkor Burger!',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items count:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$_totalItemCount items'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '\$${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandRed,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                widget.onClearCart();
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Home',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _onBottomNavTapped(int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
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
            cartItems: widget.cartItems,
            onAddToCart: (item) {
              final existingIndex = widget.cartItems.indexWhere(
                (i) =>
                    i.product.name == item.product.name &&
                    i.selectedSize == item.selectedSize,
              );
              if (existingIndex != -1) {
                widget.onUpdateQuantity(
                  widget.cartItems[existingIndex],
                  widget.cartItems[existingIndex].quantity + item.quantity,
                );
              } else {
                widget.cartItems.add(item);
              }
            },
            onUpdateCartQuantity: widget.onUpdateQuantity,
            onRemoveCartItem: widget.onRemoveItem,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    } else if (index == 2) {
      // Already on Cart
    } else if (index == 3) {
      // Orders Tab
      if (widget.onNavigateToTab != null) {
        widget.onNavigateToTab!(3);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(
            cartItems: widget.cartItems,
            onAddToCart: (item) {
              final existingIndex = widget.cartItems.indexWhere(
                (i) =>
                    i.product.name == item.product.name &&
                    i.selectedSize == item.selectedSize,
              );
              if (existingIndex != -1) {
                widget.onUpdateQuantity(
                  widget.cartItems[existingIndex],
                  widget.cartItems[existingIndex].quantity + item.quantity,
                );
              } else {
                widget.cartItems.add(item);
              }
            },
            onUpdateCartQuantity: widget.onUpdateQuantity,
            onRemoveCartItem: widget.onRemoveItem,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    } else if (index == 4) {
      // Profile Tab
      _navigateToProfile();
    }
  }

  void _navigateToProfile() {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(4);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          cartItems: widget.cartItems,
          onAddToCart: (item) {
            final existingIndex = widget.cartItems.indexWhere(
              (i) =>
                  i.product.name == item.product.name &&
                  i.selectedSize == item.selectedSize,
            );
            if (existingIndex != -1) {
              widget.onUpdateQuantity(
                widget.cartItems[existingIndex],
                widget.cartItems[existingIndex].quantity + item.quantity,
              );
            } else {
              widget.cartItems.add(item);
            }
          },
          onUpdateCartQuantity: widget.onUpdateQuantity,
          onRemoveCartItem: widget.onRemoveItem,
          onClearCart: widget.onClearCart,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: 2, // 2 is Cart
              cartItemCount: _totalItemCount,
              onItemTapped: _onBottomNavTapped,
            )
          : null,
      body: Column(
        children: [
          // 1. REUSABLE ANGKOR APP BAR
          AngkorAppBar(
            title: 'YOUR ORDER',
            showBackButton: widget.showBackButton,
            onBackPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                widget.onNavigateToTab?.call(0);
              }
            },
            showCart: false,
            showProfile: true,
            onProfilePressed: _navigateToProfile,
            actions: [
              if (widget.cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Clear Cart?'),
                        content: const Text(
                            'Are you sure you want to remove all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.onClearCart();
                              setState(() {});
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.brandRed, size: 18),
                  label: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.brandRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // 2. SCROLLABLE CONTENT
          Expanded(
            child: widget.cartItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your Cart is Empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Looks like you haven\'t added any items yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onContinueShopping != null) {
                                widget.onContinueShopping!();
                              } else if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                widget.onNavigateToTab?.call(1);
                              }
                            },
                            icon: const Icon(Icons.restaurant_menu,
                                color: Colors.white, size: 18),
                            label: const Text(
                              'Browse Menu',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandRed,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PAGE TITLE & BADGE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cart Items',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _brandYellow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$_totalItemCount ${_totalItemCount == 1 ? "Item" : "Items"}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // CART ITEMS LIST
                        ...widget.cartItems.map((item) => _buildCartItem(item)),
                        const SizedBox(height: 16),

                        // PROMO CODE SECTION
                        _buildPromoCodeSection(),
                        const SizedBox(height: 24),

                        // ORDER SUMMARY SECTION
                        _buildOrderSummary(),
                        const SizedBox(height: 16),

                        // LOYALTY POINTS BANNER
                        _buildLoyaltyBanner(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildCartItem(CartItem item) {
    final addOnsSummary = item.selectedAddOns.isNotEmpty
        ? item.selectedAddOns.join(', ')
        : 'Standard Recipe';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product.imagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Size: ${item.selectedSize} • $addOnsSummary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: _brandRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          // Actions (Trash & Quantity)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  widget.onRemoveItem(item);
                  setState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(CupertinoIcons.trash,
                      color: Colors.redAccent, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (item.quantity > 1) {
                          widget.onUpdateQuantity(item, item.quantity - 1);
                        } else {
                          widget.onRemoveItem(item);
                        }
                        setState(() {});
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child:
                            Icon(Icons.remove, size: 16, color: Colors.black87),
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        widget.onUpdateQuantity(item, item.quantity + 1);
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Icon(Icons.add, size: 16, color: _brandRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Promo Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter code (e.g. ANGKOR10)',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyPromoCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Apply',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_appliedPromoCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Promo code "$_appliedPromoCode" applied (${(_discountPercent * 100).toInt()}% off)!',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          if (_promoError != null) ...[
            const SizedBox(height: 8),
            Text(
              _promoError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(height: 32),
          _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Discount (${(_discountPercent * 100).toInt()}%)',
              '-\$${_discountAmount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Delivery Fee',
            _deliveryFee == 0.0
                ? 'FREE'
                : '\$${_deliveryFee.toStringAsFixed(2)}',
            isDiscount: _deliveryFee == 0.0,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax (8%)', '\$${_taxAmount.toStringAsFixed(2)}'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              Text(
                '\$${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                    color: _brandRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showCheckoutDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandRed,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Proceed to Checkout',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Secure encrypted checkout with QuickPay',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? _brandRed : Colors.black87,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyBanner() {
    final earnedPoints = (_totalPrice * 2).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brandYellow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.black87, shape: BoxShape.circle),
            child: Icon(Icons.star, color: _brandYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Earn $earnedPoints Points',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                const Text(
                  "You're just 120 points away from a free drink!",
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
