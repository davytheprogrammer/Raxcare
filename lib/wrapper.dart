// wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp_app/app.dart';
import 'package:fyp_app/screens/authentication/authenticate.dart';
import 'package:fyp_app/models/the_user.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<TheUser?>(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: user == null ? const Authenticate() : const App(),
    );
  }
}