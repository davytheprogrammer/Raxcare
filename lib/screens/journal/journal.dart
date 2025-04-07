import 'package:RaxCare/screens/journal/journal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CBTGuidedJournalScreen extends StatefulWidget {
  const CBTGuidedJournalScreen({Key? key}) : super(key: key);

  @override
  _CBTGuidedJournalScreenState createState() => _CBTGuidedJournalScreenState();
}

class _CBTGuidedJournalScreenState extends State<CBTGuidedJournalScreen>
    with SingleTickerProviderStateMixin {
  // API key for Gemini
  final String _apiKey = 'AIzaSyDd_38eu-JaoOwn_8ofUF2vAQvGSn-Zvto';
  final JournalService _journalService = JournalService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TabController _tabController;

  // Journal entry properties
  JournalEntry? _currentEntry;
  String? _editingDocId;
  bool _isEditing = false;
  bool _isLoadingAI = false;
  bool _hasStartedJournal = false;
  bool _showAIPanel = false;
  bool _isFirstTimeUser = true;
  bool _isOffline = false;

  // AI and CBT-related fields
  String _aiResponse = '';
  String _selectedMood = 'Neutral';
  String _selectedTrigger = '';
  int _gamblingUrgeLevel = 0;
  bool _relapseOccurred = false;
  DateTime _currentDate = DateTime.now();

  // Gemini model and chat
  GenerativeModel? _model;
  ChatSession? _chat;

  // CBT mood options
  final List<String> _moodOptions = [
    'Happy',
    'Calm',
    'Hopeful',
    'Proud',
    'Neutral',
    'Anxious',
    'Stressed',
    'Bored',
    'Sad',
    'Angry'
  ];

  // Gambling-specific triggers
  final List<String> _commonTriggers = [
    'Financial Stress',
    'Boredom',
    'Social Pressure',
    'Gambling Advertisements',
    'Sports Events',
    'Weekend Free Time',
    'Payday',
    'Relationship Issues',
    'Work Stress',
    'Past Wins',
    'Alcohol Consumption',
    'Other'
  ];

  // CBT journal templates for gambling recovery
  final List<Map<String, dynamic>> _journalTemplates = [
    {
      'title': 'Daily Check-in',
      'prompt':
          'How am I feeling today about my gambling recovery? What challenges or victories did I experience?',
      'icon': Icons.checklist_rounded,
    },
    {
      'title': 'Gambling Thought Record',
      'prompt':
          'Situation: What happened that triggered gambling thoughts?\n\nThoughts: What went through my mind?\n\nEmotions: How did I feel?\n\nBehaviors: What did I do?\n\nAlternative Response: What could I think or do differently next time?',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'Urge Surfing Journal',
      'prompt':
          'Describe your gambling urge. How intense is it (1-10)? Where do you feel it in your body? What triggered it? How can you ride this urge without giving in?',
      'icon': Icons.waves_outlined,
    },
    {
      'title': 'Financial Recovery Plan',
      'prompt':
          'What financial goals am I working toward today? What specific steps can I take to repair my finances? How will I handle money triggers without gambling?',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'title': 'Recovery Victory Journal',
      'prompt':
          'Describe a moment today, no matter how small, where you chose recovery over gambling. How did it feel? What strengths did you use?',
      'icon': Icons.emoji_events_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);

    _checkFirstTimeUser();
    _checkConnectivity();
    _initializeGemini();

    // Create a new empty journal entry
    _currentEntry = JournalEntry(
      id: const Uuid().v4(),
      title: '',
      content: '',
      date: DateTime.now(),
      mood: _selectedMood,
      urgeLevel: _gamblingUrgeLevel,
      triggers: [],
      aiInsights: '',
      userId: FirebaseAuth.instance.currentUser!.uid,
    );
  }

  void _initializeGemini() {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      _chat = _model?.startChat();
    } catch (e) {
      print('Error initializing Gemini: $e');
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstTimeUser = prefs.getBool('first_time_journal_user') ?? true;
      if (_isFirstTimeUser) {
        prefs.setBool('first_time_journal_user', false);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Function to get CBT-guided insights from Gemini
  Future<void> _getAIInsights() async {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. AI features are not available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please write in your journal first before requesting insights'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAI = true;
      _aiResponse = '';
    });

    try {
      // Prepare the context for Gemini
      final prompt = '''
You are a specialized CBT (Cognitive Behavioral Therapy) counselor for gambling addiction recovery named GEMINI, embedded within a recovery app. 

Current date and time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_currentDate)}
User's name: davytheprogrammer
Recovery start date: 2025-04-06

The user is journaling about their gambling recovery journey. Their journal content includes:
- Title: ${_titleController.text}
- Content: ${_contentController.text}
- Current mood: $_selectedMood
- Gambling urge level (0-10): $_gamblingUrgeLevel
- Current triggers: ${_selectedTrigger.isNotEmpty ? _selectedTrigger : "None selected"}
- Relapse occurred: ${_relapseOccurred ? 'Yes' : 'No'}

Analyze their writing and respond as GEMINI with compassionate CBT-focused insights:
1. Identify 1-2 thought patterns related to gambling addiction
2. Suggest 2 specific CBT techniques to address challenges mentioned
3. Highlight one strength or sign of progress you notice
4. Ask 1 thoughtful question to promote reflection

Your response should be warm and personalized but concise (max 250 words). Format your response with Markdown for readability. Sign your response as "GEMINI - Your Recovery AI Assistant".
''';

      // Make API call to Gemini
      GenerateContentResponse content = await _chat!.sendMessage(
        Content.text(prompt),
      );

      final response = content.text;

      setState(() {
        _aiResponse = response!;
        _currentEntry?.aiInsights = response;
        _isLoadingAI = false;
        _showAIPanel = true;
      });
    } catch (e) {
      setState(() {
        _isLoadingAI = false;
        _aiResponse =
            "I'm sorry, I couldn't generate insights at the moment. Please try again later.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting AI insights: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectTemplate(int index) {
    final template = _journalTemplates[index];
    setState(() {
      _titleController.text = template['title'];
      _contentController.text = template['prompt'];
      _hasStartedJournal = true;
    });
    Navigator.pop(context);
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Choose a Recovery Journal Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _journalTemplates.length,
                itemBuilder: (context, index) {
                  final template = _journalTemplates[index];
                  return InkWell(
                    onTap: () => _selectTemplate(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              template['icon'],
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  template['prompt'].split('\n')[0],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _moodOptions.map((mood) {
                final isSelected = _selectedMood == mood;

                // Different colors for different moods
                Color chipColor;
                if (['Happy', 'Calm', 'Hopeful', 'Proud'].contains(mood)) {
                  chipColor = Colors.green.shade100;
                } else if (mood == 'Neutral') {
                  chipColor = Colors.blue.shade50;
                } else {
                  chipColor = Colors.orange.shade100;
                }

                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  backgroundColor: chipColor,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedMood = mood;
                      _currentEntry?.mood = mood;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTriggerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What triggered your gambling thoughts?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _commonTriggers.map((trigger) {
                final isSelected = _selectedTrigger == trigger;
                return ChoiceChip(
                  label: Text(trigger),
                  selected: isSelected,
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Theme.of(context).colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedTrigger = trigger;
                      if (_currentEntry != null) {
                        _currentEntry!.triggers = [trigger];
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedTrigger = '';
                    if (_currentEntry != null) {
                      _currentEntry!.triggers = [];
                    }
                  });
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear Selection',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRelapseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Did you gamble today?'),
        content: Text(
          'It\'s okay to be honest - recovery is a journey with ups and downs. Tracking relapses helps identify patterns and improve strategies.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _relapseOccurred = false;
                if (_currentEntry != null) {
                  _currentEntry!.relapseOccurred = false;
                }
              });
              Navigator.pop(context);
            },
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _relapseOccurred = true;
                if (_currentEntry != null) {
                  _currentEntry!.relapseOccurred = true;
                }
              });
              Navigator.pop(context);

              // Show supportive message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Thank you for your honesty. Each day is a new opportunity.'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showUrgeSlider() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate your gambling urge (0-10)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '0 = No urge, 10 = Strongest possible urge',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _gamblingUrgeLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _gamblingUrgeLevel.toString(),
                        activeColor: _getUrgeColor(_gamblingUrgeLevel),
                        onChanged: (value) {
                          setModalState(() {
                            _gamblingUrgeLevel = value.toInt();
                          });
                        },
                      ),
                    ),
                    Text('10', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _getUrgeColor(_gamblingUrgeLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _getUrgeColor(_gamblingUrgeLevel),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getUrgeDescription(_gamblingUrgeLevel),
                      style: TextStyle(
                        color: _getUrgeColor(_gamblingUrgeLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentEntry?.urgeLevel = _gamblingUrgeLevel;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Confirm'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getUrgeColor(int level) {
    if (level <= 3) {
      return Colors.green;
    } else if (level <= 6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getUrgeDescription(int level) {
    if (level <= 1) {
      return 'Minimal Urge';
    } else if (level <= 3) {
      return 'Mild Urge';
    } else if (level <= 5) {
      return 'Moderate Urge';
    } else if (level <= 7) {
      return 'Strong Urge';
    } else {
      return 'Extreme Urge';
    }
  }

  void _showFirstTimeUserGuide() {
    if (!_isFirstTimeUser) return;

    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('CBT-Guided Gambling Recovery Journal')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This journal uses CBT (Cognitive Behavioral Therapy) principles to help with your gambling recovery, enhanced by GEMINI AI for personalized insights.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                context,
                icon: Icons.edit_note,
                title: 'Track Your Journey',
                description:
                    'Journal your thoughts, feelings, and track your urges to gamble.',
              ),
              _buildGuideItem(
                context,
                icon: Icons.psychology_alt,
                title: 'Get CBT Guidance',
                description:
                    'Request insights from GEMINI to identify thought patterns and get CBT techniques.',
              ),
              _buildGuideItem(
                context,
                icon: Icons.insights,
                title: 'Monitor Progress',
                description:
                    'See your recovery journey over time with mood and trigger tracking.',
              ),
              const SizedBox(height: 8),
              Text(
                'Your privacy is important - all journal entries are encrypted and stored securely.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showTemplateSelector();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Start Journaling'),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveJournal() async {
    // Validate form
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please provide both a title and content for your journal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update the current entry with final values
      _currentEntry!.title = _titleController.text.trim();
      _currentEntry!.content = _contentController.text.trim();
      _currentEntry!.date = DateTime.now();
      _currentEntry!.mood = _selectedMood;
      _currentEntry!.urgeLevel = _gamblingUrgeLevel;
      _currentEntry!.triggers =
          _selectedTrigger.isNotEmpty ? [_selectedTrigger] : [];
      _currentEntry!.aiInsights = _aiResponse;
      _currentEntry!.relapseOccurred = _relapseOccurred;

      if (_isEditing && _editingDocId != null) {
        await _journalService.updateJournal(_editingDocId!, _currentEntry!);
      } else {
        // Pass the JournalEntry object directly to the service
        await _journalService.addJournal(_currentEntry!);
      }

      // Reset form and show success message
      setState(() {
        _titleController.clear();
        _contentController.clear();
        _selectedMood = 'Neutral';
        _selectedTrigger = '';
        _gamblingUrgeLevel = 0;
        _relapseOccurred = false;
        _aiResponse = '';
        _hasStartedJournal = false;
        _isEditing = false;
        _editingDocId = null;
        _showAIPanel = false;

        // Create a new empty journal entry
        _currentEntry = JournalEntry(
          id: const Uuid().v4(),
          title: '',
          content: '',
          date: DateTime.now(),
          mood: _selectedMood,
          urgeLevel: _gamblingUrgeLevel,
          triggers: [],
          aiInsights: '',
          userId: FirebaseAuth.instance.currentUser!.uid,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Journal entry saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to entries tab
      _tabController.animateTo(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving journal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editJournal(DocumentSnapshot journal) {
    final data = journal.data() as Map<String, dynamic>;

    setState(() {
      _isEditing = true;
      _editingDocId = journal.id;
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      _selectedMood = data['mood'] ?? 'Neutral';
      _gamblingUrgeLevel = data['urgeLevel'] ?? 0;
      _selectedTrigger =
          data['triggers'] != null && (data['triggers'] as List).isNotEmpty
              ? (data['triggers'] as List)[0]
              : '';
      _relapseOccurred = data['relapseOccurred'] ?? false;
      _aiResponse = data['aiInsights'] ?? '';
      _showAIPanel = _aiResponse.isNotEmpty;
      _hasStartedJournal = true;

      _currentEntry = JournalEntry(
        id: journal.id,
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        date: (data['date'] as Timestamp).toDate(),
        mood: data['mood'] ?? 'Neutral',
        urgeLevel: data['urgeLevel'] ?? 0,
        triggers:
            data['triggers'] != null ? List<String>.from(data['triggers']) : [],
        aiInsights: data['aiInsights'] ?? '',
        relapseOccurred: data['relapseOccurred'] ?? false,
        userId: data['userId'] ?? FirebaseAuth.instance.currentUser!.uid,
      );
    });

    // Switch to compose tab
    _tabController.animateTo(0);
  }

  Future<void> _deleteJournal(String docId) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Journal Entry'),
            content: Text(
                'Are you sure you want to delete this entry? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _journalService.deleteJournal(docId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting journal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOfflineSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are offline. Some features are not available.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check for first-time user to show guide
    if (_isFirstTimeUser) {
      _showFirstTimeUserGuide();
    }

    return Scaffold(
      appBar: AppBar(
        title: FadeIn(
          duration: const Duration(milliseconds: 500),
          child: Row(
            children: [
              Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Recovery Journal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.edit_note),
              text: 'Write',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Entries',
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.cloud_off,
                color: Colors.orange,
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Write Journal Tab
          _buildJournalWriteTab(),

          // Journal Entries Tab
          _buildJournalEntriesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 && _hasStartedJournal
          ? FloatingActionButton(
              onPressed: _saveJournal,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.save),
            )
          : _tabController.index == 0
              ? FloatingActionButton(
                  onPressed: _showTemplateSelector,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.add),
                )
              : null,
    );
  }

  Widget _buildJournalWriteTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_hasStartedJournal)
              _buildEmptyJournalState()
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Journal form
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // CBT tracking section
                    _buildCBTTrackingSection(),
                    const SizedBox(height: 16),

                    // Content field
                    TextFormField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Journal Entry',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // AI insights request button
                    _buildAIInsightsButton(),

                    // AI insights panel
                    if (_showAIPanel || _isLoadingAI) _buildAIInsightsPanel(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyJournalState() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_note,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Begin Your Recovery Journal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Writing about your gambling recovery journey helps identify patterns and build resilience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showTemplateSelector,
                icon: Icon(Icons.add),
                label: Text('Start New Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose from CBT-guided templates or start from scratch',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCBTTrackingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Tracking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showMoodSelector,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mood,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mood: $_selectedMood',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _showUrgeSlider,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed,
                          color: _getUrgeColor(_gamblingUrgeLevel),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Urge: $_gamblingUrgeLevel/10',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showTriggerSelector,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: _selectedTrigger.isNotEmpty
                              ? Theme.of(context).colorScheme.error
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTrigger.isNotEmpty
                                ? 'Trigger: $_selectedTrigger'
                                : 'Select Trigger',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showRelapseDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _relapseOccurred
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: _relapseOccurred
                        ? Border.all(color: Colors.red.shade200)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _relapseOccurred
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: _relapseOccurred
                            ? Colors.red
                            : Colors.grey.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Relapse',
                        style: TextStyle(
                          fontSize: 14,
                          color: _relapseOccurred
                              ? Colors.red
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsButton() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: OutlinedButton.icon(
          onPressed: _isLoadingAI ? null : () => _getAIInsights(),
          icon: Icon(
            Icons.psychology,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            'Get CBT Insights from GEMINI',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsightsPanel() {
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GEMINI CBT Insights',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (_showAIPanel && !_isLoadingAI)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showAIPanel = false;
                        });
                      },
                      iconSize: 20,
                      color: Colors.grey.shade600,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            if (_isLoadingAI)
              Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing your journal entry...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: MarkdownBody(
                  data: _aiResponse,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    h2: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    h3: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    p: const TextStyle(fontSize: 14, height: 1.5),
                    blockquote: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 4,
                        ),
                      ),
                    ),
                    listBullet: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _journalService.getJournals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final journals = snapshot.data!.docs;

        if (journals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 60, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No journal entries yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Your recovery journey starts with a single entry',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0);
                    _showTemplateSelector();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Create First Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: journals.length,
          itemBuilder: (context, index) {
            final journal = journals[index];
            final data = journal.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final mood = data['mood'] ?? 'Neutral';
            final urgeLevel = data['urgeLevel'] ?? 0;
            final hasAiInsights = (data['aiInsights'] ?? '').isNotEmpty;
            final relapseOccurred = data['relapseOccurred'] ?? false;
            final triggers = data['triggers'] as List<dynamic>? ?? [];

            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 50)),
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalDetailScreen(
                        title: data['title'] ?? '',
                        content: data['content'] ?? '',
                        date: date,
                        mood: mood,
                        urgeLevel: urgeLevel,
                        triggers: List<String>.from(triggers),
                        aiInsights: data['aiInsights'] ?? '',
                        relapseOccurred: relapseOccurred,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with date and options
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (relapseOccurred)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Colors.red,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Relapse',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Spacer(),
                            PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey.shade600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                  value: 'edit',
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                  value: 'delete',
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _editJournal(journal);
                                } else if (value == 'delete') {
                                  _deleteJournal(journal.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Content preview
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          data['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ),

                      // Footer with mood, urge level, and AI indicator
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.mood,
                                    size: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mood,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _getUrgeColor(urgeLevel).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 14,
                                    color: _getUrgeColor(urgeLevel),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Urge: $urgeLevel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getUrgeColor(urgeLevel),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (hasAiInsights)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.psychology,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Journal entry model
class JournalDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final DateTime date;
  final String mood;
  final int urgeLevel;
  final List<String> triggers;
  final String aiInsights;
  final bool relapseOccurred;

  const JournalDetailScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.urgeLevel,
    required this.triggers,
    required this.aiInsights,
    required this.relapseOccurred,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(content),
            if (aiInsights.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insights',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(data: aiInsights),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
