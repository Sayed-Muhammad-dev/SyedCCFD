import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../services/fcm_service.dart';
import '../services/firebase_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onRegister;
  const LoginPage({required this.onRegister, Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = AuthController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isSubmitting = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final error = await _authController.login(email: email, password: password);
    
    if (mounted) setState(() => _isSubmitting = false);
    
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    
    // Register FCM token after login
    final user = await _authController.getCurrentUser();
    if (user != null) {
      try {
        await FCMService.setupFCM(user.uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notification setup failed: ${e.toString()}'))
          );
        }
        return;
      }

      // Check onboarding status
      if (mounted) {
        final hasCompletedOnboarding = await _firebaseService.hasCompletedOnboarding(user.uid);
        if (hasCompletedOnboarding) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isWeb = screenWidth > 800;

  return Scaffold(
    backgroundColor: Colors.grey[50],
    body: Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32 : 16),
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 420 : double.infinity),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // System Title
                    Text(
                      "Credit Card Fraud Detection",
                      style: TextStyle(
                        fontSize: isWeb ? 28 : 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Card Logos Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 32, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Icon(Icons.payment, size: 32, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Icon(Icons.account_balance_wallet, size: 32, color: Colors.green[700]),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Logo Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        size: 50,
                        color: Colors.blue[700],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: isWeb ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[850],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure login to continue',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter password';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _isSubmitting
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No account yet? ", style: TextStyle(color: Colors.grey[700])),
                        TextButton(
                          onPressed: widget.onRegister,
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
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
