import 'dart:convert';
import '../api/api_service.dart';

class GroupRunApi {
  final ApiService api;

  GroupRunApi({ApiService? api}) : api = api ?? ApiService();

  /// Create a new run group.
  /// POST /runs/groups (JWT required)
  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data, {String? token}) async {
    final res = await api.post('/runs/groups', token: token, body: jsonEncode(data));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Fetch all run groups with optional filters.
  /// GET /runs/groups?status=&women_only=&min_pace=&max_pace=&max_distance=&latitude=&longitude=&radius_km=
  Future<List<Map<String, dynamic>>> fetchGroups({
    String? token,
    Map<String, String>? filters,
  }) async {
    try {
      var path = '/runs/groups';
      if (filters != null && filters.isNotEmpty) {
        final params = filters.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        if (params.isNotEmpty) path = '$path?$params';
      }
      final res = await api.get(path, token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeGroup(item is Map ? Map<String, dynamic>.from(item) : const {}))
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  /// Fetch groups created by the current user.
  /// GET /runs/groups/me
  Future<List<Map<String, dynamic>>> fetchMyGroups({String? token}) async {
    try {
      final res = await api.get('/runs/groups/me', token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeGroup(item is Map ? Map<String, dynamic>.from(item) : const {}))
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  /// Fetch a run group by ID.
  /// GET /runs/groups/:id
  Future<Map<String, dynamic>> getGroupById(String id, {String? token}) async {
    final res = await api.get('/runs/groups/$id', token: token);
    if (res is Map) return _normalizeGroup(Map<String, dynamic>.from(res));
    return {};
  }

  /// Update a run group.
  /// PUT /runs/groups/:id (JWT required)
  Future<bool> updateGroup(String id, Map<String, dynamic> data, {String? token}) async {
    try {
      await api.put('/runs/groups/$id', token: token, body: jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a run group.
  /// DELETE /runs/groups/:id (JWT required)
  Future<bool> deleteGroup(String id, {String? token}) async {
    try {
      await api.delete('/runs/groups/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Join a run group.
  /// POST /runs/groups/:id/join (JWT required)
  Future<bool> join(String groupId, {String? token}) async {
    try {
      await api.post('/runs/groups/$groupId/join', token: token, body: jsonEncode({}));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get members of a run group.
  /// GET /runs/groups/:id/members
  Future<List<Map<String, dynamic>>> getMembers(String groupId, {String? token}) async {
    try {
      final res = await api.get('/runs/groups/$groupId/members', token: token);
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

  /// Update a group member.
  /// PUT /runs/members/:id (JWT required)
  Future<bool> updateMember(String memberId, Map<String, dynamic> data, {String? token}) async {
    try {
      await api.put('/runs/members/$memberId', token: token, body: jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove a group member (leave group).
  /// DELETE /runs/members/:id (JWT required)
  Future<bool> removeMember(String memberId, {String? token}) async {
    try {
      await api.delete('/runs/members/$memberId', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Schedule endpoints ────────────────────────────────────────────────────

  /// Get all schedules for a group.
  /// GET /runs/groups/:id/schedules
  Future<List<Map<String, dynamic>>> getSchedules(String groupId, {String? token}) async {
    try {
      final res = await api.get('/runs/groups/$groupId/schedules', token: token);
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

  /// Create a schedule for a group.
  /// POST /runs/groups/:id/schedules (JWT required)
  /// Body: {day_of_week (0-6), start_time ("HH:MM")}
  Future<Map<String, dynamic>> createSchedule(
    String groupId,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final res = await api.post('/runs/groups/$groupId/schedules', token: token, body: jsonEncode(data));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Update a schedule.
  /// PUT /runs/groups/schedules/:scheduleId (JWT required)
  Future<bool> updateSchedule(String scheduleId, Map<String, dynamic> data, {String? token}) async {
    try {
      await api.put('/runs/groups/schedules/$scheduleId', token: token, body: jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a schedule.
  /// DELETE /runs/groups/schedules/:scheduleId (JWT required)
  Future<bool> deleteSchedule(String scheduleId, {String? token}) async {
    try {
      await api.delete('/runs/groups/schedules/$scheduleId', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _normalizeGroup(Map<String, dynamic> input) {
    return {
      'id': (input['id'] ?? '').toString(),
      'name': (input['name'] ?? 'Run Group').toString(),
      'avg_pace': (input['avg_pace'] as num?)?.toDouble() ?? 0,
      'preferred_distance': (input['preferred_distance'] as num?)?.toInt() ?? 0,
      'latitude': (input['latitude'] as num?)?.toDouble() ?? 0,
      'longitude': (input['longitude'] as num?)?.toDouble() ?? 0,
      'scheduled_at': (input['scheduled_at'] ?? input['scheduled'])?.toString(),
      'max_member': (input['max_member'] as num?)?.toInt() ?? 0,
      'is_women_only': input['is_women_only'] == true,
      'status': (input['status'] ?? 'open').toString(),
      'member_count': (input['member_count'] ?? input['members_count'] as num?)?.toInt() ?? 0,
      'created_by': (input['created_by'] ?? '').toString(),
      'creator': input['creator'] is Map ? Map<String, dynamic>.from(input['creator']) : null,
      'created_at': input['created_at']?.toString(),
      'my_role': (input['my_role'] ?? '').toString(),
      'min_pace': (input['min_pace'] as num?)?.toDouble(),
      'max_pace': (input['max_pace'] as num?)?.toDouble(),
    };
  }
}
