import 'package:flutter/material.dart';
import '../../utils/preferences_service.dart';
import 'recovery_stage_screen.dart';

class AddictionTypeScreen extends StatefulWidget {
  const AddictionTypeScreen({super.key});

  @override
  State<AddictionTypeScreen> createState() => _AddictionTypeScreenState();
}

class _AddictionTypeScreenState extends State<AddictionTypeScreen> {
  final TextEditingController _addictionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Gambling addiction types for suggestions
  final List<String> _commonAddictions = [
    'Sports Betting',
    'Aviater',
    'Casino Games',
    'Poker',
    'Lottery',
    'Slot Machines',
    'Online Gambling',
    'Stock Trading and Cryptocurrency',
    'Fantasy Sports',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with 'Gambling' as the main addiction type
    _addictionController.text = 'Gambling';
  }

  @override
  void dispose() {
    _addictionController.dispose();
    super.dispose();
  }

  Future<void> _submitAddictionType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await PreferencesService.saveData(
        'addiction_type', _addictionController.text.trim());
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecoveryStageScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gambling Recovery Journey"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                "What type of gambling are you recovering from?",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "This helps us personalize your gambling recovery journey",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 32),

              // Addiction input field
              TextFormField(
                controller: _addictionController,
                decoration: InputDecoration(
                  labelText: "Type of gambling",
                  hintText: "e.g., Sports Betting, Poker, etc.",
                  prefixIcon: const Icon(Icons.casino_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your gambling type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gambling type chips
              Wrap(
                spacing: 8,
                children: _commonAddictions.map((addiction) {
                  return InputChip(
                    label: Text(addiction),
                    onSelected: (selected) {
                      setState(() {
                        _addictionController.text = addiction;
                      });
                    },
                    backgroundColor: _addictionController.text == addiction
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                  );
                }).toList(),
              ),
              const Spacer(),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAddictionType,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Continue"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
