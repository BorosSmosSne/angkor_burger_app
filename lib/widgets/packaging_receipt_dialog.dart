import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:angkor_burger_app/core/contants.dart';

class PackagingReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? customerName;

  const PackagingReceiptDialog({
    super.key,
    required this.order,
    this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Parse items safely
    List<dynamic> items = [];
    final rawItems = order['items'] ?? order['order_items'];
    if (rawItems is List) {
      items = rawItems;
    } else if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) items = decoded;
      } catch (_) {}
    }

    final id = order['id'];
    final token = order['pickup_code'] ?? '#AB-$id';
    final serviceType =
        (order['service_type'] ?? 'PICKUP').toString().toUpperCase();
    final pickupTime = order['pickup_time_slot'] ?? 'ASAP';
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
    final payment =
        '${order['payment_method'] ?? 'Cash'} (${order['payment_status'] ?? 'pending'})';

    // Customer username / email fallback
    final userDisplay = customerName ??
        order['user']?['name'] ??
        order['customer_name'] ??
        order['email'] ??
        'Guest Customer';

    // Subtotal & Tax
    double calculatedSubtotal = 0.0;
    for (final item in items) {
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
      calculatedSubtotal += (price * qty);
    }
    double taxAmount = (total - calculatedSubtotal) > 0
        ? (total - calculatedSubtotal)
        : (calculatedSubtotal * 0.08);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store Title
            const Center(
              child: Text(
                'ANGKOR BURGER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.brandRed,
                ),
              ),
            ),
            const Center(
              child: Text(
                'PACKAGING & ORDER SLIP',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1.2, color: Colors.black87),

            // Token & Order ID Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER: #AB-$id',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Service: $serviceType ($pickupTime)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      token,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Account & Date Details
            _buildReceiptRow('Customer Account:', userDisplay, isBold: true),
            const SizedBox(height: 4),
            _buildReceiptRow(
                'Date & Time:', '${order['created_at'] ?? 'Today'}'),
            _buildReceiptRow('Payment Method:', payment),

            const SizedBox(height: 10),
            const Divider(thickness: 1, color: Colors.black54),
            const Text(
              'ORDER ITEMS:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            // Items List
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No item details available.',
                    style: TextStyle(fontSize: 12)),
              )
            else
              ...items.map((item) {
                final name = item['name'] ?? item['product_name'] ?? 'Item';
                final qty = item['quantity'] ?? 1;
                final price =
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                final size = item['selected_size'] ?? item['size'];
                final notes = item['notes'] ?? item['special_instructions'];
                List addOns = [];
                if (item['selected_add_ons'] is List) {
                  addOns = item['selected_add_ons'];
                } else if (item['selected_addons'] is List) {
                  addOns = item['selected_addons'];
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$qty×  $name',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('\$${(price * qty).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (size != null && size.toString().isNotEmpty)
                        Text('  • Size: $size',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700)),
                      if (addOns.isNotEmpty)
                        Text('  • Add-ons: ${addOns.join(', ')}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700)),
                      if (notes != null && notes.toString().isNotEmpty)
                        Text('  • Note: "$notes"',
                            style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87)),
                    ],
                  ),
                );
              }),

            const Divider(thickness: 1, color: Colors.black54),

            // Financial Summary
            _buildReceiptRow(
                'Subtotal:', '\$${calculatedSubtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _buildReceiptRow(
                'Tax (VAT 8%):', '\$${taxAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            const Divider(thickness: 1.5, color: Colors.black87),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL DUE / PAID:',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bag Note
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Center(
                child: Text(
                  '★ Attach this receipt to customer packaging bag ★',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Trigger 58mm/80mm ESC/POS thermal printer or PDF print here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sent to Kitchen/Packaging Printer')),
                      );
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print Slip'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
