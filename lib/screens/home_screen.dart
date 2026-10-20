import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/dummy_data.dart';
import 'package:angkor_burger_app/data/favorites_manager.dart';
import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/custom_bottom_nav_bar.dart';
import 'package:angkor_burger_app/helpers/product_card.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/models/user_profile_model.dart';
import 'package:angkor_burger_app/screens/cart_screen.dart';
import 'package:angkor_burger_app/screens/favorites_screen.dart';
import 'package:angkor_burger_app/screens/menu_screen.dart';
import 'package:angkor_burger_app/screens/order_screen.dart';
import 'package:angkor_burger_app/screens/product_detail_screen.dart';
import 'package:angkor_burger_app/screens/user_profile_screen.dart';
import 'package:angkor_burger_app/services/rest_api.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:angkor_burger_app/screens/burger_menu_screen.dart';
import 'package:angkor_burger_app/screens/staff_kitchen_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;
  final List<CartItem> _cartItems = [];

  List<ProductModel> _loadedProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  RangeValues _priceRange = const RangeValues(0.0, 25.0);
  String _sortBy = 'Default';

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
  void initState() {
    super.initState();
    FavoritesManager.loadUserFavorites(); // Load this specific user's favorites
    _checkStaffRedirect();
    _fetchLiveProducts();
  }

  Future<void> _checkStaffRedirect() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedRole =
          (prefs.getString('angkor.pos.user_role') ??
                  prefs.getString('user_role') ??
                  UserProfileManager.profileNotifier.value.role)
              .toLowerCase();

      final currentRole = UserProfileManager.profileNotifier.value.role
          .toLowerCase();

      if (savedRole == 'staff' && currentRole == 'staff') {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BurgerMenuScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _fetchLiveProducts() async {
    try {
      final products = await RestApi.fetchProducts();
      if (mounted) {
        setState(() {
          _loadedProducts = products.where((p) => p.isActive).toList();
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  bool get _isFilterActive =>
      _selectedCategory != 'All' ||
      _priceRange.start > 0 ||
      _priceRange.end < 25.0 ||
      _sortBy != 'Default';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(String productCategory, String selectedCategory) {
    if (selectedCategory == 'All') return true;
    final p = productCategory.toLowerCase().trim();
    final s = selectedCategory.toLowerCase().trim();
    if (p == s) return true;
    if (p.replaceAll(' ', '') == s.replaceAll(' ', '')) return true;
    if (p.endsWith('s') && p.substring(0, p.length - 1) == s) return true;
    if (s.endsWith('s') && s.substring(0, s.length - 1) == p) return true;
    if (p.contains(s) || s.contains(p)) return true;
    return false;
  }

  List<ProductModel> get _filteredProducts {
    final list = _loadedProducts.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          _matchesCategory(p.category, _selectedCategory);
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesPrice =
          p.price >= _priceRange.start && p.price <= _priceRange.end;

      // ✅ Only filter by isPopular if the user specifically chose 'Popular'
      final matchesPopular = (_sortBy != 'Popular') || p.isPopular;

      return matchesCategory && matchesSearch && matchesPrice && matchesPopular;
    }).toList();

    if (_sortBy == 'Popular') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Price: Low to High') {
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
    _onBottomNavTapped(2);
  }

  void _onBottomNavTapped(int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() {
      _selectedNavIndex = index;
    });
  }

  void _showCategoryFilterBottomSheet() {
    String tempCategory = _selectedCategory;
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
            final matchingCount = _loadedProducts.where((p) {
              final matchesCategory =
                  tempCategory == 'All' ||
                  _matchesCategory(p.category, tempCategory);
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  p.category.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesPrice =
                  p.price >= tempPriceRange.start &&
                  p.price <= tempPriceRange.end;

              // ✅ Include popular filter in sheet count
              final matchesPopular = (tempSortBy != 'Popular') || p.isPopular;

              return matchesCategory &&
                  matchesSearch &&
                  matchesPrice &&
                  matchesPopular;
            }).length;

            return DraggableScrollableSheet(
              initialChildSize: 0.82,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.tune,
                                color: AppColors.brandRed,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Filter & Adjust',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategory = 'All';
                                tempPriceRange = const RangeValues(0.0, 25.0);
                                tempSortBy = 'Default';
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
                        children: _categories.map((cat) {
                          final title = cat['title'] as String;
                          final isSelected = tempCategory == title;
                          return ChoiceChip(
                            label: Text(title),
                            selected: isSelected,
                            selectedColor: AppColors.brandRed,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
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
                              setModalState(() {
                                tempCategory = title;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
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
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.brandRed,
                          inactiveTrackColor: AppColors.brandLightRed,
                          thumbColor: AppColors.brandRed,
                          overlayColor: AppColors.brandRed.withValues(
                            alpha: 0.15,
                          ),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPricePresetChip(
                            label: 'All (\$0-\$25)',
                            isSelected:
                                tempPriceRange.start == 0.0 &&
                                tempPriceRange.end == 25.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange = const RangeValues(0.0, 25.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: 'Under \$4',
                            isSelected:
                                tempPriceRange.start == 0.0 &&
                                tempPriceRange.end == 4.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange = const RangeValues(0.0, 4.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: '\$4 - \$8',
                            isSelected:
                                tempPriceRange.start == 4.0 &&
                                tempPriceRange.end == 8.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange = const RangeValues(4.0, 8.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: '\$8 - \$15',
                            isSelected:
                                tempPriceRange.start == 8.0 &&
                                tempPriceRange.end == 15.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange = const RangeValues(8.0, 15.0);
                              });
                            },
                          ),
                          _buildPricePresetChip(
                            label: '\$15+',
                            isSelected:
                                tempPriceRange.start == 15.0 &&
                                tempPriceRange.end == 25.0,
                            onTap: () {
                              setModalState(() {
                                tempPriceRange = const RangeValues(15.0, 25.0);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
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
                        children:
                            [
                              'Default',
                              'Popular',
                              'Price: Low to High',
                              'Price: High to Low',
                              'Rating: High to Low',
                            ].map((sortOption) {
                              final isSelected = tempSortBy == sortOption;
                              return ChoiceChip(
                                label: Text(sortOption),
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
                                      tempSortBy = sortOption;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
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

  Widget _buildCategoryPill({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final effectiveBrandRed = isSelected ? Colors.white : AppColors.brandRed;
    final effectiveBg = isSelected
        ? AppColors.brandRed
        : AppColors.brandLightRed;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brandRed.withValues(alpha: 0.35),
                          blurRadius: 10,
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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: isSelected ? AppColors.brandRed : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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

  Widget _buildProductCard(ProductModel product) {
    return ProductCard(
      product: product,
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
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
        final defaultSize = product.sizePrices.containsKey('M')
            ? 'M'
            : (product.sizePrices.keys.firstOrNull ?? 'M');
        final unitPrice = product.sizePrices[defaultSize] ?? product.price;
        _addToCart(
          CartItem(
            product: product,
            quantity: 1,
            selectedSize: defaultSize,
            unitPrice: unitPrice,
          ),
        );
        _showCartSnackBar();
      },
      isFavorite: FavoritesManager.isFavorite(product),
      onFavoriteChanged: (isFav) {
        setState(() {
          FavoritesManager.setFavorite(product, isFav);
        });
      },
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.brandRed
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        cartItemCount: _totalCartItems,
        onItemTapped: _onBottomNavTapped,
      ),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildHomeTab(),
          MenuScreen(
            cartItems: _cartItems,
            onAddToCart: _addToCart,
            onUpdateCartQuantity: _updateCartQuantity,
            onRemoveCartItem: _removeFromCart,
            onClearCart: _clearCart,
            showBottomNav: false,
            onNavigateToTab: _onBottomNavTapped,
          ),
          CartScreen(
            cartItems: _cartItems,
            onUpdateQuantity: _updateCartQuantity,
            onRemoveItem: _removeFromCart,
            onClearCart: _clearCart,
            showBottomNav: false,
            showBackButton: false,
            onNavigateToTab: _onBottomNavTapped,
            onContinueShopping: () => _onBottomNavTapped(0),
          ),
          // ✅ Tab 3 in HomeScreen is ALWAYS Customer Orders:
          OrderScreen(
            cartItems: _cartItems,
            onAddToCart: _addToCart,
            onUpdateCartQuantity: _updateCartQuantity,
            onRemoveCartItem: _removeFromCart,
            onClearCart: _clearCart,
            showBottomNav: false,
            onNavigateToTab: _onBottomNavTapped,
          ),
          UserProfileScreen(
            cartItems: _cartItems,
            onAddToCart: _addToCart,
            onUpdateCartQuantity: _updateCartQuantity,
            onRemoveCartItem: _removeFromCart,
            onClearCart: _clearCart,
            showBottomNav: false,
            onNavigateToTab: _onBottomNavTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        ValueListenableBuilder<UserProfileModel>(
          valueListenable: UserProfileManager.profileNotifier,
          builder: (context, profile, _) {
            return AngkorAppBar(
              actions: [
                if (UserProfileManager.isAdmin)
                  IconButton(
                    tooltip: 'Manage Catalog (Admin)',
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF7A1C1C),
                      size: 22,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BurgerMenuScreen(),
                        ),
                      );
                    },
                  )
                else ...[
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  // Reactive Favorite Button with Count Badge & Color Change
                  ValueListenableBuilder<Set<String>>(
                    valueListenable:
                        FavoritesManager.favoriteProductNamesNotifier,
                    builder: (context, favNames, _) {
                      final int count = favNames.length;
                      final bool hasFavorites = count > 0;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoritesScreen(
                                cartItems: _cartItems,
                                onAddToCart: _addToCart,
                                onUpdateCartQuantity: _updateCartQuantity,
                                onRemoveCartItem: _removeFromCart,
                                onClearCart: _clearCart,
                                onNavigateToTab: _onBottomNavTapped,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Circular background bubble (Peach/Pink when active, Grey when empty)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: hasFavorites
                                      ? const Color(0xFFFDEEEC)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasFavorites
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: hasFavorites
                                      ? const Color(0xFF7A1C1C)
                                      : Colors.black87,
                                  size: 20,
                                ),
                              ),

                              // Red notification count badge
                              if (hasFavorites)
                                Positioned(
                                  top: -2,
                                  right: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7A1C1C),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(width: 8),
              ],
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
                      onNavigateToTab: _onBottomNavTapped,
                    ),
                  ),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              },
            );
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                                        borderRadius: BorderRadius.circular(10),
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
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CarouselSlider(
                  items: bannerImages.map((imagePath) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image, size: 48),
                              ),
                        ),
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 180,
                    autoPlay: true,
                    viewportFraction: 1.0,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 800,
                    ),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: bannerImages.asMap().entries.map((entry) {
                    return _buildDot(
                      isActive: _currentBannerIndex == entry.key,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
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
                      GestureDetector(
                        onTap: () {
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
                            if (_selectedCategory == title && title != 'All') {
                              _selectedCategory = 'All';
                            } else {
                              _selectedCategory = title;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'All'
                          ? 'All Products'
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
                if (_isFilterActive) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        if (_selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(_selectedCategory),
                              selected: true,
                              selectedColor: AppColors.brandLightRed,
                              labelStyle: const TextStyle(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              deleteIconColor: AppColors.brandRed,
                              onDeleted: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                });
                              },
                            ),
                          ),
                        if (_priceRange.start > 0 || _priceRange.end < 25.0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              avatar: const Icon(
                                Icons.attach_money,
                                size: 14,
                                color: AppColors.brandRed,
                              ),
                              label: Text(
                                '\$${_priceRange.start.toStringAsFixed(1)} - \$${_priceRange.end.toStringAsFixed(1)}',
                              ),
                              selected: true,
                              selectedColor: AppColors.brandLightRed,
                              labelStyle: const TextStyle(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              deleteIconColor: AppColors.brandRed,
                              onDeleted: () {
                                setState(() {
                                  _priceRange = const RangeValues(0.0, 25.0);
                                });
                              },
                            ),
                          ),
                        if (_sortBy != 'Default')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              avatar: const Icon(
                                Icons.sort,
                                size: 14,
                                color: Colors.black87,
                              ),
                              label: Text(_sortBy),
                              selected: false,
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              deleteIconColor: Colors.black54,
                              onDeleted: () {
                                setState(() {
                                  _sortBy = 'Default';
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandRed,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load products:\n$_errorMessage',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _fetchLiveProducts();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandRed,
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredProducts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No products found matching "$_searchQuery"'
                                : 'No products found for the selected category/price filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = 'All';
                                _priceRange = const RangeValues(0.0, 25.0);
                                _sortBy = 'Default';
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            icon: const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Reset All Filters',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
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
                      return _buildProductCard(currentProduct);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
