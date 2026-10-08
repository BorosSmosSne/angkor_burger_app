import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dart_payway/dart_payway.dart' hide debugPrint;
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/constant.dart';

class CheckoutView extends StatefulWidget {
  final double amountUsd;
  final List<CartItem> cartItems;
  final PaywayPaymentOption paymentOption;

  const CheckoutView({
    super.key,
    required this.amountUsd,
    required this.cartItems,
    this.paymentOption = PaywayPaymentOption.abapay_khqr_deeplink,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  // Use the exact sandbox credentials
  late final PaywayTransactionService _service = PaywayTransactionService(
    merchant: PaywayMerchant(
      merchantID: kMerchantID,
      merchantApiName: kMerchantName,
      merchantApiKey:
          kMerchantApiKey.trim(), // Remove any trailing/leading spaces
      baseApiUrl: kBaseUrl,
      refererDomain: 'checkout-sandbox.payway.com.kh',
    ),
  );

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('PayWay Loading: $url');
          },
          onPageFinished: (url) {
            debugPrint('PayWay Finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint(
                'PayWay Error: ${error.errorCode} -${error.description}');
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('http://') ||
                request.url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    _createTransaction();
  }

  Future<void> _createTransaction() async {
    try {
      // 1. Build initial item list from CartItems
      List<PaywayTransactionItem> paywayItems = widget.cartItems.map((item) {
        return PaywayTransactionItem(
          name: item.product.name,
          quantity: item.quantity.toDouble(),
          price: double.parse(item.product.price.toStringAsFixed(2)),
        );
      }).toList();

      // 2. Sum the subtotal of items
      double itemsSubtotal = paywayItems.fold<double>(
        0.0,
        (sum, i) => sum + (i.price * i.quantity),
      );

      // 3. ABA RULE: `amount` must equal the exact sum of all line items
      // We calculate the difference (Delivery Fee + Tax - Discounts) and add it as a line item
      double difference = double.parse(
        (widget.amountUsd - itemsSubtotal).toStringAsFixed(2),
      );

      if (difference > 0) {
        paywayItems.add(
          PaywayTransactionItem(
            name: 'Delivery Fee & Taxes',
            quantity: 1.0,
            price: difference,
          ),
        );
      } else if (paywayItems.isEmpty) {
        paywayItems = [
          PaywayTransactionItem(
            name: 'Food Order',
            quantity: 1.0,
            price: double.parse(widget.amountUsd.toStringAsFixed(2)),
          ),
        ];
      }

      // 4. Exact total amount formatted to 2 decimal places
      final double finalAmount = double.parse(
        paywayItems
            .fold<double>(0.0, (sum, i) => sum + (i.price * i.quantity))
            .toStringAsFixed(2),
      );

      // 5. Unique transaction ID (max 16 chars)
      final String tranId =
          '${DateTime.now().millisecondsSinceEpoch}'.substring(0, 13);

      final transaction = PaywayCreateTransaction(
        tranId: tranId,
        reqTime: _service.uniqueReqTime(),
        amount: finalAmount,
        items: paywayItems,
        firstname: 'Customer',
        lastname: 'User',
        email: 'customer@example.com',
        phone: '012345678',
        shipping: 0.0,
        option: widget.paymentOption,
        currency: PaywayTransactionCurrency.USD,
        returnUrl: 'https://checkout-sandbox.payway.com.kh',
      );

      final uri = await _service.generateTransactionCheckoutURI(
        transaction: transaction,
      );

      debugPrint('Generated PayWay URI: $uri');
      await _webViewController.loadRequest(uri);
    } catch (e, stack) {
      debugPrint('Error creating transaction: $e\n$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABA PayWay Payment'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B1D1D)),
            ),
        ],
      ),
    );
  }
}
