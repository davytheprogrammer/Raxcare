import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat.dart';
import 'widgets/check_in_card.dart';
import 'widgets/progress_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/motivation_card.dart';
import 'widgets/celebration_dialog.dart';
import 'controllers/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  late final ConfettiController _confettiController;
  late final AnimationController _animationController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Chat()),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Your Journey',
          style: GoogleFonts.poppins(
            color: Colors.blue[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.settings, color: Colors.blue[900]),
          onPressed: () {
            // TODO: Implement settings
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.blue[900]),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.emergency, color: Colors.red[700]),
            onPressed: () {
              // TODO: Implement SOS
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckInCard(
              controller: _controller,
              onCheckIn: () {
                _animationController.forward(from: 0);
                if (_controller.shouldCelebrate()) {
                  _confettiController.play();
                  showDialog(
                    context: context,
                    builder: (context) => CelebrationDialog(
                      confettiController: _confettiController,
                      daysSober: _controller.getDaysSober(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topRight,
              child: const QuickActions(),
            ),
            const SizedBox(height: 20),
            ProgressCard(
              controller: _controller,
              progressAnimation: _progressAnimation,
            ),
            const SizedBox(height: 20),
            const MotivationCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToChat(context),
        backgroundColor: Colors.blue[900],
        tooltip: 'Chat with AI',
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
    );
  }
}
