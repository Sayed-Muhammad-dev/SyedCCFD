import 'package:flutter/material.dart';

class OnboardingScreen2 extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const OnboardingScreen2({
    Key? key,
    required this.onNext,
    required this.onBack,
    this.initialData,
  }) : super(key: key);

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  final List<String> _categories = [
    'Groceries',
    'Shopping',
    'Travel',
    'Food Delivery',
    'Online Purchases',
    'Bills & Utilities',
    'Medical',
    'Entertainment',
  ];

  Set<String> _selectedCategories = {};
  bool? _onlineTransactionsFrequency;
  bool? _internationalTransactions;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedCategories = Set<String>.from(
        widget.initialData!['frequentSpendingCategories'] ?? [],
      );
      _onlineTransactionsFrequency = widget.initialData!['onlineTransactionsFrequency'];
      _internationalTransactions = widget.initialData!['internationalTransactions'];
    }
  }

  void _handleNext() {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one spending category')),
      );
      return;
    }

    if (_onlineTransactionsFrequency == null || _internationalTransactions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    widget.onNext({
      'frequentSpendingCategories': _selectedCategories.toList(),
      'onlineTransactionsFrequency': _onlineTransactionsFrequency,
      'internationalTransactions': _internationalTransactions,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Step 2 of 3'),
        elevation: 0,
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Title
            Text(
              'Spending Categories',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Select the types of purchases you usually make.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 40),

            // Frequent Spending Categories
            Text(
              'Frequent Spending Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                  selectedColor: Colors.green[200],
                  checkmarkColor: Colors.green[900],
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Online Transactions Frequency
            Text(
              'Online Transactions Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Yes'),
                    selected: _onlineTransactionsFrequency == true,
                    onSelected: (selected) {
                      setState(() {
                        _onlineTransactionsFrequency = selected ? true : null;
                      });
                    },
                    selectedColor: Colors.green[200],
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _onlineTransactionsFrequency == true
                          ? Colors.green[700]!
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('No'),
                    selected: _onlineTransactionsFrequency == false,
                    onSelected: (selected) {
                      setState(() {
                        _onlineTransactionsFrequency = selected ? false : null;
                      });
                    },
                    selectedColor: Colors.green[200],
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _onlineTransactionsFrequency == false
                          ? Colors.green[700]!
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // International Transactions
            Text(
              'International Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Yes'),
                    selected: _internationalTransactions == true,
                    onSelected: (selected) {
                      setState(() {
                        _internationalTransactions = selected ? true : null;
                      });
                    },
                    selectedColor: Colors.green[200],
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _internationalTransactions == true
                          ? Colors.green[700]!
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('No'),
                    selected: _internationalTransactions == false,
                    onSelected: (selected) {
                      setState(() {
                        _internationalTransactions = selected ? false : null;
                      });
                    },
                    selectedColor: Colors.green[200],
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _internationalTransactions == false
                          ? Colors.green[700]!
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green[700]!),
                      foregroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

