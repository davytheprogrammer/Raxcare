import 'package:flutter/material.dart';
import 'package:fyp_app/screens/home/home.dart';
import 'package:fyp_app/screens/journal/journal.dart';

import 'screens/form/relapsehistory.dart';
import 'screens/goals/goals.dart';

import 'screens/settings.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0; // Starting index for BottomNavigationBar

  // Constants for styling
  static const Color _activeColor = Color.fromRGBO(248, 221, 145, 1.0);
  static const Color _inactiveColor = Color.fromRGBO(240, 240, 235, 1.0);
  static const Color _canvasColor = Color.fromRGBO(4, 98, 126, 1.0);
  static const TextStyle _unselectedTextStyle = TextStyle(color: Colors.yellow);

  // Screens for navigation
  final List<Widget> _screens = [
    HomePage(),
    RelapseHistoryScreen(),
    const Goals(),
    JournalScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: _canvasColor,
          textTheme: Theme.of(context).textTheme.copyWith(
                bodySmall: _unselectedTextStyle,
              ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (newIndex) => setState(() {
            _currentIndex = newIndex;
          }),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Relapse Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          unselectedItemColor: _inactiveColor,
          selectedItemColor: _activeColor,
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
