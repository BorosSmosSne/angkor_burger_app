import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int cartItemCount;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // The margin makes it "float" above the bottom of the screen
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Creates the pill shape
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, 'Home', 0),
          _buildNavItem(Icons.restaurant_menu, 'Menu', 1),
          _buildNavItem(
            Icons.shopping_cart_outlined,
            'Cart',
            2,
            badgeCount: cartItemCount,
          ),
          _buildNavItem(Icons.local_shipping_outlined, 'Orders', 3),
          _buildNavItem(Icons.person_outline, 'User', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      {int badgeCount = 0}) {
    final bool isActive = selectedIndex == index;

    // Colors based on your design
    final Color activeBgColor =
        const Color(0xFFF3C755); // The yellow pill background
    final Color activeTextColor =
        const Color(0xFF5A4A22); // Darker brown for contrast
    final Color inactiveColor = Colors.black87;
    final Color brandRed =
        const Color(0xFF8B1D1D); // Red for the notification badge

    return GestureDetector(
      onTap: () => onItemTapped(index),
      // Use behavior opaque so the whole padded area is clickable
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(microseconds: 250),
        curve: Curves.easeIn,
        width: 66,
        height: 43,
        child: Container(
          // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: activeBgColor,
                  borderRadius: BorderRadius.circular(30),
                )
              : const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isActive ? activeTextColor : inactiveColor,
                    size: 20,
                  ),
                  // Only show the red badge if the count is greater than 0
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: brandRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$badgeCount',
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
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? activeTextColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
