// firebase_service_web.dart
import 'dart:html' as html;

Future<void> showLocalNotification(
    String txnId, List<String> reasons, String merchant, double amount) async {
  final permission = await html.Notification.requestPermission();
  if (permission == 'granted') {
    final notification = html.Notification(
      'Fraud Alert - Suspicious Transaction',
      body: 'Merchant: $merchant, Amount: \$${amount.toStringAsFixed(2)}\nReasons: ${reasons.join(", ")}',
      icon: '/favicon.png',
    );
    Future.delayed(const Duration(seconds: 10), () => notification.close());
    notification.onClick.listen((event) => notification.close());
  }
}
