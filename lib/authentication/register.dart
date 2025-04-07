import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'phone_verification.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  const Register({Key? key, required this.toggleView}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>
    with SingleTickerProviderStateMixin {
  // Form controllers
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  String _errorMessage = '';

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Handle signup
  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'You must agree to the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Navigate to phone verification page
      if (userCredential.user != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhoneVerificationPage(
              userId: userCredential.user!.uid,
              nickname: _nicknameController.text.trim(),
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during registration';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade800,
                  Colors.purple.shade900,
                ],
              ),
            ),
          ),

          // Animated circles for visual effect
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            child: Container(
              height: size.height * 0.4,
              width: size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          Positioned(
            bottom: -size.height * 0.2,
            right: -size.width * 0.2,
            child: Container(
              height: size.height * 0.5,
              width: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Title
                        Center(
                          child: Container(
                            height: 100,
                            width: 100,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              color: Colors.white,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        Text(
                          'Sign up to start your journey',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Form with frosted glass effect
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Nickname field
                                    TextFormField(
                                      controller: _nicknameController,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Nickname',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.white70),
                                        prefixIcon: const Icon(Icons.person,
                                            color: Colors.white70),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.white),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.1),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a nickname';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Email field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.white70),
                                        prefixIcon: const Icon(Icons.email,
                                            color: Colors.white70),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.white),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.1),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@') ||
                                            !value.contains('.')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Password field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.white70),
                                        prefixIcon: const Icon(Icons.lock,
                                            color: Colors.white70),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.white),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.1),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Confirm password field
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: !_isConfirmPasswordVisible,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.white70),
                                        prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Colors.white70),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isConfirmPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isConfirmPasswordVisible =
                                                  !_isConfirmPasswordVisible;
                                            });
                                          },
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          // ... continuing from the previous TextFormField ...

                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.white),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Colors.redAccent,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.1),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),

                                    // Terms and conditions checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreeToTerms = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.white,
                                          checkColor: Colors.purple.shade900,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'I agree to the terms and conditions',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Display error message if any
                                    if (_errorMessage.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                          _errorMessage,
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                    const SizedBox(height: 24),

                                    // Sign up button
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _signupUser,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              Colors.purple.shade900,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          disabledBackgroundColor:
                                              Colors.white.withOpacity(0.3),
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator()
                                            : Text(
                                                'Sign Up',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Already have an account? Sign in
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.toggleView(),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Terms and privacy policy
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Navigate to terms & privacy page
                            },
                            child: Text(
                              'Terms of Service & Privacy Policy',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
