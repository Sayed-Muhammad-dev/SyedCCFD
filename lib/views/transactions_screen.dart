import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/currency_conversion_service.dart';
import '../services/fraud_detection_service.dart';

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

  // Common currency codes for selection
  static const List<String> _currencyOptions = [
    'USD', 'EUR', 'GBP', 'INR', 'JPY', 'CNY', 'AUD', 'CAD', 'CHF', 'SGD',
    'NZD', 'HKD', 'SEK', 'NOK', 'DKK', 'ZAR', 'BRL', 'RUB', 'AED', 'SAR'
  ];
  String _selectedCurrency = 'USD';
  bool _isSubmitting = false;
  // Start with Firestore by default so existing transactions show up
  // even if the backend API is empty / not yet configured.
  bool _useBackendAPI = false; // Toggle between backend API and Firestore
  List<Map<String, dynamic>> _backendTransactions = [];
  bool _loadingBackendData = false;
  // Card numbers that belong to the currently signed‑in user
  final Set<String> _userCardNumbers = {};
  bool _userCardsLoaded = false;

  /// Convert the string ranges saved during onboarding into numeric limits
  /// that the fraud engine can work with.
  double _mapMonthlySpendingRange(String? range) {
    switch (range) {
      case '<20,000':
        return 20000;
      case '20,000–50,000':
        return 50000;
      case '50,000–100,000':
        return 100000;
      case '>100,000':
        return 150000; // Reasonable upper bound for "greater than 100,000"
      default:
        return 0;
    }
  }

  double _mapUsualTransactionAmount(String? range) {
    switch (range) {
      case '<1,000':
        return 1000;
      case '1,000–5,000':
        return 5000;
      case '5,000–15,000':
        return 15000;
      case '>15,000':
        return 20000; // Reasonable upper bound for "greater than 15,000"
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    // Default currency
    _selectedCurrency = _currencyOptions.first;
    _currencyController.text = _selectedCurrency;
    _loadBackendTransactions();
    _loadUserCards();
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
  final String currentUserId = currentUser.uid;
    
    setState(() => _loadingBackendData = true);
    try {
      final transactions = await FirebaseService().fetchUserTransactionsFromBackend(
        userId: currentUserId, 
        limit: 50
      );
      if (mounted) {
        setState(() {
          // Extra safety: make absolutely sure we only keep transactions
          // that belong to the currently signed‑in user.
          _backendTransactions = transactions
              .where((tx) => tx['userId'] == currentUserId)
              .toList();
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
          SnackBar(content: Text('Backend unavailable, using Firestore: $e'))
        );
      }
    }
  }

  /// Load the current user's saved card numbers so we can ensure
  /// we only show transactions for their own cards.
  Future<void> _loadUserCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      final numbers = snapshot.docs
          .map((doc) => (doc.data()['cardNumber'] ?? '') as String)
          .where((n) => n.isNotEmpty)
          .toSet();

      if (!mounted) return;

      setState(() {
        _userCardNumbers
          ..clear()
          ..addAll(numbers);
        _userCardsLoaded = true;
      });
    } catch (e) {
      // If this fails, we simply won't filter by card number.
      print('Error loading user cards: $e');
    }
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isSubmitting = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final currency = _currencyController.text.trim();
      final now = DateTime.now();

      // Load user profile limits and card currency (from onboarding).
      final userData = await FirebaseService().getUserData(user.uid);
      final cardCurrency =
          (userData['selectedCurrency'] as String?) ?? currency;

      // Read limits using the exact field names from Firestore.
      final monthlyLimit =
          _mapMonthlySpendingRange(userData['monthlySpendingRange'] as String?);
      final usualLimit = _mapUsualTransactionAmount(
          userData['usualTransactionAmount'] as String?);
      final maxLimit =
          (userData['maximumNormalTransactionAmount'] as num?)?.toDouble() ??
              0.0;
      final limitsCurrency =
          (userData['limitsCurrency'] as String?) ?? cardCurrency;

      // Compute current month spending in card currency for "sudden spike" rule.
      final monthStart = DateTime(now.year, now.month, 1)
          .millisecondsSinceEpoch;
      final monthTxSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: monthStart)
          .get();

      double monthSoFar = 0.0;
      for (final doc in monthTxSnapshot.docs) {
        final data = doc.data();
        final txAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final txCurrency = (data['currency'] as String?) ?? cardCurrency;
        final converted = CurrencyConversionService.convert(
          amount: txAmount,
          sourceCurrency: txCurrency,
          targetCurrency: cardCurrency,
        );
        monthSoFar += converted;
      }

      final limits = UserLimits(
        monthlySpending: monthlyLimit,
        usualTransactionAmount: usualLimit,
        maximumTransactionAmount: maxLimit,
        selectedCardCurrency: cardCurrency,
        limitsCurrency: limitsCurrency,
      );

      final txn = TransactionData(
        transactionAmount: amount,
        transactionCurrency: currency,
        // For now, we treat all manual entries as "general" category.
        transactionCategory: 'general',
        timestamp: now,
        currentMonthSpendingInCardCurrency: monthSoFar,
      );

      final fraudResult = FraudDetectionService.evaluateTransaction(
        transaction: txn,
        userLimits: limits,
      );

      final isFlagged = fraudResult.finalVerdict != 'SAFE';

      await FirebaseService().addTransaction(
        merchant: _merchantController.text.trim(),
        cardNumber: _cardNumberController.text.trim(),
        cvv: _cvvController.text.trim(),
        amount: amount,
        currency: currency,
        timestamp: now,
        flagged: isFlagged,
        flagReasons: fraudResult.flagsTriggered,
        convertedAmountInCardCurrency: fraudResult.convertedAmountInCardCurrency,
        cardCurrency: fraudResult.cardCurrency,
        limitValuesUsed: fraudResult.limitValuesUsed,
        fraudVerdict: fraudResult.finalVerdict,
        originalAmount: fraudResult.originalTransactionAmount,
        originalCurrency: fraudResult.originalTransactionCurrency,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction added!')));
        _merchantController.clear();
        _cardNumberController.clear();
        _cvvController.clear();
        _amountController.clear();
        _currencyController.clear();
        
        // Refresh backend data if using backend API
        if (_useBackendAPI) {
          _loadBackendTransactions();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
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
              constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter merchant name' : null,
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
                                      if (v == null || v.trim().isEmpty) return 'Enter card number';
                                      final digitsOnly = RegExp(r'^\d{13,19}$');
                                      if (!digitsOnly.hasMatch(v.trim())) return 'Card number must be 13-19 digits';
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
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Enter CVV';
                                      final digitsOnly = RegExp(r'^\d{3,4}$');
                                      if (!digitsOnly.hasMatch(v.trim())) return 'CVV must be 3 or 4 digits';
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
                                    if (v == null || v.trim().isEmpty) return 'Enter card number';
                                    final digitsOnly = RegExp(r'^\d{13,19}$');
                                    if (!digitsOnly.hasMatch(v.trim())) return 'Card number must be 13-19 digits';
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
                                    if (v == null || v.trim().isEmpty) return 'Enter CVV';
                                    final digitsOnly = RegExp(r'^\d{3,4}$');
                                    if (!digitsOnly.hasMatch(v.trim())) return 'CVV must be 3 or 4 digits';
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
                                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                                    final digitsOnly = RegExp(r'^\d+(\.\d{1,2})?$');
                                    if (!digitsOnly.hasMatch(v.trim())) return 'Invalid amount format';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCurrency,
                                  decoration: InputDecoration(
                                    labelText: 'Currency',
                                    prefixIcon: const Icon(Icons.currency_exchange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: _currencyOptions
                                      .map((code) => DropdownMenuItem<String>(
                                            value: code,
                                            child: Text(code),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedCurrency = value;
                                      _currencyController.text = value;
                                    });
                                  },
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Select currency' : null,
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
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(
                                _isSubmitting ? 'Adding...' : 'Add Transaction',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                          child: _useBackendAPI ? _buildBackendTransactionsList() : _buildFirestoreTransactionsList(),
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
              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No transactions found', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('No transactions found for your cards', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _backendTransactions.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
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
      // Simple query without orderBy to avoid Firestore index requirement
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: currentUser.uid)
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
                  Text('Error loading transactions: ${snapshot.error}', 
                       style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No transactions found', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('No transactions found for your cards', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          );
        }

        // Sort documents by timestamp (newest first) on the client side
        var docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final ad = a.data() as Map<String, dynamic>;
            final bd = b.data() as Map<String, dynamic>;
            final at = ad['timestamp'];
            final bt = bd['timestamp'];

            int atMillis;
            int btMillis;

            if (at is Timestamp) {
              atMillis = at.millisecondsSinceEpoch;
            } else if (at is int) {
              atMillis = at;
            } else {
              atMillis = 0;
            }

            if (bt is Timestamp) {
              btMillis = bt.millisecondsSinceEpoch;
            } else if (bt is int) {
              btMillis = bt;
            } else {
              btMillis = 0;
            }

            // Newest first (descending)
            return btMillis.compareTo(atMillis);
          });

        // If we know the user's card numbers, further restrict
        // to transactions whose cardNumber/cardId matches one of them.
        if (_userCardsLoaded && _userCardNumbers.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cardNumber = (data['cardNumber'] ?? data['cardId'] ?? '') as String;
            return _userCardNumbers.contains(cardNumber);
          }).toList();
        }

        // Limit to latest 50 transactions
        final limitedDocs = docs.take(50).toList();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: limitedDocs.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
          itemBuilder: (context, index) {
            final data = limitedDocs[index].data() as Map<String, dynamic>;
            return _buildTransactionItem(data);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final merchant = data['merchant'] ?? 'Unknown Merchant';
    final amount = (data['originalAmount'] ?? data['amount'] ?? 0) as num;
    final currency = data['originalCurrency'] ?? data['currency'] ?? 'USD';
    final convertedAmount =
        (data['convertedAmountInCardCurrency'] as num?)?.toDouble();
    final cardCurrency = data['cardCurrency'] as String?;
    final fraudVerdict = data['fraudVerdict'] as String?;
    
    DateTime? timestamp;
    final timestampData = data['timestamp'];
    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate();
    } else if (timestampData is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    }
    
    final flagged = data['flagged'] == true;
    final flagReasons = List<String>.from(data['flag_reasons'] ?? data['reasons'] ?? []);

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
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${amount.toString()} $currency',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (convertedAmount != null &&
                                                  cardCurrency != null &&
                                                  cardCurrency != currency)
                                                Text(
                                                  '≈ ${convertedAmount.toStringAsFixed(2)} $cardCurrency',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              if (timestamp != null)
                                                Text(
                                                  DateFormat.yMMMd().add_jm().format(timestamp),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              if (flagged && flagReasons.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: flagReasons.map((reason) => Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[100],
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        reason,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.red[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    )).toList(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: flagged ? Colors.red[50] : Colors.green[50],
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: flagged ? Colors.red[200]! : Colors.green[200]!,
                                            ),
                                          ),
                                          child: Text(
                                            fraudVerdict ?? (flagged ? 'Flagged' : 'Safe'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: flagged ? Colors.red[700] : Colors.green[700],
        ),
                                          ),
                                        ),
                                      ],
      ),
    );
  }
}
