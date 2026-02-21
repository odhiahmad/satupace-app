import 'dart:convert';
import 'package:http/http.dart' as http;

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
      : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com');

  /// Attempts to login with email or phone number.
  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'ok': true, 'data': data};
      }
      String message = 'Invalid credentials';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = (body['message'] ?? message).toString();
      } catch (_) {}
      return {'ok': false, 'message': message};
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Register a new user with name, email, phone number, gender and password.
  @override
  Future<Map<String, dynamic>> register(String name, String email, String phoneNumber, String gender, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone_number': phoneNumber,
              'gender': gender,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'ok': true, 'data': data};
      }
      String message = 'Registration failed';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = (body['message'] ?? message).toString();
      } catch (_) {}
      return {'ok': false, 'message': message};
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Verify OTP code using phone number.
  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    final uri = Uri.parse('$baseUrl/auth/verify');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': phoneNumber, 'otp_code': otpCode}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'ok': true, 'data': data};
      }
      String message = 'Invalid OTP';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = (body['message'] ?? message).toString();
      } catch (_) {}
      return {'ok': false, 'message': message};
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Resend OTP to phone number.
  @override
  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    final uri = Uri.parse('$baseUrl/auth/resend-otp');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone_number': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'ok': true, 'data': data};
      }
      String message = 'Failed to resend OTP';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = (body['message'] ?? message).toString();
      } catch (_) {}
      return {'ok': false, 'message': message};
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Refresh access token using refresh token.
  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final uri = Uri.parse('$baseUrl/auth/refresh-token');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'ok': true, 'data': data};
      }
      return {'ok': false, 'message': 'Session expired. Please login again.'};
    } catch (e) {
      return {'ok': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Register FCM device token for push notifications.
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
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> logout(String token) async {
    final uri = Uri.parse('$baseUrl/auth/logout');
    try {
      final res = await http
          .post(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
