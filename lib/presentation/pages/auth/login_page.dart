import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/auth_utils.dart';
import 'dart:convert';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/widgets/home/custom_snackbar.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _getFcmToken();
  }

  Future<void> _getFcmToken() async {
    try {
      if (kIsWeb) {
        NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          const vapidKey = 'BLgpg7R8mfUQVGHisBhWfDErrb_x2RBLO6nrXbK3I3mDZBx-pU7Y29cnJjTyJt9Tmz33Wedjy13yrAPs1HTqr1I';
          String? token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
          setState(() {
            _fcmToken = token;
            if (token == null) {
              _errorMessage = 'FCM token is null, proceeding without notifications';
            }
          });
        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          setState(() {
            _errorMessage = 'Notification permission denied. You can still log in without notifications.';
          });
        } else {
          setState(() {
            _errorMessage = 'Notification permission not granted. You can still log in without notifications.';
          });
        }
      } else {
        String? token = await FirebaseMessaging.instance.getToken();
        setState(() {
          _fcmToken = token;
          if (token == null) {
            _errorMessage = 'FCM token is null, proceeding without notifications';
          }
        });
      }

      if (_fcmToken != null) {
        print('✅ FCM Token: $_fcmToken');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get FCM token: $e. You can still log in without notifications.';
      });
    }
  }

  Future<String?> _extractToken(http.Response response) async {
    try {
      final responseData = jsonDecode(response.body);
      return responseData['token'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeToken(String token) async {
    await SessionManager.setToken(token);
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      };
      if (_fcmToken != null) {
        body['fcmToken'] = _fcmToken!;
      }

      final loginResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      // .timeout(const Duration(seconds: 10));

      if (loginResponse.statusCode == 200) {
        final token = await _extractToken(loginResponse);
        if (token == null) {
          throw Exception('Token not found in response');
        }

        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['sub'];

        final userResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          final phoneNumber = userData['metadata']['phoneNumber'];
          final userId = userData['metadata']['id'];
          final is2FAEnabled = userData['metadata']['setting']['two_factor_enabled'] ?? false;
          final theme = userData['metadata']['setting']['theme'] ?? "Dark";

          await GetStorage().write('isDarkMode', theme == "Dark");

          if (phoneNumber == null || phoneNumber.isEmpty) {
            setState(() {
              _errorMessage = 'No phone number found for this user';
              _isLoading = false;
            });
            return;
          }

          String formattedPhoneNumber = phoneNumber.startsWith('+') ? phoneNumber : '+84$phoneNumber';

          if (is2FAEnabled) {
            await AuthUtils.startPhoneAuth(
              context: context,
              phoneNumber: formattedPhoneNumber,
              userId: userId,
              route: '/otp',
              arguments: {
                'phoneNumber': formattedPhoneNumber,
                'userId': userId,
                'token': token,
              },
              setLoading: (value) => setState(() => _isLoading = value),
            );
          } else {
            await _storeToken(token);
            await SessionManager.setLoggedIn(true);
            CustomSnackBar.show(
              context,
              message: 'Login successful!',
              borderColor: const Color(0xFF9146FF),
            );
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() {
            _errorMessage = jsonDecode(userResponse.body)['msg'] ?? 'Failed to fetch user data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = jsonDecode(loginResponse.body)['msg'] ?? 'Login failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Image.asset('assets/logo.png', height: 200, width: 200, fit: BoxFit.contain),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  color: const Color(0xFF26263B),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9146FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              prefixIcon: const Icon(Icons.email, color: Color(0xFF9146FF)),
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF9146FF), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A2E),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF9146FF)),
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF9146FF), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A2E),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade400, fontSize: 14, fontFamily: 'Inter'),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9146FF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9146FF)),
                            child: const Text(
                              "Don't have an account? Sign Up",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9146FF)),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}