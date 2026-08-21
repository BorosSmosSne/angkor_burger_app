import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/dummy_data.dart';
import 'package:angkor_burger_app/helpers/product_card.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/product_detail_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List of Banner Images for Carousel Slider
  

  int _currentBannerIndex = 0;
  final Set<String> _favoriteProductNames = {};
  final List<CartItem> _cartItems = [];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  

  final List<Map<String, dynamic>> _categories = [
    {'title': 'All', 'icon': Icons.restaurant_menu},
    {'title': 'Burgers', 'icon': Icons.lunch_dining},
    {'title': 'Hot Dogs', 'icon': Icons.fastfood},
    {'title': 'Pizza', 'icon': Icons.local_pizza},
    {'title': 'Drinks', 'icon': Icons.local_drink},
    {'title': 'Sandwiches', 'icon': Icons.breakfast_dining},
    {'title': 'Chicken', 'icon': Icons.kebab_dining},
    {'title': 'Desserts', 'icon': Icons.icecream},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter products by selected category and search query
  List<ProductModel> get _filteredProducts {
    return sampleProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _totalCartItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _totalCartPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // ==========================================================================
  // CART STATE MANAGEMENT METHODS (StatefulWidget & setState)
  // ==========================================================================

  void _addToCart(CartItem item) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (i) =>
            i.product.name == item.product.name &&
            i.selectedSize == item.selectedSize &&
            _areAddOnsEqual(i.selectedAddOns, item.selectedAddOns),
      );

      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity += item.quantity;
      } else {
        _cartItems.add(item);
      }
    });
  }

  bool _areAddOnsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  void _updateCartQuantity(CartItem item, int newQuantity) {
    setState(() {
      item.quantity = newQuantity;
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cartItems.remove(item);
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          onUpdateQuantity: _updateCartQuantity,
          onRemoveItem: _removeFromCart,
          onClearCart: _clearCart,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  // ==========================================================================
  // HELPER FUNCTIONS (WIDGET BUILDERS)
  // ==========================================================================

  // Helper function to build animated bouncing buttons
  Widget _buildAnimatedButton({
    required Widget child,
    VoidCallback? onPressed,
    double scaleFactor = 0.95,
    Duration duration = const Duration(milliseconds: 120),
  }) {
    return _AnimatedButton(
      onPressed: onPressed,
      scaleFactor: scaleFactor,
      duration: duration,
      child: child,
    );
  }

  // Helper function to build category pills
  Widget _buildCategoryPill({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final effectiveBrandRed =
        isSelected ? Colors.white : AppColors.brandRed;
    final effectiveBg =
        isSelected ? AppColors.brandRed : AppColors.brandLightRed;

    return _buildAnimatedButton(
      onPressed: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.brandRed.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: effectiveBrandRed, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              fontSize: 12,
              color: isSelected ? AppColors.brandRed : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build product card using helper/product_card.dart
  Widget _buildProductCard(ProductModel product) {
    return ProductCard(
      product: product,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: product,
              onAddToCart: _addToCart,
              cartItems: _cartItems,
              onUpdateCartQuantity: _updateCartQuantity,
              onRemoveCartItem: _removeFromCart,
              onClearCart: _clearCart,
            ),
          ),
        ).then((_) => setState(() {}));
      },
      onAddToCart: () {
        final defaultSize =
            product.sizePrices.containsKey('M') ? 'M' : (product.sizePrices.keys.firstOrNull ?? 'M');
        final unitPrice = product.sizePrices[defaultSize] ?? product.price;
        _addToCart(
          CartItem(
            product: product,
            quantity: 1,
            selectedSize: defaultSize,
            unitPrice: unitPrice,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added 1x ${product.name} to cart!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.brandRed,
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: _navigateToCart,
            ),
          ),
        );
      },
      isFavorite: _favoriteProductNames.contains(product.name),
      onFavoriteChanged: (isFav) {
        setState(() {
          if (isFav) {
            _favoriteProductNames.add(product.name);
          } else {
            _favoriteProductNames.remove(product.name);
          }
        });
      },
    );
  }

  // Helper function to build slider dots
  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color:
            isActive ? AppColors.brandRed : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // ==========================================
          // 1. FLOATING WHITE HEADER CONTAINER
          // ==========================================
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side: Logo & Text
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo_angkorBurger.png',
                        height: 38,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.lunch_dining, size: 36),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ANGKOR BURGER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandRed,
                        ),
                      ),
                    ],
                  ),
                  // Right Side: Cart Icon with live Badge & Profile Icon
                  Row(
                    children: [
                      _buildAnimatedButton(
                        onPressed: _navigateToCart,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                            if (_totalCartItems > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$_totalCartItems',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAnimatedButton(
                        onPressed: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 2. SEARCH BAR (TextField)
                  // ==========================================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search menu items (e.g. Truffle, Royal)...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandRed,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. MAIN PROMO BANNER (CAROUSEL SLIDER)
                  // ==========================================
                  Card(
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 180,
                            autoPlay: true,
                            viewportFraction: 1.0,
                            autoPlayInterval: const Duration(seconds: 4),
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                          ),
                          items: bannerImages.map((imagePath) {
                            return Image.asset(
                              imagePath,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image, size: 48),
                              ),
                            );
                          }).toList(),
                        ),
                        // Dynamic Pagination Dots
                        Positioned(
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: bannerImages.asMap().entries.map((entry) {
                              return _buildDot(
                                isActive: _currentBannerIndex == entry.key,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ==========================================
                  // 4. CATEGORIES (Horizontal ListView)
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedCategory != 'All')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Text(
                            'Show All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandRed,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final title = cat['title'] as String;
                        final icon = cat['icon'] as IconData;
                        return _buildCategoryPill(
                          title: title,
                          icon: icon,
                          isSelected: _selectedCategory == title,
                          onTap: () {
                            setState(() {
                              _selectedCategory = title;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 5. POPULAR PRODUCTS (GridView)
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All'
                            ? 'Popular Burgers'
                            : '$_selectedCategory (${_filteredProducts.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandRed,
                        ),
                      ),
                      Text(
                        '${_filteredProducts.length} items',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_filteredProducts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off,
                                size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No products found matching "$_searchQuery"',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 173 / 259,
                      ),
                      itemBuilder: (context, index) {
                        final currentProduct = _filteredProducts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: currentProduct,
                                  onAddToCart: _addToCart,
                                  cartItems: _cartItems,
                                  onUpdateCartQuantity: _updateCartQuantity,
                                  onRemoveCartItem: _removeFromCart,
                                  onClearCart: _clearCart,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: _buildProductCard(currentProduct),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Floating Cart Status Bar if Cart is not empty
          if (_totalCartItems > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.brandLightRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.brandRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_totalCartItems ${_totalCartItems == 1 ? "item" : "items"} in cart',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '\$${_totalCartPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _navigateToCart,
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// INTERNAL ANIMATED SCALE BUTTON WRAPPER
// ============================================================================
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleFactor;
  final Duration duration;

  const _AnimatedButton({
    required this.child,
    this.onPressed,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) return widget.child;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

