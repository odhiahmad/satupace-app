import '../api/api_service.dart';
import 'dart:convert';

/// Strava integration API.
/// All endpoints require JWT authentication.
class StravaApi {
  final ApiService api;

  StravaApi({ApiService? api}) : api = api ?? ApiService();

  /// Get Strava OAuth authorization URL.
  /// GET /strava/auth-url
  Future<String> getAuthUrl({String? token}) async {
    final res = await api.get('/strava/auth-url', token: token);
    if (res is Map) return (res['auth_url'] ?? '').toString();
    return '';
  }

  /// Send OAuth callback code to backend.
  /// POST /strava/callback
  Future<Map<String, dynamic>> callback(String code, {String? token}) async {
    final res = await api.post(
      '/strava/callback',
      token: token,
      body: jsonEncode({'code': code}),
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get current Strava connection status.
  /// GET /strava/connection
  Future<Map<String, dynamic>> getConnection({String? token}) async {
    final res = await api.get('/strava/connection', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Trigger sync of Strava activities.
  /// POST /strava/sync
  Future<Map<String, dynamic>> sync({String? token}) async {
    final res = await api.post('/strava/sync', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get synced Strava activities.
  /// GET /strava/activities?limit=20
  Future<List<Map<String, dynamic>>> getActivities({
    int limit = 20,
    String? token,
  }) async {
    try {
      final res = await api.get(
        '/strava/activities?limit=$limit',
        token: token,
      );
      if (res is List) {
        return res
            .map((item) =>
                item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  /// Get Strava stats (totals, avg pace, etc.).
  /// GET /strava/stats
  Future<Map<String, dynamic>> getStats({String? token}) async {
    final res = await api.get('/strava/stats', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Disconnect Strava account.
  /// DELETE /strava/disconnect
  Future<bool> disconnect({String? token}) async {
    try {
      await api.delete('/strava/disconnect', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }
}
