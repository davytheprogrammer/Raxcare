import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animate_do/animate_do.dart';

// Enhanced Preferences Service
class PreferencesService {
  static Future<void> saveData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveDateTime(String key, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value.toIso8601String());
  }

  static Future<DateTime?> getDateTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    return value != null ? DateTime.parse(value) : null;
  }
}

// Recovery Goal Model with Gambling-Specific Features
class RecoveryGoal {
  String id;
  String description;
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;
  List<String> reflections;
  String? category;
  int priority; // 1-3 where 1 is highest
  int? gamblingUrgeLevel; // 0-10 scale of gambling urges when creating goal
  List<String>
      cbtTechniques; // List of CBT techniques associated with this goal
  String? triggerSituation; // Specific gambling trigger this goal addresses

  RecoveryGoal({
    required this.description,
    this.isCompleted = false,
    String? id,
    DateTime? createdAt,
    this.completedAt,
    List<String>? reflections,
    this.category,
    this.priority = 2,
    this.gamblingUrgeLevel,
    List<String>? cbtTechniques,
    this.triggerSituation,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        reflections = reflections ?? [],
        cbtTechniques = cbtTechniques ?? [];

  factory RecoveryGoal.fromJson(Map<String, dynamic> json) {
    return RecoveryGoal(
      id: json['id'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      reflections: List<String>.from(json['reflections'] ?? []),
      category: json['category'],
      priority: json['priority'] ?? 2,
      gamblingUrgeLevel: json['gamblingUrgeLevel'],
      cbtTechniques: List<String>.from(json['cbtTechniques'] ?? []),
      triggerSituation: json['triggerSituation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'reflections': reflections,
      'category': category,
      'priority': priority,
      'gamblingUrgeLevel': gamblingUrgeLevel,
      'cbtTechniques': cbtTechniques,
      'triggerSituation': triggerSituation,
    };
  }

  Color getPriorityColor() {
    switch (priority) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.blue.shade400;
      default:
        return Colors.grey;
    }
  }

  String getPriorityText() {
    switch (priority) {
      case 1:
        return 'High Priority';
      case 2:
        return 'Medium Priority';
      case 3:
        return 'Low Priority';
      default:
        return 'Standard Priority';
    }
  }

  IconData getCategoryIcon() {
    switch (category) {
      case 'Financial Recovery':
        return Icons.account_balance_wallet_outlined;
      case 'Urge Management':
        return Icons.waves_outlined;
      case 'Support Network':
        return Icons.people_outline;
      case 'Self-care':
        return Icons.favorite_border;
      case 'Healthy Habits':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.flag_outlined;
    }
  }
}

// Enhanced Goal Provider for Gambling Recovery
class RecoveryGoalProvider with ChangeNotifier {
  List<RecoveryGoal> _goals = [];
  bool _loading = true;
  final GenerativeModel? _aiModel;
  DateTime _recoveryStartDate = DateTime(2025, 4, 6);
  int _gambleFreeStreak = 0;

  // Suggested CBT techniques for gambling recovery
  final List<String> _cbtTechniques = [
    'Cognitive Restructuring',
    'Behavioral Activation',
    'Urge Surfing',
    'Thought Records',
    'SMART Planning',
    'Stimulus Control',
    'Mindfulness Meditation',
    'Financial Planning',
    'Relapse Prevention',
    'Reward Replacement'
  ];

  List<RecoveryGoal> get goals => _goals;
  bool get loading => _loading;
  List<String> get cbtTechniques => _cbtTechniques;
  DateTime get recoveryStartDate => _recoveryStartDate;
  int get gambleFreeStreak => _gambleFreeStreak;

  double get completionRate => _goals.isEmpty
      ? 0.0
      : _goals.where((goal) => goal.isCompleted).length / _goals.length;

  List<RecoveryGoal> get incompleteGoals =>
      _goals.where((goal) => !goal.isCompleted).toList();

  List<RecoveryGoal> get completedGoals =>
      _goals.where((goal) => goal.isCompleted).toList();

  RecoveryGoalProvider({GenerativeModel? aiModel}) : _aiModel = aiModel {
    loadData();
  }

  Future<void> loadData() async {
    try {
      _loading = true;
      notifyListeners();

      // Load recovery start date
      final savedStartDate =
          await PreferencesService.getDateTime('recovery_start_date');
      if (savedStartDate != null) {
        _recoveryStartDate = savedStartDate;
      } else {
        // Set default and save
        await PreferencesService.saveDateTime(
            'recovery_start_date', _recoveryStartDate);
      }

      // Calculate streak
      _calculateStreak();

      // Load goals
      final savedGoalsString =
          await PreferencesService.getData('recovery_goals') ?? '[]';
      final List<dynamic> goalList = json.decode(savedGoalsString);
      _goals = goalList.map((goal) => RecoveryGoal.fromJson(goal)).toList();

      _goals.sort((a, b) {
        // First sort by completion
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        // Then by priority for incomplete goals
        if (!a.isCompleted && !b.isCompleted) {
          return a.priority.compareTo(b.priority);
        }
        // Then by date (newest first for incomplete, oldest first for complete)
        return a.isCompleted
            ? a.completedAt!.compareTo(b.completedAt!)
            : b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      debugPrint('Error loading recovery goals: $e');
      _goals = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveGoals() async {
    try {
      final goalsString =
          json.encode(_goals.map((goal) => goal.toJson()).toList());
      await PreferencesService.saveData('recovery_goals', goalsString);
    } catch (e) {
      debugPrint('Error saving recovery goals: $e');
    }
  }

  void _calculateStreak() {
    final now = DateTime.now();
    final difference = now.difference(_recoveryStartDate).inDays;
    _gambleFreeStreak = difference > 0 ? difference : 0;
  }

  Future<void> addGoal(
    String description, {
    String? category,
    int priority = 2,
    int? gamblingUrgeLevel,
    List<String>? cbtTechniques,
    String? triggerSituation,
  }) async {
    if (description.trim().isEmpty) return;

    final goal = RecoveryGoal(
      description: description.trim(),
      category: category,
      priority: priority,
      gamblingUrgeLevel: gamblingUrgeLevel,
      cbtTechniques: cbtTechniques,
      triggerSituation: triggerSituation,
    );
    _goals.insert(0, goal);
    await saveGoals();
    notifyListeners();
  }

  Future<void> removeGoal(String id) async {
    _goals.removeWhere((goal) => goal.id == id);
    await saveGoals();
    notifyListeners();
  }

  Future<void> toggleGoalCompletion(String id) async {
    final goalIndex = _goals.indexWhere((goal) => goal.id == id);
    if (goalIndex == -1) return;

    _goals[goalIndex].isCompleted = !_goals[goalIndex].isCompleted;
    _goals[goalIndex].completedAt =
        _goals[goalIndex].isCompleted ? DateTime.now() : null;

    // Resort goals
    _goals.sort((a, b) {
      // First sort by completion
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Then by priority for incomplete goals
      if (!a.isCompleted && !b.isCompleted) {
        return a.priority.compareTo(b.priority);
      }
      // Then by date (newest first for incomplete, oldest first for complete)
      return a.isCompleted
          ? a.completedAt!.compareTo(b.completedAt!)
          : b.createdAt.compareTo(a.createdAt);
    });

    await saveGoals();
    notifyListeners();
  }

  Future<void> addReflection(String goalId, String reflection) async {
    final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return;

    _goals[goalIndex].reflections.add(reflection);
    await saveGoals();
    notifyListeners();
  }

  Future<void> addCbtTechniques(String goalId, List<String> techniques) async {
    final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex == -1) return;

    _goals[goalIndex].cbtTechniques.addAll(techniques);
    await saveGoals();
    notifyListeners();
  }

  Future<String> getAIGuidance(String goalDescription,
      {String? triggerSituation, String? category}) async {
    if (_aiModel == null) {
      return "AI guidance is currently unavailable. Please try again later.";
    }

    try {
      final currentDate = DateTime(2025, 4, 6, 21, 55, 13);
      final currentDateFormatted =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);
      final daysSinceStart = currentDate.difference(_recoveryStartDate).inDays;

      final prompt = '''
As a CBT-focused recovery assistant specialized in gambling addiction, provide actionable guidance for this recovery goal:
"$goalDescription"

Current Date: $currentDateFormatted
User: davytheprogrammer
Days in recovery: $daysSinceStart
${triggerSituation != null ? "Trigger situation: $triggerSituation" : ""}
${category != null ? "Goal category: $category" : ""}

Provide concise, CBT-based guidance including:
1. One possible thinking pattern or cognitive distortion related to this goal
2. Two specific behavioral steps to make progress
3. One thought-challenging technique relevant to gambling recovery
4. A brief affirmation to motivate continued recovery

Focus specifically on gambling addiction recovery principles and keep the total response under 200 words.
''';

      final content = [Content.text(prompt)];
      final response = await _aiModel!.generateContent(content);
      return response.text ?? "Unable to generate guidance at this moment.";
    } catch (e) {
      debugPrint('Error getting AI guidance: $e');
      return "An error occurred while getting AI guidance. Please try again later.";
    }
  }
}

// Beautiful Recovery Goals Screen
class RecoveryGoalsScreen extends StatefulWidget {
  const RecoveryGoalsScreen({super.key});

  @override
  State<RecoveryGoalsScreen> createState() => _RecoveryGoalsScreenState();
}

class _RecoveryGoalsScreenState extends State<RecoveryGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text('Recovery Goals',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Consumer<RecoveryGoalProvider>(
                  builder: (context, provider, _) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildProgressIndicator(provider),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${provider.gambleFreeStreak} DAYS',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Gambling-Free',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FadeIn(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${provider.completedGoals.length} goals completed',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Active Goals'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ],
        body: Consumer<RecoveryGoalProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Active Goals Tab
                provider.incompleteGoals.isEmpty
                    ? _buildEmptyState('active')
                    : _buildGoalsList(provider.incompleteGoals),

                // Completed Goals Tab
                provider.completedGoals.isEmpty
                    ? _buildEmptyState('completed')
                    : _buildGoalsList(provider.completedGoals),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => _showAddGoalBottomSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProgressIndicator(RecoveryGoalProvider provider) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: provider.completionRate,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 6,
          ),
          Center(
            child: Text(
              '${(provider.completionRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String message;

    if (type == 'active') {
      icon = Icons.flag_outlined;
      title = 'No active goals';
      message = 'Add your first recovery goal to track your progress';
    } else {
      icon = Icons.emoji_events_outlined;
      title = 'No completed goals yet';
      message = 'Keep going, you\'ll achieve your goals soon!';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (type == 'active')
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Recovery Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () => _showAddGoalBottomSheet(context),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<RecoveryGoal> goalsList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goalsList.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          duration: const Duration(milliseconds: 300),
          child: RecoveryGoalCard(goal: goalsList[index]),
        );
      },
    );
  }

  void _showAddGoalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AddRecoveryGoalForm(scrollController: scrollController),
          ),
        ),
      ),
    );
  }
}

