import 'package:RaxCare/authentication/login.dart';
import 'package:RaxCare/authentication/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import '../screens/home/home.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({Key? key}) : super(key: key);

  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;
  bool onboardingComplete = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboardingComplete') ?? false;
    setState(() {
      onboardingComplete = completed;
      isLoading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    setState(() {
      onboardingComplete = true;
    });
  }

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;

    if (!onboardingComplete) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    if (user == null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: showSignIn
            ? Login(toggleView: toggleView, key: const ValueKey('login'))
            : Register(
                toggleView: toggleView,
                key: const ValueKey('register'),
              ),
      );
    }

    // For returning users
    return const HomePage();
  }
}
