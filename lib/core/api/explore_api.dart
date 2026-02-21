import '../api/api_service.dart';

class ExploreApi {
  final ApiService api;

  ExploreApi({ApiService? api}) : api = api ?? ApiService();

  /// Explore nearby runners.
  /// GET /explore/runners (JWT required)
  Future<List<Map<String, dynamic>>> getRunners({String? token}) async {
    try {
      final res = await api.get('/explore/runners', token: token);
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

  /// Explore nearby run groups.
  /// GET /explore/groups (JWT required)
  Future<List<Map<String, dynamic>>> getGroups({String? token}) async {
    try {
      final res = await api.get('/explore/groups', token: token);
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
