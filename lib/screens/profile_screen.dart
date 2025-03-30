import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController addictionController = TextEditingController();
  TextEditingController recoveryStageController = TextEditingController();
  TextEditingController goalsController = TextEditingController();
  String selectedGender = "Male";
  bool hasSupportSystem = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    nameController.text = await PreferencesService.getData('name') ?? "";
    addictionController.text =
        await PreferencesService.getData('addiction_type') ?? "";
    recoveryStageController.text =
        await PreferencesService.getData('recovery_stage') ?? "";
    goalsController.text = await PreferencesService.getData('goals') ?? "";
    selectedGender = await PreferencesService.getData('gender') ?? "Male";
    hasSupportSystem =
        (await PreferencesService.getData('support_system')) == "Yes";
    setState(() {});
  }

  Future<void> saveProfileData() async {
    await PreferencesService.saveData('name', nameController.text);
    await PreferencesService.saveData(
        'addiction_type', addictionController.text);
    await PreferencesService.saveData(
        'recovery_stage', recoveryStageController.text);
    await PreferencesService.saveData('goals', goalsController.text);
    await PreferencesService.saveData('gender', selectedGender);
    await PreferencesService.saveData(
        'support_system', hasSupportSystem ? "Yes" : "No");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture Placeholder
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(
                        'assets/default_profile.png'), // Replace with an actual image if needed
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Implement profile picture change
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Editable Profile Fields
            profileField("Full Name", nameController),
            profileField("Addiction Type", addictionController),
            profileField("Stage of Recovery", recoveryStageController),
            profileField("Goals", goalsController),

            // Gender Selection
            dropdownField("Gender", ["Male", "Female", "Other"], selectedGender,
                (newValue) {
              setState(() {
                selectedGender = newValue!;
              });
            }),

            // Support System Toggle
            ListTile(
              title: const Text("Do you have a support system?"),
              trailing: Switch(
                value: hasSupportSystem,
                onChanged: (value) {
                  setState(() {
                    hasSupportSystem = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: saveProfileData,
              child: const Text("Save Changes"),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget profileField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget dropdownField(String label, List<String> options, String selectedValue,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            items: options.map((String value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
