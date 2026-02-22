import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constansts/app_config.dart';

abstract class AuthServiceBase {
  Future<Map<String, dynamic>> login(String identifier, String password);
  Future<Map<String, dynamic>> register(String name, String email, String phoneNumber, String gender, String password);
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode);
  Future<Map<String, dynamic>> resendOtp(String phoneNumber);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<bool> registerFcmToken(String token, String fcmToken);
  Future<bool> logout(String token);
}

class AuthService implements AuthServiceBase {
  final String baseUrl;

  AuthService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  // ─── Shared response parser ───
  // Backend returns: { status: bool, message: string, data: {}, error?: { code, field, details } }

  /// Parse the backend response into a normalized map.
  /// Returns `{ok: true, data: {...}, message: '...'}` on success,
  /// or `{ok: false, message: '...', field: '...', code: '...'}` on error.
  Map<String, dynamic> _parseResponse(http.Response res, String label) {
    debugPrint('[AuthService] $label status: ${res.statusCode}');
    debugPrint('[AuthService] $label body: ${res.body}');

    if (res.body.isEmpty) {
      return {'ok': false, 'message': '$label failed — empty response (${res.statusCode})'};
    }

    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as bool? ?? false;
      final message = (body['message'] ?? '').toString();

      if (status) {
        // Success → { status: true, message, data }
        return {'ok': true, 'data': body['data'], 'message': message};
      }

      // Error → { status: false, message, error: { code, field, details } }
      final error = body['error'] as Map<String, dynamic>?;
      final errorCode = error?['code'] ?? '';
      final errorField = error?['field'] ?? '';
      final errorDetails = error?['details'] ?? '';

      // Build a user-friendly message
      String displayMsg = message;
      if (errorDetails.toString().isNotEmpty) {
        displayMsg = '$message: $errorDetails';
      }
      if (errorField.toString().isNotEmpty) {
        displayMsg = '$displayMsg (field: $errorField)';
      }

      return {
        'ok': false,
        'message': displayMsg,
        'code': errorCode.toString(),
        'field': errorField.toString(),
        'details': errorDetails.toString(),
      };
    } catch (e) {
      debugPrint('[AuthService] $label parse error: $e');
      return {'ok': false, 'message': '$label failed (${res.statusCode})'};
    }
  }

  // ─── Auth endpoints ───

  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    debugPrint('[AuthService] POST $uri');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      return _parseResponse(res, 'login');
    } catch (e) {
      debugPrint('[AuthService] login error: $e');
      return {'ok': false, 'message': 'Network error: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> register(String name, String email, String phoneNumber, String gender, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final payload = {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'gender': gender,
      'password': password,
    };
    debugPrint('[AuthService] POST $uri');
    debugPrint('[AuthService] body: ${jsonEncode(payload)}');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      return _parseResponse(res, 'register');
    } catch (e) {
      debugPrint('[AuthService] register error: $e');
      return {'ok': false, 'message': 'Network error: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    final uri = Uri.parse('$baseUrl/auth/verify');
    debugPrint('[AuthService] POST $uri');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': phoneNumber, 'otp_code': otpCode}),
          )
          .timeout(const Duration(seconds: 20));
      return _parseResponse(res, 'verifyOtp');
    } catch (e) {
      debugPrint('[AuthService] verifyOtp error: $e');
      return {'ok': false, 'message': 'Network error: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    final uri = Uri.parse('$baseUrl/auth/resend-otp');
    debugPrint('[AuthService] POST $uri');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));
      return _parseResponse(res, 'resendOtp');
    } catch (e) {
      debugPrint('[AuthService] resendOtp error: $e');
      return {'ok': false, 'message': 'Network error: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final uri = Uri.parse('$baseUrl/auth/refresh-token');
    debugPrint('[AuthService] POST $uri');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));
      return _parseResponse(res, 'refreshToken');
    } catch (e) {
      debugPrint('[AuthService] refreshToken error: $e');
      return {'ok': false, 'message': 'Network error: $e'};
    }
  }

  @override
  Future<bool> registerFcmToken(String token, String fcmToken) async {
    final uri = Uri.parse('$baseUrl/auth/device-token');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'fcm_token': fcmToken}),
          )
          .timeout(const Duration(seconds: 20));
      final parsed = _parseResponse(res, 'registerFcmToken');
      return parsed['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> logout(String token) async {
    final uri = Uri.parse('$baseUrl/auth/logout');
    try {
      final res = await http
          .post(uri, headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(const Duration(seconds: 20));
      final parsed = _parseResponse(res, 'logout');
      return parsed['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
