import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class KhqrPaymentScreen extends StatefulWidget {
  final int orderId;
  final String tranId;
  final double amount;
  final String currency;
  final String qrString;
  final String? qrImageBase64;
  final String apiBaseUrl;

  const KhqrPaymentScreen({
    super.key,
    required this.orderId,
    required this.tranId,
    required this.amount,
    this.currency = 'USD',
    required this.qrString,
    this.qrImageBase64,
    required this.apiBaseUrl,
  });

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll the backend every 3 seconds to check if ABA received the payment
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/orders/${widget.orderId}/verify'),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('Verify status [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['payment_status'];

        if (status == 'paid') {
          _pollingTimer?.cancel();
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      _isChecking = false;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      // Header Red Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

                      // Merchant Name & Amount
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          children: [
                            const Text(
                              'Angkor Burger',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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

                      // QR Code Rendering
                      if (widget.qrImageBase64 != null &&
                          widget.qrImageBase64!.contains(','))
                        Image.memory(
                          base64Decode(widget.qrImageBase64!.split(',').last),
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                        )
                      else
                        QrImageView(
                          data: widget.qrString,
                          version: QrVersions.auto,
                          size: 220.0,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),

                      const SizedBox(height: 14),
                      const Text(
                        'Scan to Pay with Any Bank App',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status indicator replacing the manual button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: khqrRed,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Waiting for payment...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tran ID: ${widget.tranId}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
