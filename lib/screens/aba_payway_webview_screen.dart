import 'dart:async';
import 'dart:convert';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dart_payway/dart_payway.dart' hide debugPrint;

class AbaPaywayWebViewScreen extends StatefulWidget {
  final String shippingAddress;
  final String apiBaseUrl; // e.g. 'http://127.0.0.1:8000/api'
  final String? authToken; // Pass Sanctum bearer token if user is logged in
  final List<CartItem> cartItems; // List of items in the cart

  const AbaPaywayWebViewScreen({
    super.key,
    required this.shippingAddress,
    required this.apiBaseUrl,
    required this.cartItems,
    this.authToken,
  });

  @override
  State<AbaPaywayWebViewScreen> createState() => _AbaPaywayWebViewScreenState();
}

class _AbaPaywayWebViewScreenState extends State<AbaPaywayWebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String _paymentStatus = 'pending'; // pending | paid | failed | expired
  int? _orderId;
  Timer? _pollTimer;
  bool _polling = false;

  // PayWay merchant credentials from Step 8 in your teacher's document
  late final PaywayTransactionService _service = PaywayTransactionService(
    merchant: PaywayMerchant(
      merchantID: 'ec479136',
      merchantApiName: 'Heng_Chhay',
      merchantApiKey: '3D83BD4673F4ABF8D7D7EA32A274F7BAE710231C',
      baseApiUrl: 'https://checkout-sandbox.payway.com.kh',
      // baseApiUrl:
      // 'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase',
      refererDomain: 'checkout-sandbox.payway.com.kh',
    ),
  );

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('PayWay WebView Loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('PayWay WebView Finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
                'PayWay WebView Error: [${error.errorCode}] ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Prevent webview crash when user taps ABA Mobile app deep link
            if (request.url.startsWith('https://') ||
                request.url.startsWith('http://')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    _initiateCheckout();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (widget.authToken != null)
          'Authorization': 'Bearer ${widget.authToken}',
      };

  Future<void> _initiateCheckout() async {
    try {
      // Format items from your Flutter CartItem model
      final itemsPayload = widget.cartItems.map((item) {
        return {
          'product_id': item.product.id,
          'name': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price,
          'selected_size': item.selectedSize,
          'selected_addons': item.selectedAddOns,
        };
      }).toList();
      // 1. Create order on your Laravel backend (Step 6 / 8)
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/orders'),
        headers: _headers,
        body: jsonEncode({
          'payment_method': 'aba_khqr',
          'shipping_address': widget.shippingAddress,
          'items': itemsPayload,
        }),
      );
      // ADD THESE DEBUG PRINTS:
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final resBody = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(resBody['message'] ?? 'Order failed');
      }

      // Safely extract data whether nested under 'data' or returned at root
      final Map<String, dynamic> data =
          (resBody['data'] != null && resBody['data'] is Map<String, dynamic>)
              ? resBody['data']
              : resBody;

      if (!data.containsKey('order_id') && !data.containsKey('id')) {
        throw Exception('Missing order_id in response: ${response.body}');
      }

      _orderId = data['order_id'] ?? data['id'];

      final items = (data['items'] as List)
          .map((i) => PaywayTransactionItem(
                name: i['name'].toString(),
                quantity: (i['quantity'] as num).toDouble(),
                price: (i['price'] as num).toDouble(),
              ))
          .toList();

      // 2. Generate PayWay checkout transaction with backend data
      final double calculatedTotal =
          items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
      final transaction = PaywayCreateTransaction(
        tranId: data['tran_id'],
        reqTime: _service.uniqueReqTime(),
        amount: calculatedTotal,
        items: items,
        firstname: 'Customer',
        lastname: 'Name',
        email: 'customer@example.com',
        phone: '0100000000',
        shipping: 0.0,
        option: PaywayPaymentOption.abapay_deeplink,
        currency: PaywayTransactionCurrency.USD,
        // returnUrl: '${widget.apiBaseUrl}/payway/callback',
        returnUrl: 'https://checkout-sandbox.payway.com.kh',
      );

      final uri = await _service.generateTransactionCheckoutURI(
        transaction: transaction,
      );
      debugPrint('--- ABA PAYWAY PAYLOAD ---');
      debugPrint('Tran ID: ${transaction.tranId}');
      debugPrint('Amount: ${transaction.amount}');
      debugPrint('Req Time: ${transaction.reqTime}');
      for (var item in transaction.items) {
        debugPrint(
            'Item: ${item.name} | Qty: ${item.quantity} | Price: ${item.price}');
      }

      debugPrint('Generated PayWay URI: $uri');
      // Load PayWay hosted checkout inside the WebView
      await _webViewController.loadRequest(uri);

      // 3. Start polling the Laravel verify endpoint
      _startPolling();
    } catch (e) {
      debugPrint('Checkout error: $e');
      debugPrint('Stack trace: $StackTrace');
      if (mounted) {
        setState(() {
          _paymentStatus = 'failed';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initialization error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startPolling({
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 5),
  }) {
    final deadline = DateTime.now().add(timeout);

    _pollTimer = Timer.periodic(interval, (_) async {
      if (_polling || _orderId == null) return;

      if (DateTime.now().isAfter(deadline)) {
        _stopPolling();
        if (mounted) setState(() => _paymentStatus = 'expired');
        return;
      }

      _polling = true;
      try {
        final res = await http.get(
          Uri.parse('${widget.apiBaseUrl}/orders/$_orderId/verify'),
          headers: _headers,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final status = body['payment_status'] as String;

          if (mounted) setState(() => _paymentStatus = status);

          if (status == 'paid') {
            _stopPolling();
            if (mounted) {
              Navigator.pop(context, true); // Return success to CheckoutScreen
            }
          } else if (status == 'failed') {
            _stopPolling();
          }
        }
      } catch (_) {
        // Network glitch, continue polling
      } finally {
        _polling = false;
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFF8B1D1D);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ABA PayWay Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: brandRed,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: brandRed),
            ),
        ],
      ),
    );
  }
}
