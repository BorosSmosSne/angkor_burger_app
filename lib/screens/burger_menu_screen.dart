import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/models/user_profile_model.dart';
import 'package:angkor_burger_app/screens/daily_sales_screen.dart';
import 'package:angkor_burger_app/screens/staff_kitchen_screen.dart';
import 'package:angkor_burger_app/screens/staff_management_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/rest_api.dart';
import 'add_product_screen.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BurgerMenuScreen extends StatefulWidget {
  const BurgerMenuScreen({super.key});

  @override
  State<BurgerMenuScreen> createState() => _BurgerMenuScreenState();
}

class _BurgerMenuScreenState extends State<BurgerMenuScreen> {
  static const Color burgundy = Color(0xFF7A1C1C);
  static const Color scaffoldBg = Color(0xFFFBF9F9);
  int _totalBackendCategories = 0;
  late Future<List<ProductModel>> _productsFuture;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  String _searchQuery = '';
  String _selectedCategory = 'All Items';
  String _currentSort = 'Newest';

  // 0 = Catalog, 1 = Orders (Consistent for both Admin and Staff)
  int _currentBottomNavIndex = 0;

  bool get _isAdmin {
    return UserProfileManager.isAdmin ||
        RestApi.currentUserRole.toLowerCase() == 'admin';
  }

  bool get _isOrdersTabSelected => _currentBottomNavIndex == 1;

  Future<void> _quickTestLogout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('angkor.pos.token');
    await UserProfileManager.reset();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(initialIsSignUp: false),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentBottomNavIndex = 0; // Always start on Catalog
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      RestApi.fetchCategories().then((categories) {
        if (mounted && categories.isNotEmpty) {
          setState(() {
            _totalBackendCategories = categories.length;
          });
        }
      });

