import 'dart:math';
import 'package:ccd/views/OTPScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  Future<bool> doesUserExist(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    print('DEBUG: Checking email existence in Firestore for: "$cleanEmail"');

    try {
      // Query Firestore for users matching the email
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('DEBUG: User exists for email "$cleanEmail"');
        return true;
      } else {
        print('DEBUG: No user found for email "$cleanEmail"');
        Get.snackbar(
          "No Account",
          "No account found with this email address. Please ensure you typed it correctly or check if the account exists.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('DEBUG: Error querying Firestore for email "$cleanEmail": $e');
      Get.snackbar(
        'Error',
        'Something went wrong while checking your account. Please try again later.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  String generateOtp() {
    final rnd = Random();
    return (10000 + rnd.nextInt(90000)).toString();
  }

  Future<void> storeOtpInFirestore(
      {required String email, required String otp}) async {
    await FirebaseFirestore.instance
        .collection('password_reset_otps')
        .doc(email)
        .set({
      'otp': otp,
      'expiresAt': DateTime.now().add(Duration(minutes: 10)),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendOtpEmail(
      {required String toEmail, required String otp}) async {
    try {
      final gmailEmail = dotenv.env["GMAIL_MAIL"];
      final gmailPassword = dotenv.env["GMAIL_PASSWORD"];

      if (gmailEmail == null || gmailEmail.isEmpty) {
        throw Exception('GMAIL_MAIL environment variable not set');
      }
      if (gmailPassword == null || gmailPassword.isEmpty) {
        throw Exception('GMAIL_PASSWORD environment variable not set');
      }

      print('DEBUG: Gmail email: $gmailEmail');
      print('DEBUG: Attempting to connect to SMTP server...');

      final gmailSmtp = gmail(gmailEmail, gmailPassword);

      final message = Message()
        ..from = Address(gmailEmail, 'Fraud Detection App')
        ..recipients.add(toEmail)
        ..subject = 'Your Password Reset OTP'
        ..html = '''
        <html>
          <body style="font-family: Arial, sans-serif; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
              <h2>Password Reset Request</h2>
              <p>Hello,</p>
              <p>Your OTP code for password reset is:</p>
              <div style="background-color: #f0f0f0; padding: 15px; border-radius: 5px; text-align: center; margin: 20px 0;">
                <h1 style="color: #6A11CB; margin: 0; letter-spacing: 5px;">$otp</h1>
              </div>
              <p style="color: #666;">This code will expire in 10 minutes.</p>
              <p style="color: #666;">If you did not request this, please ignore this email.</p>
              <hr>
              <p style="font-size: 12px; color: #999;">Fraud Detection App - Security Team</p>
            </div>
          </body>
        </html>
        ''';

      print('DEBUG: Sending email to: $toEmail');
      final response = await send(message, gmailSmtp);
      print('DEBUG: Email sent successfully. Response: $response');
    } catch (e) {
      print('ERROR: Failed to send email: ${e.toString()}');
      print('ERROR Stack trace: $e');
      rethrow; // Re-throw so the caller can handle it
    }
  }

  Future<void> handleForgotPassword(BuildContext context) async {
    final email = emailController.text.trim().toLowerCase();
    print('📨 Forgot password requested for: "$email"');
    isLoading.value = true;

    try {
      bool exists = await doesUserExist(email);
      if (!exists) {
        isLoading.value = false;
        return;
      }

      final otp = generateOtp();
      print('DEBUG: Generated OTP: $otp');

      await storeOtpInFirestore(email: email, otp: otp);
      print('DEBUG: OTP stored in Firestore');

      await sendOtpEmail(toEmail: email, otp: otp);
      print('DEBUG: OTP email sent successfully');

      Get.snackbar(
        'Success',
        'Check your Email for the OTP',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.off(() => OtpScreen(), arguments: {'email': email});
      });
    } catch (e) {
      print('ERROR in handleForgotPassword: ${e.toString()}');
      Get.snackbar(
        'Error Sending Email',
        'Failed to send OTP email. Error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
