import 'dart:convert';
import '../api/api_service.dart';

class ProfileApi {
  final ApiService api;

  ProfileApi({ApiService? api}) : api = api ?? ApiService();

  /// Create or update runner profile.
  /// POST /profiles (JWT required)
  Future<Map<String, dynamic>> createOrUpdateProfile(Map<String, dynamic> data, {String? token}) async {
    final allowedKeys = <String>{
      'name',
      'gender',
      'avg_pace',
      'preferred_distance',
      'preferred_time',
      'latitude',
      'longitude',
      'women_only_mode',
      'image',
    };
    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      if (allowedKeys.contains(entry.key)) {
        sanitized[entry.key] = entry.value;
      }
    }
    try {
      final res = await api.post('/profiles', token: token, body: jsonEncode(sanitized));
      if (res is Map) return Map<String, dynamic>.from(res);
      return {};
    } catch (_) {
      rethrow;
    }
  }

  /// Fetch the current user's profile.
  /// GET /profiles/me (JWT required)
  /// Response: { id, user_id, user: { id, name, email, phone_number, gender, has_profile, is_verified, is_active, created_at, updated_at }, avg_pace, preferred_distance, preferred_time, latitude, longitude, women_only_mode, image, is_active, created_at, updated_at }
  Future<Map<String, dynamic>> getMyProfile({String? token}) async {
    final res = await api.get('/profiles/me', token: token);
    if (res is! Map) return {};

    final body = Map<String, dynamic>.from(res);
    final user = body['user'] is Map
        ? Map<String, dynamic>.from(body['user'])
        : <String, dynamic>{};

    return {
      // Runner profile fields
      'profile_id': (body['id'] ?? '').toString(),
      'user_id': (body['user_id'] ?? user['id'] ?? '').toString(),

      // User fields (from nested user object)
      'name': user['name']?.toString(),
      'email': user['email']?.toString(),
      'phone_number': (user['phone_number'] ?? '').toString(),
      'gender': user['gender']?.toString(),
      'has_profile': user['has_profile'] == true,
      'is_verified': user['is_verified'] == true,

      // Profile fields (directly on body)
      'avg_pace': (body['avg_pace'] as num?)?.toDouble() ?? 0,
      'preferred_distance': (body['preferred_distance'] as num?)?.toInt() ?? 0,
      'preferred_time': (body['preferred_time'] ?? '').toString(),
      'latitude': (body['latitude'] as num?)?.toDouble() ?? 0,
      'longitude': (body['longitude'] as num?)?.toDouble() ?? 0,
      'women_only_mode': body['women_only_mode'] == true,
      'image': body['image']?.toString(),
      'is_active': body['is_active'] == true,
      'created_at': body['created_at']?.toString(),
      'updated_at': body['updated_at']?.toString(),
    };
  }

  /// Fetch a profile by ID.
  /// GET /profiles/:id (JWT required)
  Future<Map<String, dynamic>> getProfileById(String id, {String? token}) async {
    final res = await api.get('/profiles/$id', token: token);
    if (res is! Map) return {};
    return Map<String, dynamic>.from(res);
  }

  /// Update a profile by ID.
  /// PUT /profiles/:id (JWT required)
  Future<bool> updateProfile(String id, Map<String, dynamic> data, {String? token}) async {
    try {
      await api.put('/profiles/$id', token: token, body: jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all profiles.
  /// GET /profiles (JWT required)
  Future<List<Map<String, dynamic>>> getAllProfiles({String? token}) async {
    try {
      final res = await api.get('/profiles', token: token);
      if (res is List) {
        return res
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Delete a profile by ID.
  /// DELETE /profiles/:id (JWT required)
  Future<bool> deleteProfile(String id, {String? token}) async {
    try {
      await api.delete('/profiles/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Keep backward compatibility
  Future<Map<String, dynamic>> fetchProfile({String? token}) => getMyProfile(token: token);
  Future<bool> updateProfileLegacy(Map<String, dynamic> data, {String? token}) async {
    try {
      await createOrUpdateProfile(data, token: token);
      return true;
    } catch (_) {
      return false;
    }
  }
}
