import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/notification_api.dart';

/// Background FCM handler — must be top-level.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'satupace_default';
  static const _channelName = 'SatuPace';
  static const _channelDesc = 'Notifikasi SatuPace';

  Future<void> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _initLocalNotifications();

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _show(title: n.title ?? 'SatuPace', body: n.body ?? '');
  }

  void _onTap(RemoteMessage message) {
    debugPrint('[FCM] Tapped: ${message.data}');
  }

  Future<void> _show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show local notification from in-app chat events.
  Future<void> showChatNotification({
    required String title,
    required String body,
  }) =>
      _show(title: title, body: body);

  Future<String?> getToken() => _messaging.getToken();

  /// Register FCM token with backend (call after login).
  Future<void> registerDeviceToken(
    NotificationApi notifApi,
    String authToken,
  ) async {
    try {
      final fcmToken = await getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';
      await notifApi.registerDeviceToken(fcmToken, platform, token: authToken);
      debugPrint('[FCM] Token registered ($platform)');
    } catch (e) {
      debugPrint('[FCM] registerDeviceToken error: $e');
    }
  }

  /// Remove FCM token from backend (call on logout).
  Future<void> removeDeviceToken(
    NotificationApi notifApi,
    String authToken,
  ) async {
    try {
      final fcmToken = await getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      await notifApi.removeDeviceToken(fcmToken, token: authToken);
      debugPrint('[FCM] Token removed');
    } catch (e) {
      debugPrint('[FCM] removeDeviceToken error: $e');
    }
  }
}
