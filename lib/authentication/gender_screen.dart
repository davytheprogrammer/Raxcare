import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';
import 'addiction_type_screen.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String selectedGender = 'Male';

    return Scaffold(
      appBar: AppBar(title: const Text("Select Gender")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What is your gender?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedGender,
              items: ["Male", "Female", "Other"].map((String value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                selectedGender = newValue!;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await PreferencesService.saveData('gender', selectedGender);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddictionTypeScreen()));
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }
}
