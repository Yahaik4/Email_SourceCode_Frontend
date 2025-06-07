import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'package:testabc/utils/auth_utils.dart';
import 'dart:convert';
import 'package:testabc/widgets/home/custom_snackbar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _initiatePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch user data by username
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": _emailController.text.trim()})
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final phoneNumber = userData['metadata']['phoneNumber'];
        final userId = userData['metadata']['id'];

        if (phoneNumber == null || phoneNumber.isEmpty) {
          setState(() {
            _errorMessage = 'No phone number found for this user';
            _isLoading = false;
          });
          return;
        }

        String formattedPhoneNumber = phoneNumber.startsWith('+') ? phoneNumber : '+84$phoneNumber';

        await AuthUtils.startPhoneAuth(
          context: context,
          phoneNumber: formattedPhoneNumber,
          userId: userId,
          route: '/otp',
          arguments: {
            'phoneNumber': formattedPhoneNumber,
            'userId': userId,
            'username': _emailController.text.trim(),
            'isResetPassword': true,
          },
          setLoading: (value) => setState(() => _isLoading = value),
        );
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['msg'] ?? 'User not found';
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
                            "Reset Password",
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
                              hintText: 'Enter email',
                              prefixIcon: const Icon(Icons.person, color: Color(0xFF9146FF)),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your username';
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
                            onPressed: _isLoading ? null : _initiatePasswordReset,
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
                                    'Continue',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9146FF)),
                            child: const Text(
                              "Back to Sign In",
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