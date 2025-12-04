import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static Future<void> setupFCM(String uid) async {
    try {
      final fcm = FirebaseMessaging.instance;
      
      // Request permission
      final permission = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('FCM Permission: ${permission.authorizationStatus}');
      
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw Exception('Notification permission denied');
      }
      
      // Get token
      final token = await fcm.getToken();
      print('FCM Token: $token');
      
      if (token == null || token.isEmpty) {
        throw Exception('Failed to get FCM token');
      }
      
      // Save token to Firestore
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
      print('FCM Token saved for user: $uid');
      
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        if (newToken.isNotEmpty) {
          userRef.update({'fcmTokens': FieldValue.arrayUnion([newToken])});
        }
      });
      
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message: ${message.notification?.title}');
      });
      
    } catch (e) {
      print('FCM Setup Error: $e');
      rethrow;
    }
  }

  static Future<void> removeFCMToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid)
            .update({'fcmTokens': FieldValue.arrayRemove([token])});
        print('FCM Token removed for user: $uid');
      }
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  static void handleNotificationTap(Function(String alertId, String txnId) onTap) {
    try {
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        try {
          final alertId = message.data['alertId'];
          final txnId = message.data['txnId'];
          if (alertId != null && txnId != null) {
            onTap(alertId, txnId);
          }
        } catch (e) {
          print('Error handling notification tap: $e');
        }
      });
      
      // If the app was launched from a terminated state by tapping a notification
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        try {
          if (message == null) return;
          final alertId = message.data['alertId'];
          final txnId = message.data['txnId'];
          if (alertId != null && txnId != null) {
            onTap(alertId, txnId);
          }
        } catch (e) {
          print('Error handling initial message: $e');
        }
      });
    } catch (e) {
      print('Error setting up notification handlers: $e');
    }
  }
}
