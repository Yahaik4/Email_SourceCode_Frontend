import 'package:flutter/material.dart';
import '../presentation/pages/auth/otp_page.dart';
import '../presentation/pages/auth/register_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/profile/profile_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginPage(),
  '/home': (context) => const HomePage(),
  '/register': (context) => const RegisterPage(),
  '/otp': (context) => const OtpPage(),
  '/profile': (context) => const ProfileScreen(),
};
