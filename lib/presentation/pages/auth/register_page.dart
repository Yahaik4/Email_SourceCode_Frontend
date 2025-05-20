import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testabc/config/api_config.dart';
import 'dart:convert';
import 'package:testabc/utils/auth_utils.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy dữ liệu từ form
      final String email = _emailController.text.trim();
      final String username = _usernameController.text.trim();
      final String phoneNumberRaw = _phoneController.text.trim();
      final String password = _passwordController.text.trim();

      // Chuẩn hóa phoneNumber
      String phoneNumber = phoneNumberRaw.startsWith('+') ? phoneNumberRaw : '+84$phoneNumberRaw';

      // Gọi API /api/users/email để kiểm tra email đã tồn tại chưa
      final validateResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      if (validateResponse.statusCode == 200) {
        final responseData = jsonDecode(validateResponse.body);
        // Kiểm tra nếu email đã tồn tại (giả định metadata chứa thông tin người dùng nếu email đã đăng ký)
        if (responseData['metadata'] != null && responseData['metadata']['id'] != null) {
          setState(() {
            _errorMessage = 'This email is already registered';
            _isLoading = false;
          });
        } 
      } else {
        await AuthUtils.startPhoneAuth(
              context: context,
              phoneNumber: phoneNumber,
              userId: '',
              route: '/otp',
              arguments: {
                'phoneNumber': phoneNumber,
                'email': email,
                'username': username,
                'password': password,
              },
              setLoading: (value) => setState(() => _isLoading = value),
            );
      }
    } catch (e) {
      // Xử lý lỗi nếu gọi API thất bại
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9146FF),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'Username',
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
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your username' : null,
                          ),
                          const SizedBox(height: 12),
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
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: 'Phone Number (e.g., 0987654321)',
                              prefixIcon: const Icon(Icons.phone, color: Color(0xFF9146FF)),
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
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your phone number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Please enter a valid 10-digit phone number';
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
                              if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                                return 'Password must contain at least one uppercase letter';
                              }
                              if (!RegExp(r'(?=.*\d)').hasMatch(value)) return 'Password must contain at least one number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
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
                              if (value == null || value.isEmpty) return 'Please confirm your password';
                              if (value != _passwordController.text) return 'Passwords do not match';
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
                            onPressed: _isLoading ? null : _register,
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
                                    'Sign Up',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9146FF)),
                            child: const Text(
                              'Already have an account? Sign In',
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