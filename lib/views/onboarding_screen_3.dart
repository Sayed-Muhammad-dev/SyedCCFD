import 'package:flutter/material.dart';

class OnboardingScreen3 extends StatefulWidget {
  final Function(Map<String, dynamic>) onFinish;
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const OnboardingScreen3({
    Key? key,
    required this.onFinish,
    required this.onBack,
    this.initialData,
  }) : super(key: key);

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  double _maxNormalTransactionAmount = 10000.0;
  final Set<String> _alertTriggers = {};
  bool? _extraVerificationForLargeTransactions;
  String? _selectedCurrency;

  final List<String> _alertTriggerOptions = [
    'High-value transactions',
    'Unusual categories',
    'Transactions from another city',
    'Every transaction',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _maxNormalTransactionAmount = 
          (widget.initialData!['maximumNormalTransactionAmount'] ?? 10000.0).toDouble();
      _alertTriggers.addAll(
        List<String>.from(widget.initialData!['alertTriggers'] ?? []),
      );
      _extraVerificationForLargeTransactions = 
          widget.initialData!['extraVerificationForLargeTransactions'];
      _selectedCurrency = widget.initialData!['selectedCurrency'];
    }
  }

  String _getCurrencyPrefix() {
    switch (_selectedCurrency) {
      case 'PKR':
        return '₨';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return _selectedCurrency ?? '';
    }
  }

  void _handleFinish() {
    if (_alertTriggers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one alert trigger')),
      );
      return;
    }

    if (_extraVerificationForLargeTransactions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer the extra verification question')),
      );
      return;
    }

    widget.onFinish({
      'maximumNormalTransactionAmount': _maxNormalTransactionAmount,
      'alertTriggers': _alertTriggers.toList(),
      'extraVerificationForLargeTransactions': _extraVerificationForLargeTransactions,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('Step 3 of 3'),
        elevation: 0,
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Title
            Text(
              'Security & Alerts',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Set your preferred security thresholds and notification settings.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 40),

            // Maximum Normal Transaction Amount
            Text(
              'Maximum Normal Transaction Amount${_selectedCurrency != null ? ' ($_selectedCurrency)' : ''}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(_maxNormalTransactionAmount),
                    initialValue: _maxNormalTransactionAmount.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: _getCurrencyPrefix(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed >= 1000 && parsed <= 100000) {
                        setState(() {
                          _maxNormalTransactionAmount = parsed;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_getCurrencyPrefix()}${_maxNormalTransactionAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _maxNormalTransactionAmount,
              min: 1000.0,
              max: 100000.0,
              divisions: 99,
              label: '${_getCurrencyPrefix()}${_maxNormalTransactionAmount.toStringAsFixed(0)}',
              activeColor: Colors.red[700],
              inactiveColor: Colors.red[200],
              onChanged: (value) {
                setState(() {
                  _maxNormalTransactionAmount = value;
                });
              },
            ),
            const SizedBox(height: 40),

            // Alert Triggers
            Text(
              'Alert Triggers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ..._alertTriggerOptions.map((trigger) {
              final isSelected = _alertTriggers.contains(trigger);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CheckboxListTile(
                  title: Text(trigger),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _alertTriggers.add(trigger);
                      } else {
                        _alertTriggers.remove(trigger);
                      }
                    });
                  },
                  activeColor: Colors.red[700],
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),

            // Extra Verification for Large Transactions
            Text(
              'Extra Verification for Large Transactions',
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
                    selected: _extraVerificationForLargeTransactions == true,
                    onSelected: (selected) {
                      setState(() {
                        _extraVerificationForLargeTransactions = selected ? true : null;
                      });
                    },
                    selectedColor: Colors.red[200],
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _extraVerificationForLargeTransactions == true
                          ? Colors.red[700]!
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('No'),
                    selected: _extraVerificationForLargeTransactions == false,
                    onSelected: (selected) {
                      setState(() {
                        _extraVerificationForLargeTransactions = selected ? false : null;
                      });
                    },
                    selectedColor: Colors.red[200],
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _extraVerificationForLargeTransactions == false
                          ? Colors.red[700]!
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
                      side: BorderSide(color: Colors.red[700]!),
                      foregroundColor: Colors.red[700],
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
                    onPressed: _handleFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
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
                          'Save & Finish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle),
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

