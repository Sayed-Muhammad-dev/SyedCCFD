import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/register_page.dart';
import 'views/login_page.dart';
import 'views/dashboard_page.dart';
import 'views/credit_cards_page.dart';
import 'firebase_options.dart';
import 'views/transactions_screen.dart';
import 'views/credit_cards_screen.dart';
import 'views/realtime_check_screen.dart';
import 'views/fraud_alert_screen.dart';
import 'views/profile_screen.dart';
import 'views/generate_report_page.dart';
import 'views/onboarding_page.dart';
import 'services/fcm_service.dart';
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Handle notification taps globally (after Firebase init)
  FCMService.handleNotificationTap((alertId, txnId) {
    navigatorKey.currentState?.pushNamed('/fraudalerts', arguments: {'alertId': alertId, 'txnId': txnId});
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Credit Card Fraud Detection',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(
              onRegister: () => Navigator.pushReplacementNamed(context, '/register'),
            ),
        '/register': (context) => RegisterPage(
              onBackToLogin: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
        '/dashboard': (context) => const DashboardPage(),
        '/addcards': (context) => const CreditCardsPage(),
        '/freezeunfreeze': (context) => const FreezeUnfreezeScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/realtimecheck': (context) => const RealtimeCheckScreen(),
        '/fraudalerts': (context) => const FraudAlertScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/generate_report': (context) => const GenerateReportPage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
    );
  }
}
