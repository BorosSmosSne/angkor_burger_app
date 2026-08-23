import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/helpers/user_avatar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/user_profile_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/edit_profile_screen.dart';
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
  String _selectedLanguage = 'English (US)';

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

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _showAddressBottomSheet(String currentAddress) {
    final addressCtrl = TextEditingController(text: currentAddress);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.brandRed, size: 22),
                SizedBox(width: 8),
                Text(
                  'Edit Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              maxLines: 3,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your delivery address...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.brandRed, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (addressCtrl.text.trim().isNotEmpty) {
                    UserProfileManager.updateAddress(addressCtrl.text.trim());
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery address updated!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Address',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Text(
              'Available Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodTile(
              title: 'ABA PAY / KHQR',
              subtitle: 'Scan and pay instantly',
              imagePath: 'assets/images/ABA.jpg',
            ),
            _buildPaymentMethodTile(
              title: 'ACLEDA Mobile',
              subtitle: 'Pay via ACLEDA bank account',
              imagePath: 'assets/images/acleda.jpg',
            ),
            _buildPaymentMethodTile(
              title: 'Cash on Delivery',
              subtitle: 'Pay with physical cash on arrival',
              icon: Icons.payments_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String subtitle,
    String? imagePath,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imagePath != null
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.payment, color: AppColors.brandRed),
                    )
                  : Icon(icon ?? Icons.payment, color: AppColors.brandRed),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English (US)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: _selectedLanguage == 'English (US)'
                    ? const Icon(Icons.check, color: AppColors.brandRed)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'English (US)';
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Text('🇰🇭', style: TextStyle(fontSize: 24)),
                title: const Text('ភាសាខ្មែរ (Khmer)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: _selectedLanguage == 'ភាសាខ្មែរ (Khmer)'
                    ? const Icon(Icons.check, color: AppColors.brandRed)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'ភាសាខ្មែរ (Khmer)';
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandLightRed,
                child: Icon(Icons.phone, color: AppColors.brandRed, size: 20),
              ),
              title: const Text('Customer Hotline',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('+855 23 888 999 (8:00 AM - 10:00 PM)'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandLightRed,
                child: Icon(Icons.send, color: AppColors.brandRed, size: 20),
              ),
              title: const Text('Telegram Support',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('@angkorburger_support'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandLightRed,
                child: Icon(Icons.email_outlined,
                    color: AppColors.brandRed, size: 20),
              ),
              title: const Text('Email Us',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('support@angkorburger.com.kh'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(index);
      return;
    }
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (index == 1) {
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
      _navigateToCart();
    } else if (index == 3) {
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
      // Already on profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: 4,
              cartItemCount: _totalCartItems,
              onItemTapped: _onBottomNavTapped,
            )
          : null,
      body: ValueListenableBuilder<UserProfileModel>(
        valueListenable: UserProfileManager.profileNotifier,
        builder: (context, profile, _) {
          return Column(
            children: [
              // Header
              AngkorAppBar(
                title: 'MY PROFILE',
                showBackButton: false,
                showFavorite: false,
              ),

              // Scrollable Profile Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // User Card Header
                      _buildProfileHeaderCard(profile),
                      const SizedBox(height: 16),

                      // Loyalty Points Card
                      _buildLoyaltyCard(profile),
                      const SizedBox(height: 20),

                      // Account Settings Section
                      _buildSettingsSection(
                        title: 'Account Settings',
                        items: [
                          _buildSettingsTile(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                            subtitle:
                                '${profile.name} • ${profile.phone}',
                            onTap: _navigateToEditProfile,
                          ),
                          _buildSettingsTile(
                            icon: Icons.location_on_outlined,
                            title: 'Delivery Addresses',
                            subtitle: profile.address,
                            onTap: () =>
                                _showAddressBottomSheet(profile.address),
                          ),
                          _buildSettingsTile(
                            icon: Icons.payment_outlined,
                            title: 'Payment Methods',
                            subtitle: 'ABA Bank, ACLEDA, Cash',
                            onTap: _showPaymentMethodsBottomSheet,
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
                            subtitle: _selectedLanguage,
                            onTap: _showLanguageBottomSheet,
                          ),
                          _buildSettingsTile(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'FAQ, Hotline, Telegram',
                            onTap: _showHelpSupportBottomSheet,
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
                              content: const Text(
                                  'Are you sure you want to log out?'),
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
                                        content:
                                            Text('Logged out successfully'),
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
          );
        },
      ),
    );
  }

  Widget _buildProfileHeaderCard(UserProfileModel profile) {
    return GestureDetector(
      onTap: _navigateToEditProfile,
      child: Container(
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
            UserAvatar(
              profile: profile,
              radius: 36,
              showEditBadge: true,
              borderWidth: 2.5,
              onEditTap: _navigateToEditProfile,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandLightRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EDIT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.phone,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(UserProfileModel profile) {
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
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.black87, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    profile.membershipTier,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.rewardPoints} Reward Points Available',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'You have ${profile.rewardPoints} points ready to redeem on your next burger!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
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
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
