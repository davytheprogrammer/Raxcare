// Journal service for handling Firebase operations
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class JournalService {
  final CollectionReference journals =
      FirebaseFirestore.instance.collection('journal_entries');

  // Add a new journal entry
  Future<void> addJournal(JournalEntry entry) async {
    try {
      await journals.add({
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date,
        'mood': entry.mood,
        'urgeLevel': entry.urgeLevel,
        'triggers': entry.triggers,
        'aiInsights': entry.aiInsights,
        'relapseOccurred': entry.relapseOccurred,
        'userId': entry.userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add journal: $e');
    }
  }

  // Get all journal entries for the current user
  Stream<QuerySnapshot> getJournals() {
    return journals
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Update an existing journal entry
  Future<void> updateJournal(String docId, JournalEntry entry) async {
    try {
      await journals.doc(docId).update({
        'title': entry.title,
        'content': entry.content,
        'date': entry.date,
        'mood': entry.mood,
        'urgeLevel': entry.urgeLevel,
        'triggers': entry.triggers,
        'aiInsights': entry.aiInsights,
        'relapseOccurred': entry.relapseOccurred,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update journal: $e');
    }
  }

  // Delete a journal entry
  Future<void> deleteJournal(String docId) async {
    try {
      await journals.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete journal: $e');
    }
  }

  // Get journal entries for a specific date range
  Future<QuerySnapshot> getJournalsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      return await journals
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to fetch journals by date range: $e');
    }
  }

  // Get journal entries with high urge levels (for insights)
  Future<QuerySnapshot> getHighUrgeJournals(int threshold) async {
    try {
      return await journals
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('urgeLevel', isGreaterThanOrEqualTo: threshold)
          .orderBy('urgeLevel', descending: true)
          .limit(5)
          .get();
    } catch (e) {
      throw Exception('Failed to fetch high-urge journals: $e');
    }
  }

  // Get journal entries with relapses (for pattern analysis)
  Future<QuerySnapshot> getRelapseJournals() async {
    try {
      return await journals
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('relapseOccurred', isEqualTo: true)
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to fetch relapse journals: $e');
    }
  }

  // Get statistics for the user's journaling practice
  Future<Map<String, dynamic>> getJournalStats() async {
    try {
      // Total entries
      final totalQuery = await journals
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .count()
          .get();

      // Entries with relapses
      final relapseQuery = await journals
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('relapseOccurred', isEqualTo: true)
          .count()
          .get();

      // Average urge level
      final urgeQuery = await journals
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      double avgUrge = 0;
      if (urgeQuery.docs.isNotEmpty) {
        int totalUrge = 0;
        for (var doc in urgeQuery.docs) {
          totalUrge +=
              ((doc.data() as Map<String, dynamic>)['urgeLevel'] ?? 0) as int;
        }
        avgUrge = totalUrge / urgeQuery.docs.length;
      }

      // Most common mood
      Map<String, int> moodCounts = {};
      for (var doc in urgeQuery.docs) {
        final mood = (doc.data() as Map<String, dynamic>)['mood'] ?? 'Neutral';
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }

      String? mostCommonMood;
      int maxCount = 0;
      moodCounts.forEach((mood, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonMood = mood;
        }
      });

      return {
        'totalEntries': totalQuery.count,
        'relapseCount': relapseQuery.count,
        'averageUrgeLevel': avgUrge.toStringAsFixed(1),
        'mostCommonMood': mostCommonMood ?? 'Neutral',
      };
    } catch (e) {
      throw Exception('Failed to fetch journal statistics: $e');
    }
  }
}

// JournalEntry model
class JournalEntry {
  String id;
  String title;
  String content;
  DateTime date;
  String mood;
  int urgeLevel;
  List<String> triggers;
  String aiInsights;
  bool relapseOccurred;
  String userId;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.urgeLevel,
    required this.triggers,
    required this.aiInsights,
    this.relapseOccurred = false,
    required this.userId,
  });

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'mood': mood,
      'urgeLevel': urgeLevel,
      'triggers': triggers,
      'aiInsights': aiInsights,
      'relapseOccurred': relapseOccurred,
      'userId': userId,
    };
  }

  // Create from a Firestore document
  factory JournalEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] ?? 'Neutral',
      urgeLevel: data['urgeLevel'] ?? 0,
      triggers: List<String>.from(data['triggers'] ?? []),
      aiInsights: data['aiInsights'] ?? '',
      relapseOccurred: data['relapseOccurred'] ?? false,
      userId: data['userId'] ?? '',
    );
  }
}

// Detail screen for viewing a journal entry
class JournalDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final DateTime date;
  final String mood;
  final int urgeLevel;
  final List<String> triggers;
  final String aiInsights;
  final bool relapseOccurred;

  const JournalDetailScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.urgeLevel,
    required this.triggers,
    required this.aiInsights,
    required this.relapseOccurred,
  }) : super(key: key);

  Color _getUrgeColor(int level) {
    if (level <= 3) {
      return Colors.green;
    } else if (level <= 6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with date and metadata
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('MMMM dd, yyyy').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Spacer(),
                      if (relapseOccurred)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Relapse Day',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        context,
                        icon: Icons.mood,
                        label: mood,
                        color: Colors.blue.shade100,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        context,
                        icon: Icons.speed,
                        label: 'Urge: $urgeLevel/10',
                        color: _getUrgeColor(urgeLevel).withOpacity(0.2),
                        iconColor: _getUrgeColor(urgeLevel),
                        textColor: _getUrgeColor(urgeLevel),
                      ),
                    ],
                  ),
                  if (triggers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: triggers.map((trigger) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber,
                                size: 14,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trigger,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Journal content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // AI insights section
            if (aiInsights.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GEMINI CBT Insights',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MarkdownBody(
                        data: aiInsights,
                        styleSheet: MarkdownStyleSheet(
                          h1: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          h2: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          h3: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          p: const TextStyle(fontSize: 14, height: 1.5),
                          blockquote: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 4,
                              ),
                            ),
                          ),
                          listBullet: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? Colors.grey.shade800,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
