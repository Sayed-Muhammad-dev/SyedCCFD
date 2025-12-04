import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FreezeUnfreezeScreen extends StatelessWidget {
  const FreezeUnfreezeScreen({Key? key}) : super(key: key);

  Future<void> _toggleStatus(BuildContext context, String cardId, String currentStatus, String uid) async {
    try {
      final newStatus = currentStatus == 'active' ? 'frozen' : 'active';
      await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('cards').doc(cardId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Card status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your cards.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Freeze/Unfreeze Cards')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('cards')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No cards found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final card = docs[i].data() as Map<String, dynamic>;
              final cardId = docs[i].id;
              final ownerName = card['ownerName'] ?? 'Unknown';
              final brand = card['card_brand'] ?? 'Brand';
              final cardNumber = card['cardNumber'] ?? '****';
              final status = card['status'] ?? 'active';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('$ownerName - $brand'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card Number: $cardNumber'),
                      Text('Cardholder: $ownerName'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'active' ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status, style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _toggleStatus(context, cardId, status, user.uid),
                        child: Text(status == 'active' ? 'Freeze' : 'Unfreeze'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}