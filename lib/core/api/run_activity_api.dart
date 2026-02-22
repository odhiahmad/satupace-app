import 'dart:convert';
import '../api/api_service.dart';

class RunActivityApi {
  final ApiService api;

  RunActivityApi({ApiService? api}) : api = api ?? ApiService();

  /// Create a new run activity.
  /// POST /runs/activities (JWT required)
  /// Body: {distance, duration, calories, route_data, started_at, ended_at}
  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> data, {String? token}) async {
    final allowedKeys = <String>{
      'distance',
      'duration',
      'avg_pace',
      'calories',
      'source',
    };
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      if (allowedKeys.contains(entry.key)) {
        sanitized[entry.key] = entry.value;
      }
    }
    final res = await api.post('/runs/activities', token: token, body: jsonEncode(sanitized));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get a run activity by ID.
  /// GET /runs/activities/:id
  Future<Map<String, dynamic>> getActivityById(String id, {String? token}) async {
    final res = await api.get('/runs/activities/$id', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get run activities for a specific user.
  /// GET /runs/users/:userId/activities
  Future<List<Map<String, dynamic>>> getUserActivities(String userId, {String? token}) async {
    try {
      final res = await api.get('/runs/users/$userId/activities', token: token);
      if (res is List) {
        return res
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }
}
