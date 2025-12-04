import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? firstName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = await FirebaseService().getUserData(user.uid);
        if (mounted) {
          setState(() {
            firstName = data['firstName'] ?? '';
            _loading = false;
          });
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final crossCount = isWeb ? 4 : 2;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/fraudalerts'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO WELCOME CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[900]!, Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName != null && firstName!.isNotEmpty
                              ? 'Welcome back, $firstName'
                              : 'Welcome',
                          style: TextStyle(
                              fontSize: isWeb ? 32 : 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Monitor fraud, manage cards, and stay secure',
                          style: TextStyle(
                              fontSize: isWeb ? 18 : 14,
                              color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QUICK ACTIONS HEADER
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                        fontSize: isWeb ? 26 : 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[900]),
                  ),
                  const SizedBox(height: 20),

                  // QUICK ACTIONS GRID
                  GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                    children: [
                      _actionCard(
                          icon: Icons.credit_card,
                          title: "Credit Cards",
                          subtitle: "Manage cards",
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, '/addcards')),
                      _actionCard(
                          icon: Icons.receipt_long,
                          title: "Transactions",
                          subtitle: "View history",
                          color: Colors.orange,
                          onTap: () => Navigator.pushNamed(context, '/transactions')),
                      _actionCard(
                          icon: Icons.security_rounded,
                          title: "Realtime Check",
                          subtitle: "Live monitoring",
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(context, '/realtimecheck')),
                      _actionCard(
                          icon: Icons.block,
                          title: "Freeze Card",
                          subtitle: "Lock instantly",
                          color: Colors.indigo,
                          onTap: () => Navigator.pushNamed(context, '/freezeunfreeze')),
                      _actionCard(
                          icon: Icons.warning_amber,
                          title: "Fraud Alerts",
                          subtitle: "Suspicious activity",
                          color: Colors.red,
                          onTap: () => Navigator.pushNamed(context, '/fraudalerts')),
                      _actionCard(
                          icon: Icons.assessment,
                          title: "Reports",
                          subtitle: "Generate data",
                          color: Colors.teal,
                          onTap: () => Navigator.pushNamed(context, '/generate_report')),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // SIGN OUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
