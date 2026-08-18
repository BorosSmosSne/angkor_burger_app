import 'package:flutter/material.dart';

class CategoryPill extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  static const Color _defaultBrandRed = Color(0xFF8B1D1D);
  static const Color _defaultBg = Color(0xFFFDECEC);

  const CategoryPill({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBrandRed = iconColor ?? _defaultBrandRed;
    final effectiveBg = backgroundColor ?? _defaultBg;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }
}

class NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const NavArrow({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}
