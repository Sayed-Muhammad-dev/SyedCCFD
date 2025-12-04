import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_service_stub.dart'
    if (dart.library.html) 'firebase_service_web.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _backendUrl = 'http://localhost:8080';
  static const String _apiKey = 'b4c1a3d2-9f4e-43b0-8f6d-7f1e';

  // Copy user cards to global collection
  Future<void> copyUserCardsToGlobalCollection(String uid) async {
    final cardsSnapshot = await _firestore.collection('users').doc(uid).collection('cards').get();
    for (final doc in cardsSnapshot.docs) {
      await _firestore.collection('cards').doc(doc.id).set(doc.data());
    }
  }

  // Create a flag for a transaction
  Future<void> createFlagFromTransaction({
    required String transactionId,
    required String userId,
    required String cardId,
    required List<String> reasons,
  }) async {
    final txDoc = await _firestore.collection('transactions').doc(transactionId).get();
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

  // Add a transaction
  Future<void> addTransaction({
    required String merchant,
    required String cardNumber,
    required String cvv,
    required double amount,
    required String currency,
    required DateTime timestamp,
    required bool flagged,
    List<String>? flagReasons,
    double? convertedAmountInCardCurrency,
    String? cardCurrency,
    Map<String, double>? limitValuesUsed,
    String? fraudVerdict,
    double? originalAmount,
    String? originalCurrency,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final txnId = 'app_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 8)}';
    final txnData = <String, dynamic>{
      'txnId': txnId,
      'userId': user.uid,
      'merchant': merchant,
      'cardNumber': cardNumber,
      'cvv': cvv,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cardId': cardNumber,
      'flagged': flagged,
      'flag_reasons': flagReasons ?? <String>[],
      'originalAmount': originalAmount ?? amount,
      'originalCurrency': originalCurrency ?? currency,
      'convertedAmountInCardCurrency': convertedAmountInCardCurrency,
      'cardCurrency': cardCurrency,
      'limitValuesUsed': limitValuesUsed,
      'fraudVerdict': fraudVerdict,
    };

    await _firestore.collection('transactions').doc(txnId).set(txnData);
    await _runFraudDetection(txnData);
  }

  // Internal fraud detection
  Future<void> _runFraudDetection(Map<String, dynamic> txn) async {
    final amount = txn['amount'] as double;
    final timestamp = txn['timestamp'] as int;
    final userId = txn['userId'] as String;
    final txnId = txn['txnId'] as String;

    List<String> reasons = [];
    bool suspicious = false;

    if (amount > 5000) {
      suspicious = true;
      reasons.add('Large amount');
    }

    final hour = DateTime.fromMillisecondsSinceEpoch(timestamp).hour;
    if (hour < 6 || hour > 22) {
      suspicious = true;
      reasons.add('Odd hour');
    }

    final merchant = (txn['merchant'] as String? ?? '').toLowerCase();
    if (merchant.contains('test') || merchant.contains('dummy')) {
      suspicious = true;
      reasons.add('Test merchant');
    }

    final sinceMillis = DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000;
    final recentTxns = await _firestore.collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: sinceMillis)
        .get();

    if (recentTxns.docs.length > 3) {
      suspicious = true;
      reasons.add('High velocity');
    }

    if (suspicious) {
      await _firestore.collection('flags').doc(txnId).set({
        'userId': userId,
        'txnId': txnId,
        'transactionId': txnId,
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

      print('🚨 FRAUD DETECTED: $reasons for transaction $txnId');

      await showLocalNotification(txnId, reasons, txn['merchant'] as String, amount);
    }
  }

  // Add a credit card
  Future<void> addCreditCard(Map<String, String> card) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(user.uid).collection('cards').add(card);
  }

  // Get user data
  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  // Onboarding checks
  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['onboardingCompleted'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveOnboardingData(Map<String, dynamic> onboardingData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(user.uid).update({
      ...onboardingData,
      'onboardingCompleted': true,
      'onboardingCompletedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get selected currency
  Future<String?> getUserCurrency(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['selectedCurrency'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Auth
  Future<UserCredential> loginWithEmail({required String email, required String password}) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<bool> usernameExists(String username) async {
    final snapshot = await _firestore.collection('users').where('username', isEqualTo: username).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
    try { await cred.user!.updateDisplayName(username); } catch (_) {}

    return user;
  }

  // --- Backend transaction fetching ---
  Future<List<Map<String, dynamic>>> fetchUserTransactionsFromBackend({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_backendUrl/api/transactions?userId=$userId&limit=$limit&offset=$offset'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception('Backend API error: ${data['error']}');
        }
      } else {
        throw Exception('Backend API failed: ${res.statusCode}');
      }
    } catch (_) {
      return _fetchUserTransactionsFromFirestore(userId: userId, limit: limit);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllTransactionsFromBackend({int limit = 50, int offset = 0}) async {
    try {
      final res = await http.get(
        Uri.parse('$_backendUrl/api/transactions?limit=$limit&offset=$offset'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception('Backend API error: ${data['error']}');
        }
      } else {
        throw Exception('Backend API failed: ${res.statusCode}');
      }
    } catch (_) {
      return _fetchAllTransactionsFromFirestore(limit: limit);
    }
  }

  // --- Firestore fallback ---
  Future<List<Map<String, dynamic>>> _fetchUserTransactionsFromFirestore({required String userId, int limit = 50}) async {
    final snapshot = await _firestore.collection('transactions')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAllTransactionsFromFirestore({int limit = 50}) async {
    final snapshot = await _firestore.collection('transactions')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
