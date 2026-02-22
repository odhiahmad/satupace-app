import 'dart:convert';
import '../api/api_service.dart';

class SafetyApi {
  final ApiService api;

  SafetyApi({ApiService? api}) : api = api ?? ApiService();

  /// Report a safety concern.
  /// POST /safety (JWT required)
  /// Body: {match_id, status (reported|blocked), reason}
  Future<Map<String, dynamic>> reportUser({
    required String matchId,
    required String status,
    required String reason,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'match_id': matchId,
      'status': status,
      'reason': reason,
    };
    final res = await api.post('/media/safety', token: token, body: jsonEncode(body));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get a safety report by ID.
  /// GET /safety/:id
  Future<Map<String, dynamic>> getReportById(String id, {String? token}) async {
    final res = await api.get('/safety/$id', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }
}
