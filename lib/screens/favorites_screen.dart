import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/favorites_manager.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/product_card.dart';
import 'package:angkor_burger_app/models/cart_item_model.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:angkor_burger_app/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  final List<CartItem>? cartItems;
  final Function(CartItem item)? onAddToCart;
  final Function(CartItem item, int newQuantity)? onUpdateCartQuantity;
  final Function(CartItem item)? onRemoveCartItem;
  final VoidCallback? onClearCart;
  final Function(int tabIndex)? onNavigateToTab;

  const FavoritesScreen({
    super.key,
    this.cartItems,
    this.onAddToCart,
    this.onUpdateCartQuantity,
    this.onRemoveCartItem,
    this.onClearCart,
    this.onNavigateToTab,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  void _addToCart(ProductModel product) {
    final defaultSize = product.sizePrices.containsKey('M')
        ? 'M'
        : (product.sizePrices.keys.firstOrNull ?? 'M');
    final unitPrice = product.sizePrices[defaultSize] ?? product.price;

    widget.onAddToCart?.call(
      CartItem(
        product: product,
        quantity: 1,
        selectedSize: defaultSize,
        unitPrice: unitPrice,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openProductDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          cartItems: widget.cartItems,
          onAddToCart: widget.onAddToCart,
          onUpdateCartQuantity: widget.onUpdateCartQuantity,
          onRemoveCartItem: widget.onRemoveCartItem,
          onClearCart: widget.onClearCart,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // 1. App Bar
          AngkorAppBar(
            title: 'MY FAVORITES',
            showBackButton: true,
            showFavorite: false,
            onBackPressed: () => Navigator.pop(context),
          ),

          // 2. Favorites List/Grid
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: FavoritesManager.favoriteProductNamesNotifier,
              builder: (context, favNames, _) {
                final favoriteProducts =
                    FavoritesManager.getFavoriteProducts();

                if (favoriteProducts.isEmpty) {
                  return _buildEmptyFavoritesState();
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${favoriteProducts.length} ${favoriteProducts.length == 1 ? "Item" : "Items"} Saved',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                FavoritesManager.clearFavorites();
                              },
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Colors.red.shade400),
                              label: Text(
                                'Clear All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = favoriteProducts[index];
                            return ProductCard(
                              product: product,
                              isFavorite: true,
                              onTap: () => _openProductDetail(product),
                              onAddToCart: () => _addToCart(product),
                              onFavoriteChanged: (isFav) {
                                FavoritesManager.setFavorite(product, isFav);
                              },
                            );
                          },
                          childCount: favoriteProducts.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 30),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavoritesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.brandLightRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandRed.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: AppColors.brandRed,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any meal on the home or menu screen to save your favorites here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_rounded,
                  color: Colors.white, size: 18),
              label: const Text(
                'Explore Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
