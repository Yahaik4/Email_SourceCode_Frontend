import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://email-sourcecode-backend-951t.onrender.com'; 
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
      return 'wss://email-sourcecode-backend-951t.onrender.com'; // WebSocket URL cho web
    } else if (Platform.isAndroid) {
      return 'ws://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      return 'ws://127.0.0.1:3000';
    } else {
      return 'ws://localhost:3000';
    }
  }
}