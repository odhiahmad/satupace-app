import 'dart:convert';
import '../api/api_service.dart';

class DirectMatchApi {
  final ApiService api;

  DirectMatchApi({ApiService? api}) : api = api ?? ApiService();

  /// Get match candidates for the current user.
  /// GET /match/candidates (JWT required)
  /// Backend returns CandidateResult: { Profile: {...}, User: {...}, Compatibility, DistanceKm }
  Future<List<Map<String, dynamic>>> getCandidates({String? token}) async {
    try {
      final res = await api.get('/match/candidates', token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeCandidate(
                item is Map ? Map<String, dynamic>.from(item) : const {}))
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
    String? token,
  }) async {
    final body = <String, dynamic>{'user_2_id': userId2};
    final res = await api.post('/match', token: token, body: jsonEncode(body));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Accept a match request.
  /// PATCH /match/:id/accept (JWT required)
  Future<bool> accept(String matchId, {String? token}) async {
    try {
      await api.patch('/match/$matchId/accept', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reject a match request.
  /// PATCH /match/:id/reject (JWT required)
  Future<bool> reject(String matchId, {String? token}) async {
    try {
      await api.patch('/match/$matchId/reject', token: token);
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
      'user_1_id': (input['user_1_id'] ?? '').toString(),
      'user_2_id': (input['user_2_id'] ?? '').toString(),
      'user_1': input['user_1'],
      'user_2': input['user_2'],
      // Only present when status == 'accepted'
      'user_1_verification_photo': input['user_1_verification_photo']?.toString(),
      'user_2_verification_photo': input['user_2_verification_photo']?.toString(),
      'status': (input['status'] ?? 'pending').toString(),
      'created_at': input['created_at']?.toString(),
      'matched_at': input['matched_at']?.toString(),
    };
  }

  /// Normalizes a CandidateResult from the backend:
  /// { Profile: RunnerProfile, User: User, Compatibility: float, DistanceKm: float }
  Map<String, dynamic> _normalizeCandidate(Map<String, dynamic> input) {
    final profile = input['Profile'] is Map
      ? Map<String, dynamic>.from(input['Profile'] as Map)
      : <String, dynamic>{};
    final user = input['User'] is Map
      ? Map<String, dynamic>.from(input['User'] as Map)
      : <String, dynamic>{};
    return {
      // User entity has lowercase json tags: "id", "name", etc.
      'user_id': (user['id'] ?? user['Id'] ?? '').toString(),
      'name': (user['name'] ?? user['full_name'] ?? 'Runner').toString(),
      'avg_pace': profile['avg_pace'],
      'preferred_distance': profile['preferred_distance'],
      'preferred_time': profile['preferred_time'],
      'gender': user['gender'],
      'image': profile['image'],
      'compatibility': input['Compatibility'],
      'distance_km': input['DistanceKm'],
      'is_verified': user['is_verified'] ?? false,
    };
  }

  // Backward compatibility
  Future<List<Map<String, dynamic>>> fetchMatches({String? token}) => getMyMatches(token: token);
}
