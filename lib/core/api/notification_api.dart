import 'dart:convert';
import '../api/api_service.dart';

class NotificationApi {
  final ApiService api;

  NotificationApi({required this.api});

  /// GET /notifications?page=&limit=
  Future<List<Map<String, dynamic>>> getNotifications({
    String? token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await api.get(
        '/notifications?page=$page&limit=$limit',
        token: token,
      );
      if (res is List) {
        return res
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList();
      }
      if (res is Map && res['notifications'] is List) {
        return (res['notifications'] as List)
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// PATCH /notifications/read   body: {ids: [...]}
  Future<bool> markAsRead(List<String> ids, {String? token}) async {
    try {
      await api.patch(
        '/notifications/read',
        token: token,
        body: jsonEncode({'ids': ids}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// PATCH /notifications/read-all
  Future<bool> markAllAsRead({String? token}) async {
    try {
      await api.patch('/notifications/read-all', token: token, body: '{}');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// POST /notifications/device-token   body: {fcm_token, platform}
  Future<bool> registerDeviceToken(
    String fcmToken,
    String platform, {
    String? token,
  }) async {
    try {
      await api.post(
        '/notifications/device-token',
        token: token,
        body: jsonEncode({'fcm_token': fcmToken, 'platform': platform}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /notifications/device-token   body: {fcm_token}
  Future<bool> removeDeviceToken(String fcmToken, {String? token}) async {
    try {
      await api.delete(
        '/notifications/device-token',
        token: token,
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
