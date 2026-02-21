import 'dart:convert';
import '../api/api_service.dart';

class SafetyApi {
  final ApiService api;

  SafetyApi({ApiService? api}) : api = api ?? ApiService();

  /// Report a safety concern about a user.
  /// POST /media/safety (JWT required)
  /// Body: {reported_user_id, reason, description}
  Future<Map<String, dynamic>> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'reported_user_id': reportedUserId,
      'reason': reason,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final res = await api.post('/media/safety', token: token, body: jsonEncode(body));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get a safety report by ID.
  /// GET /media/safety/:id
  Future<Map<String, dynamic>> getReportById(String id, {String? token}) async {
    final res = await api.get('/media/safety/$id', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }
}
