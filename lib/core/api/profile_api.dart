import 'dart:convert';
import '../api/api_service.dart';

class ProfileApi {
  final ApiService api;

  ProfileApi({ApiService? api}) : api = api ?? ApiService();

  Future<Map<String, dynamic>> fetchProfile({String? token}) async {
    try {
      final res = await api.get('/profile', token: token);
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {
      return {
        'id': 'user_1',
        'name': 'Local Runner',
        'email': 'runner@example.com',
        'avg_pace': 5.45,
        'preferred_distance': 5
      };
    }
    return {};
  }

  Future<bool> updateProfile(Map<String, dynamic> data, {String? token}) async {
    try {
      await api.post('/profile', token: token, body: jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }
}
