import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/dummy_data.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/helpers/product_card.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/data/favorites_manager.dart';
import 'package:angkor_burger_app/screens/favorites_screen.dart';
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

  RangeValues _priceRange = const RangeValues(0.0, 25.0);
  String _sortBy = 'Popular';

  late List<CartItem> _cartItems;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'All Items', 'icon': Icons.restaurant_menu},
    {'title': 'Burgers', 'icon': Icons.lunch_dining},
    {'title': 'Hot Dogs', 'icon': Icons.fastfood},
    {'title': 'Pizza', 'icon': Icons.local_pizza},
    {'title': 'Drinks', 'icon': Icons.local_drink},
    {'title': 'Sandwiches', 'icon': Icons.breakfast_dining},
    {'title': 'Chicken', 'icon': Icons.kebab_dining},
    {'title': 'Desserts', 'icon': Icons.icecream},
  ];

  bool get _isFilterActive =>
      _selectedCategoryIndex != 0 ||
      _priceRange.start > 0 ||
      _priceRange.end < 25.0 ||
      _sortBy != 'Popular';

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

  bool _matchesCategory(String productCategory, String selectedCategory) {
    if (selectedCategory == 'All Items' || selectedCategory == 'All') {
      return true;
    }
    final p = productCategory.toLowerCase().trim();
    final s = selectedCategory.toLowerCase().trim();
    if (p == s) return true;
    if (p.replaceAll(' ', '') == s.replaceAll(' ', '')) return true;
    if (p.endsWith('s') && p.substring(0, p.length - 1) == s) return true;
    if (s.endsWith('s') && s.substring(0, s.length - 1) == p) return true;
    if (p.contains(s) || s.contains(p)) return true;
    return false;
  }

  // Filter products by selected category, search query, and price range
  List<ProductModel> get _filteredProducts {
    final selectedCategory =
        _categories[_selectedCategoryIndex]['title'] as String;
    final list = sampleProducts.where((p) {
      final matchesCategory = _matchesCategory(p.category, selectedCategory);
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPrice =
          p.price >= _priceRange.start && p.price <= _priceRange.end;
      return matchesCategory && matchesSearch && matchesPrice;
    }).toList();

    if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Rating: High to Low') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
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

  Widget _buildPricePresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandRed : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.brandRed : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showCategoryFilterBottomSheet() {
    int tempCategoryIndex = _selectedCategoryIndex;
    RangeValues tempPriceRange = _priceRange;
    String tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final matchingCount = sampleProducts.where((p) {
              final selectedCat =
                  _categories[tempCategoryIndex]['title'] as String;
              final matchesCategory = _matchesCategory(p.category, selectedCat);
              final matchesSearch = _searchQuery.isEmpty ||
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  p.category
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
              final matchesPrice = p.price >= tempPriceRange.start &&
                  p.price <= tempPriceRange.end;
              return matchesCategory && matchesSearch && matchesPrice;
            }).length;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header with Title and Reset All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune,
                                  color: AppColors.brandRed, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Filter & Adjust',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategoryIndex = 0;
                                tempPriceRange =
                                    const RangeValues(0.0, 25.0);
                                tempSortBy = 'Popular';
                              });
                            },
                            child: Text(
                              'Reset All',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // 1. CATEGORY SECTION
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_categories.length, (index) {
                          final cat = _categories[index];
                          final title = cat['title'] as String;
                          final icon = cat['icon'] as IconData;
                          final isSelected = tempCategoryIndex == index;

                          final count = sampleProducts.where((p) {
                            return _matchesCategory(p.category, title);
                          }).length;

                          return ChoiceChip(
                            avatar: Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.brandRed,
                            ),
                            label: Text('$title ($count)'),
                            selected: isSelected,
                            selectedColor: AppColors.brandRed,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.brandRed
                                    : Colors.grey.shade200,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempCategoryIndex = index;
                                });
                              }
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 22),

                      // 2. PRICE RANGE ADJUSTMENT SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Price Range',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandLightRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${tempPriceRange.start.toStringAsFixed(1)} - \$${tempPriceRange.end.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // RangeSlider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.brandRed,
                          inactiveTrackColor: AppColors.brandLightRed,
                          thumbColor: AppColors.brandRed,
                          overlayColor:
                              AppColors.brandRed.withValues(alpha: 0.15),
                          rangeValueIndicatorShape:
                              const PaddleRangeSliderValueIndicatorShape(),
                          valueIndicatorColor: AppColors.brandRed,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: RangeSlider(
                          values: tempPriceRange,
                          min: 0.0,
                          max: 25.0,
                          divisions: 50,
                          labels: RangeLabels(
                            '\$${tempPriceRange.start.toStringAsFixed(1)}',
                            '\$${tempPriceRange.end.toStringAsFixed(1)}',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              tempPriceRange = values;
                            });
                          },
                        ),
                      ),

                      // Quick Price Preset Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPricePresetChip(
                            label: 'All (\$0-\$25)',
                            isSelected: tempPriceRange.start == 0.0 &&
                                tempPriceRange.end == 25.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange =
                                    const RangeValues(0.0, 25.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: 'Under \$4',
                            isSelected: tempPriceRange.start == 0.0 &&
                                tempPriceRange.end == 4.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange =
                                    const RangeValues(0.0, 4.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: '\$4 - \$8',
                            isSelected: tempPriceRange.start == 4.0 &&
                                tempPriceRange.end == 8.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange =
                                    const RangeValues(4.0, 8.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: '\$8 - \$15',
                            isSelected: tempPriceRange.start == 8.0 &&
                                tempPriceRange.end == 15.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange =
                                    const RangeValues(8.0, 15.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: '\$15+',
                            isSelected: tempPriceRange.start == 15.0 &&
                                tempPriceRange.end == 25.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange =
                                    const RangeValues(15.0, 25.0);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // 3. SORT BY SECTION
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Popular',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Rating: High to Low'
                        ].map((sortOption) {
                          final isSelected = tempSortBy == sortOption;
                          return ChoiceChip(
                            label: Text(sortOption),
                            selected: isSelected,
                            selectedColor: AppColors.brandRed,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.brandRed
                                    : Colors.grey.shade200,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempSortBy = sortOption;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // 4. APPLY BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryIndex = tempCategoryIndex;
                              _priceRange = tempPriceRange;
                              _sortBy = tempSortBy;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            matchingCount > 0
                                ? 'Apply Filters ($matchingCount ${matchingCount == 1 ? "Product" : "Products"})'
                                : 'Apply Filters (0 Products)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
    final String currentCategoryTitle =
        _categories[_selectedCategoryIndex]['title'] as String;
    final IconData currentCategoryIcon =
        _categories[_selectedCategoryIndex]['icon'] as IconData;

    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // 1. FLOATING HEADER / APP BAR
          AngkorAppBar(
            title: 'MENU',
            showBackButton: false,
            onFavoritePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    cartItems: _cartItems,
                    onAddToCart: _addToCart,
                    onUpdateCartQuantity: _updateCartQuantity,
                    onRemoveCartItem: _removeFromCart,
                    onClearCart: _clearCart,
                    onNavigateToTab: widget.onNavigateToTab,
                  ),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),

          // 2. SCROLLABLE BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SEARCH BAR WITH CATEGORY FILTER
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
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.grey, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _showCategoryFilterBottomSheet,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandRed,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.tune,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    if (_isFilterActive)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                        final cat = _categories[index];
                        final String title = cat['title'] as String;
                        final IconData icon = cat['icon'] as IconData;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandRed
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.brandRed,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
                      Row(
                        children: [
                          Icon(
                            currentCategoryIcon,
                            color: AppColors.brandRed,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentCategoryTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandRed,
                            ),
                          ),
                        ],
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
                          isFavorite:
                              FavoritesManager.isFavorite(currentProduct),
                          onFavoriteChanged: (isFav) {
                            setState(() {
                              FavoritesManager.setFavorite(
                                  currentProduct, isFav);
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
