import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/rest_api.dart';
import 'add_product_screen.dart';

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
  int _currentBottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      // 1. Fetch real category count directly from Laravel GET /api/categories
      RestApi.fetchCategories().then((categories) {
        if (mounted && categories.isNotEmpty) {
          setState(() {
            _totalBackendCategories = categories.length;
          });
        }
      });

      // 2. Fetch products
      _productsFuture = RestApi.fetchProducts().then((data) {
        _allProducts = data;
        _applyFilters();
        return data;
      });
    });
  }

  // Extract all unique categories dynamically from the loaded products
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

    // 1. Dynamic Category Filter
    if (_selectedCategory != 'All Items') {
      temp = temp
          .where((p) =>
              p.category.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase())
          .toList();
    }

    // 2. Search Query Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      temp = temp
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.ingredients.any((ing) => ing.toLowerCase().contains(q)))
          .toList();
    }

    // 3. Sorting Logic
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildTopAppBar(),
      body: RefreshIndicator(
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
                  // 1. Live API Status Banner
                  _buildLiveApiCard(totalCount),
                  const SizedBox(height: 12),

                  // 2. Metrics 2x2 Grid (Passes no arguments)
                  _buildMetricsRow(),
                  const SizedBox(height: 14),

                  // 3. Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 12),

                  // 4. Dynamic Category Filter Tabs
                  _buildCategoryFilterRow(totalCount),
                  const SizedBox(height: 16),

                  // 5. Catalog List Header & Sort (with bounded, hit-testable popup button)
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: burgundy,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          if (result == true) _loadProducts();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: burgundy,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.lunch_dining, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ANGKOR BURGER',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: burgundy,
                      letterSpacing: 0.5)),
              Text('Menu Catalog',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {}),
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: burgundy,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
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

  // 2x2 Grid that calculates its counts internally with bounded Flexible widgets
  Widget _buildMetricsRow() {
    final totalCount = _allProducts.length;

    // Use live database count; fall back to product categories if 0
    final realCategoryCount = _totalBackendCategories > 0
        ? _totalBackendCategories
        : _dynamicCategories.length;

    final activeCount = _allProducts.where((p) => p.isActive).length;
    final inactiveCount = _allProducts.where((p) => !p.isActive).length;
    final popularCount = _allProducts.where((p) => p.isPopular).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          // 1. "All Items" Pill
          _buildPill('All Items ($totalCount)', 'All Items'),
          const SizedBox(width: 8),

          // 2. Dynamically Generated Pills for each category in the database
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
        // Explicit hit-testable container with bounded constraints to prevent render box hit test crashes
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
    if (burger.category.toLowerCase().contains('wing') ||
        burger.name.toLowerCase().contains('wing')) {
      badge = _buildTag(
          'Chef Choice', const Color(0xFFFFF7E6), const Color(0xFFD48806));
    } else if (burger.category.toLowerCase().contains('side') ||
        burger.name.toLowerCase().contains('potato') ||
        burger.price < 5.0) {
      badge = _buildTag('Side', Colors.grey.shade100, Colors.black54);
    } else {
      badge = _buildTag('Popular', const Color(0xFFFDEEEC), burgundy);
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
    final clean = path.trim();

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final safeUrl = Uri.encodeFull(clean);
      return Image.network(
        safeUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(
          backgroundColor: Color(0xFFFFECB3),
          child: Icon(Icons.lunch_dining, color: Colors.brown, size: 20),
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
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/images/imagelist1.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: burgundy,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      onTap: (index) => setState(() => _currentBottomNavIndex = index),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
        BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu), label: 'Catalog'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined), label: 'Outlet'),
      ],
    );
  }
}
