import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';
import 'triggers_screen.dart';

class SupportSystemScreen extends StatelessWidget {
  const SupportSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String selectedSupport = 'Yes';

    return Scaffold(
      appBar: AppBar(title: const Text("Support System")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Do you have a support system (family, friends, or groups)?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedSupport,
              items: ["Yes", "No"].map((String value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                selectedSupport = newValue!;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await PreferencesService.saveData(
                    'support_system', selectedSupport);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TriggersScreen()));
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }
}
