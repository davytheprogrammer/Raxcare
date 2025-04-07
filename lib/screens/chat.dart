import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _fadeController;
  int _gambleFreeStreak =
      1; // Default to 1 day (based on current date vs recovery start)
  String _username = 'davytheprogrammer';
  DateTime _recoveryStartDate = DateTime(2025, 4, 6); // Recovery start date
  DateTime _currentDate = DateTime(2025, 4, 7); // Current date

  // Chat themes
  int _selectedTheme = 0;
  final List<Map<String, dynamic>> _chatThemes = [
    {
      'name': 'Ocean',
      'colors': {
        'primary': Color(0xFF0D47A1),
        'secondary': Color(0xFF2196F3),
        'background': Color(0xFFF5F7FA),
        'bubbleUser': Color(0xFF0D47A1),
        'bubbleAI': Colors.white,
      },
    },
    {
      'name': 'Forest',
      'colors': {
        'primary': Color(0xFF2E7D32),
        'secondary': Color(0xFF4CAF50),
        'background': Color(0xFFF5F8F5),
        'bubbleUser': Color(0xFF2E7D32),
        'bubbleAI': Colors.white,
      },
    },
    {
      'name': 'Calm',
      'colors': {
        'primary': Color(0xFF5C6BC0),
        'secondary': Color(0xFF9FA8DA),
        'background': Color(0xFFF8F9FD),
        'bubbleUser': Color(0xFF5C6BC0),
        'bubbleAI': Colors.white,
      },
    },
  ];

  // Suggested questions for gambling recovery
  final List<String> _suggestedQuestions = [
    "How can I handle gambling urges?",
    "What financial recovery steps should I take?",
    "How do I rebuild trust with loved ones?",
    "What are healthy replacement activities?",
    "How to avoid gambling triggers?",
    "Ways to manage gambling debt?",
  ];

  // API settings - kept hardcoded as requested
  static const String API_URL = "https://api.together.xyz/v1/chat/completions";
  static const String API_KEY =
      "4db152889da5afebdba262f90e4cdcf12976ee8b48d9135c2bb86ef9b0d12bdd";

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _calculateGambleFreeStreak();
    _loadThemePreference();
    _loadInitialMessage();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getInt('chat_theme') ?? 0;
    });
  }

  Future<void> _saveThemePreference(int themeIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_theme', themeIndex);
  }

  void _calculateGambleFreeStreak() {
    // Calculate days since recovery start date
    _gambleFreeStreak = _currentDate.difference(_recoveryStartDate).inDays;
    if (_gambleFreeStreak < 0) _gambleFreeStreak = 0;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadInitialMessage() {
    _addMessage(
      "Hello ${_username}! I'm your Recovery AI Assistant. I see you're on day $_gambleFreeStreak of your gambling-free journey. How can I support you today?",
      false,
    );
  }

  Future<String> _fetchAIResponse(String userMessage) async {
    try {
      final formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(_currentDate);

      final response = await http
          .post(
            Uri.parse(API_URL),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $API_KEY",
            },
            body: json.encode({
              "model": "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO",
              "messages": [
                {
                  "role": "system",
                  "content": """
                You are an empathetic AI counselor specialized in gambling addiction recovery for the app RAX Care. Your responses should be:

                1. Specifically focused on gambling addiction recovery (not other addictions)
                2. Informed by cognitive-behavioral therapy principles for problem gambling
                3. Supportive, non-judgmental, and focused on progress
                4. Brief but meaningful (2-3 sentences max)
                5. Personalized to the user's gambling-free streak when relevant

                Current date: $formattedDate
                User: $_username
                Gambling-free days: $_gambleFreeStreak
                Recovery start date: ${DateFormat('yyyy-MM-dd').format(_recoveryStartDate)}

                Remember to:
                - Acknowledge the user's gambling-free streak when appropriate
                - Focus on specific gambling recovery techniques
                - Provide practical financial recovery advice when asked
                - Emphasize that recovery is about progress, not perfection
                - Keep responses concise, clear, and focused on gambling addiction
                """
                },
                {"role": "user", "content": userMessage}
              ],
              "temperature": 0.7,
              "max_tokens": 150,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        return responseJson['choices'][0]['message']['content'].trim();
      }
      throw Exception("API Error: ${response.statusCode}");
    } catch (e) {
      return "I apologize, but I'm having trouble connecting right now. Please try again in a moment.";
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: _currentDate,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmit(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    _messageController.clear();
    _addMessage(trimmedText, true);

    setState(() => _isTyping = true);
    try {
      final response = await _fetchAIResponse(trimmedText);
      if (mounted) {
        setState(() => _isTyping = false);
        _addMessage(response, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to send message. Please try again.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _askSuggestedQuestion(String question) {
    _handleSubmit(question);
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Chat Theme',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    _chatThemes.length,
                    (index) => _buildThemeOption(index),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(int index) {
    final theme = _chatThemes[index];
    final colors = theme['colors'] as Map<String, Color>;
    final isSelected = _selectedTheme == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = index;
        });
        _saveThemePreference(index);
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        width: 100,
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors['primary']!,
                    colors['secondary']!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors['primary']!.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ]
                    : null,
              ),
            ),
            SizedBox(height: 8),
            Text(
              theme['name'],
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors['primary'] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme colors
    final colors = _chatThemes[_selectedTheme]['colors'] as Map<String, Color>;

    return Scaffold(
      backgroundColor: colors['background'],
      appBar: _buildAppBar(colors),
      body: _buildBody(colors),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, Color> colors) {
    return AppBar(
      backgroundColor: colors['primary'],
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            radius: 16,
            child: Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recovery Assistant',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Day $_gambleFreeStreak · Gambling-free',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.color_lens_outlined),
          onPressed: _showThemeSelector,
          tooltip: 'Change Theme',
        ),
        IconButton(
          icon: Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(colors),
          tooltip: 'Help',
        ),
      ],
    );
  }

  Widget _buildBody(Map<String, Color> colors) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          _buildBackground(colors),
          Column(
            children: [
              Expanded(
                child: _buildMessageList(colors),
              ),
              _buildSuggestedQuestions(colors),
              if (_isTyping) _buildTypingIndicator(colors),
              _buildMessageInput(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Map<String, Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors['primary']!,
            colors['background']!,
          ],
          stops: const [0.0, 0.1],
        ),
      ),
    );
  }

  Widget _buildMessageList(Map<String, Color> colors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _buildMessageBubble(_messages[index], colors),
    );
  }

  Widget _buildSuggestedQuestions(Map<String, Color> colors) {
    // Only show suggestions if there are a few messages already
    if (_messages.length < 2) return SizedBox.shrink();

    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 10),
            child: ElevatedButton(
              onPressed: () =>
                  _askSuggestedQuestion(_suggestedQuestions[index]),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors['primary']!.withOpacity(0.1),
                foregroundColor: colors['primary'],
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colors['primary']!.withOpacity(0.3),
                  ),
                ),
              ),
              child: Text(
                _suggestedQuestions[index],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator(Map<String, Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors['primary']!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                DefaultTextStyle(
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colors['primary'],
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      WavyAnimatedText('Thinking...'),
                    ],
                    isRepeatingAnimation: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Map<String, Color> colors) {
    final bubbleColor =
        message.isUser ? colors['bubbleUser']! : colors['bubbleAI']!;
    final textColor = message.isUser ? Colors.white : Colors.black87;
    final timestampColor =
        message.isUser ? Colors.white.withOpacity(0.7) : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) _buildAvatar(true, colors),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft:
                      message.isUser ? Radius.circular(20) : Radius.circular(4),
                  bottomRight:
                      message.isUser ? Radius.circular(4) : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      color: timestampColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser) _buildAvatar(false, colors),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAI, Map<String, Color> colors) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isAI ? colors['primary'] : colors['primary']!.withOpacity(0.7),
      child: Icon(
        isAI ? Icons.support_agent : Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageInput(Map<String, Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.textsms_outlined,
                    color: Colors.grey.shade400,
                  ),
                ),
                onSubmitted: _handleSubmit,
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: colors['primary'],
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: () => _handleSubmit(_messageController.text),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(Map<String, Color> colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Gambling Recovery Chat',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colors['primary'],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: Icons.psychology,
              text: 'Get personalized gambling recovery support',
              color: colors['primary']!,
            ),
            _buildHelpItem(
              icon: Icons.attach_money,
              text: 'Ask about financial rebuilding strategies',
              color: colors['primary']!,
            ),
            _buildHelpItem(
              icon: Icons.healing,
              text: 'Learn techniques to resist gambling urges',
              color: colors['primary']!,
            ),
            _buildHelpItem(
              icon: Icons.people_outline,
              text: 'Get advice for rebuilding damaged relationships',
              color: colors['primary']!,
            ),
            Divider(),
            _buildHelpItem(
              icon: Icons.warning_amber,
              text:
                  'In crisis? Call National Problem Gambling Helpline: 1-800-522-4700',
              color: Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: colors['primary'],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
      {required IconData icon, required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
