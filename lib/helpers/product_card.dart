import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/animated_button.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool? isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.isFavorite,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite ?? false;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != null &&
        widget.isFavorite != oldWidget.isFavorite) {
      _isFavorite = widget.isFavorite!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPrice = widget.product.sizePrices.isNotEmpty
        ? widget.product.sizePrices.values.reduce((a, b) => a < b ? a : b)
        : widget.product.price;
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip
            .antiAlias, // Clips the image cleanly to top-left and top-right card corners
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. FULL-BLEED IMAGE SECTION =================
            Expanded(
              flex: 3, // Gives proportionally more room to the image
              child: Stack(
                fit: StackFit.expand, // Forces image to stretch edge-to-edge
                children: [
                  widget.product.imagePath.startsWith('http://') ||
                          widget.product.imagePath.startsWith('https://')
                      ? Image.network(
                          widget.product.imagePath,
                          fit: BoxFit
                              .cover, // Fills completely with zero white bars
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Image.asset(
                          widget.product.imagePath.isNotEmpty
                              ? widget.product.imagePath
                              : 'assets/images/imagelist1.jpg',
                          fit: BoxFit
                              .cover, // Fills completely with zero white bars
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood,
                                size: 40, color: Colors.grey),
                          ),
                        ),

                  // Floating Favorite Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedButton(
                      onPressed: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        widget.onFavoriteChanged?.call(_isFavorite);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color:
                              _isFavorite ? Colors.red : Colors.grey.shade700,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= 2. TITLE, RATING, PRICE =================
            Expanded(
              flex: 2, // Compact bottom section for text details
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title + Star Rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star,
                            color: AppColors.brandYellow, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          widget.product.rating.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Price + Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${displayPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.brandRed,
                          ),
                        ),
                        AnimatedButton(
                          onPressed: widget.onAddToCart ?? () {},
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
