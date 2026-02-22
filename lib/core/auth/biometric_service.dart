import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../constansts/app_config.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final String baseUrl;

  factory BiometricService({String? baseUrl}) {
    if (baseUrl != null) _instance._setBaseUrl(baseUrl);
    return _instance;
  }

  BiometricService._internal()
      : baseUrl = AppConfig.apiBaseUrl;

  String _baseUrl = AppConfig.apiBaseUrl;

  void _setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get _effectiveBaseUrl => _baseUrl;

  // ─── Local device biometric methods ───

  /// Check if biometric hardware is available on the device.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if any biometric credentials are enrolled.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Prompt user for biometric authentication on device.
  Future<bool> authenticate({String reason = 'Authenticate to login'}) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Get a friendly name for the biometric type available.
  Future<String> getBiometricLabel() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  // ─── Backend challenge-response biometric API ───

  /// Start biometric registration — returns challenge from backend.
  /// POST /biometric/register/start (JWT required)
  Future<Map<String, dynamic>> registerStart({required String token, required String deviceName}) async {
    final uri = Uri.parse('$_effectiveBaseUrl/biometric/register/start');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'device_name': deviceName}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return {'ok': true, 'data': jsonDecode(res.body)};
      }
      return _errorResponse(res, 'Failed to start biometric registration');
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Finish biometric registration — sends credential, public key, challenge & signature.
  /// POST /biometric/register/finish (JWT required)
  Future<Map<String, dynamic>> registerFinish({
    required String token,
    required String credentialId,
    required String publicKey,
    required String deviceName,
    required String challenge,
    required String signature,
  }) async {
    final uri = Uri.parse('$_effectiveBaseUrl/biometric/register/finish');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'credential_id': credentialId,
              'public_key': publicKey,
              'device_name': deviceName,
              'challenge': challenge,
              'signature': signature,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'ok': true, 'data': jsonDecode(res.body)};
      }
      return _errorResponse(res, 'Failed to finish biometric registration');
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Start biometric login — sends identifier, returns challenge.
  /// POST /auth/biometric/login/start
  Future<Map<String, dynamic>> loginStart({required String identifier}) async {
    final uri = Uri.parse('$_effectiveBaseUrl/auth/biometric/login/start');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return {'ok': true, 'data': jsonDecode(res.body)};
      }
      return _errorResponse(res, 'Failed to start biometric login');
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Finish biometric login — sends credential_id, challenge, signature. Returns JWT.
  /// POST /auth/biometric/login/finish
  Future<Map<String, dynamic>> loginFinish({
    required String credentialId,
    required String challenge,
    required String signature,
  }) async {
    final uri = Uri.parse('$_effectiveBaseUrl/auth/biometric/login/finish');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'credential_id': credentialId,
              'challenge': challenge,
              'signature': signature,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return {'ok': true, 'data': jsonDecode(res.body)};
      }
      return _errorResponse(res, 'Biometric login failed');
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Get registered biometric credentials.
  /// GET /biometric/credentials (JWT required)
  Future<Map<String, dynamic>> getCredentials({required String token}) async {
    final uri = Uri.parse('$_effectiveBaseUrl/biometric/credentials');
    try {
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return {'ok': true, 'data': jsonDecode(res.body)};
      }
      return _errorResponse(res, 'Failed to fetch credentials');
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Delete a biometric credential.
  /// DELETE /biometric/credentials/:credentialId (JWT required)
  Future<Map<String, dynamic>> deleteCredential({required String token, required String credentialId}) async {
    final uri = Uri.parse('$_effectiveBaseUrl/biometric/credentials/$credentialId');
    try {
      final res = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return {'ok': true};
      }
      return _errorResponse(res, 'Failed to delete credential');
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  Map<String, dynamic> _errorResponse(http.Response res, String fallback) {
    String message = fallback;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      message = (body['message'] ?? fallback).toString();
    } catch (_) {}
    return {'ok': false, 'message': message};
  }
}
