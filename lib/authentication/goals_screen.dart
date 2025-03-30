import 'package:flutter/material.dart';
import '../../utils/preferences_service.dart';
import 'support_system_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController goalsController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Recovery Goals")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What are your goals for recovery?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: goalsController,
              decoration: const InputDecoration(
                  labelText: "e.g., Stay sober, Avoid triggers"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await PreferencesService.saveData(
                    'goals', goalsController.text);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SupportSystemScreen()));
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }
}
