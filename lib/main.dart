import 'package:flutter/material.dart';
import 'core/routes.dart';
import 'utils/session_manager.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await SessionManager.isLoggedIn();
  runApp(MyApp(isLoggedIn: false));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Example',
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: appRoutes,
    );
  }
}