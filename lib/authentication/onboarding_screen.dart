import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({Key? key, required this.onComplete})
      : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<IntroductionScreenState> _introKey = GlobalKey();
  final DateTime _appAccessDate = DateTime(2025, 4, 6);

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    // Also store the user's name who initiated the recovery journey
    await prefs.setString('recoveryInitiator', 'davytheprogrammer');
    // Store the date they started their journey
    await prefs.setString('journeyStartDate', _appAccessDate.toIso8601String());
    widget.onComplete(); // Call the onComplete callback
  }

  @override
  Widget build(BuildContext context) {
    final PageDecoration pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 17.0,
        color: Colors.grey.shade800,
        height: 1.5,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
      bodyAlignment: Alignment.center,
      titlePadding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
    );

    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: Colors.white,
      pages: [
        PageViewModel(
          title: "Your Gambling Recovery Journey",
          body:
              "Congratulations on taking this brave first step. Acknowledging a gambling problem is challenging, but it's the beginning of your path to recovery and financial wellness.",
          image: Lottie.asset(
            'assets/animations/welcome.json',
            height: 300,
          ),
          decoration: pageDecoration,
          footer: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              "You're not alone in this journey",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        PageViewModel(
          title: "Track Your Recovery Progress",
          body:
              "Monitor your gambling-free days, financial improvements, and mood changes with personalized tracking tools. Celebrate your milestones and understand your triggers.",
          image: Lottie.asset(
            'assets/animations/progress.json',
            height: 300,
          ),
          decoration: pageDecoration,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Day-by-day progress tracking",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PageViewModel(
          title: "Gambling Triggers & Insights",
          body:
              "Identify patterns in your gambling behavior through AI-powered analytics. Understand your specific triggers and develop personalized strategies to overcome urges.",
          image: Lottie.asset(
            'assets/animations/ai_analytics.json',
            height: 280,
          ),
          decoration: pageDecoration,
          footer: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Your data stays private & secure",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.0),
                  ),
                ),
                child: const Text(
                  'BEGIN MY RECOVERY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      onDone: _completeOnboarding,
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      skip: Text(
        'Skip',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      next: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      done: Text(
        'Done',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      curve: Curves.easeInOut,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 16.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.grey.shade400,
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      isProgressTap: true,
      isProgress: true,
      freeze: false,
      animationDuration: 400,
    );
  }
}
