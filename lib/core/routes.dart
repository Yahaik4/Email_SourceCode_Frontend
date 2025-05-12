import 'package:flutter/material.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/home_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginPage(),
  '/home': (context) => HomePage(),
};
