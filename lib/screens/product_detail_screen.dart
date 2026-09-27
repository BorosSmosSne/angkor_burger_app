import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/favorites_manager.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
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
  static const Color burgundy = Color(0xFF7A1C1C);
  static const Color creamBg = Color(0xFFFBF8F5);

  int _quantity = 1;
  late String _selectedSize;
  final Set<String> _selectedAddOns = {};

  final TextEditingController _specialInstructionController =
      TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });

    // Default to 'M' if exists, otherwise first size available
    if (widget.product.sizePrices.containsKey('M')) {
      _selectedSize = 'M';
    } else if (widget.product.sizePrices.isNotEmpty) {
      _selectedSize = widget.product.sizePrices.keys.first;
    } else {
      _selectedSize = 'M';
    }
  }

// 4. Always dispose controllers to prevent memory leaks
  @override
  void dispose() {
    _specialInstructionController.dispose();
    super.dispose();
  }

  void _increaseQuantity() {
    setState(() => _quantity++);
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  double get _calculatedUnitPrice {
    double basePrice =
        widget.product.sizePrices[_selectedSize] ?? widget.product.price;
    for (final addOnName in _selectedAddOns) {
      basePrice += widget.product.addOns[addOnName] ?? 0.0;
    }
    return basePrice;
  }

  double get _calculatedTotalPrice => _calculatedUnitPrice * _quantity;

  void _handleAddToCart() {
    final cartItem = CartItem(
      product: widget.product,
      quantity: _quantity,
      selectedSize: _selectedSize,
      selectedAddOns: _selectedAddOns.toList(),
      unitPrice: _calculatedUnitPrice,
      notes: _specialInstructionController.text.trim(),
    );

    widget.onAddToCart?.call(cartItem);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(),

            // Scrollable Details
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Food Banner Card
                    _buildImageCard(),
                    const SizedBox(height: 16),

                    // 2. Info Card (Title, Category, Rating, Counter & Description)
                    _buildTitleAndDescriptionCard(),
                    const SizedBox(height: 20),

                    // 3. Dynamic Ingredients Section
                    if (widget.product.ingredients.isNotEmpty) ...[
                      _buildSectionTitle(Icons.restaurant, 'Ingredients'),
                      const SizedBox(height: 10),
                      _buildIngredientsList(),
                      const SizedBox(height: 20),
                    ],

                    // 4. Dynamic Size Options
                    if (widget.product.sizePrices.isNotEmpty) ...[
                      _buildSectionTitle(Icons.straighten, 'Select Size'),
                      const SizedBox(height: 10),
                      _buildSizeSelector(),
                      const SizedBox(height: 20),
                    ],

                    // 5. Dynamic Add-ons List
                    if (widget.product.addOns.isNotEmpty) ...[
                      _buildSectionTitle(Icons.add_circle_outline, 'Add-ons'),
                      const SizedBox(height: 10),
                      _buildAddOnsList(),
                      const SizedBox(height: 20),
                    ],

                    _buildSectionTitle(
                        Icons.edit_note_rounded, 'Special Instructions'),
                    const SizedBox(
                      height: 10,
                    ),
                    _buildSpecialInstructionsInput(),
                    const SizedBox(
                      height: 24,
                    )
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructionsInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _specialInstructionController,
        maxLines: 3,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          hintText:
              "Add a note (e.g. don't put chili, no onions, sauce on the side)...",
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Row(
            children: [
              Icon(Icons.lunch_dining, color: burgundy, size: 22),
              SizedBox(width: 8),
              Text(
                'ANGKOR BURGER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: burgundy,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesManager.favoriteProductNamesNotifier,
            builder: (context, favNames, _) {
              final isFav = FavoritesManager.isFavorite(widget.product);
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? burgundy : Colors.black87,
                  size: 22,
                ),
                onPressed: () =>
                    FavoritesManager.toggleFavorite(widget.product),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    final imagePath = widget.product.imagePath.trim();
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: imagePath.startsWith('http')
              ? Image.network(
                  imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child:
                        Icon(Icons.lunch_dining, size: 60, color: Colors.grey),
                  ),
                )
              : Image.asset(
                  width: double.infinity,
                  height: double.infinity,
                  imagePath.isNotEmpty
                      ? imagePath
                      : 'assets/images/imagelist1.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child:
                        Icon(Icons.lunch_dining, size: 60, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTitleAndDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEEEC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.product.category,
                            style: const TextStyle(
                              color: burgundy,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Counter Stepper
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: _decreaseQuantity,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: _increaseQuantity,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.product.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.product.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: burgundy, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.product.ingredients.map((ingredient) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            ingredient,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector() {
    return Row(
      children: widget.product.sizePrices.entries.map((entry) {
        final isSelected = _selectedSize == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSize = entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFDEEEC) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? burgundy : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? burgundy : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${entry.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? burgundy : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddOnsList() {
    return Column(
      children: widget.product.addOns.entries.map((entry) {
        final isChecked = _selectedAddOns.contains(entry.key);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isChecked
                  ? burgundy.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (isChecked) {
                  _selectedAddOns.remove(entry.key);
                } else {
                  _selectedAddOns.add(entry.key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isChecked ? burgundy : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '+\$${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: burgundy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Price',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                '\$${_calculatedTotalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: burgundy,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _handleAddToCart,
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 18),
            label: const Text(
              'Add to Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
