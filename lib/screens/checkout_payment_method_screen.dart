import 'package:flutter/material.dart';
import 'khqr_payment_screen.dart';

class CheckoutPaymentMethodScreen extends StatelessWidget {
  final double amount;
  final String tranId;
  final String qrString;
  final String? qrImageBase64;
  final String? apiBaseUrl;
  final int? orderId;
  final double? subtotal;
  final String storeName;

  const CheckoutPaymentMethodScreen({
    super.key,
    required this.amount,
    required this.tranId,
    required this.qrString,
    this.qrImageBase64,
    this.apiBaseUrl,
    this.orderId,
    this.subtotal,
    this.storeName = 'Shopping Store',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF5AB48C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              storeName,
              style: const TextStyle(
                color: Color(0xFF5AB48C),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose way to pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),

              // 1. ABA KHQR Option
              _buildPaymentOption(
                context: context,
                leadingWidget: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005E7B), // ABA Blue
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ABA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1232E), // KHQR Red
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'KHQR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                title: 'ABA KHQR',
                subtitle: 'Scan to pay with any banking app',
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KhqrPaymentScreen(
                        tranId: tranId,
                        amount: amount,
                        subtotal: subtotal ?? (amount * 0.9),
                        qrString: qrString,
                        qrImageBase64: qrImageBase64,
                        apiBaseUrl: apiBaseUrl,
                        orderId: orderId,
                        merchantName: storeName,
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),

              const SizedBox(height: 14),

              // 2. Credit/Debit Card
              _buildPaymentOption(
                context: context,
                leadingWidget: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF02627E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
                ),
                title: 'Credit/Debit Card',
                subtitle: 'VISA  Mastercard  JCB  UnionPay',
                onTap: () {},
              ),

              const SizedBox(height: 14),

              // 3. Alipay
              _buildPaymentOption(
                context: context,
                leadingWidget: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1677FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('支', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                title: 'Alipay',
                subtitle: 'Scan to pay with Alipay',
                onTap: () {},
              ),

              const SizedBox(height: 14),

              // 4. WeChat
              _buildPaymentOption(
                context: context,
                leadingWidget: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF07C160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble, color: Colors.white, size: 22),
                ),
                title: 'WeChat',
                subtitle: 'Scan to pay with WeChat',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required Widget leadingWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEFF1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}