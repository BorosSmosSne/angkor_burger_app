import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class KhqrPaymentScreen extends StatefulWidget {
  final String qrString;
  final String tranId;
  final String phpBaseUrl;
  final double amount;
  final String currency; // 'USD' or 'KHR'
  final String merchantName;

  const KhqrPaymentScreen({
    super.key,
    required this.qrString,
    required this.tranId,
    required this.phpBaseUrl,
    this.amount = 0.0,
    this.currency = 'KHR',
    this.merchantName = 'Salad',
  });

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Poll the status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkPaymentStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final res = await http.get(
        Uri.parse(
            '${widget.phpBaseUrl}/check-transaction?tran_id=${widget.tranId}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final paymentStatusCode = data['data']?['payment_status_code'];
        final paymentStatus = data['data']?['payment_status'];

        if (paymentStatusCode == 0 || paymentStatus == 'APPROVED') {
          _timer?.cancel();
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

  String _formatAmount() {
    if (widget.currency.toUpperCase() == 'KHR') {
      final khrVal = widget.amount.toInt();
      return khrVal.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return widget.amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    const khqrHeaderRed = Color(0xFFE21A1A);
    const double qrDisplaySize = 210.0;
    const double logoDisplaySize = 42.0; // ~20% of QR size

    return Scaffold(
      backgroundColor:
          const Color(0xFF323236), // Dark background seen in reference
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- WHITE BILL CARD ---
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. OFFICIAL KHQR RED TOP BAR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          color: khqrHeaderRed,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'KHQR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),

                      // 2. MERCHANT NAME & LARGE AMOUNT SECTION
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.merchantName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _formatAmount(),
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.currency.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 3. DASHED DIVIDER LINE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const dashWidth = 4.0;
                            const dashSpace = 3.5;
                            final count =
                                (constraints.maxWidth / (dashWidth + dashSpace))
                                    .floor();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(count, (_) {
                                return const SizedBox(
                                  width: dashWidth,
                                  height: 1.0,
                                  child: DecoratedBox(
                                    decoration:
                                        BoxDecoration(color: Color(0xFFD6D6D6)),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 4. PRECISE SIZED QR CODE WITH CENTER EMBLEM IMAGE
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: widget.qrString,
                            version: QrVersions.auto,
                            size: qrDisplaySize,
                            padding: const EdgeInsets.all(0),
                            // CRITICAL: High Error Correction Level prevents scan failure with center logo
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                          Container(
                            width: logoDisplaySize,
                            height: logoDisplaySize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/bakong_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: khqrHeaderRed,
                                  // child: const Icon(Icons.qr_code,
                                  //     color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 5. SCAN TO PAY TEXT
                      const Text(
                        'Scan to Pay',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // TRAN ID & REALTIME POLLING STATUS
                Text(
                  'Tran ID: ${widget.tranId}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Waiting for payment confirmation...',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Simulator button for local testing
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Simulate Success (Test Mode)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
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
