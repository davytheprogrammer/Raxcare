import 'package:RaxCare/screens/goals/goals.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:RaxCare/models/the_user.dart';
import 'package:RaxCare/screens/home/home.dart';
import 'package:RaxCare/services/auth.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'wrapper.dart';
import 'package:RaxCare/screens/tracking.dart';
import 'package:RaxCare/screens/community.dart';

class Routes {
  static const String app = '/app';
  static const String wrapper = '/wrapper';
  static const String home = '/home';
  static const String tracking = '/tracking';
  static const String community = '/community';
  static const String chat = '/chat';
  static const String goals = '/goals'; // Add goals route if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    // Ensure user document exists
    await _ensureUserDocumentsExist();

    runApp(const MyApp());
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    runApp(const MyApp());
  }
}

Future<void> _ensureUserDocumentsExist() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Query all existing users
    QuerySnapshot userQuery = await firestore.collection('users').get();

    // If no users exist, create a template document
    if (userQuery.docs.isEmpty) {
      await firestore.collection('users').doc('template').set({
        'sobriety_start_date': '',
        'has_checked_in_today': false,
        'total_check_ins': 0,
        'last_check_in_date': '',
      });
    }
  } catch (e) {
    debugPrint("Error ensuring user documents: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<TheUser?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, __) => null,
        ),
        ChangeNotifierProvider(
          create: (_) => RecoveryGoalProvider(),
        ),
      ],
      child: MaterialApp(
        initialRoute: Routes.wrapper,
        routes: {
          Routes.app: (context) => const App(),
          Routes.wrapper: (context) => const Wrapper(),
          Routes.home: (context) => HomePage(),
          Routes.tracking: (context) => const Tracking(),
          Routes.community: (context) => const Community(),
          // Add goals route if needed:
          // Routes.goals: (context) => GoalsScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
