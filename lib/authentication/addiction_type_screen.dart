import 'package:flutter/material.dart';
import '../../utils/preferences_service.dart';
import 'recovery_stage_screen.dart';

class AddictionTypeScreen extends StatelessWidget {
  const AddictionTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController addictionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Type of Addiction")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What type of addiction are you recovering from?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: addictionController,
              decoration: const InputDecoration(
                  labelText: "e.g., Alcohol, Drugs, Gambling"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await PreferencesService.saveData(
                    'addiction_type', addictionController.text);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RecoveryStageScreen()));
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }
}
