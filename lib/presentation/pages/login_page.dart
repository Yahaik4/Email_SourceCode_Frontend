import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print("Google Login: ${userCredential.user?.displayName}");
    } catch (e) {
      print("Google Login Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                // icon: Image.asset('assets/google.png', height: 24),
                label: const Text("Đăng nhập với Google"),
                onPressed: signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              // const SizedBox(height: 16),
              // ElevatedButton.icon(
              //   icon: Image.asset('assets/facebook.png', height: 24),
              //   label: const Text("Đăng nhập với Facebook"),
              //   onPressed: signInWithFacebook,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: const Color(0xFF1877F2),
              //     foregroundColor: Colors.white,
              //     minimumSize: const Size(double.infinity, 50),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
