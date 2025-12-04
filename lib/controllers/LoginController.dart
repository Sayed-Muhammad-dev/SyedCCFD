import 'package:ccd/views/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoggingIn = false.obs;
  final RxBool isPasswordHidden = true.obs;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoggingIn.value = true;
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // ✅ If login successful, navigate to Dashboard
      if (userCredential.user != null) {
        Get.offAll(() => const DashboardPage());
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message ?? 'Something went wrong',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoggingIn.value = false;
    }
  }
}
