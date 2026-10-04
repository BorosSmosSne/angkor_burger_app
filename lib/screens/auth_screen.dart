import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/helpers/animated_button.dart';
import 'package:angkor_burger_app/models/user_model.dart';
import 'package:angkor_burger_app/screens/home_screen.dart';
import 'package:angkor_burger_app/services/rest_api.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

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
  bool _isLoading = false;

  ConfirmationResult? _webConfirmationResult; // For web OTP verification

  String? _verificationId;
  int? _resendToken;

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

  // 1. Send SMS Code (Web + Mobile compatible)
  Future<void> sendPhoneCode(String phoneNumber) async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // Web flow using signInWithPhoneNumber
        final confirmationResult =
            await FirebaseAuth.instance.signInWithPhoneNumber(
          phoneNumber.trim(),
        );
        setState(() {
          _webConfirmationResult = confirmationResult;
          _isLoading = false;
        });
        _showOtpInputDialog();
      } else {
        // Mobile flow
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber.trim(),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _signInWithPhoneCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() => _isLoading = false);
            _showErrorDialog(e.message ?? 'Phone verification failed.');
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
            _showOtpInputDialog();
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.message ?? 'Phone verification failed.');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to send verification code: $e');
    }
  }

  void _showOtpInputDialog() {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Verification Code',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: '6-digit OTP',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              verifyOtp(otpController.text);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

// 2. Verify OTP & Complete Sign-In
  Future<void> verifyOtp(String smsCode) async {
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential;
      if (kIsWeb && _webConfirmationResult != null) {
        userCredential = await _webConfirmationResult!.confirm(smsCode.trim());
      } else if (_verificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode.trim(),
        );
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        setState(() => _isLoading = false);
        return;
      }

      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await saveCredentials(User(
          token: idToken,
          email: userCredential.user?.phoneNumber ?? '',
        ));
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.message ?? 'Invalid code entered.');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Verification error: $e');
    }
  }

  Future<void> _signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final idToken = await userCredential.user?.getIdToken();
    if (idToken != null) {
      await saveCredentials(User(
        token: idToken,
        phone: userCredential.user?.phoneNumber ?? '',
      ));
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _showPhoneInputDialog() {
    final TextEditingController phoneController =
        TextEditingController(text: '+855');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.phone_android_rounded, color: _brandRed),
            const SizedBox(width: 8),
            const Text(
              'Phone Sign-In',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your phone number with country code to receive a verification code.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+855 12 345 678',
                prefixIcon: const Icon(Icons.phone),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final number = phoneController.text.trim();
              if (number.isNotEmpty && number.length > 6) {
                Navigator.pop(ctx);
                sendPhoneCode(number);
              }
            },
            child: const Text('Send Code'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRememberedCredentials() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
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
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('angkor.pos.token', user.token ?? '');

    // Save or clear Remember Me credentials
    if (_rememberMe || _keepSignedIn) {
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

  // --- GOOGLE SIGN IN METHOD ---
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // 1. Create Google Auth Provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      // 2. Trigger Native Firebase Sign-In Popup
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      // 3. Obtain Firebase ID token
      final user = userCredential.user;
      final idToken = await userCredential.user?.getIdToken();

      if (user != null && idToken != null) {
        final email = user.email ?? '';
        final name = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Google User';
        final phone = user.phoneNumber ?? '';

        // 3. Save the auth credentials locally
        await saveCredentials(User(
          token: idToken,
          // email: userCredential.user?.email ?? '',
          // name: userCredential.user?.displayName ?? 'Google User',
          email: email,
          name: name,
          phone: phone,
        ));

        // 4. Persist to Laravel MySQL database
        await RestApi.updateUserProfile(
          email: email,
          name: name,
          phone: phone,
          address: '',
        );
      }

      // 4. Navigate to HomeScreen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Auth Error: ${e.code} - ${e.message}');
      _showErrorDialog(e.message ?? 'Google Sign-In failed.');
    } catch (e) {
      debugPrint('Google Sign-In General Error: $e');
      _showErrorDialog('Failed to sign in with Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Authenticate user with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Get the Firebase ID token (JWT)
      final idToken = await userCredential.user?.getIdToken();

      // 3. Save the token to local storage using your existing helper
      if (idToken != null) {
        await saveCredentials(User(token: idToken, email: email));
      }

      // 4. Navigate to HomeScreen on success
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(_getAuthErrorMessage(e));
    } catch (e) {
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // old
  // Future<void> login() async {
  //   final email = 'angkor@gmail.com';
  //   final password = 'sv9@123';
  //   if (_emailController.text == email &&
  //       _passwordController.text == password) {
  //     final responeToken =
  //         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI4IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE4MDAwMDAwMDB9.6n4w6_uCgMbeuY7Vp_tHhUksL8Pq8wW7Fk1Z6_9_1z2';
  //     await saveCredentials(User(token: responeToken));
  //     // print('Logged in successfully!');
  //     if (mounted) {
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (context) => const HomeScreen()),
  //         (route) => false,
  //       );
  //     }
  //   } else {
  //     showDialog(
  //       context: context,
  //       builder: (context) => Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //         child: const Padding(
  //           padding: EdgeInsets.all(20),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 'Login Failed',
  //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  //               ),
  //               SizedBox(height: 8),
  //               Text(
  //                 'Invalid email or password',
  //                 textAlign: TextAlign.center,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  // }
// --- FIREBASE SIGN UP ---
  Future<void> signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('Please enter your full name.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter your email and password.');
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 1. Save display name to firebase
      final fullName = _nameController.text.trim();
      if (fullName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(fullName);
        await userCredential.user?.reload(); // Refresh user data
      }

      await RestApi.updateUserProfile(
          email: _emailController.text.trim(),
          name: fullName.isNotEmpty ? fullName : 'User',
          phone: '',
          address: '');

      // 2. Immediately update the profile manager
      UserProfileManager.updateProfile(
        name: fullName.isNotEmpty ? fullName : 'User',
        email: _emailController.text.trim(),
        phone: '',
        address: '',
      );

      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await saveCredentials(User(
            token: idToken,
            name: fullName,
            email: userCredential.user?.email ?? ''));
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(_getAuthErrorMessage(e));
    } catch (e) {
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

// Extracted error dialog helper
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _animation.value > 0.5 ? 'Sign Up Failed' : 'Login Failed',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_isLoading) return;
    if (_animation.value > 0.5) {
      signUp();
    } else {
      login();
    }
  }

  void _toggleTab(bool isSignUp) {
    FocusScope.of(context).unfocus();
    setState(() {
      // 1. Always clear the passwords for security & clean validation
      _passwordController.clear();
      _confirmPasswordController.clear();

      // 2. Clear full name when going back to Log In mode
      if (!isSignUp) {
        _nameController.clear();
      }

      // Note: We leave _emailController intact so the user doesn't have to re-type it!
    });
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          onPressed: _isLoading ? () {} : _handleSubmit,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandRed,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _brandRed.withValues(alpha: 0.6),
                              minimumSize: const Size(double.infinity, 52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : AnimatedBuilder(
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
                                onPressed: _isLoading ? null : signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
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
                                  side: BorderSide(color: Colors.grey.shade300),
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
                            const SizedBox(width: 8),

                            // 📱 Phone Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _isLoading ? null : _showPhoneInputDialog,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Icon(Icons.phone_iphone_rounded,
                                    color: _brandRed, size: 22),
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
                      color: _brandRed,
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
                              Colors.white,
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
                              Colors.white,
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
