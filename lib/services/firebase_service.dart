import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
// import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseService {
  /// Copy all cards from users/{uid}/cards subcollection to a top-level 'cards' collection.
  Future<void> copyUserCardsToGlobalCollection(String uid) async {
    final cardsSnapshot =
        await _firestore.collection('users').doc(uid).collection('cards').get();
    for (final doc in cardsSnapshot.docs) {
      await _firestore.collection('cards').doc(doc.id).set(doc.data());
    }
  }

  /// Create a flag for a transaction by copying relevant data to 'flags' collection.
  Future<void> createFlagFromTransaction({
    required String transactionId,
    required String userId,
    required String cardId,
    required List<String> reasons,
  }) async {
    final txDoc =
        await _firestore.collection('transactions').doc(transactionId).get();
    final tx = txDoc.data();
    if (tx == null) throw Exception('Transaction not found');
    await _firestore.collection('flags').add({
      'userId': userId,
      'transactionId': transactionId,
      'cardId': cardId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'reasons': reasons,
      'merchant': tx['merchant'],
      'amount': tx['amount'],
    });
  }

  /// Add a transaction to the 'transactions' collection in Firestore.
  Future<void> addTransaction({
    required String merchant,
    required String cardNumber,
    required String cvv,
    required double amount,
    required String currency,
    required DateTime timestamp,
    required bool flagged,
    List<String>? flagReasons,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Create transaction with proper format for webhook compatibility
    final txnId =
        'app_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 8)}';
    final txnData = {
      'txnId': txnId,
      'userId': user.uid,
      'merchant': merchant,
      'cardNumber': cardNumber,
      'cvv': cvv,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cardId': cardNumber, // Use cardNumber as cardId for now
    };

    // Write to transactions collection (this will trigger the Firestore rules via webhook logic)
    await _firestore.collection('transactions').doc(txnId).set(txnData);

    // Run the same fraud detection logic as the webhook server
    await _runFraudDetection(txnData);
  }

  /// Run fraud detection logic (same as webhook server)
  Future<void> _runFraudDetection(Map<String, dynamic> txn) async {
    final amount = txn['amount'] as double;
    final timestamp = txn['timestamp'] as int;
    final userId = txn['userId'] as String;
    final txnId = txn['txnId'] as String;

    List<String> reasons = [];
    bool suspicious = false;

    // Same rules as webhook server
    if (amount > 5000) {
      suspicious = true;
      reasons.add('Large amount');
    }

    final hour = DateTime.fromMillisecondsSinceEpoch(timestamp).hour;
    if (hour < 6 || hour > 22) {
      suspicious = true;
      reasons.add('Odd hour');
    }

    // Check for test merchants
    final merchant = (txn['merchant'] as String? ?? '').toLowerCase();
    if (merchant.contains('test') || merchant.contains('dummy')) {
      suspicious = true;
      reasons.add('Test merchant');
    }

    // Velocity check: last 5 min
    final sinceMillis = DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000;
    final recentTxns = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: sinceMillis)
        .get();

    if (recentTxns.docs.length > 3) {
      suspicious = true;
      reasons.add('High velocity');
    }

    if (suspicious) {
      // Create flag and alert (same as webhook server)
      await _firestore.collection('flags').doc(txnId).set({
        'userId': userId,
        'txnId': txnId,
        'transactionId':
            txnId, // Add this for compatibility with realtime check screen
        'cardId': txn['cardId'],
        'merchant': txn['merchant'],
        'amount': amount,
        'reasons': reasons,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('alerts').doc(txnId).set({
        'userId': userId,
        'txnId': txnId,
        'transactionId': txnId,
        'reasons': reasons,
        'type': 'suspicious_transaction',
        'status': 'unread',
        'merchant': txn['merchant'],
        'amount': amount,
        'cardId': txn['cardId'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send local notification (since we can't send FCM from client)
      print('🚨 FRAUD DETECTED: $reasons for transaction $txnId');

      // Try to show browser notification
      try {
        // await _showLocalNotification(txnId, reasons, txn['merchant'] as String, amount);
      } catch (e) {
        print('Failed to show local notification: $e');
      }
    }
  }

  /// Show local browser notification for fraud detection
  // Future<void> _showLocalNotification(String txnId, List<String> reasons, String merchant, double amount) async {
  //   try {
  //     // Request permission if not already granted
  //     final permission = await html.Notification.requestPermission();
  //     if (permission == 'granted') {
  //       final notification = html.Notification(
  //         'Fraud Alert - Suspicious Transaction',
  //         body: 'Merchant: $merchant, Amount: \$${amount.toStringAsFixed(2)}\nReasons: ${reasons.join(", ")}',
  //         icon: '/favicon.png',
  //       );

  //       // Auto close after 10 seconds
  //       Future.delayed(const Duration(seconds: 10), () {
  //         notification.close();
  //       });

  //       // Handle click to navigate to fraud alerts
  //       notification.onClick.listen((event) {
  //         // Bring window to front and close notification
  //         notification.close();
  //         // Optional: You can add navigation logic here if needed
  //       });
  //     }
  //   } catch (e) {
  //     print('Browser notification error: $e');
  //   }
  // }

  /// Store a credit card in the user's cards subcollection in Firestore.
  Future<void> addCreditCard(Map<String, String> card) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cards')
        .add(card);
  }

  /// Fetch user data from Firestore by uid.
  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  /// Logs in a user with email and password using Firebase Auth.
  Future<UserCredential> loginWithEmail(
      {required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Backend API configuration
  static const String _backendUrl =
      'http://localhost:8080'; // Change this to your deployed backend URL
  static const String _apiKey =
      'b4c1a3d2-9f4e-43b0-8f6d-7f1e'; // Use the same key as in your backend env

  /// Fetch transactions for a specific user from backend API
  Future<List<Map<String, dynamic>>> fetchUserTransactionsFromBackend(
      {required String userId, int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_backendUrl/api/transactions?userId=$userId&limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception('Backend API returned error: ${data['error']}');
        }
      } else {
        throw Exception(
            'Backend API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user transactions from backend: $e');
      // Fallback to Firestore if backend fails
      return await _fetchUserTransactionsFromFirestore(
          userId: userId, limit: limit);
    }
  }

  /// Fetch all transactions from backend API (admin view)
  Future<List<Map<String, dynamic>>> fetchAllTransactionsFromBackend(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/transactions?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception('Backend API returned error: ${data['error']}');
        }
      } else {
        throw Exception(
            'Backend API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching transactions from backend: $e');
      // Fallback to Firestore if backend fails
      return await _fetchAllTransactionsFromFirestore(limit: limit);
    }
  }

  /// Fallback method to fetch user transactions directly from Firestore
  Future<List<Map<String, dynamic>>> _fetchUserTransactionsFromFirestore(
      {required String userId, int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching user transactions from Firestore: $e');
      return [];
    }
  }

  /// Fallback method to fetch all transactions directly from Firestore
  Future<List<Map<String, dynamic>>> _fetchAllTransactionsFromFirestore(
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error fetching transactions from Firestore: $e');
      return [];
    }
  }

  /// Returns true if username exists in 'users' collection.
  Future<bool> usernameExists(String username) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Registers a user in Firebase Auth and creates a Firestore doc with extra fields.
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    // Create user in Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());

    // Optionally update displayName on Auth user
    try {
      await cred.user!.updateDisplayName(username);
    } catch (_) {}

    return user;
  }
}
