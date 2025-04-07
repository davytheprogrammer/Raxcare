import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CallSponsorScreen extends StatefulWidget {
  const CallSponsorScreen({Key? key}) : super(key: key);

  @override
  State<CallSponsorScreen> createState() => _CallSponsorScreenState();
}

class _CallSponsorScreenState extends State<CallSponsorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  List<Map<String, dynamic>> sponsors = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedContactCategory = 0;

  // New properties for gambling recovery specific features
  String _lastCallDate = '';
  int _supportCallsMade = 0;
  bool _emergencyMode = false;

  // List of support types for gambling recovery
  final List<Map<String, dynamic>> _contactCategories = [
    {
      'name': 'Personal Sponsors',
      'icon': Icons.person_outline,
      'description': 'People who support your gambling recovery journey'
    },
    {
      'name': 'GA Contacts',
      'icon': Icons.group_outlined,
      'description': 'Gamblers Anonymous members and counselors'
    },
    {
      'name': 'Helplines',
      'icon': Icons.support_agent,
      'description': '24/7 gambling addiction helplines and resources'
    },
  ];

  // Default helplines for gambling support
  final List<Map<String, dynamic>> _defaultHelplines = [
    {
      'name': 'Gamblers Rax Anonymous',
      'phone': '0713350040',
      'notes': 'Information about local GA meetings and resources.',
      'relationship': 'Support Group',
      'availability': 'Office hours',
      'category': 2,
      'isDefault': true
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _contactCategories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedContactCategory = _tabController.index;
      });
    });
    _loadSponsors();
    _loadSupportStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _relationshipController.dispose();
    _availabilityController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSupportStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastCallDate = prefs.getString('last_support_call_date') ?? '';
      _supportCallsMade = prefs.getInt('support_calls_made') ?? 0;
    });
  }

  Future<void> _updateSupportStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentDate = DateFormat('yyyy-MM-dd').format(now);

    await prefs.setString('last_support_call_date', currentDate);
    final callsMade = prefs.getInt('support_calls_made') ?? 0;
    await prefs.setInt('support_calls_made', callsMade + 1);

    setState(() {
      _lastCallDate = currentDate;
      _supportCallsMade = callsMade + 1;
    });
  }

  Future<void> _loadSponsors() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final sponsorsJson = prefs.getStringList('gambling_sponsors') ?? [];

    try {
      final loadedSponsors = sponsorsJson
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .toList();

      // Check if we have any sponsors loaded
      if (loadedSponsors.isEmpty) {
        // Add default helplines if this is first time
        sponsors = [..._defaultHelplines];
      } else {
        sponsors = loadedSponsors;
      }

      // Make sure category is set
      for (var sponsor in sponsors) {
        if (!sponsor.containsKey('category')) {
          sponsor['category'] = 0;
        }
      }
    } catch (e) {
      // Handle JSON parsing error
      sponsors = [..._defaultHelplines];
    }

    setState(() {
      _isLoading = false;
    });

    // Save sponsors to ensure defaults are saved
    await _saveSponsors();
  }

  Future<void> _saveSponsors() async {
    final prefs = await SharedPreferences.getInstance();
    final sponsorsJson = sponsors.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('gambling_sponsors', sponsorsJson);
  }

  Future<void> _addSponsor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        sponsors.add({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'notes': _notesController.text,
          'relationship': _relationshipController.text,
          'availability': _availabilityController.text,
          'category': _selectedContactCategory,
          'isDefault': false,
          'lastContacted': '',
        });
        _nameController.clear();
        _phoneController.clear();
        _notesController.clear();
        _relationshipController.clear();
        _availabilityController.clear();
      });
      await _saveSponsors();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Support contact added successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _deleteSponsor(int index) async {
    final sponsor = sponsors[index];

    // Don't allow deleting default helplines
    if (sponsor['isDefault'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default helplines cannot be deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      sponsors.removeAt(index);
    });
    await _saveSponsors();
  }

  Future<void> _callSponsor(Map<String, dynamic> sponsor) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: sponsor['phone']);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);

        // Record the contact in the sponsor's data
        sponsor['lastContacted'] =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        await _saveSponsors();

        // Update support call statistics
        await _updateSupportStats();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling ${sponsor['name']}...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw 'Could not launch dialer';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showAddSponsorDialog() {
    _nameController.clear();
    _phoneController.clear();
    _notesController.clear();
    _relationshipController.clear();
    _availabilityController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20) +
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Add Recovery Support Contact',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48), // Balance the close button
                ],
              ),
              const SizedBox(height: 24),

              // Contact category selection
              Text(
                'Contact Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SegmentedButton<int>(
                    segments: _contactCategories.asMap().entries.map((entry) {
                      return ButtonSegment<int>(
                        value: entry.key,
                        label: Text(entry.value['name']),
                        icon: Icon(entry.value['icon']),
                      );
                    }).toList(),
                    selected: {_selectedContactCategory},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _selectedContactCategory = newSelection.first;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter the contact name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter a valid phone number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _relationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'E.g., Sponsor, Friend, Counselor',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _availabilityController,
                decoration: InputDecoration(
                  labelText: 'Best Time to Contact',
                  hintText: 'E.g., Evenings, Weekends, 24/7',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional information',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _addSponsor,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'SAVE CONTACT',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEmergencyMode() {
    setState(() {
      _emergencyMode = !_emergencyMode;
    });

    if (_emergencyMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Emergency mode activated. Gambling helplines highlighted.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredSponsors() {
    if (_emergencyMode) {
      // In emergency mode, show helplines first, then all others
      return [
        ...sponsors.where((s) => s['category'] == 2).toList(),
        ...sponsors.where((s) => s['category'] != 2).toList(),
      ];
    } else {
      // Normal mode, filter by selected category
      return sponsors
          .where((s) => s['category'] == _selectedContactCategory)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gambling Recovery Support',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_emergencyMode
                ? Icons.warning_amber
                : Icons.warning_amber_outlined),
            color: _emergencyMode ? Colors.red : null,
            onPressed: _toggleEmergencyMode,
            tooltip: 'Gambling Urge Emergency Mode',
          ),
        ],
        bottom: _emergencyMode
            ? null
            : TabBar(
                controller: _tabController,
                tabs: _contactCategories.map((category) {
                  return Tab(
                    icon: Icon(category['icon']),
                    text: category['name'],
                  );
                }).toList(),
                labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats bar
                if (_supportCallsMade > 0 || _lastCallDate.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastCallDate.isNotEmpty
                                ? 'Last support call: $_lastCallDate · $_supportCallsMade calls made'
                                : '$_supportCallsMade support calls made',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Emergency mode banner
                if (_emergencyMode)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.red.shade50,
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.red,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gambling Urge Emergency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Take a deep breath. These contacts can help you right now.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Empty state or contacts list
                Expanded(
                  child: _getFilteredSponsors().isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _getFilteredSponsors().length,
                          itemBuilder: (context, index) {
                            final sponsor = _getFilteredSponsors()[index];
                            return SponsorCard(
                              name: sponsor['name'] ?? '',
                              phoneNumber: sponsor['phone'] ?? '',
                              notes: sponsor['notes'] ?? '',
                              relationship: sponsor['relationship'] ?? '',
                              availability: sponsor['availability'] ?? '',
                              lastContacted: sponsor['lastContacted'] ?? '',
                              isDefault: sponsor['isDefault'] ?? false,
                              isHelpline: sponsor['category'] == 2,
                              isEmergencyMode: _emergencyMode,
                              onCall: () => _callSponsor(sponsor),
                              onDelete: () => _deleteSponsor(index),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSponsorDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Contact',
      ),
    );
  }

  Widget _buildEmptyState() {
    final categoryIndex = _selectedContactCategory;
    final category = _contactCategories[categoryIndex];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category['icon'],
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No ${category['name']} yet',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              category['description'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSponsorDialog,
            icon: const Icon(Icons.add),
            label: Text('Add ${categoryIndex == 2 ? 'Helpline' : 'Contact'}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SponsorCard extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String notes;
  final String relationship;
  final String availability;
  final String lastContacted;
  final bool isDefault;
  final bool isHelpline;
  final bool isEmergencyMode;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  const SponsorCard({
    Key? key,
    required this.name,
    required this.phoneNumber,
    required this.notes,
    required this.relationship,
    required this.availability,
    required this.lastContacted,
    required this.isDefault,
    required this.isHelpline,
    required this.isEmergencyMode,
    required this.onCall,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color cardBaseColor = isEmergencyMode && isHelpline
        ? Colors.red.shade50
        : isHelpline
            ? Colors.blue.shade50
            : Colors.white;

    final Color accentColor = isEmergencyMode && isHelpline
        ? Colors.red
        : isHelpline
            ? Colors.blue
            : Theme.of(context).colorScheme.primary;

    final bool isRecent = lastContacted.isNotEmpty &&
        DateTime.now()
                .difference(DateFormat('yyyy-MM-dd').parse(lastContacted))
                .inDays <
            7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: cardBaseColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: accentColor.withOpacity(0.2),
                      child: Icon(
                        isHelpline ? Icons.support_agent : Icons.person,
                        color: accentColor,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isDefault)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (relationship.isNotEmpty ||
                              availability.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  if (relationship.isNotEmpty)
                                    Chip(
                                      label: Text(relationship),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: accentColor,
                                      ),
                                      backgroundColor:
                                          accentColor.withOpacity(0.1),
                                      shape: StadiumBorder(),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (availability.isNotEmpty)
                                    Chip(
                                      label: Text(availability),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                      backgroundColor: Colors.grey.shade100,
                                      shape: StadiumBorder(),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isDefault)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Contact'),
                              content: const Text(
                                'Are you sure you want to delete this contact?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDelete();
                                  },
                                  child: const Text(
                                    'DELETE',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),

                // Last contacted indicator
                if (lastContacted.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: isRecent ? Colors.green : Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Last contacted: $lastContacted',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isRecent ? Colors.green : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone),
                  label: Text(isEmergencyMode && isHelpline
                      ? 'CALL NOW (EMERGENCY)'
                      : 'CALL NOW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmergencyMode && isHelpline
                        ? Colors.red
                        : accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
