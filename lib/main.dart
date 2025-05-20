import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:testabc/core/routes.dart';
import 'package:testabc/firebase_options.dart';
import 'package:testabc/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await GetStorage.init();
    final storage = GetStorage();
    final isLoggedIn = storage.read('token') != null;
    final isDarkMode = storage.read('isDarkMode') ?? true; // Mặc định là Dark dựa trên backend
    await SessionManager.setLoggedIn(isLoggedIn);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode ? const Color(0xFF1F1F2A) : Colors.blue.shade900,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkMode ? const Color(0xFF1F1F2A) : Colors.white,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    runApp(MyApp(isLoggedIn: isLoggedIn, isDarkMode: isDarkMode));
  } catch (e) {
    debugPrint('Initialization failed: $e');
    runApp(const ErrorApp());
  }
}

class ThemeProvider extends InheritedWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const ThemeProvider({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
    required Widget child,
  }) : super(key: key, child: child);

  static ThemeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool isDarkMode;

  const MyApp({Key? key, required this.isLoggedIn, required this.isDarkMode}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    GetStorage().listenKey('isDarkMode', (value) {
      setState(() {
        _isDarkMode = value as bool;
      });
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      GetStorage().write('isDarkMode', _isDarkMode);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: _isDarkMode ? const Color(0xFF1F1F2A) : Colors.blue.shade900,
          statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: _isDarkMode ? const Color(0xFF1F1F2A) : Colors.white,
          systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        title: 'Email App',
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        initialRoute: widget.isLoggedIn ? '/home' : '/login',
        routes: appRoutes,
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      primaryColor: Colors.blue.shade900,
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF9146FF),
      scaffoldBackgroundColor: const Color(0xFF2C2C38),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9146FF),
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F1F2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3C3C48)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3C3C48)),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1F1F2A),
        selectedItemColor: Color(0xFF9146FF),
        unselectedItemColor: Colors.white70,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF2C2C38),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize app. Please try again.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}