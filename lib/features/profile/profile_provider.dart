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

  // Get specific profile fields
  String? get name => _profile?['name'];
  String? get email => _profile?['email'];
  double? get avgPace => _profile?['avg_pace'];
  int? get preferredDistance => _profile?['preferred_distance'];
  double? get latitude => _profile?['latitude'];
  double? get longitude => _profile?['longitude'];

  // Fetch profile
  Future<void> fetchProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _profile = await _api.fetchProfile(token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      // Merge updates with existing profile
      _profile = {...?_profile, ...updates};

      await _api.updateProfile(_profile!, token: token);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      // Revert on error
      await fetchProfile();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // Update name
  Future<bool> updateName(String name) async {
    return updateProfile({'name': name});
  }

  // Update email
  Future<bool> updateEmail(String email) async {
    return updateProfile({'email': email});
  }

  // Update pace
  Future<bool> updatePace(double pace) async {
    return updateProfile({'avg_pace': pace});
  }

  // Update preferred distance
  Future<bool> updatePreferredDistance(int distance) async {
    return updateProfile({'preferred_distance': distance});
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
