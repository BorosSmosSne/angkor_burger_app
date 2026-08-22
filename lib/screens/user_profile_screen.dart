import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/menu_screen.dart';
import 'package:angkor_burger_app/screens/order_screen.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  final List<CartItem>? cartItems;
  final Function(CartItem item)? onAddToCart;
  final Function(CartItem item, int newQuantity)? onUpdateCartQuantity;
  final Function(CartItem item)? onRemoveCartItem;
  final VoidCallback? onClearCart;
  final bool showBottomNav;
  final Function(int tabIndex)? onNavigateToTab;

  const UserProfileScreen({
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
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late List<CartItem> _cartItems;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems ?? [];
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
      // Orders Tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(
            cartItems: _cartItems,
            onAddToCart: widget.onAddToCart,
            onUpdateCartQuantity: widget.onUpdateCartQuantity,
            onRemoveCartItem: widget.onRemoveCartItem,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    } else if (index == 4) {
      // Already on Profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: 4, // 4 is User
              cartItemCount: _totalCartItems,
              onItemTapped: _onBottomNavTapped,
            )
          : null,
      body: Column(
        children: [
          // Header
          AngkorAppBar(
            title: 'MY PROFILE',
            totalCartItems: _totalCartItems,
            showBackButton: false,
            onCartPressed: _navigateToCart,
          ),

          // Scrollable Profile Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User Card Header
                  _buildProfileHeaderCard(),
                  const SizedBox(height: 16),

                  // Loyalty Points Card
                  _buildLoyaltyCard(),
                  const SizedBox(height: 20),

                  // Account Settings Section
                  _buildSettingsSection(
                    title: 'Account Settings',
                    items: [
                      _buildSettingsTile(
                        icon: Icons.person_outline,
                        title: 'Personal Information',
                        subtitle: 'Name, email, phone',
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'Delivery Addresses',
                        subtitle: 'Home, Office',
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        subtitle: 'ABA Bank, QuickPay, Cards',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App Settings Section
                  _buildSettingsSection(
                    title: 'Preferences',
                    items: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandLightRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: AppColors.brandRed, size: 20),
                        ),
                        title: const Text('Push Notifications',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Order updates & promo deals',
                            style: TextStyle(fontSize: 12)),
                        trailing: Switch(
                          value: _notificationsEnabled,
                          activeThumbColor: AppColors.brandRed,
                          activeTrackColor:
                              AppColors.brandRed.withValues(alpha: 0.4),
                          onChanged: (val) {
                            setState(() {
                              _notificationsEnabled = val;
                            });
                          },
                        ),
                      ),
                      _buildSettingsTile(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: 'English (US)',
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'FAQ, Live chat',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged out successfully'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Text('Logout',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.brandLightRed,
                child: const Icon(Icons.person,
                    size: 40, color: AppColors.brandRed),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.brandYellow,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.edit, size: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boros Smos Sne',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+855 12 345 678',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  'boros.burger@gmail.com',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3C755), Color(0xFFE5B53B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.stars, color: Colors.black87, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Gold Member',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '150 Reward Points Available',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Redeem',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 14, bottom: 4),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.brandLightRed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.brandRed, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
