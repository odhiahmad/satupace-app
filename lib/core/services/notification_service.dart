import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/notification_api.dart';
import '../router/navigation_service.dart';
import '../router/route_names.dart';

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
    _handleNavigation(message.data, message.notification?.title);
  }

  void _handleNavigation(Map<String, dynamic> data, String? title) {
    final type = data['type']?.toString() ?? '';
    final refId = data['ref_id']?.toString() ?? '';

    final nav = NavigationService();
    switch (type) {
      case 'direct_message':
        if (refId.isNotEmpty) {
          nav.navigateTo(RouteNames.directChat, arguments: {
            'matchId': refId,
            'partnerName': title ?? 'Runner',
          });
        }
        break;

      case 'group_message':
        if (refId.isNotEmpty) {
          nav.navigateTo(RouteNames.groupChat, arguments: {
            'groupId': refId,
            'groupName': title ?? 'Grup',
            'myRole': '',
          });
        }
        break;

      case 'match_accepted':
        if (refId.isNotEmpty) {
          nav.navigateTo(RouteNames.directChat, arguments: {
            'matchId': refId,
            'partnerName': title ?? 'Runner',
          });
        }
        break;

      case 'match_request':
      case 'match_rejected':
        nav.navigateTo(RouteNames.directMatch);
        break;

      case 'group_invite':
      case 'group_join_approved':
      case 'group_join_request':
      case 'group_role_changed':
      case 'group_member_left':
      case 'group_full':
      case 'group_completed':
      case 'group_schedule_start':
        if (refId.isNotEmpty) {
          nav.navigateTo(RouteNames.groupDetail,
              arguments: {'groupId': refId, 'myRole': ''});
        } else {
          nav.navigateTo(RouteNames.groupRun);
        }
        break;

      case 'group_join_rejected':
      case 'group_member_kicked':
      case 'group_cancelled':
        nav.navigateTo(RouteNames.groupRun);
        break;

      case 'activity_logged':
        nav.navigateTo(RouteNames.runActivity);
        break;

      case 'profile_incomplete':
      case 'account_verified':
      case 'password_changed':
      case 'email_change_request':
      case 'user_reported':
      case 'user_blocked':
      case 'auto_suspended':
        nav.navigateTo(RouteNames.profile);
        break;

      default:
        break;
    }
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
