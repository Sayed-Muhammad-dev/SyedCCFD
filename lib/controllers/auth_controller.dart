
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  /// Returns the current Firebase user.
  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
  /// Returns `null` on success, or a String error message on failure.
  Future<String?> login({required String email, required String password}) async {
    try {
      await _service.loginWithEmail(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  final FirebaseService _service;

  AuthController({FirebaseService? service}) : _service = service ?? FirebaseService();

  /// Returns `null` on success, or a String error message on failure.
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
      await _service.registerWithEmail(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );
      return null; // success
    } on FirebaseException catch (e) {
      // Firestore or Auth error
      return 'Registration failed: ${e.message}';
    } catch (e) {
      return 'Registration failed: $e';
    }
  }
}
