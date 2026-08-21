import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final Function(CartItem item)? onAddToCart;
  final List<CartItem>? cartItems;
  final Function(CartItem item, int newQuantity)? onUpdateCartQuantity;
  final Function(CartItem item)? onRemoveCartItem;
  final VoidCallback? onClearCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onAddToCart,
    this.cartItems,
    this.onUpdateCartQuantity,
    this.onRemoveCartItem,
    this.onClearCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late String _selectedSize;
  final Set<String> _selectedAddOns = {};

  @override
  void initState() {
    super.initState();
    if (widget.product.sizePrices.containsKey('M')) {
      _selectedSize = 'M';
    } else if (widget.product.sizePrices.isNotEmpty) {
      _selectedSize = widget.product.sizePrices.keys.first;
    } else {
      _selectedSize = 'M';
    }
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  // Calculate unit price based on selected size and selected addons
  double get _calculatedUnitPrice {
    double basePrice =
        widget.product.sizePrices[_selectedSize] ?? widget.product.price;
    for (final addOnName in _selectedAddOns) {
      basePrice += widget.product.addOns[addOnName] ?? 0.0;
    }
    return basePrice;
  }

  // Calculate total price for the selected quantity
  double get _calculatedTotalPrice {
    return _calculatedUnitPrice * _quantity;
  }

  int get _cartCount {
    if (widget.cartItems == null) return 0;
    return widget.cartItems!.fold(0, (sum, item) => sum + item.quantity);
  }

  void _navigateToCart() {
    if (widget.cartItems != null &&
        widget.onUpdateCartQuantity != null &&
        widget.onRemoveCartItem != null &&
        widget.onClearCart != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartScreen(
            cartItems: widget.cartItems!,
            onUpdateQuantity: widget.onUpdateCartQuantity!,
            onRemoveItem: widget.onRemoveCartItem!,
            onClearCart: widget.onClearCart!,
          ),
        ),
      ).then((_) => setState(() {}));
    }
  }

  void _handleAddToCart() {
    final cartItem = CartItem(
      product: widget.product,
      quantity: _quantity,
      selectedSize: _selectedSize,
      selectedAddOns: _selectedAddOns.toList(),
      unitPrice: _calculatedUnitPrice,
    );

    widget.onAddToCart?.call(cartItem);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${_quantity}x ${widget.product.name} (Size $_selectedSize) to cart!',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.brandRed,
        action: widget.cartItems != null
            ? SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: _navigateToCart,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // Top Navigation Header
          AngkorAppBar(
            showBackButton: true,
            totalCartItems: _cartCount,
            onCartPressed: _navigateToCart,
            onBackPressed: () => Navigator.pop(context),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Product Image in a styled Card
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        widget.product.imagePath,
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 260,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Information Card
                    Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.product.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandLightRed,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.product.category,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.brandRed,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.star,
                                            color: AppColors.brandYellow,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.product.rating.toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Selector
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(24),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.remove, size: 16),
                                        onPressed: _decreaseQuantity,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: Text(
                                          '$_quantity',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: _increaseQuantity,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Dynamic Description
                            if (widget.product.description.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                widget.product.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Dynamic Ingredients Section
                    if (widget.product.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.restaurant, 'Ingredients'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.product.ingredients
                            .map((ingredient) =>
                                _buildIngredientChip(ingredient))
                            .toList(),
                      ),
                    ],

                    // Dynamic Size Selection Section
                    if (widget.product.sizePrices.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.straighten, 'Select Size'),
                      const SizedBox(height: 12),
                      Row(
                        children:
                            widget.product.sizePrices.entries.map((entry) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildSizeOption(
                                entry.key,
                                '\$${entry.value.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Dynamic Add-ons Selection Section
                    if (widget.product.addOns.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.add_circle_outline, 'Add-ons'),
                      const SizedBox(height: 12),
                      ...widget.product.addOns.entries.map((entry) {
                        final isSelected = _selectedAddOns.contains(entry.key);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildAddOnCheckbox(
                            entry.key,
                            '+\$${entry.value.toStringAsFixed(2)}',
                            isSelected,
                            (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedAddOns.add(entry.key);
                                } else {
                                  _selectedAddOns.remove(entry.key);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart Bar in a Card
            Card(
              margin: EdgeInsets.zero,
              elevation: 8,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${_calculatedTotalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleAddToCart,
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandRed, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSizeOption(String size, String price) {
    bool isSelected = _selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = size),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandLightRed : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.brandRed : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              size,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.brandRed : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.brandRed : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnCheckbox(
    String title,
    String price,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.brandRed,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        secondary: Text(
          price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.brandRed,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
