import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import 'add_dummy_transaction_button.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController();
  bool _isSubmitting = false;
  bool _useBackendAPI = true; // Toggle between backend API and Firestore
  List<Map<String, dynamic>> _backendTransactions = [];
  bool _loadingBackendData = false;

  @override
  void initState() {
    super.initState();
    _loadBackendTransactions();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendTransactions() async {
    if (!_useBackendAPI) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _loadingBackendData = true);
    try {
      final transactions =
          await FirebaseService().fetchUserTransactionsFromBackend(
        userId: currentUser.uid,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _backendTransactions = transactions;
          _loadingBackendData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingBackendData = false;
          _useBackendAPI = false; // Fallback to Firestore on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend unavailable, using Firestore: $e')),
        );
      }
    }
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isSubmitting = true);

    try {
      await FirebaseService().addTransaction(
        merchant: _merchantController.text.trim(),
        cardNumber: _cardNumberController.text.trim(),
        cvv: _cvvController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        currency: _currencyController.text.trim(),
        timestamp: DateTime.now(),
        flagged: false,
        flagReasons: [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Transaction added!')));
        _merchantController.clear();
        _cardNumberController.clear();
        _cvvController.clear();
        _amountController.clear();
        _currencyController.clear();

        if (_useBackendAPI) {
          _loadBackendTransactions();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_useBackendAPI) {
                _loadBackendTransactions();
              } else {
                setState(() {}); // Refresh Firestore stream
              }
            },
          ),
          IconButton(
            icon: Icon(_useBackendAPI ? Icons.cloud : Icons.storage),
            onPressed: () {
              setState(() {
                _useBackendAPI = !_useBackendAPI;
                if (_useBackendAPI) {
                  _loadBackendTransactions();
                }
              });
            },
            tooltip: _useBackendAPI ? 'Using Backend API' : 'Using Firestore',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 32 : 16),
          child: Center(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: AddDummyTransactionButton()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Transaction Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Transaction',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _merchantController,
                            decoration: InputDecoration(
                              labelText: 'Merchant Name',
                              prefixIcon: const Icon(Icons.store),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter merchant name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          if (isWeb)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cardNumberController,
                                    decoration: InputDecoration(
                                      labelText: 'Card Number',
                                      prefixIcon: const Icon(Icons.credit_card),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter card number';
                                      }
                                      final digitsOnly = RegExp(r'^\d{16}$');
                                      if (!digitsOnly.hasMatch(v.trim())) {
                                        return 'Card number must be exactly 16 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cvvController,
                                    decoration: InputDecoration(
                                      labelText: 'CVV',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter CVV';
                                      }
                                      final digitsOnly = RegExp(r'^\d{3}$');
                                      if (!digitsOnly.hasMatch(v.trim())) {
                                        return 'CVV must be exactly 3 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextFormField(
                                  controller: _cardNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Card Number',
                                    prefixIcon: const Icon(Icons.credit_card),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter card number';
                                    }
                                    final digitsOnly = RegExp(r'^\d{16}$');
                                    if (!digitsOnly.hasMatch(v.trim())) {
                                      return 'Card number must be exactly 16 digits';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _cvvController,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter CVV';
                                    }
                                    final digitsOnly = RegExp(r'^\d{3}$');
                                    if (!digitsOnly.hasMatch(v.trim())) {
                                      return 'CVV must be exactly 3 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _amountController,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter amount';
                                    }
                                    final digitsOnly =
                                        RegExp(r'^\d+(\.\d{1,2})?$');
                                    if (!digitsOnly.hasMatch(v.trim())) {
                                      return 'Invalid amount format';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _currencyController,
                                  decoration: InputDecoration(
                                    labelText: 'Currency',
                                    prefixIcon:
                                        const Icon(Icons.currency_exchange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Enter currency'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _addTransaction,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(
                                _isSubmitting ? 'Adding...' : 'Add Transaction',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transactions List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'My Card Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: _useBackendAPI
                              ? _buildBackendTransactionsList()
                              : _buildFirestoreTransactionsList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackendTransactionsList() {
    if (_loadingBackendData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (_backendTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No transactions found',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('No transactions found for your cards',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _backendTransactions.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final data = _backendTransactions[index];
        return _buildTransactionItem(data);
      },
    );
  }

  Widget _buildFirestoreTransactionsList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Please log in to view transactions',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error loading transactions',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No transactions found',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('No transactions found for your cards',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          itemCount: docs.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey[200]),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTransactionItem(data);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final merchant = data['merchant'] ?? 'Unknown Merchant';
    final amount = data['amount'] ?? 0;
    final currency = data['currency'] ?? 'USD';

    DateTime? timestamp;
    final timestampData = data['timestamp'];
    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate();
    } else if (timestampData is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    }

    final flagged = data['flagged'] == true;
    final flagReasons =
        List<String>.from(data['flag_reasons'] ?? data['reasons'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: flagged ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              flagged ? Icons.warning_amber : Icons.check_circle,
              color: flagged ? Colors.red[700] : Colors.green[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp != null
                      ? DateFormat('MMM d, y • h:mm a').format(timestamp)
                      : 'Unknown date',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (flagged && flagReasons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      flagReasons.join(', '),
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: flagged ? Colors.red[700] : Colors.green[700],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
