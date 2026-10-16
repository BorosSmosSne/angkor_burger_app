import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/customer_info_model.dart';
import 'package:flutter/material.dart';

/// Enum representing the service / delivery method chosen by customer.
enum ServiceType {
  delivery('Delivery', Icons.two_wheeler_rounded),
  pickup('Pickup', Icons.storefront_rounded);

  final String label;
  final IconData icon;
  const ServiceType(this.label, this.icon);
}

/// Model representing a supported payment method option in Angkor Burger.
class PaymentMethodModel {
  final String id;
  final String name;
  final IconData? icon;
  final String? imagePath;
  final Color brandColor;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    this.icon,
    this.imagePath,
    required this.brandColor,
  });
}

/// Model representing all data required for checkout & order submission.
class CheckoutModel {
  final CustomerInfoModel customerInfo;
  final ServiceType serviceType;
  final String paymentMethod;
  final List<CartItem> cartItems;
  final double subtotal;
  // final double deliveryFee;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String? promoCode;
  final String orderId;
  final DateTime createdAt;

  CheckoutModel({
    required this.customerInfo,
    this.serviceType = ServiceType.pickup,
    this.paymentMethod = 'Cash',
    this.cartItems = const [],
    required this.subtotal,
    // required this.deliveryFee,
    this.discountAmount = 0.0,
    required this.taxAmount,
    required this.total,
    this.promoCode,
    String? orderId,
    DateTime? createdAt,
  })  : orderId = orderId ??
            '#AB-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}',
        createdAt = createdAt ?? DateTime.now();

  /// Default payment methods: Cash, ABA Pay, and Credit Card only
  static List<PaymentMethodModel> get defaultPaymentMethods => [
        const PaymentMethodModel(
          id: 'cash',
          name: 'Cash',
          icon: Icons.payments_rounded,
          brandColor: Color(0xFF2E7D32),
        ),
        const PaymentMethodModel(
          id: 'aba',
          name: 'ABA Pay',
          imagePath: 'assets/images/ABA.jpg',
          icon: Icons.account_balance_wallet_rounded,
          brandColor: Color(0xFF004D7A),
        ),
        const PaymentMethodModel(
          id: 'card',
          name: 'Credit Card',
          icon: Icons.credit_card_rounded,
          brandColor: Color(0xFF1976D2),
        ),
      ];

  /// Helper to compute subtotal
  static double calculateSubtotal(List<CartItem>? items,
      {double fallback = 29.00}) {
    if (items != null && items.isNotEmpty) {
      return items.fold(0.0, (sum, item) => sum + item.totalPrice);
    }
    return fallback;
  }

  /// Helper to compute delivery fee (always 0.0 for Pickup)
  static double calculateDeliveryFee({
    required bool isDelivery,
    required double subtotal,
    double? customFee,
  }) {
    if (!isDelivery) return 0.0;
    if (customFee != null) return customFee;
    return subtotal > 25.0 ? 0.0 : 1.50;
  }

  /// Helper to compute tax amount (8%)
  static double calculateTax(double subtotal, {double taxRate = 0.08}) {
    return subtotal * taxRate;
  }

  /// Helper to compute grand total
  static double calculateTotal({
    required double subtotal,
    required double discount,
    // required double deliveryFee,
    required double tax,
  }) {
    return (subtotal - discount + tax).clamp(0.0, double.infinity);
  }
}
