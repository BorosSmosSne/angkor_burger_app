import 'package:angkor_burger_app/screens/login_screen.dart';
import 'package:angkor_burger_app/screens/sign_up_screen.dart';
import 'package:angkor_burger_app/widgets/animated_button.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _brandRed = Color(0xFF8B1D1D);
  static const Color _bgColor = Color(0xFFFCF5F0);
  static const Color _brandYellow = Color(0xFFFEBB0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned(
            top: 95,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/AngkorWat_victor.png',
                width: 270,
                // height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 100),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          Text(
                            'WELCOME',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: _brandYellow,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Login or Sign Up to Continue...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 24),
                          Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              'assets/images/logo_angkorBurger.png',
                              height: 250,
                              width: 250,
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'ANGKOR BURGER',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _brandRed,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Angkor Burger serves tasty, fresh, and \n affordable burgers for everyone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AnimatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandRed,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AnimatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Already have an Account',
                            style: TextStyle(
                              color: _brandRed,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    AnimatedButton(
                      onPressed: () {},
                      child: Text(
                        'Continue as a guest',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
