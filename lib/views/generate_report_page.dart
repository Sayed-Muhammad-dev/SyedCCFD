import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GenerateReportPage extends StatefulWidget {
  const GenerateReportPage({Key? key}) : super(key: key);

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  int totalTransactions = 0;
  int fraudulentTransactions = 0;
  int frozenCards = 0;
  int activeCards = 0;
  List<String> frozenCardLast4 = [];
  List<String> activeCardLast4 = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    // Transactions
    final txSnap = await _firestore.collection('transactions').where('userId', isEqualTo: user.uid).get();
    totalTransactions = txSnap.docs.length;
    // Fraudulent Transactions
    final fraudSnap = await _firestore.collection('fraud_reports').where('userId', isEqualTo: user.uid).get();
    fraudulentTransactions = fraudSnap.docs.length;
    // Cards
    final cardsSnap = await _firestore.collection('users').doc(user.uid).collection('cards').get();
    frozenCards = 0;
    activeCards = 0;
    frozenCardLast4.clear();
    activeCardLast4.clear();
    for (final doc in cardsSnap.docs) {
      final card = doc.data();
      final cardNumber = card['cardNumber'] ?? '';
      final last4 = cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber;
      final status = card['status'] ?? 'active';
      if (status == 'frozen') {
        frozenCards++;
        frozenCardLast4.add(last4);
      } else {
        activeCards++;
        activeCardLast4.add(last4);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('User Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Total Transactions: $totalTransactions'),
            pw.Text('Fraudulent Transactions: $fraudulentTransactions'),
            pw.Text('Frozen Cards (${frozenCards}): ${frozenCardLast4.join(", ")}'),
            pw.Text('Active Cards (${activeCards}): ${activeCardLast4.join(", ")}'),
          ],
        ),
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/user_report.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF downloaded to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
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
                      Text('Total Transactions: $totalTransactions', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Fraudulent Transactions: $fraudulentTransactions', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Frozen Cards ($frozenCards): ${frozenCardLast4.join(", ")}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Active Cards ($activeCards): ${activeCardLast4.join(", ")}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                        onPressed: _downloadPdf,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
