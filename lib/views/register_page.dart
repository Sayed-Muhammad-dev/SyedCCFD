import 'package:ccd/controllers/RegisterController.dart';
import 'package:ccd/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  final RegisterController registerCtrl = Get.put(RegisterController());

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: registerCtrl.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              TextFormField(
                controller: registerCtrl.usernameController,
                decoration: const InputDecoration(labelText: "Username *"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter username'
                    : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: registerCtrl.emailController,
                decoration: const InputDecoration(labelText: "Email *"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter email";
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Enter valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // First name
              TextFormField(
                controller: registerCtrl.fnameController,
                decoration: const InputDecoration(labelText: "First Name *"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter first name'
                    : null,
              ),
              const SizedBox(height: 12),

              // Last name
              TextFormField(
                controller: registerCtrl.lnameController,
                decoration: const InputDecoration(labelText: "Last Name *"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter last name'
                    : null,
              ),
              const SizedBox(height: 12),

              // Password
              TextFormField(
                controller: registerCtrl.passwordController,
                decoration: const InputDecoration(labelText: "Password *"),
                obscureText: true,
                onChanged: registerCtrl.checkPasswordStrength,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter password";
                  if (registerCtrl.passwordStrength.value < 1.0) {
                    return "Password too weak";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Password Checklist
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChecklistItem("At least 8 characters",
                          registerCtrl.passwordChecklist['len']!),
                      _buildChecklistItem("At least 1 uppercase letter",
                          registerCtrl.passwordChecklist['upper']!),
                      _buildChecklistItem("At least 1 lowercase letter",
                          registerCtrl.passwordChecklist['lower']!),
                      _buildChecklistItem("At least 1 number",
                          registerCtrl.passwordChecklist['num']!),
                      _buildChecklistItem("At least 2 special characters",
                          registerCtrl.passwordChecklist['special']!),
                    ],
                  )),
              const SizedBox(height: 6),

              // Password Strength Bar
              Obx(() => LinearProgressIndicator(
                    value: registerCtrl.passwordStrength.value,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      registerCtrl.passwordStrength.value < 0.4
                          ? Colors.red
                          : registerCtrl.passwordStrength.value < 1.0
                              ? Colors.orange
                              : Colors.green,
                    ),
                    backgroundColor: Colors.grey.shade300,
                    minHeight: 6,
                  )),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: registerCtrl.confirmController,
                decoration:
                    const InputDecoration(labelText: "Confirm Password *"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Confirm password";
                  if (value != registerCtrl.passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Register Button
              Obx(() => registerCtrl.isSubmitting.value
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => registerCtrl.register(() {
                        Get.to(() => EmailVerificationScreen(
                            emailAddress: registerCtrl.emailController.text));
                      }),
                      child: const Text("Register"),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red, size: 18),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
