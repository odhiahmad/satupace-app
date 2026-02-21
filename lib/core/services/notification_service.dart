import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      await _messaging.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // For now log using debugPrint; can be extended to show local notifications
        debugPrint('FCM message received: ${message.notification?.title} ${message.notification?.body}');
      });
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<String?> getToken() => _messaging.getToken();
}
