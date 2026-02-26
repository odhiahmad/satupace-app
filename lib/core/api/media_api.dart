import 'dart:convert';
import '../api/api_service.dart';

class MediaApi {
  final ApiService api;

  MediaApi({ApiService? api}) : api = api ?? ApiService();

  /// Upload a photo.
  /// POST /media/photos (JWT required)
  /// Body: {image (base64), type, is_primary}
  Future<Map<String, dynamic>> uploadPhoto({
    required String imageBase64,
    required String type,
    bool isPrimary = false,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'image': imageBase64,
      'type': type,
      'is_primary': isPrimary,
    };
    final res = await api.post('/media/photos', token: token, body: jsonEncode(body), timeout: const Duration(seconds: 120));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get a photo by ID.
  /// GET /media/photos/:id
  Future<Map<String, dynamic>> getPhotoById(String id, {String? token}) async {
    final res = await api.get('/media/photos/$id', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get all photos for a user.
  /// GET /media/users/:userId/photos
  Future<List<Map<String, dynamic>>> getUserPhotos(String userId, {String? token}) async {
    try {
      final res = await api.get('/media/users/$userId/photos', token: token);
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

  /// Get primary photo for a user.
  /// GET /media/users/:userId/photos/primary
  Future<Map<String, dynamic>> getPrimaryPhoto(String userId, {String? token}) async {
    try {
      final res = await api.get('/media/users/$userId/photos/primary', token: token);
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    return {};
  }

  /// Get photos for the currently logged-in user.
  /// GET /media/me/photos (JWT required)
  Future<List<Map<String, dynamic>>> getMyPhotos({String? token}) async {
    try {
      final res = await api.get('/media/me/photos', token: token);
      if (res is List) {
        return res
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Verify face against the stored verification photo.
  /// POST /media/photos/verify-face (JWT required)
  /// Body: {image: base64}
  /// Returns: {matched: bool, similarity: float, photo: {...}?}
  Future<Map<String, dynamic>> verifyFace({
    required String imageBase64,
    String? token,
  }) async {
    final body = <String, dynamic>{'image': imageBase64};
    final res = await api.post(
      '/media/photos/verify-face',
      token: token,
      body: jsonEncode(body),
      timeout: const Duration(seconds: 30),
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }
}
