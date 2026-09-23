import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/rest_api.dart';
import 'add_product_screen.dart';

class BurgerMenuCatalogScreen extends StatefulWidget {
  const BurgerMenuCatalogScreen({super.key});

  @override
  State<BurgerMenuCatalogScreen> createState() => _BurgerMenuCatalogScreenState();
}

class _BurgerMenuCatalogScreenState extends State<BurgerMenuCatalogScreen> {
  static const Color burgundy = Color(0xFF7A1C1C);
  static const Color scaffoldBg = Color(0xFFFBF9F9);

  late Future<List<ProductModel>> _productsFuture;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  String _searchQuery = '';
  String _selectedCategory = 'All Items';
  int _currentBottomNavIndex = 1; // 1 = Catalog active

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = RestApi.fetchProducts().then((data) {
        _allProducts = data;
        _applyFilters();
        return data;
      });
    });
  }

  void _applyFilters() {
    List<ProductModel> temp = List.from(_allProducts);

    // Filter by Category Pill
    if (_selectedCategory == 'Burgers') {
      temp = temp.where((p) => p.category.toLowerCase().contains('burger')).toList();
    } else if (_selectedCategory == 'Sides & Wings') {
      temp = temp.where((p) => !p.category.toLowerCase().contains('burger')).toList();
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      temp = temp.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.ingredients.any((ing) => ing.toLowerCase().contains(q))
      ).toList();
    }

    setState(() {
      _filteredProducts = temp;
    });
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      body: RefreshIndicator(
        onRefresh: () async => _loadProducts(),
        color: burgundy,
        child: FutureBuilder<List<ProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _allProducts.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: burgundy));
            }

            final totalCount = _allProducts.length;
            final categoryCount = _allProducts.map((e) => e.category).toSet().length;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live API Products Banner
                  _buildLiveApiCard(totalCount),
                  const SizedBox(height: 12),

                  // 2. Metrics Row (Catalog Synced & Categories Active)
                  _buildMetricsRow(totalCount, categoryCount),
                  const SizedBox(height: 14),

                  // 3. Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 12),

                  // 4. Horizontal Category Filter Pills
                  _buildCategoryFilterRow(totalCount),
                  const SizedBox(height: 16),

                  // 5. Section Header & Sorting
                  _buildCatalogHeader(),
                  const SizedBox(height: 8),

                  // 6. Food List
                  if (_filteredProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No menu items match your criteria.', style: TextStyle(color: Colors.grey)),
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
                  const SizedBox(height: 80), // Padding above floating bar
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

  // --- Top Custom AppBar ---
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
            child: const Icon(Icons.lunch_dining, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ANGKOR BURGER',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: burgundy, letterSpacing: 0.5),
              ),
              Text(
                'Menu Catalog',
                style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black87),
          onPressed: () {},
        ),
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

  // --- Live API Products Banner ---
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
                    const Text('Menu Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 6),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  ],
                ),
                Text(
                  'Live API Products • $totalCount Items',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _loadProducts,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, size: 18, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.edit_note, size: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // --- 2-Card Metrics Row ---
  Widget _buildMetricsRow(int totalCount, int categoryCount) {
    return Row(
      children: [
        // Metric 1: Catalog Status
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CATALOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 5, color: Colors.green),
                          SizedBox(width: 3),
                          Text('Synced', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$totalCount Products', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Text('All outlets aligned', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Metric 2: Categories
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CATEGORIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Icon(Icons.restaurant, size: 14, color: burgundy),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$categoryCount Active', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Text('Updated just now', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Search Bar ---
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

  // --- Category Filter Tabs (Pills) ---
  Widget _buildCategoryFilterRow(int totalCount) {
    final burgersCount = _allProducts.where((p) => p.category.toLowerCase().contains('burger')).length;
    final sidesCount = totalCount - burgersCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('All Items ($totalCount)', 'All Items'),
          const SizedBox(width: 8),
          _buildPill('Burgers ($burgersCount)', 'Burgers'),
          const SizedBox(width: 8),
          _buildPill('Sides & Wings ($sidesCount)', 'Sides & Wings'),
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
          border: Border.all(color: isSelected ? burgundy : Colors.grey.shade300),
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

  // --- Section Subtitle Row ---
  Widget _buildCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Main Catalog List',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
        Row(
          children: const [
            Text('Sort by Rank', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ],
    );
  }

  // --- Product Card ---
  Widget _buildProductCard(ProductModel burger) {
    // Dynamic Badges (Popular / Chef Choice / Side)
    Widget badge;
    if (burger.category.toLowerCase().contains('wing') || burger.category.toLowerCase().contains('korean')) {
      badge = _buildTag('Chef Choice', const Color(0xFFFFF7E6), const Color(0xFFD48806));
    } else if (burger.category.toLowerCase().contains('potato') || burger.price < 5.0) {
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
          // Image Thumbnail with Star Rating overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildItemImage(burger.imagePath),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 9),
                      const SizedBox(width: 2),
                      Text(
                        burger.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Core Product Info
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 6),
                    badge,
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '\$${burger.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: burgundy),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Flexible(
                      child: Text(
                        burger.nutritionFacts,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
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

          // Actions: Edit & Delete Icons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductScreen(existingProduct: burger)),
                  );
                  if (result == true) _loadProducts();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFDEEEC), shape: BoxShape.circle),
                  child: const Icon(Icons.edit_outlined, size: 14, color: burgundy),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _deleteProduct(burger),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, size: 14, color: Colors.grey),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: text)),
    );
  }

  // --- Image Resolver ---
  Widget _buildItemImage(String path) {
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        Uri.encodeFull(clean),
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

    if (assetPath.contains('burger.png') || assetPath.contains('wings.png') || assetPath.isEmpty) {
      assetPath = 'assets/images/imagelist1.jpg';
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset('assets/images/imagelist1.jpg', fit: BoxFit.cover),
    );
  }

  // --- 5-Tab Bottom Navigation Bar ---
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: burgundy,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      onTap: (index) {
        setState(() => _currentBottomNavIndex = index);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Catalog'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Outlet'),
      ],
    );
  }
}