import 'package:flutter/material.dart';

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

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Add OTP verification logic here if needed
      print("Verifying OTP: ${_otpController.text}");
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendOtp() {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      // TODO: Add logic to resend OTP here (e.g., API call)
      print("Resending OTP to phone number");
      setState(() {
        _errorMessage = 'A new OTP has been sent!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error resending OTP: $e';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E), // Twitch dark background
              Color(0xFF0F0F1A), // Slightly darker for gradient
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                color: Color(0xFF26263B), // Twitch dark card background
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Verify OTP",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9146FF), // Twitch purple
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "We have sent an OTP code to your phone number",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontFamily: 'Inter',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit OTP code',
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF9146FF)),
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
                              borderSide: BorderSide(color: Color(0xFF9146FF), width: 2),
                            ),
                            filled: true,
                            fillColor: Color(0xFF1A1A2E),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the OTP code';
                            }
                            if (value.length != 6) {
                              return 'OTP code must be 6 digits';
                            }
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
                                onPressed: _isLoading || _isResending ? null : _resendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 89, 49, 154), // Darker Twitch purple
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isResending
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Resend',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading || _isResending ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF9146FF), // Twitch purple
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Verify',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading || _isResending
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF9146FF),
                          ),
                          child: const Text(
                            'Back to login',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
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
    );
  }
}