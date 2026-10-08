import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/constant.dart';

class KhqrPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final List<CartItem> cartItems;

  const KhqrPaymentScreen({
    super.key,
    required this.amount,
    this.currency = 'USD',
    required this.cartItems,
  });

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  bool _isLoading = true;
  String? _errorMsg;
  String? _qrString;
  String? _qrImageBase64;
  late String _tranId;

  @override
  void initState() {
    super.initState();
    _tranId = '${DateTime.now().millisecondsSinceEpoch}'.substring(0, 13);
    _generateKhqr();
  }

  Future<void> _generateKhqr() async {
    try {
      // 1. UTC Timestamp formatted strictly as YYYYMMDDHHmmss
      final now = DateTime.now().toUtc();
      final pad = (int n) => n.toString().padLeft(2, '0');
      final reqTime =
          '${now.year}${pad(now.month)}${pad(now.day)}${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';

      // 2. Format amount
      final cleanAmount = widget.currency == 'KHR'
          ? widget.amount.toInt().toString()
          : widget.amount.toStringAsFixed(2);

      // 3. Build item list matching amount exactly
      final double numPrice = double.parse(cleanAmount);
      final List<Map<String, dynamic>> itemsList = [
        {"name": "Burger Order", "quantity": 1, "price": numPrice},
      ];
      final String items = base64Encode(utf8.encode(jsonEncode(itemsList)));

      const String shipping = '0.00';
      const String firstname = 'Customer';
      const String lastname = 'User';
      const String email = 'customer@example.com';
      const String phone = '012345678';
      const String type = 'purchase';
      const String paymentOption = 'abapay_khqr';
      final String currency = widget.currency;
      const String returnUrl = 'https://checkout-sandbox.payway.com.kh';

      // 4. Exact 14-parameter ABA PayWay hash concatenation
      final String rawHash = '$reqTime'
          '${kMerchantID.trim()}'
          '$_tranId'
          '$cleanAmount'
          '$items'
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

      // 5. Send POST request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/api/payment-gateway/v1/payments/purchase'),
      );

      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Referer': 'https://checkout-sandbox.payway.com.kh',
        'Origin': 'https://checkout-sandbox.payway.com.kh',
      });

      request.fields.addAll({
        'req_time': reqTime,
        'merchant_id': kMerchantID.trim(),
        'tran_id': _tranId,
        'amount': cleanAmount,
        'items': items,
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] != null &&
            data['status']['code'] != null &&
            data['status']['code'] != '00' &&
            data['status']['code'] != 0) {
          setState(() {
            _errorMsg =
                'PayWay Error [${data['status']['code']}]: ${data['status']['message']}';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _qrString = data['qrString'];
          _qrImageBase64 = data['qrImage'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg =
              'Server responded with status ${response.statusCode}:\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const khqrRed = Color(0xFFE21A1A);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      appBar: AppBar(
        title: const Text('ABA KHQR Payment'),
        backgroundColor: const Color(0xFF8B1D1D),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Generating KHQR...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              : _errorMsg != null
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to generate KHQR:\n\n$_errorMsg',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 360),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: const BoxDecoration(
                                    color: khqrRed,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'KHQR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                  child: Column(
                                    children: [
                                      Text(
                                        kMerchantName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            widget.amount.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            widget.currency,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(indent: 16, endIndent: 16),
                                const SizedBox(height: 12),

                                // QR Render
                                if (_qrImageBase64 != null &&
                                    _qrImageBase64!.contains(','))
                                  Image.memory(
                                    base64Decode(
                                        _qrImageBase64!.split(',').last),
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.contain,
                                  )
                                else if (_qrString != null)
                                  QrImageView(
                                    data: _qrString!,
                                    version: QrVersions.auto,
                                    size: 220.0,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),

                                const SizedBox(height: 12),
                                const Text(
                                  'Scan to Pay with Any Bank App',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: khqrRed,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('I Have Paid'),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
