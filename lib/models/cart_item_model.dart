import 'package:angkor_burger_app/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  final String selectedSize;
  final List<String> selectedAddOns;
  final double unitPrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize = 'M',
    this.selectedAddOns = const [],
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;
}