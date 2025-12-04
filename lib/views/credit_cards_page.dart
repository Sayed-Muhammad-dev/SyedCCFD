import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({Key? key}) : super(key: key);

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final FocusNode _cvvFocusNode = FocusNode();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isBack = false;

  List<Map<String, String>> _cards = [];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    _cvvFocusNode.addListener(_handleCVVFocus);
    _numberController.addListener(() {
      if (mounted) setState(() {});
    });
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _handleCVVFocus() {
    if (_cvvFocusNode.hasFocus) {
      _flipController.forward();
      if (mounted) setState(() => _isBack = true);
    } else {
      _flipController.reverse();
      if (mounted) setState(() => _isBack = false);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  String _getCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'MasterCard';
    if (number.startsWith('3')) {
      if (number.length > 1 && (number[1] == '4' || number[1] == '7')) return 'Amex';
      return 'Diners Club';
    }
    if (number.startsWith('6')) return 'Discover';
    if (number.startsWith('35')) return 'JCB';
    if (number.startsWith('62')) return 'UnionPay';
    return 'Other';
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'Visa': return Colors.blue.shade700;
      case 'MasterCard': return Colors.deepOrange.shade400;
      case 'Amex': return Colors.teal.shade400;
      case 'Discover': return Colors.orange.shade400;
      case 'Diners Club': return Colors.indigo.shade400;
      case 'JCB': return Colors.purple.shade400;
      case 'UnionPay': return Colors.green.shade700;
      default: return Colors.grey.shade400;
    }
  }


  String _maskNumber(String number) {
    number = number.padRight(16, '*');
    return number.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ');
  }

  Future<void> _addCard() async {
    if (_formKey.currentState?.validate() ?? false) {
      final card = {
        'ownerName': _nameController.text.trim(),
        'cardNumber': _numberController.text.trim(),
        'expiry': _expiryController.text.trim(),
        'cvv': _cvvController.text.trim(),
        'card_brand': _getCardType(_numberController.text.trim()),
        'status': 'active',
      };
      
      if (mounted) {
        setState(() {
          _cards.add(card);
          _nameController.clear();
          _numberController.clear();
          _expiryController.clear();
          _cvvController.clear();
        });
      }
      
      try {
        await FirebaseService().addCreditCard(card);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card saved to Firestore!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save card: $e')),
          );
        }
      }
    }
  }

  void _deleteCard(int index) {
    if (mounted) {
      setState(() {
        _cards.removeAt(index);
      });
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month),
      lastDate: DateTime(now.year + 20),
      helpText: 'Select Expiry Date',
      fieldLabelText: 'Expiry Date',
      builder: (context, child) => child ?? const SizedBox(),
    );
    if (picked != null && mounted) {
      setState(() {
        _expiryController.text = '${picked.month.toString().padLeft(2, '0')}/${picked.year % 100}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardType = _getCardType(_numberController.text);
    final cardColor = _getCardColor(cardType);
    final maskedNumber = _maskNumber(_numberController.text);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text(
          'Credit Cards',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32 : 16),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Preview Section
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value * 3.1416;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(angle),
                              child: _isBack
                                  ? _buildCardBack(cardColor, isWeb)
                                  : _buildCardFront(cardColor, maskedNumber, cardType, isWeb),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Form Section
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
                          'Card Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Cardholder Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter cardholder name' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _numberController,
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            counterText: '',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 16,
                          validator: (v) => v == null || v.length < 16 ? 'Enter 16 digits' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                decoration: InputDecoration(
                                  labelText: 'Expiry Date',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                readOnly: true,
                                onTap: _pickExpiry,
                                validator: (v) => v == null || v.isEmpty ? 'Select expiry date' : null,
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
                                  counterText: '',
                                ),
                                obscureText: true,
                                maxLength: 4,
                                focusNode: _cvvFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v == null || v.length < 3 ? 'Enter CVV' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _addCard,
                            icon: const Icon(Icons.add_card),
                            label: const Text(
                              'Add Card',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
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
                
                // Saved Cards Section
                if (_cards.isNotEmpty)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Cards',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._cards.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final card = entry.value;
                          final type = _getCardType(card['cardNumber'] ?? '');
                          final color = _getCardColor(type);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withOpacity(0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.credit_card,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    _maskNumber(card['cardNumber'] ?? ''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        card['ownerName'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Expires: ${card['expiry'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                                    onPressed: () => _showDeleteDialog(idx),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteCard(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(Color color, String maskedNumber, String type, bool isWeb) {
    String cardLabel;
    switch (type) {
      case 'Visa': cardLabel = 'VISA'; break;
      case 'MasterCard': cardLabel = 'MasterCard'; break;
      case 'Amex': cardLabel = 'AMERICAN EXPRESS'; break;
      case 'Discover': cardLabel = 'DISCOVER'; break;
      case 'Diners Club': cardLabel = 'DINERS CLUB'; break;
      case 'JCB': cardLabel = 'JCB'; break;
      case 'UnionPay': cardLabel = 'UNIONPAY'; break;
      default: cardLabel = 'CARD';
    }
    
    final cardWidth = isWeb ? 350.0 : MediaQuery.of(context).size.width * 0.85;
    final cardHeight = cardWidth * 0.6; // Maintain aspect ratio
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: isWeb ? 35 : 30,
                height: isWeb ? 25 : 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white70, width: 1),
                ),
              ),
              Text(
                cardLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWeb ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            maskedNumber,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 20 : 18,
              letterSpacing: 2,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _nameController.text.isEmpty ? 'CARDHOLDER NAME' : _nameController.text.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'EXP ${_expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isWeb ? 12 : 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Color color, bool isWeb) {
    final cardWidth = isWeb ? 350.0 : MediaQuery.of(context).size.width * 0.85;
    final cardHeight = cardWidth * 0.6;
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: isWeb ? 35 : 30,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Text(
            'CVV',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: isWeb ? 60 : 50,
            padding: EdgeInsets.symmetric(
              vertical: isWeb ? 8 : 6,
              horizontal: isWeb ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _cvvController.text.isEmpty ? '***' : _cvvController.text,
              style: TextStyle(
                color: Colors.black,
                fontSize: isWeb ? 14 : 12,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
