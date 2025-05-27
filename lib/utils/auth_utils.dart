import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testabc/widgets/home/custom_snackbar.dart';

class AuthUtils {
  static Future<void> startPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required String userId,
    required String route,
    required Map<String, dynamic> arguments,
    required Function(bool) setLoading,
  }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          arguments['autoCredential'] = credential;
          Navigator.pushNamed(context, route, arguments: arguments);
          setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          CustomSnackBar.show(
            context,
            message: 'Verification failed: ${e.message}',
            borderColor: Colors.red.shade400,
          );
          setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          arguments['verificationId'] = verificationId;
          Navigator.pushNamed(context, route, arguments: arguments);
          CustomSnackBar.show(
            context,
            message: 'OTP sent to $phoneNumber',
            borderColor: const Color(0xFF9146FF),
          );
          setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setLoading(false);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: 'Error starting phone auth: $e',
        borderColor: Colors.red.shade400,
      );
      setLoading(false);
    }
  }
}