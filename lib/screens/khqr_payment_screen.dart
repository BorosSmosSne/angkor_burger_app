import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class KhqrPaymentScreen extends StatefulWidget {
  final int? orderId;
  final String tranId;
  final double amount;
  final double? subtotal;
  final String currency;
  final String qrString;
  final String? qrImageBase64;
  final String? apiBaseUrl;
  final String merchantName;

  const KhqrPaymentScreen({
    super.key,
    this.orderId,
    required this.tranId,
    required this.amount,
    this.subtotal,
    this.currency = 'USD',
    required this.qrString,
    this.qrImageBase64,
    this.apiBaseUrl,
    this.merchantName = 'Shopping Store',
  });

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  Timer? _pollingTimer;
  bool _isChecking = false;

  static const Color khqrRed = Color(0xFFC94846);
  static const Color brandGreen = Color(0xFF6CC09A);
  static const Color downloadBlue = Color(0xFF3FB5D6);
  static const Color pageGrey = Color(0xFFF5F5F5);

  static const double _headerHeight = 58;
  static const double _foldSize = 28;

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
    if (widget.apiBaseUrl == null) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isChecking) return;
      _isChecking = true;

      try {
        final url = widget.orderId != null
            ? '${widget.apiBaseUrl}/orders/${widget.orderId}/verify'
            : '${widget.apiBaseUrl}/check-transaction?tran_id=${widget.tranId}';

        final res = await http
            .get(Uri.parse(url), headers: {'Accept': 'application/json'});

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final status =
              (data['payment_status'] ?? data['data']?['payment_status'] ?? '')
                  .toString()
                  .toUpperCase();
          final statusCode = data['payment_status_code'] ??
              data['data']?['payment_status_code'];

          if (status == 'PAID' || status == 'APPROVED' || statusCode == 0) {
            _pollingTimer?.cancel();
            if (mounted) Navigator.pop(context, true);
          }
        }
      } catch (_) {
      } finally {
        _isChecking = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtotalVal = widget.subtotal ?? (widget.amount * 0.86);
    final isUSD = widget.currency.toUpperCase() == 'USD';

    // European decimal comma on the card, e.g. "147,45"
    final amountFormatted = isUSD
        ? widget.amount.toStringAsFixed(2).replaceAll('.', ',')
        : widget.amount.toStringAsFixed(0);
    final subtotalFormatted = isUSD
        ? '${subtotalVal.toStringAsFixed(2)} USD'
        : '${subtotalVal.toStringAsFixed(0)} KHR';
    final totalFormatted = isUSD
        ? '${widget.amount.toStringAsFixed(2)} USD'
        : '${widget.amount.toStringAsFixed(0)} KHR';

    // QR size adapts to small screens (card padding 24*2 + inner margin 32*2)
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = math.min(220.0, screenWidth - 48 - 64);

    return Scaffold(
      backgroundColor: pageGrey,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    _buildTicketCard(qrSize, amountFormatted),
                    const SizedBox(height: 24),
                    _buildActions(),
                  ],
                ),
              ),
            ),
            _buildSummary(subtotalFormatted, totalFormatted),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- top bar
  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Color(0xFF222222), size: 18),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: brandGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ ticket card
  Widget _buildTicketCard(double qrSize, String amountFormatted) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Red KHQR banner
                  Container(
                    height: _headerHeight,
                    width: double.infinity,
                    color: khqrRed,
                    alignment: Alignment.center,
                    child: const Text(
                      'KHQR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Merchant + amount, aligned with the QR's left edge
                  SizedBox(
                    width: qrSize,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.merchantName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              amountFormatted,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.currency.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF222222),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Full-width perforation
                  const MicroDashedDivider(
                    color: Color(0xFF9E9E9E),
                    dashWidth: 6,
                    dashSpace: 4,
                  ),

                  const SizedBox(height: 26),

                  _buildQr(qrSize),

                  const SizedBox(height: 28),
                ],
              ),
            ),

            // Red fold triangle: the white body's top-right corner is cut
            // diagonally and this fills the cut.
            const Positioned(
              top: _headerHeight,
              right: 0,
              child: CustomPaint(
                size: Size(_foldSize, _foldSize),
                painter: _FoldPainter(khqrRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQr(double size) {
    final hasImage =
        widget.qrImageBase64 != null && widget.qrImageBase64!.contains(',');

    if (hasImage) {
      // Image from the bank API already carries its own center logo
      return Image.memory(
        base64Decode(widget.qrImageBase64!.split(',').last),
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    final symbol = widget.currency.toUpperCase() == 'USD' ? '\$' : '៛';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: widget.qrString,
            version: QrVersions.auto,
            size: size,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            // High error correction so the center badge doesn't break scans
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          // Center currency badge
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.6),
                ),
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- actions
  Widget _buildActions() {
    return Column(
      children: [
        const Text(
          'Scan to Pay',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'or',
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('QR Code saved to gallery.')),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_download_outlined,
                    color: downloadBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Download QR',
                  style: TextStyle(
                    color: downloadBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'and upload to Mobile Banking app\nsupporting KHQR',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF9E9E9E),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- summary
  Widget _buildSummary(String subtotal, String total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtotal,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const MicroDashedDivider(color: Color(0xFFD0D0D0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                total,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Right triangle with its right angle at the top-right corner.
class _FoldPainter extends CustomPainter {
  final Color color;
  const _FoldPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FoldPainter old) => old.color != color;
}

/// Dashed perforated divider.
class MicroDashedDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  const MicroDashedDivider({
    super.key,
    this.height = 1.0,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
    this.color = const Color(0xFFCBD5E1),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount =
            (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        );
      },
    );
  }
}
