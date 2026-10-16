import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:angkor_burger_app/constant.dart';
import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/checkout_model.dart';
import 'package:angkor_burger_app/models/customer_info_model.dart';
import 'package:angkor_burger_app/models/order_model.dart';
import 'package:angkor_burger_app/screens/checkout_payment_method_screen.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/order_screen.dart';
import 'package:angkor_burger_app/services/rest_api.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double? subtotal;
  final double? discountAmount;
  final double? taxAmount;
  final double? total;
  final VoidCallback? onClearCart;
  final Function(int tabIndex)? onNavigateToTab;

  const CheckoutScreen({
    super.key,
    this.subtotal,
    this.discountAmount,
    this.taxAmount,
    this.total,
    this.onClearCart,
    this.onNavigateToTab,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ServiceType _serviceType = ServiceType.pickup;
  String _selectedPayment = 'Cash';
  final String _selectedPickupTime = 'ASAP (~5 mins)';

  List<PaymentMethodModel> get _paymentMethods => CheckoutModel.defaultPaymentMethods;

  late final TextEditingController _nameController =
      TextEditingController(text: UserProfileManager.currentProfile.name);
  late final TextEditingController _phoneController =
      TextEditingController(text: UserProfileManager.currentProfile.phone);
  final TextEditingController _promoController = TextEditingController();

  double _discountPercent = 0.0;
  String? _appliedPromoCode;
  String? _promoError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

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

  double get _calculatedTax {
    return widget.taxAmount ?? CheckoutModel.calculateTax(_calculatedSubtotal);
  }

  // ✅ Total strictly based on subtotal, discount, and tax (no delivery fee)
  double get _calculatedTotal {
    return CheckoutModel.calculateTotal(
      subtotal: _calculatedSubtotal,
      discount: _appliedDiscount,
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

  Future<void> _processOrder() async {
    if (_isSubmitting) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your full name'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your phone number'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final selected = _selectedPayment.toLowerCase();
    final isAba = selected.contains('aba');

    final currentEmail = UserProfileManager.profileNotifier.value.email.trim();
    final currentUserId = RestApi.currentUserId;

    final itemsPayload = widget.cartItems.map((item) {
      return {
        'product_id': item.product.id ?? 1,
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('${RestApi.baseUrl}/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': currentUserId,
          'email': currentEmail,
          'payment_method': isAba ? 'aba_pay' : _selectedPayment,
          'shipping_address': 'Angkor Burger - Riverside Main Store',
          'service_type': 'pickup',
          'pickup_time_slot': _selectedPickupTime,
          'total': _calculatedTotal,
          'amount': _calculatedTotal,
          'items': itemsPayload,
        }),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resBody['message'] ?? 'Failed to create order.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final orderData = resBody['data'];
      final int orderId = orderData['order_id'];
      final String tranId = orderData['tran_id'];

      if (isAba) {
        final now = DateTime.now().toUtc();
        final pad = (int n) => n.toString().padLeft(2, '0');
        final reqTime =
            '${now.year}${pad(now.month)}${pad(now.day)}${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';

        final cleanAmount = _calculatedTotal.toStringAsFixed(2);
        final List<Map<String, dynamic>> paywayItemsList = [
          {
            "name": "Food Order",
            "quantity": 1,
            "price": double.parse(cleanAmount)
          },
        ];
        final String itemsBase64 =
            base64Encode(utf8.encode(jsonEncode(paywayItemsList)));

        const String shipping = '0.00';
        final String firstname = _nameController.text.trim();
        const String lastname = 'Customer';
        final String email =
            currentEmail.isNotEmpty ? currentEmail : 'customer@example.com';
        final String phone = _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : '012345678';
        const String type = 'purchase';
        const String paymentOption = 'abapay_khqr';
        const String currency = 'USD';
        const String returnUrl = 'https://checkout-sandbox.payway.com.kh';

        final String rawHash = '$reqTime'
            '${kMerchantID.trim()}'
            '$tranId'
            '$cleanAmount'
            '$itemsBase64'
            '$shipping'
            '$firstname'
            '$lastname'
            '$email'
            '$phone'
            '$type'
            '$paymentOption'
            '$returnUrl'
            '$currency';

        final keyBytes = utf8.encode(kMerchantApiKey.trim());
        final hmac = Hmac(sha512, keyBytes);
        final hash = base64Encode(hmac.convert(utf8.encode(rawHash)).bytes);

        final purchaseReq = http.MultipartRequest(
          'POST',
          Uri.parse('$kBaseUrl/api/payment-gateway/v1/payments/purchase'),
        );

        purchaseReq.headers.addAll({
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Referer': 'https://checkout-sandbox.payway.com.kh',
          'Origin': 'https://checkout-sandbox.payway.com.kh',
        });

        purchaseReq.fields.addAll({
          'req_time': reqTime,
          'merchant_id': kMerchantID.trim(),
          'tran_id': tranId,
          'amount': cleanAmount,
          'items': itemsBase64,
          'shipping': shipping,
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'phone': phone,
          'type': type,
          'payment_option': paymentOption,
          'return_url': returnUrl,
          'currency': currency,
          'hash': hash,
        });

        final streamedResponse = await purchaseReq.send();
        final purchaseRes = await http.Response.fromStream(streamedResponse);
        final Map<String, dynamic> paywayData = jsonDecode(purchaseRes.body);

        if (purchaseRes.statusCode != 200 ||
            (paywayData['status']?['code'] != '00' &&
                paywayData['status']?['code'] != 0)) {
          setState(() => _isSubmitting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(paywayData['status']?['message'] ??
                    'Failed to generate ABA QR.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        final String? qrString = paywayData['qrString'];
        final String? qrImage = paywayData['qrImage'];

        setState(() => _isSubmitting = false);

        final paymentSuccess = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPaymentMethodScreen(
              amount: _calculatedTotal,
              subtotal: _calculatedSubtotal,
              tranId: tranId,
              qrString: qrString ?? '',
              qrImageBase64: qrImage,
              apiBaseUrl: RestApi.baseUrl,
              orderId: orderId,
              storeName: 'Angkor Burger',
            ),
          ),
        );

        if (paymentSuccess != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Payment cancelled or incomplete.'),
                  backgroundColor: Colors.orange),
            );
          }
          return;
        }
      }

      setState(() => _isSubmitting = false);

      final customerInfo = CustomerInfoModel(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: 'Angkor Burger - Riverside Main Store',
      );

      final checkoutOrder = CheckoutModel(
        customerInfo: customerInfo,
        serviceType: ServiceType.pickup,
        paymentMethod: _selectedPayment,
        cartItems: widget.cartItems,
        subtotal: _calculatedSubtotal,
        discountAmount: _appliedDiscount,
        taxAmount: _calculatedTax,
        total: _calculatedTotal,
        promoCode: _appliedPromoCode,
      );

      final newOrder = OrderModel.fromCheckout(checkoutOrder);
      OrderManager.addOrder(newOrder);

      widget.onClearCart?.call();

      _showOrderPlacedSuccessDialog(checkoutOrder,
          customOrderId: '#AB-$orderId');
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('Error placing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Connection error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showOrderPlacedSuccessDialog(CheckoutModel order,
      {String? customOrderId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 54),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order Placed!',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'Thank you for ordering with Angkor Burger.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                        const Text('Order Number:',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          customOrderId ?? order.orderId,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service:',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const Text('Pickup',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment:',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(order.paymentMethod,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid:',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          '\$${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandRed),
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
                    Navigator.pop(dialogContext);
                    if (widget.onNavigateToTab != null) {
                      Navigator.pop(context);
                      widget.onNavigateToTab!(3);
                      return;
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track / View My Orders',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (widget.onNavigateToTab != null) {
                      Navigator.pop(context);
                      widget.onNavigateToTab!(0);
                      return;
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandRed,
                    side: const BorderSide(color: AppColors.brandRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Home',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          AngkorAppBar(
            title: 'CHECKOUT',
            showBackButton: true,
            showFavorite: false,
            onBackPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceMethodCard(),
                  const SizedBox(height: 16),
                  _buildCustomerInformationCard(),
                  const SizedBox(height: 16),
                  _buildPickupLocationCard(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 16),
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomPlaceOrderBar(),
        ],
      ),
    );
  }

  Widget _buildServiceMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              icon: Icons.storefront_rounded, title: 'Service Method'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandRed,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandRed.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Pickup Store',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Customer Information'),
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

  Widget _buildPickupLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.store_mall_directory_outlined,
            title: 'Pickup Location',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandLightRed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.brandRed.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.storefront_rounded, color: AppColors.brandRed, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Angkor Burger - Riverside Main Store',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '#124 Preah Sisowath Quay, Phnom Penh',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              icon: Icons.payments_outlined, title: 'Payment Method'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _paymentMethods.map((pm) {
                  return _buildPaymentOptionCard(
                      paymentMethod: pm, width: itemWidth);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final hasRealItems = widget.cartItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              icon: Icons.receipt_long_outlined, title: 'Order Summary'),
          const SizedBox(height: 16),
          if (hasRealItems)
            ...widget.cartItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ))
          else
            _buildSummaryRow('Signature Truffle Burger x1', '\$18.50'),
          const Divider(height: 24),
          _buildSummaryRow(
              'Subtotal', '\$${_calculatedSubtotal.toStringAsFixed(2)}',
              isLight: true),
          if (_appliedDiscount > 0)
            _buildSummaryRow(
              'Discount (${(_discountPercent * 100).toInt()}%)',
              '-\$${_appliedDiscount.toStringAsFixed(2)}',
              isLight: true,
              valueColor: Colors.green.shade700,
            ),
          _buildSummaryRow(
              'Tax (8%)', '\$${_calculatedTax.toStringAsFixed(2)}',
              isLight: true),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.brandRed)),
              Text(
                '\$${_calculatedTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.brandRed)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Promo Code (e.g. ANGKOR10)',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyPromoCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 18),
                ),
                child: const Text('Apply',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_appliedPromoCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Promo "$_appliedPromoCode" applied (${(_discountPercent * 100).toInt()}% off)!',
              style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
          if (_promoError != null) ...[
            const SizedBox(height: 8),
            Text(_promoError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPlaceOrderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))
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
                Text('Total Payment',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(
                  '\$${_calculatedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.brandRed),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Place Order',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: AppColors.brandRed.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.brandRed, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
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
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.brandRed, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard(
      {required PaymentMethodModel paymentMethod, required double width}) {
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
              width: isSelected ? 2 : 1),
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
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child:
                      Image.asset(paymentMethod.imagePath!, fit: BoxFit.cover),
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
                child: Icon(paymentMethod.icon ?? Icons.payments_rounded,
                    color: paymentMethod.brandColor, size: 18),
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
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.brandRed, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isLight = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isLight ? Colors.grey.shade600 : Colors.black87,
                  fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: isLight ? FontWeight.normal : FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                  fontSize: 14)),
        ],
      ),
    );
  }
}