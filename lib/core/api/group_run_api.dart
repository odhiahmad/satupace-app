import 'dart:convert';
import '../api/api_service.dart';

class GroupRunApi {
  final ApiService api;

  GroupRunApi({ApiService? api}) : api = api ?? ApiService();

  Future<List<Map<String, dynamic>>> fetchGroups({String? token}) async {
    try {
      final res = await api.get('/groups', token: token);
      if (res is List) return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return List.generate(
        6,
        (i) => {
          'id': 'group_$i',
          'name': 'Morning Run ${i + 1}',
          'distance': '${5 + i} km',
          'scheduled': '06:00',
        },
      );
    }
    return [];
  }

  Future<bool> join(String groupId, {String? token}) async {
    try {
      await api.post('/groups/$groupId/join', token: token, body: jsonEncode({}));
      return true;
    } catch (_) {
      return false;
    }
  }
}
