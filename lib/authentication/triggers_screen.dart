import 'package:flutter/material.dart';
import '../../utils/preferences_service.dart';
import '../screens/home/home.dart';

class TriggersScreen extends StatelessWidget {
  const TriggersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController triggersController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Triggers & Risk Factors")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What are your triggers or risk factors?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: triggersController,
              decoration: const InputDecoration(
                  labelText: "e.g., Stress, Social Pressure, Anxiety"),
              maxLines: 3,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await PreferencesService.saveData(
                    'triggers', triggersController.text);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }
}
