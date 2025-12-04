import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final Map<String, dynamic>? initialData;

  const OnboardingScreen1({
    Key? key,
    required this.onNext,
    this.initialData,
  }) : super(key: key);

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  String? _monthlySpending;
  String? _usualTransactionAmount;
  String? _weeklyTransactionFrequency;
  String? _selectedCurrency;

  final List<String> _monthlySpendingOptions = [
    '<20,000',
    '20,000–50,000',
    '50,000–100,000',
    '>100,000',
  ];

  final List<String> _transactionAmountOptions = [
    '<1,000',
    '1,000–5,000',
    '5,000–15,000',
    '>15,000',
  ];

  final List<String> _frequencyOptions = [
    '1–2',
    '3–6',
    'Daily',
    'Multiple times daily',
  ];

  final List<String> _currencyOptions = [
    'PKR',
    'USD',
    'EUR',
    'GBP',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _monthlySpending = widget.initialData!['monthlySpendingRange'];
      _usualTransactionAmount = widget.initialData!['usualTransactionAmount'];
      _weeklyTransactionFrequency = widget.initialData!['weeklyTransactionFrequency'];
      _selectedCurrency = widget.initialData!['selectedCurrency'];
    }
  }

  void _handleNext() {
    if (_monthlySpending == null || 
        _usualTransactionAmount == null || 
        _weeklyTransactionFrequency == null ||
        _selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    widget.onNext({
      'monthlySpendingRange': _monthlySpending,
      'usualTransactionAmount': _usualTransactionAmount,
      'weeklyTransactionFrequency': _weeklyTransactionFrequency,
      'selectedCurrency': _selectedCurrency,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Step 1 of 3'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Title
            Text(
              'Basic Spending Profile',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Tell us about your typical monthly and weekly spending behavior.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 40),

            // Card Currency
            Text(
              'Card Currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                hintText: 'Select your card currency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _currencyOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value;
                });
              },
            ),
            const SizedBox(height: 28),

            // Monthly Spending Range
            Text(
              'Monthly Spending Range${_selectedCurrency != null ? ' ($_selectedCurrency)' : ''}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _monthlySpending,
              decoration: InputDecoration(
                hintText: 'Select monthly spending range',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _monthlySpendingOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _monthlySpending = value;
                });
              },
            ),
            const SizedBox(height: 28),

            // Usual Transaction Amount
            Text(
              'Usual Transaction Amount${_selectedCurrency != null ? ' ($_selectedCurrency)' : ''}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _usualTransactionAmount,
              decoration: InputDecoration(
                hintText: 'Select usual transaction amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _transactionAmountOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _usualTransactionAmount = value;
                });
              },
            ),
            const SizedBox(height: 28),

            // Weekly Transaction Frequency
            Text(
              'Weekly Transaction Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _weeklyTransactionFrequency,
              decoration: InputDecoration(
                hintText: 'Select weekly transaction frequency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _frequencyOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _weeklyTransactionFrequency = value;
                });
              },
            ),
            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

