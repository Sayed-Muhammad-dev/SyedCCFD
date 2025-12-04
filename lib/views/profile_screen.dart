import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  String firstName = '';
  String lastName = '';
  String email = '';
  List<Map<String, dynamic>> cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    email = user.email ?? '';
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    firstName = userData['firstName'] ?? '';
    lastName = userData['lastName'] ?? '';
    final cardsSnap = await _firestore.collection('users').doc(user.uid).collection('cards').get();
    cards = cardsSnap.docs.map((doc) => doc.data()).toList();
    setState(() => _loading = false);
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }
    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: _currentPasswordController.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      // Delete cards subcollection
      final cardsSnap = await _firestore.collection('users').doc(user.uid).collection('cards').get();
      for (final doc in cardsSnap.docs) {
        await doc.reference.delete();
      }
      await user.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile deleted')));
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: '$firstName $lastName',
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),
                      const Text('Your Cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ...cards.map((card) {
                        final cardType = card['type'] ?? 'Card';
                        final cardNumber = card['cardNumber'] ?? '';
                        final last4 = cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber;
                        final expiry = card['expiry'] ?? '';
                        return ListTile(
                          title: Text('$cardType ending in $last4'),
                          subtitle: Text('Expiry: $expiry'),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                      const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(labelText: 'Current Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(labelText: 'New Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmNewPasswordController,
                        decoration: const InputDecoration(labelText: 'Confirm New Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _changePassword,
                              child: const Text('Save Profile'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _deleteProfile,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Delete Profile'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
