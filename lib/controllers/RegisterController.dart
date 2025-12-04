import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final RxDouble passwordStrength = 0.0.obs;
  final RxMap<String, bool> passwordChecklist = {
    'len': false,
    'upper': false,
    'lower': false,
    'num': false,
    'special': false,
  }.obs;

  final RxBool isSubmitting = false.obs;

  // ✅ Strong password rules
  void checkPasswordStrength(String password) {
    final len = password.length >= 8;
    final upper = RegExp(r'[A-Z]').hasMatch(password);
    final lower = RegExp(r'[a-z]').hasMatch(password);
    final num = RegExp(r'[0-9]').hasMatch(password);

    // At least 2 special characters
    final specialMatches = RegExp(r'[^A-Za-z0-9]').allMatches(password).length;
    final special = specialMatches >= 2;

    // Update checklist
    passwordChecklist['len'] = len;
    passwordChecklist['upper'] = upper;
    passwordChecklist['lower'] = lower;
    passwordChecklist['num'] = num;
    passwordChecklist['special'] = special;

    // Score calculation
    final score = [len, upper, lower, num, special].where((v) => v).length;
    passwordStrength.value = score / 5.0;
  }

  // ✅ Register new user with Firebase + Save to Firestore
  Future<void> register(VoidCallback onBackToLogin) async {
    if (!formKey.currentState!.validate()) return;

    isSubmitting.value = true;

    try {
      // Create user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save user info in Firestore under "Users" collection
        await FirebaseFirestore.instance.collection("Users").doc(user.uid).set({
          "uid": user.uid,
          "username": usernameController.text.trim(),
          "firstName": fnameController.text.trim(),
          "lastName": lnameController.text.trim(),
          "email": emailController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar(
        "Success",
        "User registered successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      onBackToLogin();
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Registration failed",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
