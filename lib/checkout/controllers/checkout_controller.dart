import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dart_payway/dart_payway.dart' hide debugPrint;
import '../../../constant.dart';

class CheckoutController extends GetxController {
  late final WebViewController webViewController;
  final isLoading = true.obs;

  late final PaywayTransactionService service = PaywayTransactionService(
    merchant: PaywayMerchant(
      merchantID: kMerchantID,
      merchantApiName: kMerchantName,
      merchantApiKey: kMerchantApiKey,
      baseApiUrl: kBaseUrl,
      refererDomain: kRefererDomain,
    ),
  );

  @override
  void onInit() {
    super.onInit();

    // 1. Initialize WebView with JavaScript and proper User-Agent
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => debugPrint('PayWay started: $url'),
          onPageFinished: (url) {
            debugPrint('PayWay finished: $url');
            isLoading.value = false;
          },
          onWebResourceError: (error) {
            debugPrint('PayWay WebView Error: ${error.description}');
          },
        ),
      );

    // 2. Read arguments passed from Cart / Checkout
    final args = Get.arguments;
    if (args != null && args is Map) {
      final double total = (args['amount'] as num).toDouble();
      final List<PaywayTransactionItem> items = (args['items'] as List)
          .map((i) => PaywayTransactionItem(
                name: i['name'].toString(),
                quantity: (i['quantity'] as num).toDouble(),
                price: (i['price'] as num).toDouble(),
              ))
          .toList();
      createTransaction(amountUsd: total, items: items);
    } else {
      // Fallback test item ($1.00 USD)
      createTransaction(
        amountUsd: 1.00,
        items: [
          PaywayTransactionItem(
            name: 'Demo Item',
            quantity: 1.0,
            price: 1.00,
          ),
        ],
      );
    }
  }

  Future<void> createTransaction({
    required double amountUsd,
    required List<PaywayTransactionItem> items,
    bool isKhr = false, // Set to true if merchant profile is KHR-only
  }) async {
    try {
      isLoading.value = true;

      double finalAmount;
      List<PaywayTransactionItem> finalItems;
      PaywayTransactionCurrency currency;

      if (isKhr) {
        currency = PaywayTransactionCurrency.KHR;
        finalItems = items
            .map((i) => i.copyWith(
                  price: (i.price * kUsdToKhrRate).roundToDouble(),
                ))
            .toList();
        finalAmount = finalItems.fold<double>(
          0.0,
          (sum, i) => sum + (i.price * i.quantity),
        );
      } else {
        // Standard USD (keep clean 2 decimals)
        currency = PaywayTransactionCurrency.USD;
        finalItems = items
            .map((i) => i.copyWith(
                  price: double.parse(i.price.toStringAsFixed(2)),
                ))
            .toList();
        finalAmount = double.parse(
          finalItems
              .fold<double>(0.0, (sum, i) => sum + (i.price * i.quantity))
              .toStringAsFixed(2),
        );
      }

      final transaction = PaywayCreateTransaction(
        tranId: service.uniqueTranID(),
        reqTime: service.uniqueReqTime(),
        amount: finalAmount,
        items: finalItems,
        firstname: 'Customer',
        lastname: 'User',
        email: 'customer@example.com',
        phone: '012345678',
        shipping: 0.0,
        // Must use abapay_khqr_deeplink or abapay_khqr for scannable QR card
        option: PaywayPaymentOption.abapay_khqr_deeplink,
        currency: currency,
        returnUrl: 'https://checkout-sandbox.payway.com.kh',
      );

      final uri = await service.generateTransactionCheckoutURI(
        transaction: transaction,
      );

      debugPrint('Generated URI: $uri');
      await webViewController.loadRequest(uri);
    } catch (e, stack) {
      debugPrint('Error creating transaction: $e\n$stack');
    }
  }
}
