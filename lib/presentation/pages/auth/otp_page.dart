import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/auth_utils.dart';
import 'dart:convert';
import 'package:testabc/utils/session_manager.dart';
import 'package:testabc/widgets/home/custom_snackbar.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({Key? key}) : super(key: key);

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _storeToken(String token) async {
    await SessionManager.setToken(token);
  }

  Future<void> _clearToken() async {
    await SessionManager.clear();
  }

  Future<void> _verifyOtp(
    String verificationId,
    String phoneNumber,
    String? email,
    String? username,
    String? password,
    String? userId,
    PhoneAuthCredential? autoCredential,
    String? loginToken,
    bool isResetPassword,
  ) async {
    if (!_formKey.currentState!.validate() && autoCredential == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      PhoneAuthCredential credential = autoCredential ??
          PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: _otpController.text.trim(),
          );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        if (isResetPassword) {
          // Password reset flow
          Navigator.pushNamed(context, '/reset-password', arguments: {
            'userId': userId,
          });
        } else if (email != null && username != null && password != null) {
          // Register flow
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'username': username,
              'phoneNumber': userCredential.user!.phoneNumber,
              'password': password,
            }),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            if (responseData['statusCode'] == 200) {
              CustomSnackBar.show(
                context,
                message: 'Registration successful! Please log in.',
                borderColor: const Color(0xFF9146FF),
              );
              await Future.delayed(const Duration(seconds: 1));
              Navigator.pushReplacementNamed(context, '/login');
            } else {
              setState(() {
                _errorMessage = 'Registration failed: ${responseData['msg'] ?? 'Unknown error'}';
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Registration failed: ${jsonDecode(response.body)['msg'] ?? 'Server error'}';
            });
          }
        } else if (userId != null && loginToken != null) {
          // Login flow with 2FA
          await _storeToken(loginToken);
          await SessionManager.setLoggedIn(true);
          CustomSnackBar.show(context, message: 'Login successful!', borderColor: const Color(0xFF9146FF));
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            _errorMessage = 'Invalid flow configuration';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid OTP or error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp(String phoneNumber, String userId, String? email, String? username, String? password, String? loginToken, bool isResetPassword) async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    await AuthUtils.startPhoneAuth(
      context: context,
      phoneNumber: phoneNumber,
      userId: userId,
      route: '/otp',
      arguments: {
        'phoneNumber': phoneNumber,
        'userId': userId,
        'email': email,
        'username': username,
        'password': password,
        'token': loginToken,
        'isResetPassword': isResetPassword,
      },
      setLoading: (value) => setState(() => _isResending = value),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String verificationId = arguments['verificationId'] ?? '';
    final String phoneNumber = arguments['phoneNumber'] ?? '';
    final String? email = arguments['email'];
    final String? username = arguments['username'];
    final String? password = arguments['password'];
    final String? userId = arguments['userId'];
    final PhoneAuthCredential? autoCredential = arguments['autoCredential'];
    final String? loginToken = arguments['token'];
    final bool isResetPassword = arguments['isResetPassword'] ?? false;

    return WillPopScope(
      onWillPop: () async {
        await _clearToken();
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
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
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9146FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "We have sent an OTP code to $phoneNumber",
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade400, fontFamily: 'Inter'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              hintText: 'Enter 6-digit OTP code',
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
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (value) {
                              if (autoCredential != null) return null;
                              if (value == null || value.isEmpty) return 'Please enter the OTP code';
                              if (value.length != 6) return 'OTP code must be 6 digits';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: _errorMessage!.contains('has been sent')
                                      ? const Color(0xFF9146FF)
                                      : Colors.red.shade400,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading || _isResending
                                      ? null
                                      : () => _resendOtp(phoneNumber, userId ?? '', email, username, password, loginToken, isResetPassword),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 89, 49, 154),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _isResending
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Resend',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading || _isResending
                                      ? null
                                      : () => _verifyOtp(verificationId, phoneNumber, email, username, password, userId, autoCredential, loginToken, isResetPassword),
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
                                          'Verify',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading || _isResending
                                ? null
                                : () async {
                                    await _clearToken();
                                    Navigator.pop(context);
                                  },
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9146FF)),
                            child: const Text(
                              'Back to login',
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
          ),
        ),
      ),
    );
  }
}