import 'package:flutter/material.dart';
import '../../core/api/profile_api.dart';
import '../../core/services/secure_storage_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileApi _api;
  final SecureStorageService _storage;

  Map<String, dynamic>? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  bool _hasTriedLoadingCache = false;

  ProfileProvider({
    required ProfileApi api,
    required SecureStorageService storage,
  })  : _api = api,
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

  // Fetch profile
  Future<void> fetchProfile() async {
    // If already loaded, don't load again
    if (_profile != null) {
      return;
    }

    // Try loading from cache first (only once)
    if (!_hasTriedLoadingCache) {
      _hasTriedLoadingCache = true;
      final cachedProfile = await _storage.readProfileData();
      if (cachedProfile != null) {
        _profile = cachedProfile;
        notifyListeners();
        return;
      }
    }

    // If no cache, fetch from API
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _profile = await _api.getMyProfile(token: token);
      // Cache the profile data
      await _storage.writeProfileData(_profile!);
      // Cache name so other pages (e.g. chat) can read it without Provider
      final nameVal = _profile?['name']?.toString();
      if (nameVal != null && nameVal.isNotEmpty) {
        await _storage.writeUserName(nameVal);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Refresh profile from API (bypass cache)
  Future<void> refreshProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _profile = await _api.getMyProfile(token: token);
      // Cache the profile data
      await _storage.writeProfileData(_profile!);
      // Cache name so other pages (e.g. chat) can read it without Provider
      final nameVal = _profile?['name']?.toString();
      if (nameVal != null && nameVal.isNotEmpty) {
        await _storage.writeUserName(nameVal);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update profile (runner profile fields)
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      // POST /profiles handles both create and update (upsert)
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

      // Update in-memory profile with the merged data
      _profile = <String, dynamic>{...?_profile, ...merged};
      // Persist updated profile to cache
      await _storage.writeProfileData(_profile!);
      // Persist updated name if it changed
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

  // Update location
  Future<bool> updateLocation(double latitude, double longitude) async {
    return updateProfile({
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
