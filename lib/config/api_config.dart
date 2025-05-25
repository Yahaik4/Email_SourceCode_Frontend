import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // HTTP base URL for API calls
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static String get webSocketUrl {
    if (kIsWeb) {
      return 'ws://localhost:3000'; // WebSocket URL for web
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:3000'; // WebSocket URL for Android emulator
    } else if (Platform.isIOS) {
      return 'ws://127.0.0.1:3000'; // WebSocket URL for iOS simulator
    } else {
      return 'ws://localhost:3000'; // Fallback
    }
  }
}