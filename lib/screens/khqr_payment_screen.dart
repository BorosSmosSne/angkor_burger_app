import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class KhqrPaymentScreen extends StatefulWidget {
  final String qrString;
  final String tranId;
  final double amount;
  final String currency;
  final String merchantName;
  final String? deepLink;
  final Future<bool> Function()? onCheckStatus;

  const KhqrPaymentScreen({
    super.key,
    required this.qrString,
    required this.tranId,
    required this.amount,
    this.currency = 'USD',
    this.merchantName = 'Angkor Burger',
    this.deepLink,
    this.onCheckStatus,
  });

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  Timer? _statusTimer;
  bool _isChecking = false;

  static const Color abaBlue = Color(0xFF005E7B);
  static const Color khqrRed = Color(0xFFE1232E);

  @override
  void initState() {
    super.initState();
    _startStatusPolling();
  }

  void _startStatusPolling() {
    if (widget.onCheckStatus == null) return;
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isChecking) return;
      _isChecking = true;
      try {
        final isPaid = await widget.onCheckStatus!();
        if (isPaid && mounted) {
          timer.cancel();
          Navigator.pop(context, true);
        }
      } catch (_) {
      } finally {
        _isChecking = false;
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _openAbaApp() async {
    if (widget.deepLink != null && widget.deepLink!.isNotEmpty) {
      final uri = Uri.parse(widget.deepLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = widget.currency.toUpperCase() == 'USD'
        ? '\$${widget.amount.toStringAsFixed(2)}'
        : '${widget.amount.toStringAsFixed(0)} KHR';

    return Scaffold(
      backgroundColor: const Color(0xFF14191E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14191E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'KHQR Payment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Main ABA KHQR Bill Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Red KHQR Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
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
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                          ),
                        ),
                      ),
                    ),

                    // Merchant Info & Amount
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: Column(
                        children: [
                          Text(
                            widget.merchantName,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedAmount,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Receipt Perforation Line
                    const ReceiptDivider(),

                    // QR Code Presentation
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFF1F5F9), width: 1.5),
                        ),
                        child: QrImageView(
                          data: widget.qrString,
                          version: QrVersions.auto,
                          size: 210,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          embeddedImage:
                              const AssetImage('assets/images/bakong_logo.png'),
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(42, 42),
                          ),
                        ),
                      ),
                    ),

                    const Text(
                      'Scan to pay with any banking app',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Open in ABA Mobile Button (Brand Color #005E7B)
              if (widget.deepLink != null && widget.deepLink!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openAbaApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: abaBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 20),
                    label: const Text(
                      'Pay with ABA Mobile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Transaction Status Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(abaBlue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Waiting for payment...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tran ID: ${widget.tranId}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Receipt Perforated Separator with Side Notches
class ReceiptDivider extends StatelessWidget {
  const ReceiptDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  height: 1.5,
                  color: index.isEven
                      ? const Color(0xFFCBD5E1)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF14191E),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF14191E),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
