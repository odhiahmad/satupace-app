import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _userIdKey = 'user_id';
  static const _introSeenKey = 'intro_seen';
  static const _profileSetupKey = 'profile_setup_done';
  static const _userNameKey = 'user_name';
  static const _profileDataKey = 'profile_data';

  // --- Access Token ---
  Future<void> writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // --- Refresh Token ---
  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> readRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // --- Biometric ---
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  // --- User ID ---
  Future<void> writeUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  Future<String?> readUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // --- User Name ---
  Future<void> writeUserName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
  }

  Future<String?> readUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  // --- Profile Data (cached) ---
  Future<void> writeProfileData(Map<String, dynamic> profileData) async {
    final jsonStr = jsonEncode(profileData);
    await _storage.write(key: _profileDataKey, value: jsonStr);
  }

  Future<Map<String, dynamic>?> readProfileData() async {
    final jsonStr = await _storage.read(key: _profileDataKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteProfileData() async {
    await _storage.delete(key: _profileDataKey);
  }

  // --- Intro Seen ---
  Future<void> setIntroSeen(bool seen) async {
    await _storage.write(key: _introSeenKey, value: seen ? 'true' : 'false');
  }

  Future<bool> hasSeenIntro() async {
    final val = await _storage.read(key: _introSeenKey);
    return val == 'true';
  }

  // --- Profile Setup ---
  Future<void> setProfileSetupDone(bool done) async {
    await _storage.write(key: _profileSetupKey, value: done ? 'true' : 'false');
  }

  Future<bool> isProfileSetupDone() async {
    final val = await _storage.read(key: _profileSetupKey);
    return val == 'true';
  }

  // --- Clear All ---
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _profileSetupKey);
    await _storage.delete(key: _profileDataKey);
    // Keep _introSeenKey so user doesn't see intro again
  }
}
