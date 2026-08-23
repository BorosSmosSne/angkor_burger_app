import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/checkout_model.dart';
import 'package:angkor_burger_app/models/customer_info_model.dart';
import 'package:angkor_burger_app/models/order_model.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/order_screen.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? cartItems;
  final double? subtotal;
  final double? deliveryFee;
  final double? discountAmount;
  final double? taxAmount;
  final double? total;
  final VoidCallback? onClearCart;
  final Function(int tabIndex)? onNavigateToTab;

  const CheckoutScreen({
    super.key,
    this.cartItems,
    this.subtotal,
    this.deliveryFee,
    this.discountAmount,
    this.taxAmount,
    this.total,
    this.onClearCart,
    this.onNavigateToTab,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  ServiceType _serviceType = ServiceType.delivery;
  String _selectedPayment = 'Cash';

  bool get _isDelivery => _serviceType == ServiceType.delivery;
  List<PaymentMethodModel> get _paymentMethods =>
      CheckoutModel.defaultPaymentMethods;

  // Text Controllers for the form
  late final TextEditingController _nameController =
      TextEditingController(text: UserProfileManager.currentProfile.name);
  late final TextEditingController _phoneController =
      TextEditingController(text: UserProfileManager.currentProfile.phone);
  late final TextEditingController _addressController =
      TextEditingController(text: UserProfileManager.currentProfile.address);
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  double _discountPercent = 0.0;
  String? _appliedPromoCode;
  String? _promoError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _floorController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // Calculate pricing using CheckoutModel helpers
  double get _calculatedSubtotal {
    return CheckoutModel.calculateSubtotal(
      widget.cartItems,
      fallback: widget.subtotal ?? 29.00,
    );
  }

  double get _appliedDiscount {
    if (_discountPercent > 0) {
      return _calculatedSubtotal * _discountPercent;
    }
    return widget.discountAmount ?? 0.0;
  }

  double get _calculatedDeliveryFee {
    return CheckoutModel.calculateDeliveryFee(
      isDelivery: _isDelivery,
      subtotal: _calculatedSubtotal,
      customFee: widget.deliveryFee,
    );
  }

  double get _calculatedTax {
    return widget.taxAmount ?? CheckoutModel.calculateTax(_calculatedSubtotal);
  }

  double get _calculatedTotal {
    return CheckoutModel.calculateTotal(
      subtotal: _calculatedSubtotal,
      discount: _appliedDiscount,
      deliveryFee: _calculatedDeliveryFee,
      tax: _calculatedTax,
    );
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



  void _processOrder() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_isDelivery && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Build the CustomerInfoModel & CheckoutModel
    final customerInfo = CustomerInfoModel(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      buildingFloor: _floorController.text.trim().isNotEmpty
          ? _floorController.text.trim()
          : null,
      noteToDriver: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    final checkoutOrder = CheckoutModel(
      customerInfo: customerInfo,
      serviceType: _serviceType,
      paymentMethod: _selectedPayment,
      cartItems: widget.cartItems ?? [],
      subtotal: _calculatedSubtotal,
      deliveryFee: _calculatedDeliveryFee,
      discountAmount: _appliedDiscount,
      taxAmount: _calculatedTax,
      total: _calculatedTotal,
      promoCode: _appliedPromoCode,
    );

    // Save order into OrderManager so it appears in My Orders
    final newOrder = OrderModel.fromCheckout(checkoutOrder);
    OrderManager.addOrder(newOrder);

    // Clear cart
    widget.onClearCart?.call();

    _showOrderPlacedSuccessDialog(checkoutOrder);
  }

  void _showOrderPlacedSuccessDialog(CheckoutModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 54,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order Placed!',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Thank you for ordering with Angkor Burger.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Number:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          order.orderId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Service:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          order.serviceType.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          order.paymentMethod,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Paid:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog

                    if (widget.onNavigateToTab != null) {
                      Navigator.pop(context);
                      widget.onNavigateToTab!(3); // Go to Orders tab
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track / View My Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog

                    if (widget.onNavigateToTab != null) {
                      Navigator.pop(context);
                      widget.onNavigateToTab!(0); // Go to Home tab
                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandRed,
                    side: const BorderSide(color: AppColors.brandRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // 1. REUSABLE ANGKOR APP BAR
          AngkorAppBar(
            title: 'CHECKOUT',
            showBackButton: true,
            showFavorite: false,
            onBackPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),

          // 2. SCROLLABLE CHECKOUT CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: SERVICE METHOD ---
                  _buildServiceMethodCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 2: CUSTOMER INFORMATION ---
                  _buildCustomerInformationCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 3: DELIVERY ADDRESS / PICKUP LOCATION ---
                  _buildDeliveryAddressCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 4: PAYMENT METHOD ---
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 16),

                  // --- SECTION 5: ORDER SUMMARY ---
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. FIXED BOTTOM BUTTON
          _buildBottomPlaceOrderBar(),
        ],
      ),
    );
  }

  // --- SECTION WIDGETS WITH WHITE CONTAINER BACKGROUNDS ---

  // 1. Service Method Card
  Widget _buildServiceMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.delivery_dining_rounded,
            title: 'Service Method',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _serviceType = ServiceType.delivery),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDelivery
                            ? AppColors.brandRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isDelivery
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.brandRed.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ServiceType.delivery.icon,
                            size: 18,
                            color: _isDelivery
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ServiceType.delivery.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isDelivery
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _serviceType = ServiceType.pickup),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isDelivery
                            ? AppColors.brandRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isDelivery
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.brandRed.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ServiceType.pickup.icon,
                            size: 18,
                            color: !_isDelivery
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ServiceType.pickup.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: !_isDelivery
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Customer Information Card
  Widget _buildCustomerInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Customer Information',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Phone Number',
            hint: 'e.g. +855 12 345 678',
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // 3. Delivery Address / Pickup Card
  Widget _buildDeliveryAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
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
              _buildSectionHeader(
                icon: _isDelivery
                    ? Icons.location_on_outlined
                    : Icons.store_mall_directory_outlined,
                title: _isDelivery ? 'Delivery Address' : 'Pickup Location',
              ),
              if (_isDelivery)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Current GPS location detected'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandLightRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 13,
                          color: AppColors.brandRed,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Locate',
                          style: TextStyle(
                            color: AppColors.brandRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isDelivery) ...[
            _buildTextField(
              label: 'Street Address',
              hint: 'Enter your full delivery address',
              controller: _addressController,
              prefixIcon: Icons.home_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Building / Floor',
                    hint: 'e.g. Apt 4B',
                    controller: _floorController,
                    prefixIcon: Icons.apartment_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Note to Driver',
                    hint: 'e.g. Gate code',
                    controller: _noteController,
                    prefixIcon: Icons.speaker_notes_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Map Preview Placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Opacity(
                      opacity: 0.25,
                      child: Icon(
                        Icons.map_outlined,
                        size: 90,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandRed.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Delivery location confirmed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Pickup Store Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandLightRed,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandRed.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.brandRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Angkor Burger - Riverside Main Store',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#124 Preah Sisowath Quay, Daun Penh, Phnom Penh',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(
                              Icons.access_time_filled,
                              color: AppColors.brandRed,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ready in ~15 mins from order time',
                              style: TextStyle(
                                color: AppColors.brandRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Payment Method Card
  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.payments_outlined,
            title: 'Payment Method',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _paymentMethods.map((pm) {
                  return _buildPaymentOptionCard(
                    paymentMethod: pm,
                    width: itemWidth,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. Order Summary Card
  Widget _buildOrderSummaryCard() {
    final hasRealItems =
        widget.cartItems != null && widget.cartItems!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Order Summary',
          ),
          const SizedBox(height: 16),

          // Items list
          if (hasRealItems) ...[
            ...widget.cartItems!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} x${item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),
          ] else ...[
            _buildSummaryRow('Signature Truffle Burger x1', '\$18.50'),
            _buildSummaryRow('Spicy Miso Fries x1', '\$6.00'),
            _buildSummaryRow('Iced Yuzu Matcha x1', '\$4.50'),
          ],

          const Divider(height: 24),
          _buildSummaryRow(
            'Subtotal',
            '\$${_calculatedSubtotal.toStringAsFixed(2)}',
            isLight: true,
          ),
          if (_appliedDiscount > 0)
            _buildSummaryRow(
              'Discount (${(_discountPercent * 100).toInt()}%)',
              '-\$${_appliedDiscount.toStringAsFixed(2)}',
              isLight: true,
              valueColor: Colors.green.shade700,
            ),
          _buildSummaryRow(
            'Delivery Fee',
            _calculatedDeliveryFee == 0.0
                ? 'FREE'
                : '\$${_calculatedDeliveryFee.toStringAsFixed(2)}',
            isLight: true,
            valueColor:
                _calculatedDeliveryFee == 0.0 ? Colors.green.shade700 : null,
          ),
          _buildSummaryRow(
            'Tax (8%)',
            '\$${_calculatedTax.toStringAsFixed(2)}',
            isLight: true,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.brandRed,
                ),
              ),
              Text(
                '\$${_calculatedTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.brandRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Promo Code Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Promo Code (e.g. ANGKOR10)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyPromoCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 18,
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_appliedPromoCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Promo "$_appliedPromoCode" applied (${(_discountPercent * 100).toInt()}% off)!',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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

  // 6. Bottom Place Order Bar
  Widget _buildBottomPlaceOrderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Payment',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '\$${_calculatedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.brandRed,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Place Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE HELPER WIDGETS ---

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.brandRed.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.brandRed,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: Colors.grey.shade600)
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.brandRed,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required PaymentMethodModel paymentMethod,
    required double width,
  }) {
    final isSelected = _selectedPayment == paymentMethod.name;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = paymentMethod.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandRed.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? AppColors.brandRed : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (paymentMethod.imagePath != null)
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    paymentMethod.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      paymentMethod.icon ?? Icons.payments_rounded,
                      color: paymentMethod.brandColor,
                      size: 18,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: paymentMethod.brandColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  paymentMethod.icon ?? Icons.payments_rounded,
                  color: paymentMethod.brandColor,
                  size: 18,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                paymentMethod.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.brandRed : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandRed,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isLight = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isLight ? Colors.grey.shade600 : Colors.black87,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isLight ? FontWeight.normal : FontWeight.bold,
              color: valueColor ?? Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
