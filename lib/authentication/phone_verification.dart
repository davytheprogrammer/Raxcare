import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'dart:ui';

class PhoneVerificationPage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String email;

  const PhoneVerificationPage({
    Key? key,
    required this.userId,
    required this.nickname,
    required this.email,
  }) : super(key: key);

  @override
  _PhoneVerificationPageState createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;
  String _errorMessage = '';
  String _selectedCountryCode = '+1'; // Default country code (US)
  final Map<String, RegExp> _phonePatterns = {
    '+1': RegExp(r'^[2-9]\d{9}$'), // US: 10 digits, no leading 1
    '+44': RegExp(r'^7\d{9}$'), // UK: 10 digits starting with 7
    '+91': RegExp(r'^\d{10}$'), // India: 10 digits
    '+234': RegExp(r'^\d{10}$'), // Nigeria: 10 digits
    '+27': RegExp(r'^[6-8]\d{8}$'), // South Africa: 9 digits starting with 6-8
    '+254': RegExp(r'^[7,1]\d{8}$'), // Kenya: 9 digits starting with 7 or 1
    '+255': RegExp(r'^[6-7]\d{8}$'), // Tanzania: 9 digits starting with 6 or 7
    '+256': RegExp(r'^[7]\d{8}$'), // Uganda: 9 digits starting with 7
    '+61': RegExp(r'^4\d{8}$'), // Australia: 9 digits starting with 4
  };

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validatePhoneNumber(String phoneNumber) {
    final pattern = _phonePatterns[_selectedCountryCode];
    if (pattern == null) {
      return phoneNumber.length >= 8 && RegExp(r'^\d+$').hasMatch(phoneNumber);
    }
    return pattern.hasMatch(phoneNumber);
  }

  Future<void> _simulateVerification() async {
    if (!_validatePhoneNumber(_phoneController.text.trim())) {
      setState(() {
        _errorMessage =
            'Please enter a valid phone number for $_selectedCountryCode';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulate verification process with a delay
      await Future.delayed(const Duration(seconds: 2));

      // Store user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'nickname': widget.nickname,
        'email': widget.email,
        'phone': '$_selectedCountryCode ${_phoneController.text.trim()}',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isVerified = true;
      });

      // Play success animation
      _animationController.forward();

      // Navigate to home after a delay
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to store user data. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSuccessContent() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Verification Successful!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will be redirected shortly...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputForm() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: CountryCodePicker(
                onChanged: (countryCode) {
                  setState(() {
                    _selectedCountryCode = countryCode.dialCode!;
                  });
                },
                initialSelection: 'US',
                favorite: const [
                  '+1',
                  '+44',
                  '+91',
                  '+234',
                  '+27',
                  '+254',
                  '+255',
                  '+256',
                  '+61'
                ],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                textStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
                dialogTextStyle: GoogleFonts.poppins(
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: GoogleFonts.poppins(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
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
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _simulateVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.purple.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.white.withOpacity(0.3),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    'Verify Phone Number',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
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
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Phone Verification',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Phone icon
                          Container(
                            height: 100,
                            width: 100,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_android,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'Verify Your Phone Number',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'We need to verify your phone number to complete your registration',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Phone input form or Success message
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
                                child: _isVerified
                                    ? _buildSuccessContent()
                                    : _buildPhoneInputForm(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Additional information text
                          Text(
                            'By continuing, you agree to receive SMS messages for verification.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
