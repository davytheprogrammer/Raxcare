import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';
import 'goals_screen.dart';

class RecoveryStageScreen extends StatelessWidget {
  const RecoveryStageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String selectedStage = 'Just Starting';

    return Scaffold(
      appBar: AppBar(title: const Text("Stage of Recovery")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Where are you in your recovery journey?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedStage,
              items: ["Just Starting", "In Treatment", "Post-Treatment"]
                  .map((String value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                selectedStage = newValue!;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await PreferencesService.saveData(
                    'recovery_stage', selectedStage);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GoalsScreen()));
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }
}
