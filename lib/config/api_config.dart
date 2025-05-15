import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Chạy trên web
      return 'http://localhost:3000'; // Thay bằng URL backend thực tế nếu deploy
    } else if (Platform.isAndroid) {
      // Chạy trên giả lập Android
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      // Chạy trên giả lập iOS
      return 'http://127.0.0.1:3000';
    } else {
      // Nền tảng khác (fallback)
      return 'http://localhost:3000';
    }
  }
}