import 'dart:async';
import 'package:angkor_burger_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

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

    // After popping up, navigate to WelcomeScreen and let Hero fly logo into place
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WelcomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
    });
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
