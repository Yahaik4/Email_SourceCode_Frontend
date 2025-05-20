
import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class SessionManager {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _tokenKey = 'token';
  static final _storage = GetStorage();

  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(_isLoggedInKey, value);
  }

  static Future<bool> isLoggedIn() async {
    return _storage.read(_isLoggedInKey) ?? false;
  }

  static Future<void> setToken(String token) async {
    await _storage.write(_tokenKey, base64Encode(utf8.encode(token)));
  }

  static Future<String?> getToken() async {
    final encoded = _storage.read(_tokenKey);
    return encoded != null ? utf8.decode(base64Decode(encoded)) : null;
  }

  static Future<void> clear() async {
    await _storage.remove(_isLoggedInKey);
    await _storage.remove(_tokenKey);
  }

  static Future<void> clearSession() async {
    await _storage.erase();
  }
}