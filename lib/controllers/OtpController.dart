import 'package:ccd/views/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpController extends GetxController {
  final String email;
  OtpController(this.email);

  var enteredOtp = ''.obs;
  var isVerifying = false.obs;
  var isResending = false.obs;

  // Only set enteredOtp.value, never wrap input widgets in Obx unless you read from obs
  void setOtp(String value) => enteredOtp.value = value;

  Future<void> verifyOtp() async {
    if (enteredOtp.value.length != 5) {
      Get.snackbar('Error', 'Please enter the 5-digit OTP.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isVerifying.value = true;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(email)
          .get();

      if (!doc.exists) {
        Get.snackbar(
            'Error', 'No OTP found for this email. Please request a new one.',
            backgroundColor: Colors.red, colorText: Colors.white);
        isVerifying.value = false;
        return;
      }

      final data = doc.data()!;
      final otp = data['otp'];
      final expiresAtField = data['expiresAt'];
      late DateTime expiresAt;
      if (expiresAtField is Timestamp) {
        expiresAt = expiresAtField.toDate();
      } else if (expiresAtField is DateTime) {
        expiresAt = expiresAtField;
      } else {
        throw Exception('Invalid expiresAt format');
      }

      if (DateTime.now().isAfter(expiresAt)) {
        Get.snackbar('Expired', 'OTP has expired. Please request a new one.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        isVerifying.value = false;
        return;
      }

      if (enteredOtp.value == otp) {
        await FirebaseFirestore.instance
            .collection('password_reset_otps')
            .doc(email)
            .delete();

        // Send Firebase password reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        // Show snackbar and go to login
        Get.snackbar(
          'Check your email',
          "We've sent a password reset link to $email. Please check your inbox to reset your password.",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        // Navigate to LoginScreen, adjust this according to your app
        Future.delayed(const Duration(milliseconds: 800), () {
          Get.to(LoginScreen());
        });
      } else {
        Get.snackbar('Error', 'Invalid OTP. Try again.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar(
          'Error', 'An error occurred. Please try again. (${e.toString()})',
          backgroundColor: Colors.red, colorText: Colors.white);
    }

    isVerifying.value = false;
  }

  Future<void> resendOtp() async {
    isResending.value = true;
    try {
      final otp =
          (10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString();

      await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(email)
          .set({
        'otp': otp,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // You should send the OTP via your backend/email service here

      Get.snackbar('OTP', 'A new OTP has been sent to your email.',
          backgroundColor: Colors.blue, colorText: Colors.white);
    } catch (e) {
      Get.snackbar(
          'Error', 'Failed to resend OTP. Please try again.\n${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    isResending.value = false;
  }
}