      _productsFuture = RestApi.fetchProducts().then((data) {
        _allProducts = data;
        _applyFilters();
        return data;
      });
    });
  }

  List<String> get _dynamicCategories {
    final Map<String, String> uniqueMap = {};
    for (final p in _allProducts) {
      final trimmed = p.category.trim();
      if (trimmed.isNotEmpty) {
        final lower = trimmed.toLowerCase();
        if (!uniqueMap.containsKey(lower)) {
          uniqueMap[lower] = trimmed;
        }
      }
    }
    final categories = uniqueMap.values.toList();
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  void _applyFilters() {
    List<ProductModel> temp = List.from(_allProducts);

    if (_selectedCategory != 'All Items') {
      temp = temp
          .where((p) =>
              p.category.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase())
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      temp = temp
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.ingredients.any((ing) => ing.toLowerCase().contains(q)))
          .toList();
    }

    switch (_currentSort) {
      case 'Newest':
        temp.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Oldest':
        temp.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'Rank':
        temp.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Price: Low to High':
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Name: A to Z':
        temp.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    setState(() {
      _filteredProducts = temp;
    });
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: burgundy),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await RestApi.deleteProduct(product.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        _loadProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildTopAppBar(),
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildCatalogTabBody(),
          const StaffKitchenScreen(showAppBar: false),
        ],
      ),
      // floatingActionButton: _currentBottomNavIndex == 0 && _isAdmin
      //     ? FloatingActionButton(
      //         backgroundColor: burgundy,
      //         shape: const CircleBorder(),
      //         elevation: 4,
      //         onPressed: () async {
      //           final result = await Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //                 builder: (context) => const AddProductScreen()),
      //           );
      //           if (result == true) _loadProducts();
      //         },
      //         child: const Icon(Icons.add, color: Colors.white, size: 28),
      //       )
      //     : null,
      // To (Visible whenever on Catalog tab):
      floatingActionButton: _currentBottomNavIndex == 0
          ? FloatingActionButton(
              backgroundColor: burgundy,
              shape: const CircleBorder(),
              elevation: 4,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddProductScreen()),
                );
                if (result == true) _loadProducts();
              },
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCatalogTabBody() {
    return RefreshIndicator(
      onRefresh: () async => _loadProducts(),
      color: burgundy,
      child: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _allProducts.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: burgundy));
          } else if (snapshot.hasError && _allProducts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    'Connection Error: ${snapshot.error}\n\nPlease check your Laravel API.'),
              ),
            );
          }

          final totalCount = _allProducts.length;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLiveApiCard(totalCount),
                const SizedBox(height: 12),
                _buildMetricsRow(),
                const SizedBox(height: 14),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildCategoryFilterRow(totalCount),
                const SizedBox(height: 16),
                _buildCatalogHeader(),
                const SizedBox(height: 8),
                if (_filteredProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No menu items found for this filter.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_filteredProducts[index]);
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo_angkorBurger.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: burgundy,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.lunch_dining, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ANGKOR BURGER',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: burgundy,
                      letterSpacing: 0.5)),
              // ✅ Dynamic User Name and Role Badge
              ValueListenableBuilder<UserProfileModel>(
                valueListenable: UserProfileManager.profileNotifier,
                builder: (context, profile, _) {
                  final String displayName =
                      profile.name.isNotEmpty ? profile.name : 'User';
                  final String roleLabel = _isAdmin ? 'ADMIN' : 'STAFF';

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _isAdmin
                              ? const Color(0xFFFDEEEC)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _isAdmin ? burgundy : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Text(
              //     _isOrdersTabSelected
              //         ? 'Kitchen & Orders Display'
              //         : (_isAdmin
              //             ? 'Menu Catalog (Admin)'
              //             : 'Staff Menu Catalog'),
              //     style: const TextStyle(
              //         fontSize: 12,
              //         color: Colors.black54,
              //         fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        if (_isAdmin)
          IconButton(
            tooltip: 'Staff Management',
            icon: const Icon(Icons.badge_outlined, color: burgundy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StaffManagementScreen(),
                ),
              );
            },
          ),
        // IconButton(
        //   icon: Icon(
        //     _isOrdersTabSelected
        //         ? Icons.restaurant_menu
        //         : Icons.assignment_ind_outlined,
        //     color: burgundy,
        //   ),
        //   tooltip: _isOrdersTabSelected ? 'Back to Catalog' : 'Kitchen Orders',
        //   onPressed: () {
        //     setState(() {
        //       _currentBottomNavIndex = _isOrdersTabSelected ? 0 : 1;
        //     });
        //   },
        // ),
        PopupMenuButton<String>(
          tooltip: 'Account Menu',
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: burgundy,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          onSelected: (value) {
            if (value == 'home') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else if (value == 'staff') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StaffManagementScreen()),
              );
            } else if (value == 'logout') {
              _quickTestLogout();
            }
          },
          itemBuilder: (context) => [
            if (_isAdmin)
              const PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, color: Colors.black87, size: 18),
                    SizedBox(width: 8),
                    Text('Customer View', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            if (_isAdmin)
              const PopupMenuItem(
                value: 'staff',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.black87, size: 18),
                    SizedBox(width: 8),
                    Text('Staff Management', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Log Out',
                      style: TextStyle(fontSize: 13, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLiveApiCard(int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEEC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lunch_dining, color: burgundy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Menu Inventory',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 6),
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                  ],
                ),
                Text('Live API Products • $totalCount Items',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          InkWell(
            onTap: _loadProducts,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, size: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final totalCount = _allProducts.length;
    final realCategoryCount = _totalBackendCategories > 0
        ? _totalBackendCategories
        : _dynamicCategories.length;

    final activeCount = _allProducts.where((p) => p.isActive).length;
    final inactiveCount = _allProducts.where((p) => !p.isActive).length;
    final popularCount = _allProducts.where((p) => p.isPopular).length;
    final inStockCount = _allProducts.where((p) => p.isInStock).length;
    final outOfStockCount = _allProducts.where((p) => !p.isInStock).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DailySalesScreen()),
            );
          },
          child: _buildMetricCard(
            title: 'ORDERS & SALES',
            value: 'Daily Summary',
            subtext: 'Tap to view daily revenue & count',
            badgeText: 'Reports',
            badgeColor: Colors.deepOrange,
            icon: Icons.analytics_outlined,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: _buildMetricCard(
                title: 'CATALOG',
                value: '$totalCount Products',
                subtext: '$activeCount Active',
                badgeText: 'Synced',
                badgeColor: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 1,
              child: _buildMetricCard(
                title: 'CATEGORIES',
                value: '$realCategoryCount Active',
                subtext: 'Live from API',
                badgeText: 'Updated',
                badgeColor: Colors.blue,
                icon: Icons.restaurant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: _buildMetricCard(
                title: 'POPULAR',
                value: '$popularCount Items',
                subtext: 'Featured',
                badgeText: 'Top Rank',
                badgeColor: Colors.orange,
                icon: Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 1,
              child: _buildMetricCard(
                title: 'INACTIVE',
                value: '$inactiveCount Items',
                subtext: 'Draft / Hidden',
                badgeText: inactiveCount > 0 ? 'Review' : 'Clean',
                badgeColor: inactiveCount > 0 ? Colors.redAccent : Colors.grey,
                icon: Icons.visibility_off,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: _buildMetricCard(
                title: 'IN STOCK',
                value: '$inStockCount Available',
                subtext: 'Ready to order',
                badgeText: 'Kitchen Ready',
                badgeColor: Colors.teal,
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 1,
              child: _buildMetricCard(
                title: 'OUT OF STOCK',
                value: '$outOfStockCount Sold Out',
                subtext: 'Restock needed',
                badgeText: outOfStockCount > 0 ? 'Alert' : 'None',
                badgeColor:
                    outOfStockCount > 0 ? Colors.deepOrange : Colors.grey,
                icon: Icons.remove_shopping_cart_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(icon, size: 14, color: badgeColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        onChanged: (val) {
          _searchQuery = val;
          _applyFilters();
        },
        decoration: const InputDecoration(
          hintText: 'Search menu items by name, category...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow(int totalCount) {
    final categories = _dynamicCategories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPill('All Items ($totalCount)', 'All Items'),
          const SizedBox(width: 8),
          ...categories.map((cat) {
            final count = _allProducts
                .where(
                    (p) => p.category.trim().toLowerCase() == cat.toLowerCase())
                .length;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildPill('$cat ($count)', cat),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPill(String title, String categoryKey) {
    final isSelected = _selectedCategory == categoryKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryKey;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? burgundy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: isSelected ? burgundy : Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Main Catalog List',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_filteredProducts.length} Loaded',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 32),
          child: PopupMenuButton<String>(
            tooltip: 'Sort by',
            padding: EdgeInsets.zero,
            initialValue: _currentSort,
            onSelected: (String value) {
              setState(() {
                _currentSort = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'Newest',
                  child: Text('Newest Added', style: TextStyle(fontSize: 12))),
              PopupMenuItem(
                  value: 'Oldest',
                  child: Text('Oldest Added', style: TextStyle(fontSize: 12))),
              PopupMenuItem(
                  value: 'Rank',
                  child: Text('Sort by Rank (Rating)',
                      style: TextStyle(fontSize: 12))),
              PopupMenuItem(
                  value: 'Price: Low to High',
                  child: Text('Price: Low to High',
                      style: TextStyle(fontSize: 12))),
              PopupMenuItem(
                  value: 'Price: High to Low',
                  child: Text('Price: High to Low',
                      style: TextStyle(fontSize: 12))),
              PopupMenuItem(
                  value: 'Name: A to Z',
                  child: Text('Name: A to Z', style: TextStyle(fontSize: 12))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort by $_currentSort',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel burger) {
    Widget badge;
    if (burger.isPopular) {
      badge = _buildTag('Popular', const Color(0xFFFDEEEC), burgundy);
    } else if (burger.category.toLowerCase().contains('wing') ||
        burger.name.toLowerCase().contains('wing')) {
      badge = _buildTag(
          'Chef Choice', const Color(0xFFFFF7E6), const Color(0xFFD48806));
    } else if (burger.category.toLowerCase().contains('side') ||
        burger.name.toLowerCase().contains('potato') ||
        burger.price < 5.0) {
      badge = _buildTag('Side', Colors.grey.shade100, Colors.black54);
    } else {
      badge = _buildTag('Standard', Colors.grey.shade100, Colors.black54);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildBurgerImage(burger.imagePath),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 9),
                      const SizedBox(width: 2),
                      Text(burger.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        burger.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 6),
                    badge,
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('\$${burger.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: burgundy)),
                    const Text(' • ',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Flexible(
                      child: Text(
                        burger.nutritionFacts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${burger.sizePrices.length} Sizes (${burger.sizePrices.keys.join(', ')}) • ${burger.addOns.length} Add-ons',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
          // if (_isAdmin)
          //   Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       InkWell(
          //         onTap: () async {
          //           final result = await Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) =>
          //                   AddProductScreen(existingProduct: burger),
          //             ),
          //           );
          //           if (result == true) _loadProducts();
          //         },
          //         borderRadius: BorderRadius.circular(16),
          //         child: Container(
          //           padding: const EdgeInsets.all(6),
          //           decoration: const BoxDecoration(
          //               color: Color(0xFFFDEEEC), shape: BoxShape.circle),
          //           child: const Icon(Icons.edit_outlined,
          //               size: 14, color: burgundy),
          //         ),
          //       ),
          //       const SizedBox(width: 6),
          //       InkWell(
          //         onTap: () => _confirmDelete(burger),
          //         borderRadius: BorderRadius.circular(16),
          //         child: Container(
          //           padding: const EdgeInsets.all(6),
          //           decoration: BoxDecoration(
          //               color: Colors.grey.shade100, shape: BoxShape.circle),
          //           child: const Icon(Icons.delete_outline,
          //               size: 14, color: Colors.grey),
          //         ),
          //       ),
          //     ],
          //   ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddProductScreen(existingProduct: burger),
                    ),
                  );
                  if (result == true) _loadProducts();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Color(0xFFFDEEEC), shape: BoxShape.circle),
                  child: const Icon(Icons.edit_outlined,
                      size: 14, color: burgundy),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _confirmDelete(burger),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline,
                      size: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 8.5, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildBurgerImage(String path) {
    String clean = path.trim();

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        clean = clean
            .replaceAll('127.0.0.1:8000', '10.0.2.2:8000')
            .replaceAll('localhost:8000', '10.0.2.2:8000');
      }

      final safeUrl = Uri.encodeFull(clean);

      return CachedNetworkImage(
        imageUrl: safeUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => Container(
          color: const Color(0xFFFDEEEC),
          child: const Center(
            child: Icon(Icons.lunch_dining, color: Color(0xFF7A1C1C), size: 22),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/images/imagelist1.jpg',
          fit: BoxFit.cover,
        ),
      );
    }

    String assetPath = clean;
    if (assetPath.startsWith('assets/assets/')) {
      assetPath = assetPath.replaceFirst('assets/assets/', 'assets/');
    } else if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }

    if (assetPath.contains('burger.png') ||
        assetPath.contains('wings.png') ||
        assetPath.isEmpty) {
      assetPath = 'assets/images/imagelist1.jpg';
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/imagelist1.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: burgundy,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Catalog',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Orders',
        ),
      ],
    );
  }
}
