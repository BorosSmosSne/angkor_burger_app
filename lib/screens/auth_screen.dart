import 'package:angkor_burger_app/helpers/animated_button.dart';
import 'package:angkor_burger_app/models/user_model.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const AuthScreen({super.key, this.initialIsSignUp = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _keepSignedIn = false;
  bool _rememberMe = false;

  final Color _brandRed = const Color(0xFF8B1D1D);
  final Color _bgColor = const Color(0xFFFCF5F0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.initialIsSignUp ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final bool remember =
        preferences.getBool('angkor.pos.remember_me') ?? false;
    if (remember) {
      final String? savedEmail =
          preferences.getString('angkor.pos.saved_email');
      final String? savedPassword =
          preferences.getString('angkor.pos.saved_password');
      if (mounted) {
        setState(() {
          _rememberMe = true;
          if (savedEmail != null && savedEmail.isNotEmpty) {
            _emailController.text = savedEmail;
          }
          if (savedPassword != null && savedPassword.isNotEmpty) {
            _passwordController.text = savedPassword;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> saveCredentials(User user) async {
    // Save the token to local storage
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString('angkor.pos.token', user.token ?? '');

    // Save or clear Remember Me credentials
    if (_rememberMe) {
      await preferences.setBool('angkor.pos.remember_me', true);
      await preferences.setString(
          'angkor.pos.saved_email', _emailController.text.trim());
      await preferences.setString(
          'angkor.pos.saved_password', _passwordController.text);
    } else {
      await preferences.setBool('angkor.pos.remember_me', false);
      await preferences.remove('angkor.pos.saved_email');
      await preferences.remove('angkor.pos.saved_password');
    }
  }

  Future<void> login() async {
    final email = 'angkor@gmail.com';
    final password = 'sv9@123';
    if (_emailController.text == email &&
        _passwordController.text == password) {
      final responeToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI4IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE4MDAwMDAwMDB9.6n4w6_uCgMbeuY7Vp_tHhUksL8Pq8wW7Fk1Z6_9_1z2';
      await saveCredentials(User(token: responeToken));
      // print('Logged in successfully!');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Login Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Invalid email or password',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _handleSubmit() {
    if (_animation.value > 0.5) {
      // Sign Up mode
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign Up Failed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text('Please enter your email and password'),
                ],
              ),
            ),
          ),
        );
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      login();
    }
  }

  void _toggleTab(bool isSignUp) {
    FocusScope.of(context).unfocus();
    if (isSignUp) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo & Branding Header (Outside on top of the card)
                  Hero(
                    tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/logo_angkorBurger.png',
                        height: 90,
                        width: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ANGKOR BURGER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _brandRed,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Elevate your dining experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card Container (BoxDecoration)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Smooth Synchronized Tab Switcher
                          _buildTabSwitcher(),
                          const SizedBox(height: 24),

                          // Full Name Field (Collapses & fades when switching to Log In)
                          SizeTransition(
                            sizeFactor: _animation,
                            axisAlignment: -1.0,
                            child: FadeTransition(
                              opacity: _animation,
                              child: _buildLabelTextField(
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                controller: _nameController,
                              ),
                            ),
                          ),

                          // Email Field (Always visible in both)
                          _buildLabelTextField(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          // Password Field (Always visible in both)
                          _buildLabelTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            isPassword: true,
                            isHidden: _isPasswordHidden,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),

                          // Confirm Password Field (Collapses & fades when switching to Log In)
                          SizeTransition(
                            sizeFactor: _animation,
                            axisAlignment: -1.0,
                            child: FadeTransition(
                              opacity: _animation,
                              child: _buildLabelTextField(
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                controller: _confirmPasswordController,
                                isPassword: true,
                                isHidden: _isConfirmPasswordHidden,
                                onToggleVisibility: () {
                                  setState(() {
                                    _isConfirmPasswordHidden =
                                        !_isConfirmPasswordHidden;
                                  });
                                },
                              ),
                            ),
                          ),

                          // Checkbox Row (Keep signed in / Remember me & Forgot Password)
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, _) {
                              final double t = _animation.value;
                              final bool isSignUpState = t > 0.5;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: isSignUpState
                                              ? _keepSignedIn
                                              : _rememberMe,
                                          activeColor: _brandRed,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              if (isSignUpState) {
                                                _keepSignedIn = val ?? false;
                                              } else {
                                                _rememberMe = val ?? false;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isSignUpState
                                            ? 'Keep me signed in'
                                            : 'Remember me',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Forgot Password (smoothly fades in during Log In mode)
                                  Opacity(
                                    opacity: (1.0 - t).clamp(0.0, 1.0),
                                    child: IgnorePointer(
                                      ignoring: t > 0.2,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          // Forgot password handler
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _brandRed,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          AnimatedButton(
                            onPressed: _handleSubmit,
                            child: ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandRed,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, _) {
                                  return Text(
                                    _animation.value > 0.5
                                        ? 'Sign Up'
                                        : 'Log In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 1. The Divider
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 2. The Side-by-Side Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  icon: Image.asset(
                                    'assets/images/google.png',
                                    height: 20,
                                    width: 20,
                                  ),
                                  label: const Text(
                                    'Google',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  icon: const Icon(
                                    Icons.facebook,
                                    color: Colors.blue,
                                    size: 22,
                                  ),
                                  label: const Text(
                                    'Facebook',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 3. The Bottom Footer (Animated switch between Log In / Sign Up)
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, _) {
                              final bool isSignUpState = _animation.value > 0.5;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isSignUpState
                                        ? 'Already have an account? '
                                        : "Don't have an account? ",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _toggleTab(!isSignUpState),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        isSignUpState ? 'Log In' : 'Sign Up',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _brandRed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  // Sliding Pill Tab Switcher
  Widget _buildTabSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final double t =
              _animation.value; // 1.0 = SignUp (Left), 0.0 = LogIn (Right)
          return Stack(
            children: [
              // Smooth Sliding White Pill Indicator
              Align(
                alignment: Alignment(-1.0 + (1.0 - t) * 2.0, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab Texts
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleTab(true),
                      child: Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color.lerp(
                              Colors.grey.shade600,
                              _brandRed,
                              t,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleTab(false),
                      child: Center(
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color.lerp(
                              _brandRed,
                              Colors.grey.shade600,
                              t,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabelTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    bool isPassword = false,
    bool isHidden = true,
    TextInputType? keyboardType,
    VoidCallback? onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword && isHidden,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _brandRed, width: 1.5),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
