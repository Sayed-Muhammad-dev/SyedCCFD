import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseService _service;

  AuthController({FirebaseService? service})
      : _service = service ?? FirebaseService();

  /// Returns the current Firebase user.
  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  /// LOGIN: Returns null on success, or a String error on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _service.loginWithEmail(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// REGISTER + SEND VERIFICATION EMAIL
  ///
  /// Returns:
  /// null → success
  /// String → error message
  Future<String?> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // Check username availability
    final exists = await _service.usernameExists(username);
    if (exists) return 'Username already exists';

    try {
      // Create user account
      await _service.registerWithEmail(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );

      // Send verification email
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }

      return null; // success
    } on FirebaseException catch (e) {
      return 'Registration failed: ${e.message}';
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
