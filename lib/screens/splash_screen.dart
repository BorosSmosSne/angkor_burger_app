import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/screens/burger_menu_screen.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/screens/welcome_screen.dart';
import 'package:angkor_burger_app/services/rest_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  static const Color _bgColor = Color(0xFFFCF5F0);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Pop-up bounce effect from small to big
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    // Smooth fade in
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    String? token;
    String savedRole = 'customer';

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      token = preferences.getString('angkor.pos.token');

      // Read role directly from SharedPreferences or UserProfileManager
      savedRole = (preferences.getString('angkor.pos.user_role') ??
              preferences.getString('user_role') ??
              UserProfileManager.profileNotifier.value.role)
          .toLowerCase();

      RestApi.currentUserRole = savedRole;
    } catch (e) {
      debugPrint('Error reading SharedPreferences: $e');
    }

    final bool hasValidToken = token != null && token.trim().isNotEmpty;

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    if (hasValidToken) {
      // Route Staff and Admin directly to BurgerMenuScreen
      if (savedRole == 'admin' ||
          savedRole == 'staff' ||
          UserProfileManager.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BurgerMenuScreen()),
        );
      } else {
        // Route Customer to HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/logo_angkorBurger.png',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
