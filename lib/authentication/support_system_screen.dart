import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';
import 'triggers_screen.dart';

class SupportSystemScreen extends StatefulWidget {
  const SupportSystemScreen({super.key});

  @override
  State<SupportSystemScreen> createState() => _SupportSystemScreenState();
}

class _SupportSystemScreenState extends State<SupportSystemScreen> {
  String _selectedSupport = 'Yes';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gambling Recovery Support"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              "Your Support Network",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              "Do you have people who support your gambling recovery?",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 32),

            // Modern selection cards with updated UI
            Column(
              children: [
                _buildSupportOption(
                  context,
                  title: "Yes, I have support",
                  subtitle:
                      "Family, friends, or support groups help me stay accountable",
                  icon: Icons.people_alt_outlined,
                  isSelected: _selectedSupport == 'Yes',
                  onTap: () => setState(() => _selectedSupport = 'Yes'),
                ),
                const SizedBox(height: 16),
                _buildSupportOption(
                  context,
                  title: "No, I'm building my support",
                  subtitle:
                      "I'm working on finding gambling-specific support resources",
                  icon: Icons.person_search_outlined,
                  isSelected: _selectedSupport == 'No',
                  onTap: () => setState(() => _selectedSupport = 'No'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Information card about gambling support
            Card(
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Recovery Resources",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Consider joining Gamblers Anonymous, seeking therapy, or contacting a gambling helpline for additional support.",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        await PreferencesService.saveData(
                          'support_system',
                          _selectedSupport,
                        );
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TriggersScreen(),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                    : const Text(
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

  Widget _buildSupportOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey.shade100,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
