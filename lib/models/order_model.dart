import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/checkout_model.dart';
import 'package:flutter/material.dart';

class OrderModel {
  final String orderId;
  final String restaurantName;
  final String itemsSummary;
  final List<CartItem> items;
  final double totalPrice;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final double progress;
  final String estimatedTime;
  final String serviceMethod;
  final String paymentMethod;
  final String? deliveryAddress;
  final DateTime orderDate;
  final bool isDelivered;

  OrderModel({
    required this.orderId,
    this.restaurantName = 'Angkor Burger - Riverside',
    required this.itemsSummary,
    this.items = const [],
    required this.totalPrice,
    this.status = 'Preparing Food',
    this.statusColor = const Color(0xFFE65100),
    this.statusIcon = Icons.outdoor_grill_outlined,
    this.progress = 0.35,
    this.estimatedTime = '15-20 mins',
    this.serviceMethod = 'Delivery',
    this.paymentMethod = 'Cash',
    this.deliveryAddress,
    DateTime? orderDate,
    this.isDelivered = false,
  }) : orderDate = orderDate ?? DateTime.now();

  /// Create an active OrderModel from a submitted CheckoutModel
  factory OrderModel.fromCheckout(CheckoutModel checkout) {
    String summary;
    if (checkout.cartItems.isNotEmpty) {
      summary = checkout.cartItems
          .map((item) =>
              '${item.quantity}x ${item.product.name} (${item.selectedSize})')
          .join(', ');
    } else {
      summary = '1x Signature Truffle Burger, 1x Spicy Miso Fries';
    }

    final isPickup = checkout.serviceType == ServiceType.pickup;

    return OrderModel(
      orderId: checkout.orderId,
      restaurantName: isPickup
          ? 'Angkor Burger - Riverside Main Store (Pickup)'
          : 'Angkor Burger - Riverside',
      itemsSummary: summary,
      items: List.from(checkout.cartItems),
      totalPrice: checkout.total,
      status: isPickup ? 'Preparing for Pickup' : 'Preparing Food',
      statusColor: isPickup
          ? const Color(0xFF8B1D1D)
          : const Color(0xFFE65100),
      statusIcon: isPickup
          ? Icons.storefront_rounded
          : Icons.outdoor_grill_outlined,
      progress: 0.30,
      estimatedTime: isPickup ? '10-15 mins' : '15-20 mins',
      serviceMethod: checkout.serviceType.label,
      paymentMethod: checkout.paymentMethod,
      deliveryAddress: checkout.customerInfo.address,
      orderDate: checkout.createdAt,
      isDelivered: false,
    );
  }
}

/// In-memory repository for active and past orders across the app session
class OrderManager {
  static final List<OrderModel> activeOrders = [
    OrderModel(
      orderId: '#AB-9021',
      restaurantName: 'Angkor Burger - Riverside',
      itemsSummary: '2x Truffle Wagyu Deluxe, 1x Coca-Cola',
      totalPrice: 28.50,
      status: 'Preparing Food',
      statusColor: const Color(0xFFE65100),
      statusIcon: Icons.outdoor_grill_outlined,
      progress: 0.45,
      estimatedTime: '15-20 mins',
      serviceMethod: 'Delivery',
      paymentMethod: 'ABA Pay',
    ),
    OrderModel(
      orderId: '#AB-8942',
      restaurantName: 'Angkor Burger - BKK1',
      itemsSummary: '1x Crispy Chicken Burger, 1x Fries',
      totalPrice: 14.20,
      status: 'Driver on the way',
      statusColor: const Color(0xFF1976D2),
      statusIcon: Icons.delivery_dining_outlined,
      progress: 0.85,
      estimatedTime: '5-8 mins',
      serviceMethod: 'Delivery',
      paymentMethod: 'Cash',
    ),
  ];

  static final List<OrderModel> pastOrders = [
    OrderModel(
      orderId: '#AB-7712',
      restaurantName: 'Angkor Burger - Riverside',
      itemsSummary: '1x Double Cheeseburger, 1x Milkshake',
      totalPrice: 18.00,
      status: 'Delivered',
      isDelivered: true,
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      serviceMethod: 'Delivery',
      paymentMethod: 'Cash',
    ),
    OrderModel(
      orderId: '#AB-6530',
      restaurantName: 'Angkor Burger - Toul Kork',
      itemsSummary: '3x Classic Angkor Burger, 2x French Fries',
      totalPrice: 32.50,
      status: 'Delivered',
      isDelivered: true,
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      serviceMethod: 'Delivery',
      paymentMethod: 'KHQR',
    ),
    OrderModel(
      orderId: '#AB-5419',
      restaurantName: 'Angkor Burger - Riverside',
      itemsSummary: '1x BBQ Bacon Burger, 1x Iced Lemon Tea',
      totalPrice: 15.75,
      status: 'Delivered',
      isDelivered: true,
      orderDate: DateTime.now().subtract(const Duration(days: 11)),
      serviceMethod: 'Pickup',
      paymentMethod: 'ACLEDA',
    ),
  ];

  /// Add a newly placed order to the top of active orders
  static void addOrder(OrderModel order) {
    activeOrders.insert(0, order);
  }
}
