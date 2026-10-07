import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Check empty fields
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the fields.'),
        ),
      );
      return;
    }

    // Check password length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------
      // 1. CREATE FIREBASE AUTHENTICATION ACCOUNT
      // --------------------------------------------------
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User account could not be created.');
      }

      // --------------------------------------------------
      // 2. SAVE USER PROFILE IN FIRESTORE
      // --------------------------------------------------
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': name,
          'email': email,
          'profileImage': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        // Authentication account has already been created.
        // Firestore failure should not make signup look unsuccessful.
        debugPrint('FIRESTORE ERROR: $firestoreError');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! 🎉'),
        ),
      );

      // --------------------------------------------------
      // 3. GO TO HOME SCREEN
      // --------------------------------------------------
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // --------------------------------------------------
      // FIREBASE AUTH ERROR DETAILS
      // --------------------------------------------------
      debugPrint('SIGNUP ERROR CODE: ${e.code}');
      debugPrint('SIGNUP ERROR MESSAGE: ${e.message}');

      String message = 'Sign up failed. Please try again.';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'operation-not-allowed') {
        message =
        'Email/Password sign-up is not enabled in Firebase.';
      } else if (e.code == 'network-request-failed') {
        message =
        'Network error. Please check your internet connection.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (e.code == 'invalid-credential') {
        message =
        'Firebase could not verify these credentials.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      // --------------------------------------------------
      // OTHER ERRORS
      // --------------------------------------------------
      debugPrint('GENERAL SIGNUP ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 25),

              // --------------------------------------------------
              // BACK BUTTON
              // --------------------------------------------------
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF6B5B7B),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // LOGO
              // --------------------------------------------------
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8B6E2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // TITLE
              // --------------------------------------------------
              const Text(
                'Create Account ✨',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B7B),
                ),
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // SUBTITLE
              // --------------------------------------------------
              const Text(
                'Start your reading journey with ReadAura',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9A8FA3),
                ),
              ),

              const SizedBox(height: 35),

              // --------------------------------------------------
              // NAME FIELD
              // --------------------------------------------------
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFFC8B6E2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // EMAIL FIELD
              // --------------------------------------------------
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFC8B6E2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // PASSWORD FIELD
              // --------------------------------------------------
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFC8B6E2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --------------------------------------------------
              // SIGN UP BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8B6E2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // LOGIN LINK
              // --------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFF9A8FA3),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF6B5B7B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}