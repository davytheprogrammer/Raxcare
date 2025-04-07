import 'package:flutter/material.dart';
import 'support_system_screen.dart';
import '../../utils/preferences_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<String> _selectedGoals = {};
  bool _isSubmitting = false;

  // Gambling-specific recovery goals
  final List<Map<String, dynamic>> _commonGoals = [
    {'text': 'Stop gambling', 'icon': Icons.block_outlined},
    {
      'text': 'Financial recovery',
      'icon': Icons.account_balance_wallet_outlined
    },
    {'text': 'Pay off debts', 'icon': Icons.money_off_outlined},
    {'text': 'Avoid betting urges', 'icon': Icons.not_interested_outlined},
    {'text': 'Rebuild trust', 'icon': Icons.handshake_outlined},
    {'text': 'New hobbies', 'icon': Icons.interests_outlined},
    {'text': 'Manage triggers', 'icon': Icons.warning_amber_outlined},
    {'text': 'Mental wellness', 'icon': Icons.psychology_outlined},
    {'text': 'Join support group', 'icon': Icons.group_outlined},
    {'text': 'Budget planning', 'icon': Icons.savings_outlined},
    {'text': 'Repair relationships', 'icon': Icons.favorite_border_outlined},
    {'text': 'Self-exclusion', 'icon': Icons.do_not_disturb_on_outlined},
  ];

  void _toggleGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gridHeight = screenHeight * 0.55;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gambling Recovery Goals"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              "What are your gambling recovery goals?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              "Select all the goals that matter to you",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 24),

            // Visual indicator for goal selection
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _selectedGoals.isNotEmpty
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.3)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedGoals.isNotEmpty
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedGoals.isNotEmpty
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: _selectedGoals.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedGoals.isNotEmpty
                          ? "${_selectedGoals.length} goal${_selectedGoals.length > 1 ? 's' : ''} selected"
                          : "Select at least one goal to continue",
                      style: TextStyle(
                        color: _selectedGoals.isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                        fontWeight: _selectedGoals.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Grid of goal options with updated layout
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 400 ? 3 : 2,
                  childAspectRatio: 1.25,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _commonGoals.length,
                itemBuilder: (context, index) {
                  final goal = _commonGoals[index];
                  final isSelected = _selectedGoals.contains(goal['text']);

                  return GestureDetector(
                    onTap: () => _toggleGoal(goal['text']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                goal['icon'],
                                size: 32,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  goal['text'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
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

            const Spacer(),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedGoals.isEmpty || _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);

                        // Save goals to preferences
                        await PreferencesService.saveData(
                          'recovery_goals',
                          _selectedGoals.join(', '),
                        );

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SupportSystemScreen(),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
