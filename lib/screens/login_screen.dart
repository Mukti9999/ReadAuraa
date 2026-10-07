import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email and password.',
            style: TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
            style: TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // FORGOT PASSWORD
  // --------------------------------------------------

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter your email first.',
            style: TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent.',
            style: TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Could not send reset email.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Times New Roman'),
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // CONTINUE AS GUEST
  // --------------------------------------------------

  Future<void> _continueAsGuest() async {
    // Make sure no Firebase user remains signed in.
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // --------------------------------------------------
  // INIT STATE
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                height: 230,
                width: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8DDF1).withOpacity(0.55),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF7DDE7).withOpacity(0.50),
                ),
              ),
            ),

            const Positioned(
              top: 90,
              left: 35,
              child: Text(
                '✦',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 18,
                  color: Color(0xFFC8B6E2),
                ),
              ),
            ),

            const Positioned(
              top: 145,
              right: 40,
              child: Text(
                '✧',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 23,
                  color: Color(0xFFD9C5E8),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // --------------------------------------------------
                      // LOGO
                      // --------------------------------------------------
                      Container(
                        height: 92,
                        width: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8DDF1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC8B6E2).withOpacity(0.25),
                              blurRadius: 25,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            height: 67,
                            width: 67,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8B6E2),
                              borderRadius: BorderRadius.circular(21),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 39,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'READAURA',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Color(0xFF6B5B7B),
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Continue your reading journey',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 14,
                          color: Color(0xFF9A8FA3),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --------------------------------------------------
                      // LOGIN CARD
                      // --------------------------------------------------
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.045),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Welcome Back ✨',
                                style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B5B7B),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sign in to continue exploring your reading world.',
                                style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 13,
                                  color: Color(0xFF9A8FA3),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // EMAIL
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Times New Roman',
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFFC8B6E2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFFF9FC),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC8B6E2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // PASSWORD
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Times New Roman',
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFFC8B6E2),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF9A8FA3),
                                    size: 21,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFFF9FC),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC8B6E2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // FORGOT PASSWORD
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontFamily: 'Times New Roman',
                                    color: Color(0xFF8C7A9D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // LOGIN BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC8B6E2),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 23,
                                        width: 23,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontFamily: 'Times New Roman',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // --------------------------------------------------
                            // GUEST MODE
                            // --------------------------------------------------
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _continueAsGuest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3DCE8),
                                  foregroundColor: const Color(0xFF6B5B7B),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                    side: const BorderSide(
                                      color: Color(0xFFC8B6E2),
                                      width: 1.3,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Continue as Guest 🌷',
                                  style: TextStyle(
                                    fontFamily: 'Times New Roman',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // --------------------------------------------------
                      // OR
                      // --------------------------------------------------
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 12,
                                color: Color(0xFF9A8FA3),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --------------------------------------------------
                      // SIGN UP
                      // --------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              color: Color(0xFF9A8FA3),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                color: Color(0xFF6B5B7B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'READ • FEEL • REFLECT',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 9,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB0A3B8),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
