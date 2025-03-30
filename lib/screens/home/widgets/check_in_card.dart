import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../form/relapseform.dart';
import '../controllers/home_controller.dart';

// State interface for CheckInCard
abstract class CheckInState {
  Widget buildContent(BuildContext context, _CheckInCardState state);
  void onCheckIn(BuildContext context, _CheckInCardState state);
  void onRelapse(BuildContext context, _CheckInCardState state);
  Color getGradientStart();
  Color getGradientEnd();
}

// Default state
class ActiveCheckInState implements CheckInState {
  @override
  Widget buildContent(BuildContext context, _CheckInCardState state) {
    final daysSober = state.widget.controller.getDaysSober();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Check-In',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: state.widget.controller.hasCheckedInToday
              ? null
              : () => state.handleCheckIn(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: getGradientEnd(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: StadiumBorder(),
            elevation: 0,
          ),
          child: Text(
            state.widget.controller.hasCheckedInToday ? '✓ Done' : 'Check In',
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(height: 12),
        _buildMilestoneRow(daysSober),
        if (!state.widget.controller.hasCheckedInToday && daysSober > 0)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tap to check in today!',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic),
            ),
          ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => state.handleRelapse(),
          child: Text(
            'Relapsed?',
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
                decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(int days) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('Days', days.toString()),
          _statItem('Weeks', (days / 7).floor().toString()),
          _statItem('Months', (days / 30).floor().toString()),
        ],
      );

  Widget _statItem(String label, String value) => Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        ],
      );

  @override
  void onCheckIn(BuildContext context, _CheckInCardState state) =>
      state.handleCheckIn();

  @override
  void onRelapse(BuildContext context, _CheckInCardState state) =>
      state.handleRelapse();

  @override
  Color getGradientStart() => Color(0xFF6B48FF);

  @override
  Color getGradientEnd() => Color(0xFF00DDEB);
}

// Celebration state
class MilestoneCheckInState implements CheckInState {
  @override
  Widget buildContent(BuildContext context, _CheckInCardState state) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ActiveCheckInState().buildContent(context, state),
        Positioned(
          top: 0,
          right: 0,
          child: Icon(Icons.star, color: Colors.yellowAccent, size: 20),
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
  Color getGradientStart() => Color(0xFFFF7E5F);

  @override
  Color getGradientEnd() => Color(0xFFfeb47b);
}

class CheckInCard extends StatefulWidget {
  final HomeController controller;
  final VoidCallback onCheckIn;

  const CheckInCard(
      {Key? key, required this.controller, required this.onCheckIn})
      : super(key: key);

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  CheckInState state = ActiveCheckInState(); // Initialize directly

  @override
  void initState() {
    super.initState();
    _updateState();
    widget.controller.addListener(_updateUI); // Restore original listener name
  }

  void _updateState() {
    state = widget.controller.shouldCelebrate()
        ? MilestoneCheckInState()
        : ActiveCheckInState();
  }

  void _updateUI() {
    setState(_updateState); // Restore _updateUI method
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateUI); // Match listener name
    super.dispose();
  }

  Future<void> handleCheckIn() async {
    if (await _showPrompt(
        'Check-In Time', 'Are you ready to mark today as a win?', 'Yes')) {
      await widget.controller.checkIn(context);
      widget.onCheckIn();
      if (widget.controller.shouldCelebrate()) {
        setState(() => state = MilestoneCheckInState());
        _showPrompt('Milestone Achieved! 🎉',
            'You’ve hit ${widget.controller.getDaysSober()} days!', 'Awesome');
      }
    }
  }

  Future<void> handleRelapse() async {
    if (await _showPrompt(
        'Relapse?', 'Want to log this to grow stronger?', 'Yes')) {
      await _showPrompt(
          'You’ve Got This!', 'Every step teaches us something.', 'Continue');
      await widget.controller.handleRelapse(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => RelapseFormScreen()));
      setState(() => state = ActiveCheckInState());
    }
  }

  Future<bool> _showPrompt(
      String title, String message, String confirmText) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: state.getGradientEnd())),
            content: Text(message,
                style: GoogleFonts.poppins(color: Colors.black87)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.getGradientEnd(),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(confirmText,
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [state.getGradientStart(), state.getGradientEnd()],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: state.buildContent(context, this),
    );
  }
}
