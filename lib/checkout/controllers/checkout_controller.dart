import 'dart:ui';
import 'package:flutter/foundation.dart' as foundation;
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dart_payway/dart_payway.dart';
import '../../../constant.dart';

class CheckoutController extends GetxController {
  final double amountUsd;
  final List<PaywayTransactionItem> items;

  CheckoutController({
    required this.amountUsd,
    required this.items,
  });
  late final WebViewController webViewController;

  final service = PaywayTransactionService(
    merchant: PaywayMerchant(
      merchantID: kMerchantID,
      merchantApiName: kMerchantName,
      merchantApiKey: kMerchantApiKey,
      baseApiUrl: kBaseUrl,
      refererDomain: 'https://yourdomain.app',
    ),
  );

  @override
  void onInit() {
    super.onInit();

    // 1. Initialize WebView controller with unrestricted JS
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => foundation.debugPrint('started: $url'),
          onPageFinished: (url) => foundation.debugPrint('finished: $url'),
          onWebResourceError: (error) => foundation.debugPrint(
            'WebView error: ${error.description}',
          ),
        ),
      );
    // Call createTransaction with real cart data
    createTransaction(amountUsd, items);

    // 2. Trigger test transaction (USD 2.00 converted to 8,200 KHR)
    createTransaction(
      2.00,
      [
        PaywayTransactionItem(
          name: 'Burger Test',
          quantity: 1,
          price: 2.00,
        ),
      ],
    );
  }

  Future<void> createTransaction(
    double amountUsd,
    List<PaywayTransactionItem> items,
  ) async {
    try {
      // Convert USD -> KHR (whole riel) and recompute total from items
      final khrItems = items
          .map((i) => i.copyWith(
                price: (i.price * kUsdToKhrRate).roundToDouble(),
              ))
          .toList();

      final khrAmount = khrItems.fold<double>(
        0.0,
        (sum, i) => sum + (i.price * i.quantity),
      );

      // Build the PayWay transaction object
      final transaction = PaywayCreateTransaction(
        tranId: service.uniqueTranID(),
        reqTime: service.uniqueReqTime(),
        amount: khrAmount,
        items: khrItems,
        firstname: 'Customer',
        lastname: 'Name',
        email: 'customer@example.com',
        phone: '0100000000',
        shipping: 0.0,
        option: PaywayPaymentOption
            .abapay_khqr_deeplink, // Forces KHQR receipt display
        currency: PaywayTransactionCurrency.USD, // Must match KHR
        returnUrl: 'https://checkout-sandbox.payway.com.kh',
      );

      // Generate checkout URI and load into WebView
      final uri = await service.generateTransactionCheckoutURI(
        transaction: transaction,
      );

      await webViewController.loadRequest(uri);
    } catch (e) {
      foundation.debugPrint('Error creating transaction: $e');
    }
  }
}
