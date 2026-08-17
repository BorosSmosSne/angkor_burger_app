import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/widgets/category_pill.dart';
import 'package:angkor_burger_app/widgets/product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color _brandRed = const Color(0xFF8B1D1D);
  final Color _brandColor = const Color(0xFFFCF5F0);

  // List of Banner Images for Carousel Slider
  final List<String> _bannerImages = [
    'assets/images/imagelist1.jpg',
    'assets/images/imagelist2.jpg',
    'assets/images/imagelist3.jpg',
  ];

  int _currentBannerIndex = 0;

  final List<ProductModel> _sampleProducts = [
    ProductModel(
      name: 'Truffle Burger',
      price: 5.99,
      rating: 4.8,
      imagePath: 'assets/images/imagelist1.jpg',
    ),
    ProductModel(
      name: 'Royal Cheese Burger',
      price: 6.49,
      rating: 4.9,
      imagePath: 'assets/images/imagelist2.jpg',
    ),
    ProductModel(
      name: 'Spicy Khmer Burger',
      price: 5.49,
      rating: 4.7,
      imagePath: 'assets/images/imagelist3.jpg',
    ),
    ProductModel(
      name: 'Double Beef Delight',
      price: 7.99,
      rating: 4.9,
      imagePath: 'assets/images/imagelist1.jpg',
    ),
  ];

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? _brandRed : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCategoryPill(String title, IconData icon) {
    return CategoryPill(
      title: title,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandColor,
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
                      Text(
                        'ANGKOR BURGER',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _brandRed,
                        ),
                      ),
                    ],
                  ),
                  // Right Side: Notification & Profile Icons
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none,
                            color: Colors.black87, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline,
                            color: Colors.black87, size: 20),
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
                        prefixIcon: const Icon(CupertinoIcons.search,
                            color: Colors.grey),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _brandRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune,
                                color: Colors.white, size: 20),
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
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _brandRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryPill('Burgers', Icons.lunch_dining),
                      _buildCategoryPill('Hot Dogs', Icons.fastfood),
                      _buildCategoryPill('Pizza', Icons.local_pizza),
                      _buildCategoryPill('Drinks', Icons.local_drink),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 5. POPULAR BURGERS
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Burgers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _brandRed,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See all',
                          style: TextStyle(color: Colors.grey.shade600),
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
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final product = _sampleProducts[index];
                      return ProductCard(
                        product: product,
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
