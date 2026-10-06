import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dart_payway/dart_payway.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends StatelessWidget {
  final double amountUsd;
  final List<CartItem> cartItems;

  const CheckoutView({
    super.key,
    required this.amountUsd,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context) {
    // Convert your app's CartItems to PaywayTransactionItems
    final paywayItems = cartItems.map((item) {
      return PaywayTransactionItem(
        name: item.product.name,
        quantity: item.quantity.toDouble(),
        price: item.product.price.toDouble(),
      );
    }).toList();

    // Initialize the controller with real items
    final controller = Get.put(
      CheckoutController(
        amountUsd: amountUsd,
        items: paywayItems,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ABA PayWay Payment'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: WebViewWidget(controller: controller.webViewController),
    );
  }
}
