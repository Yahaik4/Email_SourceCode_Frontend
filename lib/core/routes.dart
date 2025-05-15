import 'package:flutter/material.dart';
import 'package:testabc/presentation/pages/auth/otp_page.dart';
import 'package:testabc/presentation/pages/auth/register_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/home/home_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginPage(),
  '/home': (context) => HomePage(),
  '/register': (context) => const RegisterPage(),
  '/otp': (context) => const OtpPage(),
};
