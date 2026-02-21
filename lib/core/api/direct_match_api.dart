import 'dart:convert';
import '../api/api_service.dart';

class DirectMatchApi {
  final ApiService api;

  DirectMatchApi({ApiService? api}) : api = api ?? ApiService();

  Future<List<Map<String, dynamic>>> fetchMatches({String? token}) async {
    try {
      final res = await api.get('/matches', token: token);
      if (res is List) return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return List.generate(
        5,
        (i) => {
          'id': 'match_$i',
          'name': 'Match ${i + 1}',
          'preferred': '${5 + i} km',
        },
      );
    }
    return [];
  }

  Future<bool> accept(String matchId, {String? token}) async {
    try {
      await api.post('/matches/$matchId/accept', token: token, body: jsonEncode({}));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String matchId, {String? token}) async {
    try {
      await api.post('/matches/$matchId/reject', token: token, body: jsonEncode({}));
      return true;
    } catch (_) {
      return false;
    }
  }
}
