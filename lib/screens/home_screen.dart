import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/product_card.dart';
import 'package:angkor_burger_app/models/product_model.dart';
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
  final List<String> _bannerImages = [
    'assets/images/imagelist1.jpg',
    'assets/images/imagelist2.jpg',
    'assets/images/imagelist3.jpg',
  ];

  int _currentBannerIndex = 0;
  final Set<String> _favoriteProductNames = {};

  final List<ProductModel> _sampleProducts = [
    ProductModel(
      name: 'Truffle Burger',
      price: 5.99,
      rating: 4.8,
      imagePath: 'assets/images/imagelist1.jpg',
      description:
          'Juicy beef patty infused with black truffle sauce and cheddar cheese.',
      category: 'Burgers',
      sizePrices: {'S': 5.99, 'M': 6.99, 'L': 7.99},
      addOns: {
        'Chicken Strip': 1.50,
        'Truffle Aioli': 0.75,
        'Extra Cheese': 1.00,
      },
      ingredients: [
        'Beef Patty',
        'Truffle Sauce',
        'Cheddar Cheese',
        'Brioche Bun',
        'Lettuce',
        'Pickles',
      ],
    ),
    ProductModel(
      name: 'Royal Cheese Burger',
      price: 6.49,
      rating: 4.9,
      imagePath: 'assets/images/imagelist2.jpg',
      description:
          'Classic double beef burger with melted American cheese and fresh lettuce.',
      category: 'Burgers',
      sizePrices: {'S': 6.49, 'M': 7.49, 'L': 8.49},
      addOns: {
        'Extra Bacon': 1.50,
        'Extra Cheese': 1.00,
        'Fried Egg': 0.80,
      },
      ingredients: [
        'Double Beef',
        'American Cheese',
        'Lettuce',
        'Tomato',
        'Special Sauce',
        'Sesame Bun',
      ],
    ),
    ProductModel(
      name: 'Spicy Khmer Burger',
      price: 5.49,
      rating: 4.7,
      imagePath: 'assets/images/imagelist3.jpg',
      description:
          'Spicy seasoned grilled patty with special local herbal sauce.',
      category: 'Burgers',
      sizePrices: {'S': 5.49, 'M': 6.49, 'L': 7.49},
      addOns: {
        'Spicy Sauce': 0.50,
        'Fried Egg': 0.80,
        'Extra Patty': 2.00,
      },
      ingredients: [
        'Grilled Patty',
        'Khmer Herbal Sauce',
        'Chili',
        'Fresh Lettuce',
        'Cucumber',
        'Toasted Bun',
      ],
    ),
    ProductModel(
      name: 'Double Beef Delight',
      price: 7.99,
      rating: 4.9,
      imagePath: 'assets/images/imagelist1.jpg',
      description:
          'Loaded two-tier beef patty stacked with crispy bacon and cheese.',
      category: 'Burgers',
      sizePrices: {'S': 7.99, 'M': 8.99, 'L': 9.99},
      addOns: {
        'Extra Cheese': 1.00,
        'Crispy Bacon': 1.50,
        'Grilled Mushrooms': 1.20,
      },
      ingredients: [
        'Double Beef Patty',
        'Crispy Bacon',
        'Melted Cheese',
        'Caramelized Onion',
        'BBQ Sauce',
        'Brioche Bun',
      ],
    ),
  ];

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
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final effectiveBrandRed = iconColor ?? AppColors.brandRed;
    final effectiveBg = backgroundColor ?? AppColors.brandLightRed;

    return _buildAnimatedButton(
      onPressed: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: effectiveBg, // Light red background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: effectiveBrandRed, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            builder: (context) => ProductDetailScreen(product: product),
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
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32), // Rounds the bottom corners
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withAlpha(13), // Soft shadow for the floating effect
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // Put SafeArea INSIDE the container so the white background reaches the top of the phone
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
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/burger_logo.png',
                          height: 40,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.lunch_dining, size: 36),
                        ),
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
                  // Right Side: Notification & Profile Icons
                  Row(
                    children: [
                      _buildAnimatedButton(
                        onPressed: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: Colors.black87, size: 20),
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
                          child: const Icon(Icons.person_outline,
                              color: Colors.black87, size: 20),
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
                  // 2. SEARCH BAR
                  // ==========================================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search menus items',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildAnimatedButton(
                            onPressed: () {},
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune,
                                  color: Colors.white, size: 20),
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
                  Stack(
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
                        items: _bannerImages.map((imagePath) {
                          return Builder(
                            builder: (BuildContext context) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
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
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      // Dynamic Pagination Dots
                      Positioned(
                        bottom: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _bannerImages.asMap().entries.map((entry) {
                            return _buildDot(
                              isActive: _currentBannerIndex == entry.key,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 4. CATEGORIES
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      _buildAnimatedButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCategoryPill(
                              title: 'Burgers', icon: Icons.lunch_dining),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCategoryPill(
                              title: 'Hot Dogs', icon: Icons.fastfood),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCategoryPill(
                              title: 'Pizza', icon: Icons.local_pizza),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCategoryPill(
                              title: 'Drinks', icon: Icons.local_drink),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCategoryPill(
                              title: 'Snacks', icon: Icons.bakery_dining),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCategoryPill(
                              title: 'Desserts', icon: Icons.icecream),
                        ),
                        _buildCategoryPill(
                            title: 'Combos', icon: Icons.takeout_dining),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 5. POPULAR BURGERS
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Popular Burgers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandRed,
                        ),
                      ),
                      _buildAnimatedButton(
                        onPressed: () {},
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sampleProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 173 / 259,
                    ),
                    itemBuilder: (context, index) {
                      final currentProduct = _sampleProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: currentProduct),
                            ),
                          );
                        },
                        child: _buildProductCard(currentProduct),
                      );
                    },
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
