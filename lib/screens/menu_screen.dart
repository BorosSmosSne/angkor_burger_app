import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/dummy_data.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/helpers/product_card.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/order_screen.dart';
import 'package:angkor_burger_app/screens/product_detail_screen.dart';
import 'package:angkor_burger_app/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  final List<CartItem>? cartItems;
  final Function(CartItem item)? onAddToCart;
  final Function(CartItem item, int newQuantity)? onUpdateCartQuantity;
  final Function(CartItem item)? onRemoveCartItem;
  final VoidCallback? onClearCart;
  final bool showBottomNav;
  final Function(int tabIndex)? onNavigateToTab;

  const MenuScreen({
    super.key,
    this.cartItems,
    this.onAddToCart,
    this.onUpdateCartQuantity,
    this.onRemoveCartItem,
    this.onClearCart,
    this.showBottomNav = true,
    this.onNavigateToTab,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favoriteProductNames = {};

  late List<CartItem> _cartItems;

  final List<String> _categories = [
    'All Items',
    'Burgers',
    'Hot Dogs',
    'Pizzas',
    'Drinks',
    'Sandwichs',
    'Chickens',
    'Desserts'
  ];

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems ?? [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter products by selected category and search query
  List<ProductModel> get _filteredProducts {
    final selectedCategory = _categories[_selectedCategoryIndex];
    return sampleProducts.where((p) {
      final bool matchesCategory;
      if (selectedCategory == 'All Items' || selectedCategory == 'All') {
        matchesCategory = true;
      } else {
        final sel = selectedCategory.toLowerCase();
        final pCat = p.category.toLowerCase();
        matchesCategory = sel == pCat ||
            (sel == 'pizzas' && pCat == 'pizza') ||
            (sel == 'sandwichs' && pCat == 'sandwiches') ||
            (sel == 'chickens' && pCat == 'chicken') ||
            sel.startsWith(pCat) ||
            pCat.startsWith(sel);
      }
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
  // CART STATE MANAGEMENT METHODS
  // ==========================================================================

  void _addToCart(CartItem item) {
    if (widget.onAddToCart != null) {
      widget.onAddToCart!(item);
      setState(() {});
      return;
    }
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
    if (widget.onUpdateCartQuantity != null) {
      widget.onUpdateCartQuantity!(item, newQuantity);
      setState(() {});
      return;
    }
    setState(() {
      item.quantity = newQuantity;
    });
  }

  void _removeFromCart(CartItem item) {
    if (widget.onRemoveCartItem != null) {
      widget.onRemoveCartItem!(item);
      setState(() {});
      return;
    }
    setState(() {
      _cartItems.remove(item);
    });
  }

  void _clearCart() {
    if (widget.onClearCart != null) {
      widget.onClearCart!();
      setState(() {});
      return;
    }
    setState(() {
      _cartItems.clear();
    });
  }

  void _navigateToCart() {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(2);
      return;
    }
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

  void _showCartSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        content: Row(
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
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_totalCartItems ${_totalCartItems == 1 ? "item" : "items"} in cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '\$${_totalCartPrice.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandRed,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _navigateToCart();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Cart',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(index);
      return;
    }
    if (index == 0) {
      // Home Tab
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (index == 1) {
      // Menu Tab (already here, reset selection)
      setState(() {
        _selectedCategoryIndex = 0;
        _searchController.clear();
        _searchQuery = '';
      });
    } else if (index == 2) {
      // Cart Tab
      _navigateToCart();
    } else if (index == 3) {
      // Orders Tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(
            cartItems: _cartItems,
            onAddToCart: _addToCart,
            onUpdateCartQuantity: _updateCartQuantity,
            onRemoveCartItem: _removeFromCart,
            onClearCart: _clearCart,
          ),
        ),
      );
    } else if (index == 4) {
      // Profile Tab
      _navigateToProfile();
    }
  }

  void _navigateToProfile() {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(4);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          cartItems: _cartItems,
          onAddToCart: _addToCart,
          onUpdateCartQuantity: _updateCartQuantity,
          onRemoveCartItem: _removeFromCart,
          onClearCart: _clearCart,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // 1. FLOATING HEADER / APP BAR
          AngkorAppBar(
            title: 'ANGKOR BURGER',
            totalCartItems: _totalCartItems,
            showBackButton: false,
            onBackPressed: () => Navigator.pop(context),
            onCartPressed: _navigateToCart,
            onProfilePressed: _navigateToProfile,
          ),

          // 2. SCROLLABLE BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SEARCH BAR
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
                        hintText: 'Search menu items (e.g. Burger, Pizza)...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CATEGORY HORIZONTAL SELECTOR
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = _selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandRed
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.brandColor
                                    : Colors.black54,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CATEGORY TITLE AND ITEM COUNT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _categories[_selectedCategoryIndex],
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
                  const SizedBox(height: 14),

                  // PRODUCTS GRID
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
                        return ProductCard(
                          product: currentProduct,
                          onTap: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
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
                            ).then((result) {
                              if (mounted) {
                                setState(() {});
                                if (result == true) {
                                  Future.microtask(() {
                                    if (mounted) {
                                      _showCartSnackBar();
                                    }
                                  });
                                }
                              }
                            });
                          },
                          onAddToCart: () {
                            final defaultSize = currentProduct.sizePrices
                                    .containsKey('M')
                                ? 'M'
                                : (currentProduct.sizePrices.keys.firstOrNull ??
                                    'M');
                            final unitPrice =
                                currentProduct.sizePrices[defaultSize] ??
                                    currentProduct.price;
                            _addToCart(
                              CartItem(
                                product: currentProduct,
                                quantity: 1,
                                selectedSize: defaultSize,
                                unitPrice: unitPrice,
                              ),
                            );
                            _showCartSnackBar();
                          },
                          isFavorite: _favoriteProductNames
                              .contains(currentProduct.name),
                          onFavoriteChanged: (isFav) {
                            setState(() {
                              if (isFav) {
                                _favoriteProductNames.add(currentProduct.name);
                              } else {
                                _favoriteProductNames
                                    .remove(currentProduct.name);
                              }
                            });
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: 1,
              cartItemCount: _totalCartItems,
              onItemTapped: _onBottomNavTapped,
            )
          : null,
    );
  }
}
