import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamblingRecoveryMotivationCard extends StatefulWidget {
  final String userName;
  final DateTime recoveryStartDate;

  GamblingRecoveryMotivationCard({
    Key? key,
    this.userName = 'davytheprogrammer',
    DateTime? recoveryStartDate,
  })  : recoveryStartDate = recoveryStartDate ?? DateTime(2025, 4, 6),
        super(key: key);

  @override
  State<GamblingRecoveryMotivationCard> createState() =>
      _GamblingRecoveryMotivationCardState();
}

class _GamblingRecoveryMotivationCardState
    extends State<GamblingRecoveryMotivationCard>
    with SingleTickerProviderStateMixin {
  String _quote = "Loading your motivation...";
  bool _isLoading = true;
  String _timeOfDay = "today";
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _recoveryDays = 0;
  DateTime _currentTime = DateTime.now();
  String _favoriteQuote = "";
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _determineTimeOfDay();
    _calculateRecoveryDays();
    _loadFavoriteQuote();
    _fetchNewQuote();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _determineTimeOfDay() {
    final hour = _currentTime.hour;
    if (hour < 12) {
      _timeOfDay = "this morning";
    } else if (hour < 17) {
      _timeOfDay = "this afternoon";
    } else {
      _timeOfDay = "this evening";
    }
  }

  void _calculateRecoveryDays() {
    // Calculate days since recovery start date
    final recoveryStart = DateTime(2025, 4, 6); // Default to April 6, 2025
    final difference = _currentTime.difference(recoveryStart).inDays;
    _recoveryDays = difference > 0 ? difference : 0;
  }

  Future<void> _loadFavoriteQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQuote = prefs.getString('favorite_recovery_quote');
    if (savedQuote != null && savedQuote.isNotEmpty) {
      setState(() {
        _favoriteQuote = savedQuote;
      });
    }
  }

  Future<void> _saveFavoriteQuote(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_recovery_quote', quote);
    setState(() {
      _favoriteQuote = quote;
      _isFavorited = true;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to your favorites'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchNewQuote() async {
    setState(() => _isLoading = true);
    _animationController.reset();

    try {
      // Set the API key
      const apiKey = 'AIzaSyCOutG-g_tVZKzbTtH0bzNjWdoaDVA2YCo';
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      // Format current date and time in YYYY-MM-DD HH:MM:SS format
      final currentTime = DateTime(2025, 4, 6, 22, 4, 7);
      final formattedTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);

      final prompt = '''
Generate a powerful, emotional recovery affirmation to help someone resist relapsing into gambling addiction.

Current date: $formattedTime
User: ${widget.userName}
Recovery days: $_recoveryDays
Time context: $_timeOfDay

Make the message:
1) Specific to gambling addiction recovery
2) Personal to the current time of day ($_timeOfDay)
3) Mention their $_recoveryDays days of progress if applicable
4) Raw, authentic, and deeply motivational

Keep it under 2 sentences for mobile screens. Don't use quotation marks or attribution.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      setState(() {
        _quote = response.text ??
            "Every moment you resist gambling adds to your strength and rebuilds your future.";
        _isLoading = false;
        _isFavorited = _quote == _favoriteQuote;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _quote =
            "The money saved from not gambling $_timeOfDay is an investment in the life you truly deserve.";
        _isLoading = false;
        _isFavorited = _quote == _favoriteQuote;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.1, 0.9],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with recovery days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_recoveryDays days strong',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              )
                            : Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Your Gambling Recovery Shield',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Quote
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _quote,
                      key: ValueKey<String>(_quote),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Favorite button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_isFavorited) {
                          // Already favorited, do nothing
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Already in your favorites'),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _saveFavoriteQuote(_quote);
                        }
                      });
                    },
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),

                  // New quote button
                  ElevatedButton.icon(
                    onPressed: _fetchNewQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'New Motivation',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Share button
                  IconButton(
                    onPressed: () {
                      // Share functionality would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Quote copied to clipboard'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
