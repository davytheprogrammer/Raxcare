import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../form/relapseform.dart';
import '../controllers/home_controller.dart';

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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateUI);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() => setState(() {});

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
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
        LinearProgressIndicator(
          value: progress / nextMilestone,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Next milestone: $nextMilestone days',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
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
            color: Colors.blue[900],
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
              backgroundColor: Colors.blue[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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

  Future<void> _handleCheckIn() async {
    final shouldProceed = await _showHonestyReminder();
    if (shouldProceed ?? false) {
      await widget.controller.checkIn(context);
      widget.onCheckIn();

      if (widget.controller.shouldCelebrate()) {
        _showCelebrationDialog();
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
            color: Colors.blue[900],
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
              backgroundColor: Colors.blue[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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

  Future<void> _handleRelapse() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'I Had a Relapse',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
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
              backgroundColor: Colors.blue[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            color: Colors.blue[900],
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
          color: Colors.blue[900],
        ),
      ),
      ],
    ),
    actions: [
    ElevatedButton(
    onPressed: () => Navigator.pop(context),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue[900],
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
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
    final successDays = widget.controller.getDaysSober();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Daily Check-in',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.controller.hasCheckedInToday
                    ? null
                    : _handleCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  disabledBackgroundColor: Colors.white.withOpacity(0.7),
                ),
                child: Text(
                  widget.controller.hasCheckedInToday
                      ? '✓ Checked In Today'
                      : 'Check In Now',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildProgressIndicator(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Days', successDays.toString()),
                  _buildStatColumn(
                    'Weeks',
                    (successDays / 7).floor().toString(),
                  ),
                  _buildStatColumn(
                    'Months',
                    (successDays / 30).floor().toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!widget.controller.hasCheckedInToday && successDays > 0)
                Text(
                  "Don't forget to check in today!",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _handleRelapse,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                ),
                child: Text(
                  'I Had a Relapse',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}