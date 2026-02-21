import 'dart:convert';
import '../api/api_service.dart';

class DirectMatchApi {
  final ApiService api;

  DirectMatchApi({ApiService? api}) : api = api ?? ApiService();

  /// Get match candidates for the current user.
  /// GET /match/candidates (JWT required)
  Future<List<Map<String, dynamic>>> getCandidates({String? token}) async {
    try {
      final res = await api.get('/match/candidates', token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeMatch(item is Map ? Map<String, dynamic>.from(item) : const {}))
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  /// Send a match request to another user.
  /// POST /match (JWT required)
  Future<Map<String, dynamic>> sendMatchRequest({
    required String userId2,
    String? message,
    String? token,
  }) async {
    final body = <String, dynamic>{'user_id_2': userId2};
    if (message != null && message.isNotEmpty) body['message'] = message;
    final res = await api.post('/match', token: token, body: jsonEncode(body));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Accept a match request.
  /// PATCH /match/:id/accept (JWT required)
  Future<bool> accept(String matchId, {String? token}) async {
    try {
      await api.patch('/match/$matchId/accept', token: token, body: jsonEncode({}));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reject a match request.
  /// PATCH /match/:id/reject (JWT required)
  Future<bool> reject(String matchId, {String? token}) async {
    try {
      await api.patch('/match/$matchId/reject', token: token, body: jsonEncode({}));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get a match by ID.
  /// GET /match/:id (JWT required)
  Future<Map<String, dynamic>> getMatchById(String matchId, {String? token}) async {
    final res = await api.get('/match/$matchId', token: token);
    if (res is Map) return _normalizeMatch(Map<String, dynamic>.from(res));
    return {};
  }

  /// Get current user's matches.
  /// GET /match/me (JWT required)
  Future<List<Map<String, dynamic>>> getMyMatches({String? token}) async {
    try {
      final res = await api.get('/match/me', token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeMatch(item is Map ? Map<String, dynamic>.from(item) : const {}))
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  Map<String, dynamic> _normalizeMatch(Map<String, dynamic> input) {
    return {
      'id': (input['id'] ?? '').toString(),
      'user1_id': (input['user1_id'] ?? '').toString(),
      'user2_id': (input['user2_id'] ?? '').toString(),
      'status': (input['status'] ?? 'pending').toString(),
      'message': input['message']?.toString(),
      'created_at': input['created_at']?.toString(),
      'matched_at': input['matched_at']?.toString(),
      'display_name': (input['display_name'] ?? input['name'] ?? 'Runner').toString(),
      'preferred_distance': (input['preferred_distance'] ?? input['preferred']) is num
          ? (input['preferred_distance'] ?? input['preferred'])
          : int.tryParse((input['preferred_distance'] ?? input['preferred'] ?? '0').toString()) ?? 0,
      'avg_pace': (input['avg_pace'] as num?)?.toDouble() ?? 0,
    };
  }

  // Backward compatibility
  Future<List<Map<String, dynamic>>> fetchMatches({String? token}) => getMyMatches(token: token);
}
