import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeController extends ChangeNotifier {
  // Rename to match chat screen names
  DateTime? _recoveryStartDate;
  int currentMilestone = 1;
  bool hasCheckedInToday = false;
  int _gambleFreeStreak = 0;
  late SharedPreferences prefs;
  final List<int> milestones = [1, 7, 14, 21, 30, 60, 90, 180, 365];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;
  Timer? _dateChecker;
  int? _lastCelebratedDays;

  // New properties for offline handling
  bool isSyncing = false;
  bool pendingSync = false;
  List<Map<String, dynamic>> _pendingActions = [];

  // Notification related properties
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool notificationsEnabled = true;
  List<TimeOfDay> dailyReminderTimes = [];

  // Getters and setters for renamed properties to maintain backward compatibility
  DateTime? get sobrietyStartDate => _recoveryStartDate;
  set sobrietyStartDate(DateTime? date) {
    _recoveryStartDate = date;
  }

  int get totalCheckIns => _gambleFreeStreak;
  set totalCheckIns(int value) {
    _gambleFreeStreak = value;
  }

  Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
    await _initializeNotifications();
    await _getUserId();

    if (userId != null) {
      // Load local data first
      await _loadLocalData();

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      // If online, sync with Firebase
      if (isOnline) {
        await _syncDataFromFirebase();
        await _syncPendingActionsToFirebase();
      }

      _updateMilestone();
      _startDateChecker();
      await _scheduleAllNotifications();
    }
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    String? startDateStr = prefs.getString('recovery_start_date');
    String? lastCheckInStr = prefs.getString('last_check_in_date');
    _recoveryStartDate =
        startDateStr != null ? DateTime.parse(startDateStr) : null;
    lastCheckInDate =
        lastCheckInStr != null ? DateTime.parse(lastCheckInStr) : null;
    _gambleFreeStreak = prefs.getInt('gamble_free_streak') ?? 0;
    hasCheckedInToday = _hasCheckedInToday();
    _lastCelebratedDays = prefs.getInt('last_celebrated_days');

    // Load pending actions
    final pendingActionsJson = prefs.getStringList('pending_actions') ?? [];
    _pendingActions = pendingActionsJson
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
    pendingSync = _pendingActions.isNotEmpty;

    // Load notification settings
    notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    dailyReminderTimes = _loadReminderTimes();
  }

  Future<void> syncPendingData() async {
    if (_pendingActions.isEmpty) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      await _syncPendingActionsToFirebase();
    }
  }

  Future<void> _syncPendingActionsToFirebase() async {
    if (_pendingActions.isEmpty) return;

    setState(() => isSyncing = true);

    try {
      for (var action in _pendingActions) {
        final type = action['type'];

        if (type == 'check_in') {
          // Update Firebase with cached check-in
          await _firestore.collection('users').doc(userId).update({
            'recovery_start_date': _recoveryStartDate?.toIso8601String() ?? '',
            'has_checked_in_today': true,
            'gamble_free_streak': _gambleFreeStreak,
            'last_check_in_date': action['date'],
            'last_sync_time': DateTime.now().toIso8601String(),
          });

          // Also add to history collection for tracking
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('check_in_history')
              .add({
            'date': action['date'],
            'streak': action['streak'],
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else if (type == 'relapse') {
          // Update Firebase with cached relapse
          await _firestore.collection('users').doc(userId).update({
            'recovery_start_date': '',
            'has_checked_in_today': false,
            'gamble_free_streak': 0,
            'relapse_date': action['date'],
            'last_sync_time': DateTime.now().toIso8601String(),
          });

          // Add to relapse history
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('relapse_history')
              .add({
            'date': action['date'],
            'previous_streak': action['previous_streak'],
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      // Clear pending actions after successful sync
      _pendingActions.clear();
      await prefs.setStringList('pending_actions', []);
      pendingSync = false;
    } catch (e) {
      print('Error syncing pending actions to Firebase: $e');
    } finally {
      setState(() => isSyncing = false);
    }
  }

  void setState(Function() updateFunction) {
    updateFunction();
    notifyListeners();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleAllNotifications() async {
    if (!notificationsEnabled) return;

    await flutterLocalNotificationsPlugin.cancelAll();

    for (var reminderTime in dailyReminderTimes) {
      await _scheduleDailyReminder(reminderTime);
    }

    await _scheduleMilestoneNotifications();
    await _scheduleRandomMotivationalNotifications();

    if (!hasCheckedInToday) {
      await _scheduleCheckInReminder();
    }
  }

  Future<void> _scheduleDailyReminder(TimeOfDay time) async {
    final now = DateTime.now();
    var scheduledTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1000 + dailyReminderTimes.indexOf(time),
      'Daily Recovery Reminder',
      'Remember to stay strong and committed to your gambling-free journey today!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Recovery Reminders',
          channelDescription: 'Reminders to stay committed to your recovery',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleMilestoneNotifications() async {
    final upcomingMilestones =
        milestones.where((m) => m > _gambleFreeStreak).toList();

    for (var milestone in upcomingMilestones) {
      final daysToMilestone = milestone - _gambleFreeStreak;
      final milestoneDate = DateTime.now().add(Duration(days: daysToMilestone));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        2000 + milestone,
        'Milestone Approaching!',
        'You\'re ${daysToMilestone} days away from ${milestone} days gambling-free! Keep going!',
        tz.TZDateTime.from(
            milestoneDate.subtract(const Duration(days: 1)), tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestone_reminder',
            'Milestone Reminders',
            channelDescription:
                'Notifications for upcoming recovery milestones',
            importance: Importance.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _scheduleCheckInReminder() async {
    final now = DateTime.now();
    var eveningTime = DateTime(now.year, now.month, now.day, 20, 0);

    if (eveningTime.isBefore(now)) {
      eveningTime = eveningTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      3000,
      'Daily Check-in Reminder',
      'Don\'t forget to check in today and track your gambling-free progress!',
      tz.TZDateTime.from(eveningTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_reminder',
          'Check-in Reminders',
          channelDescription: 'Reminders to complete your daily check-in',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleRandomMotivationalNotifications() async {
    final messages = [
      'You\'re doing amazing! One day at a time without gambling.',
      'Remember why you started this recovery journey. You\'ve got this!',
      'Every gambling-free day is a victory. Celebrate your strength!',
    ];

    final random = Random();

    for (int i = 0; i < 2; i++) {
      final daysToAdd = random.nextInt(7);
      final hours = 9 + random.nextInt(10);
      final minutes = random.nextInt(60);

      var notificationTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day + daysToAdd,
        hours,
        minutes,
      );

      if (notificationTime.isBefore(DateTime.now())) {
        notificationTime = notificationTime.add(const Duration(days: 7));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        4000 + i,
        'Gambling Recovery Boost',
        messages[random.nextInt(messages.length)],
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'motivational',
            'Motivational Messages',
            channelDescription: 'Encouraging messages to support your recovery',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> showMilestoneAchievedNotification(int days) async {
    await flutterLocalNotificationsPlugin.show(
      5000,
      '🎉 Congratulations! 🎉',
      'You\'ve reached $days days gambling-free! Amazing work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestone_achieved',
          'Milestone Achieved',
          channelDescription:
              'Celebrations for reaching gambling recovery milestones',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  Future<void> addDailyReminder(TimeOfDay time) async {
    dailyReminderTimes.add(time);
    await _saveReminderTimes();
    await _scheduleDailyReminder(time);
    notifyListeners();
  }

  Future<void> removeDailyReminder(TimeOfDay time) async {
    dailyReminderTimes
        .removeWhere((t) => t.hour == time.hour && t.minute == time.minute);
    await _saveReminderTimes();
    await flutterLocalNotificationsPlugin
        .cancel(1000 + dailyReminderTimes.indexOf(time));
    notifyListeners();
  }

  Future<void> _saveReminderTimes() async {
    final timesAsString =
        dailyReminderTimes.map((t) => '${t.hour}:${t.minute}').toList();
    await prefs.setStringList('daily_reminder_times', timesAsString);
  }

  List<TimeOfDay> _loadReminderTimes() {
    final timesAsString = prefs.getStringList('daily_reminder_times') ?? [];
    return timesAsString.map((s) {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  Future<void> toggleNotifications(bool enabled) async {
    notificationsEnabled = enabled;
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await _scheduleAllNotifications();
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
    notifyListeners();
  }

  bool shouldCelebrate() {
    if (_gambleFreeStreak == 0) return false;
    if (_lastCelebratedDays == _gambleFreeStreak) return false;

    bool shouldCelebrate = milestones.contains(_gambleFreeStreak);
    if (_gambleFreeStreak > 365) {
      shouldCelebrate = shouldCelebrate || (_gambleFreeStreak % 30 == 0);
    }

    if (shouldCelebrate) {
      _lastCelebratedDays = _gambleFreeStreak;
      prefs.setInt('last_celebrated_days', _gambleFreeStreak);
    }

    return shouldCelebrate;
  }

  Future<void> _getUserId() async {
    User? user = _auth.currentUser;
    userId = user?.uid;
  }

  Future<void> _syncDataFromFirebase() async {
    try {
      if (userId == null) return;

      setState(() => isSyncing = true);

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        // Use new property names to match chat screen
        String? firebaseStartDate = data['recovery_start_date'];
        bool firebaseCheckedInToday = data['has_checked_in_today'] ?? false;
        int firebaseGambleFreeStreak = data['gamble_free_streak'] ?? 0;
        String? firebaseLastCheckIn = data['last_check_in_date'];
        String? firebaseLastSyncTime = data['last_sync_time'];

        String? localLastSyncTime = prefs.getString('last_sync_time');

        // Only update local data if Firebase data is newer
        bool shouldUpdateLocal = true;
        if (localLastSyncTime != null && firebaseLastSyncTime != null) {
          DateTime localSync = DateTime.parse(localLastSyncTime);
          DateTime firebaseSync = DateTime.parse(firebaseLastSyncTime);
          shouldUpdateLocal = firebaseSync.isAfter(localSync);
        }

        if (shouldUpdateLocal) {
          await prefs.setString('recovery_start_date', firebaseStartDate ?? '');
          await prefs.setInt('gamble_free_streak', firebaseGambleFreeStreak);
          await prefs.setString(
              'last_check_in_date', firebaseLastCheckIn ?? '');
          await prefs.setBool(
            'checkin_${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
            firebaseCheckedInToday,
          );
          await prefs.setString('last_sync_time',
              firebaseLastSyncTime ?? DateTime.now().toIso8601String());

          // Update in-memory values
          _recoveryStartDate =
              firebaseStartDate != null && firebaseStartDate.isNotEmpty
                  ? DateTime.parse(firebaseStartDate)
                  : null;
          _gambleFreeStreak = firebaseGambleFreeStreak;
          lastCheckInDate =
              firebaseLastCheckIn != null && firebaseLastCheckIn.isNotEmpty
                  ? DateTime.parse(firebaseLastCheckIn)
                  : null;
          hasCheckedInToday = firebaseCheckedInToday;
        }
      } else {
        // Create new user document
        await _firestore.collection('users').doc(userId).set({
          'recovery_start_date': _recoveryStartDate?.toIso8601String() ?? '',
          'has_checked_in_today': hasCheckedInToday,
          'gamble_free_streak': _gambleFreeStreak,
          'last_check_in_date': lastCheckInDate?.toIso8601String() ?? '',
          'last_sync_time': DateTime.now().toIso8601String(),
        });

        await prefs.setString(
            'last_sync_time', DateTime.now().toIso8601String());
      }

      setState(() => isSyncing = false);
    } catch (e) {
      print('Error syncing data from Firebase: $e');
      setState(() => isSyncing = false);
    }
  }

  Future<void> _syncDataToFirebase() async {
    try {
      if (userId == null) return;

      final now = DateTime.now().toIso8601String();

      await _firestore.collection('users').doc(userId).update({
        'recovery_start_date': _recoveryStartDate?.toIso8601String() ?? '',
        'has_checked_in_today': hasCheckedInToday,
        'gamble_free_streak': _gambleFreeStreak,
        'last_check_in_date': lastCheckInDate?.toIso8601String() ?? '',
        'last_sync_time': now,
      });

      await prefs.setString('last_sync_time', now);
    } catch (e) {
      print('Error syncing data to Firebase: $e');
    }
  }

  Future<void> _addPendingAction(String type,
      {Map<String, dynamic>? extraData}) async {
    final action = {
      'type': type,
      'date': DateTime.now().toIso8601String(),
      ...?extraData,
    };

    _pendingActions.add(action);

    // Save to SharedPreferences
    final pendingActionsJson =
        _pendingActions.map((action) => jsonEncode(action)).toList();

    await prefs.setStringList('pending_actions', pendingActionsJson);
    pendingSync = true;
    notifyListeners();
  }

  bool _hasCheckedInToday() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return prefs.getBool('checkin_$today') ?? false;
  }

  void _startDateChecker() {
    _dateChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_hasDateChanged()) {
        _handleNewDay();
      }
    });
  }

  bool _hasDateChanged() {
    final lastCheck = prefs.getString('last_date_check');
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastCheck != currentDate;
  }

  Future<bool> checkMissedDay(BuildContext context) async {
    if (lastCheckInDate == null) return false;

    final today = DateTime.now();
    final difference = today.difference(lastCheckInDate!).inDays;

    if (difference > 1) {
      bool shouldReset = await _showMissedDayDialog(context);
      return shouldReset;
    }
    return false;
  }

  Future<bool> _showMissedDayDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Missed Check-in', style: GoogleFonts.poppins()),
        content: Text(
          'We noticed you missed checking in yesterday. Were you loyal to your plan, or did you gamble? Please be honest with yourself.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('I Gambled',
                style: GoogleFonts.poppins(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('I Stayed Gambling-Free',
                style: GoogleFonts.poppins(color: Colors.green)),
          ),
        ],
      ),
    );

    return result ?? true;
  }

  void _handleNewDay() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('last_date_check', today);
    hasCheckedInToday = false;
    notifyListeners();
    await _scheduleAllNotifications();
  }

  void _updateMilestone() {
    if (_recoveryStartDate == null) return;
    int daysSober = _gambleFreeStreak;
    for (int milestone in milestones.reversed) {
      if (daysSober >= milestone) {
        currentMilestone = milestone;
        notifyListeners();
        return;
      }
    }
  }

  DateTime? lastCheckInDate;

  Future<void> checkIn(BuildContext context, {bool isOnline = true}) async {
    if (hasCheckedInToday) return;

    setState(() => isSyncing = true);

    if (await checkMissedDay(context)) {
      await _resetData(isOnline: isOnline);
      setState(() => isSyncing = false);
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_recoveryStartDate == null) {
      _recoveryStartDate = DateTime.parse(today);
      await prefs.setString('recovery_start_date', today);
    }

    _gambleFreeStreak++;
    lastCheckInDate = DateTime.now();

    // Always save to SharedPreferences first (offline-first)
    await prefs.setInt('gamble_free_streak', _gambleFreeStreak);
    await prefs.setString(
        'last_check_in_date', lastCheckInDate!.toIso8601String());
    await prefs.setBool('checkin_$today', true);
    hasCheckedInToday = true;

    // If online, sync to Firebase
    if (isOnline) {
      try {
        await _syncDataToFirebase();

        // Also add check-in to history
        if (userId != null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('check_in_history')
              .add({
            'date': today,
            'streak': _gambleFreeStreak,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error syncing check-in to Firebase: $e');
        // Add to pending actions to sync later
        await _addPendingAction('check_in', extraData: {
          'streak': _gambleFreeStreak,
        });
      }
    } else {
      // If offline, add to pending actions
      await _addPendingAction('check_in', extraData: {
        'streak': _gambleFreeStreak,
      });
    }

    if (shouldCelebrate()) {
      await showMilestoneAchievedNotification(_gambleFreeStreak);
    }

    _updateMilestone();
    await _scheduleAllNotifications();

    setState(() => isSyncing = false);
    notifyListeners();
  }

  int getDaysSober() {
    return _gambleFreeStreak;
  }

  Future<void> handleRelapse(BuildContext context,
      {bool isOnline = true}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Beginning', style: GoogleFonts.poppins()),
        content: Text(
          "It's okay to start fresh. Remember, every day is a new opportunity in your gambling recovery.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _resetData(isOnline: isOnline);
    }
  }

  Future<void> _resetData({bool isOnline = true}) async {
    setState(() => isSyncing = true);

    final previousStreak = _gambleFreeStreak;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Always update SharedPreferences first (offline-first)
    await prefs.remove('recovery_start_date');
    await prefs.remove('last_celebrated_days');
    await prefs.setInt('gamble_free_streak', 0);
    await prefs.remove('last_check_in_date');
    await _resetCheckins();

    _recoveryStartDate = null;
    hasCheckedInToday = false;
    _lastCelebratedDays = null;
    _gambleFreeStreak = 0;
    lastCheckInDate = null;

    // If online, sync to Firebase
    if (isOnline) {
      try {
        await _syncDataToFirebase();

        // Add relapse to history
        if (userId != null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('relapse_history')
              .add({
            'date': today,
            'previous_streak': previousStreak,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error syncing relapse to Firebase: $e');
        // Add to pending actions to sync later
        await _addPendingAction('relapse', extraData: {
          'previous_streak': previousStreak,
        });
      }
    } else {
      // If offline, add to pending actions
      await _addPendingAction('relapse', extraData: {
        'previous_streak': previousStreak,
      });
    }

    await _scheduleAllNotifications();

    setState(() => isSyncing = false);
    notifyListeners();
  }

  Future<void> _resetCheckins() async {
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('checkin_')) {
        await prefs.remove(key);
      }
    }
  }

  @override
  void dispose() {
    _dateChecker?.cancel();
    super.dispose();
  }
}
