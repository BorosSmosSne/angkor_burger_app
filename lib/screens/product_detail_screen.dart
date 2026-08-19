import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
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
    // Default selected size to 'M' if available, otherwise first size in sizePrices
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

  // Calculate total price using widget.product.sizePrices and widget.product.addOns
  double get _calculatedPrice {
    // 1. Get base price based on selected size from widget.product
    double basePrice =
        widget.product.sizePrices[_selectedSize] ?? widget.product.price;

    // 2. Add prices for dynamic addons selected in _selectedAddOns set
    for (final addOnName in _selectedAddOns) {
      basePrice += widget.product.addOns[addOnName] ?? 0.0;
    }

    // 3. Multiply by selected quantity
    return basePrice * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brandRed,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset(
                          'assets/images/logo_angkorBurger.png',
                          height: 24,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.fastfood,
                            color: AppColors.brandYellow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ANGKOR BURGER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.white,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
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

                    // Product Name, Category, Rating & Quantity Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(8),
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
                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: _decreaseQuantity,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
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
                      const SizedBox(height: 16),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],

                    // Dynamic Ingredients
                    if (widget.product.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 24),
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

                    // Dynamic Size Selection
                    if (widget.product.sizePrices.isNotEmpty) ...[
                      const SizedBox(height: 24),
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

                    // Dynamic Add-ons Selection
                    if (widget.product.addOns.isNotEmpty) ...[
                      const SizedBox(height: 24),
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

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
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
                          '\$${_calculatedPrice.toStringAsFixed(2)}',
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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${_quantity}x ${widget.product.name} to cart!',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.brandRed,
                            ),
                          );
                        },
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
          ],
        ),
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
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
            width: isSelected ? 2 : 1,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
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
