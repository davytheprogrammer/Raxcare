import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import '../../form/relapseform.dart';
import '../controllers/home_controller.dart';

// State pattern maintained with enhanced states
abstract class CheckInState {
  Widget buildContent(BuildContext context, _CheckInCardState state);
  void onCheckIn(BuildContext context, _CheckInCardState state);
  void onRelapse(BuildContext context, _CheckInCardState state);
  Color getGradientStart();
  Color getGradientEnd();
  String getMotivationalQuote();
}

// Default state with enhanced motivational content
class ActiveCheckInState implements CheckInState {
  // Motivational quotes specifically for gambling recovery
  final List<String> _motivationalQuotes = [
    "Every day gambling-free is a victory worth celebrating.",
    "Your freedom from gambling is worth more than any bet ever could be.",
    "Recovery happens one choice, one day, one moment at a time.",
    "Financial peace comes from decisions you're making right now.",
    "Your strength is greater than any gambling urge.",
    "Today's choice to stay gambling-free builds tomorrow's freedom.",
    "Your life is too valuable to gamble away.",
    "The best bet you can make is on yourself and your recovery.",
  ];

  String getMotivationalQuote() {
    return _motivationalQuotes[Random().nextInt(_motivationalQuotes.length)];
  }

  @override
  Widget buildContent(BuildContext context, _CheckInCardState state) {
    final daysSober = state.widget.controller.getDaysSober();
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 360;
    final quote = getMotivationalQuote();
    final bool isCheckingIn = state._isCheckingIn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with responsive text sizes
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  Text(
                    'Daily Recovery Check-In',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              // Motivational quote with responsive padding
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 16,
                  vertical: isSmallScreen ? 4 : 8,
                ),
                child: Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current streak visualization - made responsive
        Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 10),
          child: Column(
            children: [
              _buildStreakDisplay(context, daysSober, isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Interactive check-in button - height adjusted for small screens
              Container(
                width: double.infinity,
                height: isSmallScreen ? 60 : 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: state.widget.controller.hasCheckedInToday
                    ? _buildCheckedInStatus(context, isSmallScreen)
                    : _buildCheckInButton(
                        context, state, isCheckingIn, isSmallScreen),
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Additional stats - now more compact
        if (daysSober > 0) _buildInsightRow(context, daysSober, isSmallScreen),

        // Setback reporting - smaller for compact view
        Padding(
          padding: EdgeInsets.only(top: isSmallScreen ? 10 : 14),
          child: TextButton.icon(
            onPressed: () => state.handleRelapse(),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: isSmallScreen ? 14 : 16,
              color: Colors.white.withOpacity(0.7),
            ),
            label: Text(
              'Report a setback',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 6 : 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakDisplay(
      BuildContext context, int days, bool isSmallScreen) {
    // Circle streak counter with responsive sizes
    final circleSize = isSmallScreen ? 100.0 : 120.0;
    final innerCircleSize = circleSize * 0.85;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: days > 0
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                blurRadius: isSmallScreen ? 15 : 20,
                spreadRadius: isSmallScreen ? 3 : 5,
              ),
            ],
          ),
        ),
        // Progress circle
        SizedBox(
          width: circleSize,
          height: circleSize,
          child: CircularProgressIndicator(
            value: days > 0 ? (days % 30) / 30 : 0,
            strokeWidth: isSmallScreen ? 6 : 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            color: Colors.white,
          ),
        ),
        // Inner circle with days count
        Container(
          width: innerCircleSize,
          height: innerCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                days.toString(),
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 30 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'DAYS',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckedInStatus(BuildContext context, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade300,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Text(
              'CHECKED IN TODAY',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        StreamBuilder<DateTime>(
          stream: Stream.periodic(
              const Duration(seconds: 1), (_) => DateTime.now()),
          builder: (context, snapshot) {
            final now = DateTime.now();
            final tomorrow = DateTime(now.year, now.month, now.day + 1);
            final remaining = tomorrow.difference(now);

            return Text(
              'Next check-in in ${remaining.inHours}h ${(remaining.inMinutes % 60)}m',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCheckInButton(BuildContext context, _CheckInCardState state,
      bool isCheckingIn, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isCheckingIn ? null : () => state.handleCheckIn(),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Center(
          child: isCheckingIn
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isSmallScreen ? 20 : 24,
                      height: isSmallScreen ? 20 : 24,
                      child: CircularProgressIndicator(
                        strokeWidth: isSmallScreen ? 2 : 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      'CHECKING IN...',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: isSmallScreen ? 0.5 : 1,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 10),
                    Text(
                      'CHECK IN NOW',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: isSmallScreen ? 0.5 : 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(BuildContext context, int days, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 12,
        horizontal: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInsightItem(
            context,
            title: '${(days / 7).floor()}',
            subtitle: 'WEEKS',
            icon: Icons.calendar_view_week,
            isSmallScreen: isSmallScreen,
          ),
          _buildInsightDivider(isSmallScreen),
          _buildInsightItem(
            context,
            title: '${(days / 30).floor()}',
            subtitle: 'MONTHS',
            icon: Icons.calendar_month,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightDivider(bool isSmallScreen) {
    return Container(
      width: 1,
      height: isSmallScreen ? 30 : 40,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildInsightItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: isSmallScreen ? 14 : 16,
            ),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 10 : 11,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  @override
  void onCheckIn(BuildContext context, _CheckInCardState state) =>
      state.handleCheckIn();

  @override
  void onRelapse(BuildContext context, _CheckInCardState state) =>
      state.handleRelapse();

  @override
  Color getGradientStart() => const Color(0xFF9333EA);

  @override
  Color getGradientEnd() => const Color(0xFF4F46E5);
}

// Celebration state with enhanced animations and visuals
class MilestoneCheckInState implements CheckInState {
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  final List<String> _celebrationQuotes = [
    "What an achievement! Your commitment to recovery is inspiring!",
    "This milestone proves your incredible strength and determination!",
    "Look how far you've come in your recovery journey. Incredible!",
    "You're breaking free from gambling's chains with every milestone!",
    "Every day gambling-free is building your bright new future!",
  ];

  String getMotivationalQuote() {
    return _celebrationQuotes[Random().nextInt(_celebrationQuotes.length)];
  }

  @override
  Widget buildContent(BuildContext context, _CheckInCardState state) {
    _confettiController.play();
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Stack(
      children: [
        // Main content
        ActiveCheckInState().buildContent(context, state),

        // Confetti effect
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: isSmallScreen ? 3 : 5,
            minBlastForce: 1,
            emissionFrequency: 0.05,
            numberOfParticles: isSmallScreen ? 15 : 20,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),

        // Milestone badge - adjusted for small screens
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: isSmallScreen ? 3 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: isSmallScreen ? 14 : 16,
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Text(
                  'MILESTONE!',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void onCheckIn(BuildContext context, _CheckInCardState state) =>
      ActiveCheckInState().onCheckIn(context, state);

  @override
  void onRelapse(BuildContext context, _CheckInCardState state) =>
      ActiveCheckInState().onRelapse(context, state);

  @override
  Color getGradientStart() => const Color(0xFFFF6B6B);

  @override
  Color getGradientEnd() => const Color(0xFFFF8E53);
}

class CheckInCard extends StatefulWidget {
  final HomeController controller;
  final VoidCallback onCheckIn;

  const CheckInCard({
    Key? key,
    required this.controller,
    required this.onCheckIn,
  }) : super(key: key);

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  CheckInState state = ActiveCheckInState();
  bool _isCheckingIn = false;
  bool _animatingMilestone = false;

  @override
  void initState() {
    super.initState();

    // First initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Now initialize the animation after the controller is created
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _updateState();
    widget.controller.addListener(_updateUI);
    _animationController.forward();
  }

  void _updateState() {
    setState(() {
      state = widget.controller.shouldCelebrate()
          ? MilestoneCheckInState()
          : ActiveCheckInState();
    });
  }

  void _updateUI() {
    bool shouldCelebrate = widget.controller.shouldCelebrate();

    // Animate to celebration state if needed
    if (shouldCelebrate && !_animatingMilestone) {
      setState(() {
        _animatingMilestone = true;
      });

      // Reset animation controller
      _animationController.reset();

      // Play scale-down animation
      _animationController.forward().then((_) {
        // Switch state and play scale-up animation
        setState(() {
          state = MilestoneCheckInState();
          _animationController.reset();
        });

        _animationController.forward().then((_) {
          setState(() {
            _animatingMilestone = false;
          });
        });
      });
    } else if (!shouldCelebrate && !(state is ActiveCheckInState)) {
      // Switch back to active state with animation
      _animationController.reset();

      setState(() {
        state = ActiveCheckInState();
      });

      _animationController.forward();
    } else {
      _updateState();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateUI);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> handleCheckIn() async {
    // Don't proceed if already checking in
    if (_isCheckingIn) return;

    setState(() {
      _isCheckingIn = true;
    });

    // Perform check-in operation
    if (await _showCheckInDialog()) {
      try {
        await widget.controller.checkIn(context);
        widget.onCheckIn();

        // Update UI animation handled by _updateUI listener
      } catch (e) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking in: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isCheckingIn = false;
    });
  }

  Future<bool> _showCheckInDialog() async {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network(
                    'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                    width: isSmallScreen ? 120 : 150,
                    height: isSmallScreen ? 120 : 150,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'Check In For Today',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: state.getGradientEnd(),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    'Confirm that you have stayed gambling-free today?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Not Yet',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.getGradientEnd(),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 18 : 24,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Yes, I Did It!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> handleRelapse() async {
    // Show supportive dialog for relapse reporting
    if (await _showRelapseDialog()) {
      try {
        await widget.controller.handleRelapse(context);

        // Show form for additional details
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RelapseFormScreen()),
        );

        setState(() {
          state = ActiveCheckInState();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showRelapseDialog() async {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.network(
                    'https://assets4.lottiefiles.com/packages/lf20_qpwbiyxf.json',
                    width: isSmallScreen ? 100 : 120,
                    height: isSmallScreen ? 100 : 120,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'A Moment of Truth',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    'Acknowledging setbacks is part of the healing process. Would you like to reset your counter and learn from this experience?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    'Remember: Recovery is not linear, and every new day is a fresh opportunity.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 18 : 24,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Reset Counter',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        // Reduced margins for smaller card
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [state.getGradientStart(), state.getGradientEnd()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: state.getGradientEnd().withOpacity(0.3),
              blurRadius: isSmallScreen ? 15 : 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // Reduced padding for more compact card
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: state.buildContent(context, this),
        ),
      ),
    );
  }
}
