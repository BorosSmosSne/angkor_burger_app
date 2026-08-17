import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/widgets/category_pill.dart';
import 'package:angkor_burger_app/widgets/product_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color _brandRed = const Color(0xFF8B1D1D);
  final Color _brandColor = const Color(0xFFFCF5F0);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandColor,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        title: Text(
          'Angkor Burger',
          style: TextStyle(
            color: _brandRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: _brandRed),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart tapped')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  CategoryPill(title: 'Burgers', icon: Icons.lunch_dining),
                  CategoryPill(title: 'Drinks', icon: Icons.local_drink),
                  CategoryPill(title: 'Sides', icon: Icons.fastfood),
                  CategoryPill(title: 'Desserts', icon: Icons.icecream),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
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

            // Products Grid for testing ProductCard
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sampleProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}
