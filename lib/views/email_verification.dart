import 'dart:async';
import 'package:ccd/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? emailAddress;
  EmailVerificationScreen({Key? key, required this.emailAddress})
      : super(key: key);

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late Timer _verificationCheckTimer;
  late Timer _resendCooldownTimer;
  int _remainingTime = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    sendVerificationEmail();
    startResendCooldown();
    startPeriodicVerificationCheck();
  }

  void startPeriodicVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await checkEmailVerification();
    });
  }

  void startResendCooldown() {
    setState(() {
      _canResend = false;
      _remainingTime = 60;
    });

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _resendCooldownTimer.cancel();
      }
    });
  }

  Future<void> sendVerificationEmail() async {
    setState(() {
      _isVerifying = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent to ${widget.emailAddress}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user?.emailVerified ?? false) {
        // Cancel timers
        _verificationCheckTimer.cancel();
        _resendCooldownTimer.cancel();

        // Save verification state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isEmailVerified', true);
        await prefs.setString('userEmail', user?.email ?? '');

        // Navigate to home screen
        Navigator.pop(context);
        Get.to(() => LoginScreen());
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  @override
  void dispose() {
    _verificationCheckTimer.cancel();
    _resendCooldownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Email Verification'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Email Verification Lottie Animation
              Lottie.asset(
                'assets/emailverify.json',
                height: 200,
                width: 200,
                repeat: true,
              ),

              const SizedBox(height: 30),

              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'A verification email has been sent to\n${widget.emailAddress}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 30),

              // Circular Countdown Timer
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: _remainingTime / 60,
                center: Text(
                  '$_remainingTime',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: _canResend ? Colors.green : Colors.deepPurple,
                backgroundColor: Colors.deepPurple.shade100,
              ),

              const SizedBox(height: 20),

              // Resend Email Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _canResend
                    ? ElevatedButton(
                        onPressed: _isVerifying
                            ? null
                            : () {
                                sendVerificationEmail();
                                startResendCooldown();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        child: _isVerifying
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Resend Verification Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      )
                    : Text(
                        'Resend in $_remainingTime seconds',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // Wrong Email Option
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.to(() => LoginScreen());
                },
                child: Text(
                  'Wrong email? Go back to Login',
                  style: TextStyle(
                    color: Colors.deepPurple[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
