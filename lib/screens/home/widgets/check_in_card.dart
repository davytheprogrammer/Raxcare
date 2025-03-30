import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../form/relapseform.dart';
import '../controllers/home_controller.dart';

// Base interface for different CheckInCard states
abstract class CheckInState {
  Widget buildUI(BuildContext context, _CheckInCardState state);
  void handleCheckIn(BuildContext context, _CheckInCardState state);
  void handleRelapse(BuildContext context, _CheckInCardState state);
  Color getPrimaryColor();
  Color getSecondaryColor();
}



// Default state implementation
class NormalCheckInState implements CheckInState {
  @override
  Widget buildUI(BuildContext context, _CheckInCardState state) {
    final successDays = state.widget.controller.getDaysSober();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Text(
          'Daily Check-in',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: state.widget.controller.hasCheckedInToday
              ? null
              : () => state.handleCheckIn(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            disabledBackgroundColor: Colors.white.withOpacity(0.7),
            elevation: 0,
          ),
          child: Text(
            state.widget.controller.hasCheckedInToday
                ? '✓ Checked In Today'
                : 'Check In Now',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: getSecondaryColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        state._buildProgressIndicator(),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            state._buildStatColumn('Days', successDays.toString()),
            state._buildStatColumn(
              'Weeks',
              (successDays / 7).floor().toString(),
            ),
            state._buildStatColumn(
              'Months',
              (successDays / 30).floor().toString(),
            ),
          ],
        ),
        if (!state.widget.controller.hasCheckedInToday && successDays > 0) ...[
          const SizedBox(height: 12),
          Text(
            "Don't forget to check in today!",
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => state.handleRelapse(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'I Had a Relapse',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  void handleCheckIn(BuildContext context, _CheckInCardState state) {
    state._showHonestyReminder();
  }

  @override
  void handleRelapse(BuildContext context, _CheckInCardState state) {
    state.handleRelapse();
  }

  @override
  Color getPrimaryColor() => Colors.blue[700]!;

  @override
  Color getSecondaryColor() => Colors.blue[900]!;
}

// Celebratory state when milestones are reached
class CelebrateCheckInState implements CheckInState {
  @override
  Widget buildUI(BuildContext context, _CheckInCardState state) {
    final ui = NormalCheckInState().buildUI(context, state);
    // Return enhanced UI with celebration effects
    return Stack(
      children: [
        ui,
        Positioned(
          top: 10,
          right: 10,
          child: Icon(
            Icons.celebration,
            color: Colors.amber[300],
            size: 24,
          ),
        ),
      ],
    );
  }

  @override
  void handleCheckIn(BuildContext context, _CheckInCardState state) {
    NormalCheckInState().handleCheckIn(context, state);
  }

  @override
  void handleRelapse(BuildContext context, _CheckInCardState state) {
    NormalCheckInState().handleRelapse(context, state);
  }

  @override
  Color getPrimaryColor() => Colors.indigo[600]!;

  @override
  Color getSecondaryColor() => Colors.indigo[900]!;
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

class _CheckInCardState extends State<CheckInCard> {
  late CheckInState currentState;

  @override
  void initState() {
    super.initState();
    // Determine initial state based on controller data
    _updateState();
    widget.controller.addListener(_updateUI);
  }

  void _updateState() {
    if (widget.controller.shouldCelebrate()) {
      currentState = CelebrateCheckInState();
    } else {
      currentState = NormalCheckInState();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    setState(() {
      _updateState();
    });
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = widget.controller.getDaysSober();
    final nextMilestone = widget.controller.milestones.firstWhere(
          (milestone) => milestone > progress,
      orElse: () => progress + 30,
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress / nextMilestone,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Next milestone: $nextMilestone days',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<bool?> _showHonestyReminder() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        title: Text(
          'Moment of Reflection',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: currentState.getSecondaryColor(),
          ),
        ),
        content: Text(
          'Remember, this journey is about your personal growth. Being honest with yourself is the first step toward lasting change. Are you sure you want to check in for today?',
          style: GoogleFonts.poppins(
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Let me think',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentState.getSecondaryColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Yes, Check In',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleCheckIn() async {
    final shouldProceed = await _showHonestyReminder();
    if (shouldProceed ?? false) {
      await widget.controller.checkIn(context);
      widget.onCheckIn();

      if (widget.controller.shouldCelebrate()) {
        _showCelebrationDialog();
        setState(() {
          currentState = CelebrateCheckInState();
        });
      }
    }
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Congratulations! 🎉',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: currentState.getSecondaryColor(),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve reached ${widget.controller.getDaysSober()} days!',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Text(
              'Keep going strong! Every day is a victory.',
              style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentState.getSecondaryColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Thank you!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleRelapse() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'I Had a Relapse',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: currentState.getSecondaryColor(),
          ),
        ),
        content: Text(
          'Remember, relapse is a part of recovery, not the end of it. Would you like to record this experience to help understand and learn from it?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Not Now',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentState.getSecondaryColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Yes, Record It',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldProceed ?? false) {
      await _showEncouragementDialog();
      await widget.controller.handleRelapse(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RelapseFormScreen(),
        ),
      );
      setState(() {
        currentState = NormalCheckInState();
      });
    }
  }

  Future<void> _showEncouragementDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'You Are Stronger Than You Think',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: currentState.getSecondaryColor(),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Every setback is a setup for a comeback. Your honesty and courage in acknowledging this moment shows your commitment to growth.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Text(
              'Let us understand what led to this moment and use it to grow stronger.',
              style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic,
                color: currentState.getSecondaryColor(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentState.getSecondaryColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Reduced from 8
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Added margins for better spacing
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              currentState.getPrimaryColor(),
              currentState.getSecondaryColor()
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
          child: currentState.buildUI(context, this),
        ),
      ),
    );
  }
}