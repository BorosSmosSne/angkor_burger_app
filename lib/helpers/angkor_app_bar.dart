import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/helpers/animated_button.dart';
import 'package:flutter/material.dart';

/// A universal, reusable custom header / app bar widget with Angkor Burger branding,
/// live cart badge, profile button, back button, and full customization for every screen.
///
/// Can be used both as:
/// 1. `appBar: AngkorAppBar(...)` in a `Scaffold`
/// 2. Directly inside a `Column` or body: `Column(children: [AngkorAppBar(...), ...])`
class AngkorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showLogo;
  final String logoPath;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool showCart;
  final int totalCartItems;
  final VoidCallback? onCartPressed;
  final bool showProfile;
  final VoidCallback? onProfilePressed;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Color? textColor;

  const AngkorAppBar({
    super.key,
    this.title = 'ANGKOR BURGER',
    this.titleWidget,
    this.showLogo = true,
    this.logoPath = 'assets/images/logo_angkorBurger.png',
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.showCart = true,
    this.totalCartItems = 0,
    this.onCartPressed,
    this.showProfile = true,
    this.onProfilePressed,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.height = 70.0,
    this.padding,
    this.textColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    // 1. Leading / Back Button Section
    Widget? leadingSection;
    if (leading != null) {
      leadingSection = leading;
    } else if (showBackButton) {
      leadingSection = AnimatedButton(
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
      );
    }

    // 2. Logo Section
    Widget? logoSection;
    if (showLogo) {
      logoSection = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Image.asset(
          logoPath,
          height: 36,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.lunch_dining,
            size: 34,
            color: AppColors.brandRed,
          ),
        ),
      );
    }

    // 3. Title Section
    final Widget titleContent = titleWidget ??
        Text(
          title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: textColor ?? AppColors.brandRed,
            letterSpacing: 0.5,
          ),
        );

    // 4. Trailing / Actions Section
    Widget trailingSection;
    if (actions != null) {
      trailingSection = Row(
        mainAxisSize: MainAxisSize.min,
        children: actions!,
      );
    } else {
      trailingSection = Row(
        mainAxisSize: MainAxisSize.min,
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
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
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
      );
    }

    return Container(
      padding:
          padding ?? const EdgeInsets.only(left: 18, right: 18, bottom: 14),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ??
            const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left / Title area
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: centerTitle
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (leadingSection != null) leadingSection,
                    if (logoSection != null) logoSection,
                    Flexible(child: titleContent),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right / Actions area
              trailingSection,
            ],
          ),
        ),
      ),
    );
  }
}
