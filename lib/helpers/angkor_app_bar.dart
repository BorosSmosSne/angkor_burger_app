import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/animated_button.dart';
import 'package:flutter/material.dart';

/// A reusable custom header / app bar widget with Angkor Burger branding,
/// live cart badge, profile button, and optional back button.
class AngkorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int totalCartItems;
  final VoidCallback? onCartPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBackPressed;
  final bool showCart;
  final bool showProfile;
  final bool showBackButton;
  final String title;

  const AngkorAppBar({
    super.key,
    this.totalCartItems = 0,
    this.onCartPressed,
    this.onProfilePressed,
    this.onBackPressed,
    this.showCart = true,
    this.showProfile = true,
    this.showBackButton = false,
    this.title = 'ANGKOR BURGER',
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side: Optional Back Button + Logo + Title
            Row(
              children: [
                if (showBackButton) ...[
                  AnimatedButton(
                    onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                        size: 18,
                      ),
                    ),
                  ),
                ],
                Image.asset(
                  'assets/images/logo_angkorBurger.png',
                  height: 38,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.lunch_dining, size: 36),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandRed,
                  ),
                ),
              ],
            ),

            // Right Side: Cart Icon with live Badge & Profile Icon
            Row(
              children: [
                if (showCart) ...[
                  AnimatedButton(
                    onPressed: onCartPressed,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                        if (totalCartItems > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.brandRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '$totalCartItems',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (showCart && showProfile) const SizedBox(width: 8),
                if (showProfile) ...[
                  AnimatedButton(
                    onPressed: onProfilePressed ?? () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
