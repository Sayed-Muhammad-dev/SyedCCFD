import 'package:flutter/material.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_3.dart';
import '../services/firebase_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  final Map<String, dynamic> _onboardingData = {};
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSaving = false;

  void _handleScreen1Next(Map<String, dynamic> data) {
    setState(() {
      _onboardingData.addAll(data);
      _currentStep = 1;
    });
  }

  void _handleScreen2Next(Map<String, dynamic> data) {
    setState(() {
      _onboardingData.addAll(data);
      _currentStep = 2;
    });
  }

  void _handleScreen2Back() {
    setState(() {
      _currentStep = 0;
    });
  }

  void _handleScreen3Back() {
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _handleScreen3Finish(Map<String, dynamic> data) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Merge all onboarding data
      final allData = {
        ..._onboardingData,
        ...data,
      };

      // Save to Firestore
      await _firebaseService.saveOnboardingData(allData);

      if (mounted) {
        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving onboarding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Saving your preferences...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentStep) {
      case 0:
        return OnboardingScreen1(
          onNext: _handleScreen1Next,
          initialData: _onboardingData,
        );
      case 1:
        return OnboardingScreen2(
          onNext: _handleScreen2Next,
          onBack: _handleScreen2Back,
          initialData: _onboardingData,
        );
      case 2:
        return OnboardingScreen3(
          onFinish: _handleScreen3Finish,
          onBack: _handleScreen3Back,
          initialData: _onboardingData,
        );
      default:
        return OnboardingScreen1(
          onNext: _handleScreen1Next,
          initialData: _onboardingData,
        );
    }
  }
}

