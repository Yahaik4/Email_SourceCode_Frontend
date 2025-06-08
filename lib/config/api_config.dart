import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://email-sourcecode-backend-951t.onrender.com'; 
    } else if (Platform.isAndroid) {
      return 'https://email-sourcecode-backend-951t.onrender.com';
    } else if (Platform.isIOS) {
      return 'https://email-sourcecode-backend-951t.onrender.com';
    } else {
      return 'https://email-sourcecode-backend-951t.onrender.com';
    }
  }

  static String get webSocketUrl {
    if (kIsWeb) {
      return 'wss://email-sourcecode-backend-951t.onrender.com'; // WebSocket URL cho web
    } else if (Platform.isAndroid) {
      return 'wss://email-sourcecode-backend-951t.onrender.com';
    } else if (Platform.isIOS) {
      return 'wss://email-sourcecode-backend-951t.onrender.com';
    } else {
      return 'wss://email-sourcecode-backend-951t.onrender.com';
    }
  }
}