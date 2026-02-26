import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/media_api.dart';
import '../../core/services/secure_storage_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileApi _api;
  final MediaApi? _mediaApi;
  final SecureStorageService _storage;

  Map<String, dynamic>? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  bool _loadedFromApi = false;

  // Verification photo state
  String? _verificationPhotoUrl;
  bool _loadingVerificationPhoto = false;

  String? get verificationPhotoUrl => _verificationPhotoUrl;
  bool get loadingVerificationPhoto => _loadingVerificationPhoto;

  ProfileProvider({
    required ProfileApi api,
    required SecureStorageService storage,
    MediaApi? mediaApi,
  })  : _api = api,
        _mediaApi = mediaApi,
        _storage = storage;

  // Getters
  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  // Profile ID & User ID
  String? get profileId => _profile?['profile_id']?.toString();
  String? get userId => _profile?['user_id']?.toString();

  // User fields
  String? get name => _profile?['name']?.toString();
  String? get email => _profile?['email']?.toString();
  String? get phoneNumber => _profile?['phone_number']?.toString();
  String? get gender => _profile?['gender']?.toString();
  bool get hasProfile => _profile?['has_profile'] == true;
  bool get isVerified => _profile?['is_verified'] == true;
  bool get isActive => _profile?['is_active'] == true;
  String? get createdAt => _profile?['created_at']?.toString();
  String? get updatedAt => _profile?['updated_at']?.toString();

  // Runner profile fields
  double? get avgPace {
    final v = _profile?['avg_pace'];
    return v is num ? v.toDouble() : null;
  }

  int? get preferredDistance {
    final v = _profile?['preferred_distance'];
    return v is num ? v.toInt() : null;
  }

  String? get preferredTime => _profile?['preferred_time']?.toString();
  bool get womenOnlyMode => _profile?['women_only_mode'] == true;
  String? get image => _profile?['image']?.toString();

  double? get latitude {
    final v = _profile?['latitude'];
    return v is num ? v.toDouble() : null;
  }

  double? get longitude {
    final v = _profile?['longitude'];
    return v is num ? v.toDouble() : null;
  }

  /// Clear in-memory profile — call this on logout so next login fetches fresh data.
  void clearProfile() {
    _profile = null;
    _error = null;
    _loading = false;
    _saving = false;
    _loadedFromApi = false;
    notifyListeners();
  }

  /// Fetch profile: shows cached data immediately, then always refreshes from API.
  /// Subsequent calls are no-ops once loaded from API (use [refreshProfile] to force).
  Future<void> fetchProfile() async {
    // Already loaded fresh from API — skip
    if (_loadedFromApi) return;

    // Show cached data immediately while we fetch from API
    if (_profile == null) {
      final cachedProfile = await _storage.readProfileData();
      if (cachedProfile != null) {
        _profile = cachedProfile;
        notifyListeners();
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final oldImage = _profile?['image']?.toString();
      _profile = await _api.getMyProfile(token: token);

      // 1. Preserve old image if API didn't return one
      if ((_profile?['image'] == null || _profile!['image'].toString().isEmpty) &&
          oldImage != null && oldImage.isNotEmpty) {
        _profile!['image'] = oldImage;
      }

      // 2. Fallback to dedicated photo endpoint if still no image
      final mediaApi1 = _mediaApi;
      if ((_profile?['image'] == null || _profile!['image'].toString().isEmpty) &&
          mediaApi1 != null) {
        final uid = _profile?['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          try {
            final photo = await mediaApi1.getPrimaryPhoto(uid, token: token);
            final url = photo['url']?.toString();
            if (url != null && url.isNotEmpty) _profile!['image'] = url;
          } catch (_) {}
        }
      }

      _loadedFromApi = true;
      await _storage.writeProfileData(_profile!);
      final nameVal = _profile?['name']?.toString();
      if (nameVal != null && nameVal.isNotEmpty) {
        await _storage.writeUserName(nameVal);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Force refresh from API (bypass cache and previous load state).
  Future<void> refreshProfile() async {
    _loadedFromApi = false;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final oldImage = _profile?['image']?.toString();
      _profile = await _api.getMyProfile(token: token);

      // 1. Preserve old image if API didn't return one
      if ((_profile?['image'] == null || _profile!['image'].toString().isEmpty) &&
          oldImage != null && oldImage.isNotEmpty) {
        _profile!['image'] = oldImage;
      }

      // 2. Fallback to dedicated photo endpoint if still no image
      final mediaApi2 = _mediaApi;
      if ((_profile?['image'] == null || _profile!['image'].toString().isEmpty) &&
          mediaApi2 != null) {
        final uid = _profile?['user_id']?.toString();
        if (uid != null && uid.isNotEmpty) {
          try {
            final photo = await mediaApi2.getPrimaryPhoto(uid, token: token);
            final url = photo['url']?.toString();
            if (url != null && url.isNotEmpty) _profile!['image'] = url;
          } catch (_) {}
        }
      }

      _loadedFromApi = true;
      await _storage.writeProfileData(_profile!);
      final nameVal = _profile?['name']?.toString();
      if (nameVal != null && nameVal.isNotEmpty) {
        await _storage.writeUserName(nameVal);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update profile (runner profile fields).
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      // Backend expects ALL fields — merge current profile with updates
      final merged = <String, dynamic>{
        'avg_pace': _profile?['avg_pace'] ?? 0,
        'preferred_distance': _profile?['preferred_distance'] ?? 0,
        'preferred_time': _profile?['preferred_time'] ?? 'morning',
        'latitude': _profile?['latitude'] ?? 0,
        'longitude': _profile?['longitude'] ?? 0,
        'women_only_mode': _profile?['women_only_mode'] ?? false,
        ...updates,
      };
      await _api.createOrUpdateProfile(merged, token: token);

      _profile = <String, dynamic>{...?_profile, ...merged};
      await _storage.writeProfileData(_profile!);
      final nameVal = _profile?['name']?.toString();
      if (nameVal != null && nameVal.isNotEmpty) {
        await _storage.writeUserName(nameVal);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Update location.
  Future<bool> updateLocation(double latitude, double longitude) async {
    return updateProfile({'latitude': latitude, 'longitude': longitude});
  }

  /// Upload a profile photo and persist the URL on the profile.
  /// [imageFile] — the File picked by image_picker.
  Future<bool> uploadProfileImage(File imageFile) async {
    if (_mediaApi == null) {
      _error = 'Media API tidak tersedia';
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _mediaApi.uploadPhoto(
        imageBase64: base64Image,
        type: 'profile',
        isPrimary: true,
        token: token,
      );

      // Backend returns the uploaded photo URL in result['url'] or result['image']
      final url = (result['url'] ?? result['image'] ?? '').toString();
      if (url.isNotEmpty) {
        await updateProfile({'image': url});
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user has a verification photo by fetching all their photos.
  Future<void> checkVerificationPhoto() async {
    if (_mediaApi == null) return;
    _loadingVerificationPhoto = true;
    notifyListeners();
    try {
      final token = await _storage.readToken();
      if (token == null) return;
      final photos = await _mediaApi.getMyPhotos(token: token);
      final verif = photos.where((p) => p['type'] == 'verification').firstOrNull;
      _verificationPhotoUrl = verif?['url']?.toString();
    } catch (_) {
    } finally {
      _loadingVerificationPhoto = false;
      notifyListeners();
    }
  }

  /// Upload a verification photo (must be a frontal face selfie).
  Future<bool> uploadVerificationPhoto(File imageFile) async {
    if (_mediaApi == null) {
      _error = 'Media API tidak tersedia';
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _mediaApi.uploadPhoto(
        imageBase64: base64Image,
        type: 'verification',
        isPrimary: false,
        token: token,
      );

      final url = (result['url'] ?? '').toString();
      if (url.isNotEmpty) {
        _verificationPhotoUrl = url;
      }
      // Refresh profile so is_verified status updates
      await refreshProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Verify face against stored verification photo.
  /// Returns the raw API response: {matched: bool, similarity: double}.
  Future<Map<String, dynamic>> verifyFace(File imageFile) async {
    if (_mediaApi == null) return {'matched': false, 'error': 'Media API tidak tersedia'};
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      return await _mediaApi.verifyFace(imageBase64: base64Image, token: token);
    } catch (e) {
      return {'matched': false, 'error': e.toString()};
    }
  }
}