// Add Recovery Goal Form
class AddRecoveryGoalForm extends StatefulWidget {
  final ScrollController scrollController;

  const AddRecoveryGoalForm({
    super.key,
    required this.scrollController,
  });

  @override
  State<AddRecoveryGoalForm> createState() => _AddRecoveryGoalFormState();
}

class _AddRecoveryGoalFormState extends State<AddRecoveryGoalForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _triggerController = TextEditingController();
  String? _selectedCategory;
  int _priority = 2;
  int _gamblingUrgeLevel = 3;
  List<String> _selectedTechniques = [];
  bool _showAdvancedOptions = false;
  bool _isGettingAIHelp = false;
  String _aiSuggestion = '';

  final List<String> _goalCategories = [
    'Financial Recovery',
    'Urge Management',
    'Support Network',
    'Self-care',
    'Healthy Habits',
    'Other'
  ];

  @override
  void dispose() {
    _goalController.dispose();
    _triggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        children: [
          const Text(
            'Create New Recovery Goal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set meaningful goals to support your gambling recovery journey',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Goal description field
          TextFormField(
            controller: _goalController,
            decoration: InputDecoration(
              labelText: 'What do you want to achieve?',
              hintText: 'E.g., Attend GA meetings weekly',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a goal description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Goal Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            value: _selectedCategory,
            hint: const Text('Select a category'),
            items: _goalCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Priority selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goal Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityOption(1, 'High', Colors.red.shade400),
                  const SizedBox(width: 12),
                  _buildPriorityOption(2, 'Medium', Colors.orange.shade400),
                  const SizedBox(width: 12),
                  _buildPriorityOption(3, 'Low', Colors.blue.shade400),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Advanced options toggle
          InkWell(
            onTap: () {
              setState(() {
                _showAdvancedOptions = !_showAdvancedOptions;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    _showAdvancedOptions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced Recovery Options',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Advanced options
          if (_showAdvancedOptions) ...[
            const SizedBox(height: 16),

            // Trigger situation
            TextFormField(
              controller: _triggerController,
              decoration: InputDecoration(
                labelText: 'Trigger Situation (Optional)',
                hintText: 'E.g., Walking past a casino',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.warning_amber_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Urge level slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Gambling Urge Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0 = No urge, 10 = Extreme urge',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('0'),
                    Expanded(
                      child: Slider(
                        value: _gamblingUrgeLevel.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _gamblingUrgeLevel.toString(),
                        activeColor: _getUrgeColor(_gamblingUrgeLevel),
                        onChanged: (value) {
                          setState(() {
                            _gamblingUrgeLevel = value.toInt();
                          });
                        },
                      ),
                    ),
                    const Text('10'),
                  ],
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getUrgeColor(_gamblingUrgeLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getUrgeDescription(_gamblingUrgeLevel),
                      style: TextStyle(
                        color: _getUrgeColor(_gamblingUrgeLevel),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CBT Techniques
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CBT Techniques to Apply',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<RecoveryGoalProvider>(
                  builder: (context, provider, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.cbtTechniques.map((technique) {
                        final isSelected =
                            _selectedTechniques.contains(technique);
                        return FilterChip(
                          label: Text(technique),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTechniques.add(technique);
                              } else {
                                _selectedTechniques.remove(technique);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade800,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // AI Suggestion Button
          if (!_isGettingAIHelp && _aiSuggestion.isEmpty)
            OutlinedButton.icon(
              icon: Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: const Text('Get AI Goal Suggestions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed:
                  _goalController.text.isNotEmpty ? _getAISuggestion : null,
            ),

          // Loading indicator
          if (_isGettingAIHelp)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(),
              ),
            ),

          // AI Suggestion
          if (_aiSuggestion.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Suggestions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _aiSuggestion = '';
                          });
                        },
                        iconSize: 16,
                        color: Colors.grey.shade700,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiSuggestion),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit and Cancel buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Goal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOption(int value, String label, Color color) {
    final isSelected = _priority == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                value == 1
                    ? Icons.keyboard_double_arrow_up
                    : value == 2
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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

  Future<void> _getAISuggestion() async {
    if (_goalController.text.isEmpty) return;

    setState(() {
      _isGettingAIHelp = true;
    });

    try {
      final result =
          await Provider.of<RecoveryGoalProvider>(context, listen: false)
              .getAIGuidance(
        _goalController.text,
        triggerSituation: _triggerController.text,
        category: _selectedCategory,
      );

      setState(() {
        _aiSuggestion = result;
        _isGettingAIHelp = false;
      });
    } catch (e) {
      setState(() {
        _aiSuggestion = 'Sorry, I couldn\'t generate suggestions at this time.';
        _isGettingAIHelp = false;
      });
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      Provider.of<RecoveryGoalProvider>(context, listen: false).addGoal(
        _goalController.text,
        category: _selectedCategory,
        priority: _priority,
        gamblingUrgeLevel: _showAdvancedOptions ? _gamblingUrgeLevel : null,
        cbtTechniques:
            _selectedTechniques.isNotEmpty ? _selectedTechniques : null,
        triggerSituation:
            _triggerController.text.isNotEmpty ? _triggerController.text : null,
      );
      Navigator.pop(context);
    }
  }
}

// Stunning Recovery Goal Card
class RecoveryGoalCard extends StatefulWidget {
  final RecoveryGoal goal;

  const RecoveryGoalCard({super.key, required this.goal});

  @override
  State<RecoveryGoalCard> createState() => _RecoveryGoalCardState();
}

class _RecoveryGoalCardState extends State<RecoveryGoalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecoveryGoalProvider>(context, listen: false);
    final goal = widget.goal;
    final dateFormat = DateFormat('MMM d, y');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => provider.toggleGoalCompletion(goal.id),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: goal.isCompleted
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: goal.isCompleted
                                    ? Colors.green
                                    : goal.getPriorityColor(),
                                width: 2,
                              ),
                            ),
                            child: goal.isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.green,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: goal.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: goal.isCompleted
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (goal.category != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
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
                                            goal.getCategoryIcon(),
                                            size: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            goal.category!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Icon(
                                    goal.priority == 1
                                        ? Icons.keyboard_double_arrow_up
                                        : goal.priority == 2
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                    size: 14,
                                    color: goal.getPriorityColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    goal.getPriorityText(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: goal.getPriorityColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _buildDetailsSection(context, goal, dateFormat),
                    ],
                  ],
                ),
              ),

              // Bottom section with date
              if (!_expanded)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        goal.isCompleted
                            ? 'Completed ${dateFormat.format(goal.completedAt!)}'
                            : 'Created ${dateFormat.format(goal.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (goal.gamblingUrgeLevel != null) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getUrgeColor(goal.gamblingUrgeLevel!)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 10,
                                color: _getUrgeColor(goal.gamblingUrgeLevel!),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Urge: ${goal.gamblingUrgeLevel}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getUrgeColor(goal.gamblingUrgeLevel!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(
      BuildContext context, RecoveryGoal goal, DateFormat dateFormat) {
    final provider = Provider.of<RecoveryGoalProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dates section
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(goal.createdAt),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (goal.isCompleted)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(goal.completedAt!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Trigger situation
        if (goal.triggerSituation != null &&
            goal.triggerSituation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Trigger Situation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.triggerSituation!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // CBT Techniques
        if (goal.cbtTechniques.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'CBT Techniques',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goal.cbtTechniques.map((technique) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  technique,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Reflections
        if (goal.reflections.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Reflections & Progress Notes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          ...goal.reflections.map(
            (reflection) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Text(
                reflection,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Add Note'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _showAddReflectionDialog(context, goal.id),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: goal.isCompleted
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.replay, size: 16),
                      label: const Text('Restart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => provider.toggleGoalCompletion(goal.id),
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => provider.toggleGoalCompletion(goal.id),
                    ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // AI guidance and delete buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.psychology, size: 16),
                label: const Text('AI Guidance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: BorderSide(color: Colors.deepPurple.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  final guidance = await provider.getAIGuidance(
                    goal.description,
                    triggerSituation: goal.triggerSituation,
                    category: goal.category,
                  );

                  if (!mounted) return;

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('Recovery Guidance'),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Text(guidance),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _showDeleteConfirmation(context, goal.id),
            ),
          ],
        ),
      ],
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

  void _showAddReflectionDialog(BuildContext context, String goalId) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Progress Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'How are you progressing with this goal?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<RecoveryGoalProvider>(context, listen: false)
                    .addReflection(goalId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
            'Are you sure you want to delete this goal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<RecoveryGoalProvider>(context, listen: false)
                  .removeGoal(goalId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
