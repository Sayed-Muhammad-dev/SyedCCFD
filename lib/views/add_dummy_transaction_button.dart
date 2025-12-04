import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AddDummyTransactionButton extends StatelessWidget {
  const AddDummyTransactionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Add Dummy Transaction'),
      onPressed: () async {
        await FirebaseService().addTransaction(
          merchant: 'Amazon',
          cardNumber: '1234567890123456',
          cvv: '123',
          amount: 49.99,
          currency: 'USD',
          timestamp: DateTime.now(),
          flagged: true,
          flagReasons: ['Unusual location', 'Large amount'],
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dummy transaction added!')),
        );
      },
    );
  }
}
