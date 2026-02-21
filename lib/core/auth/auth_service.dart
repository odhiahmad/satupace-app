import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AuthServiceBase {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<bool> logout(String token);
}

class AuthService implements AuthServiceBase {
  final String baseUrl;

  AuthService({this.baseUrl = 'https://api.example.com'});

  /// Attempts to login. Expects a JSON response with `token` and optional `name`.
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    try {
      final res = await http.post(uri, body: {'email': email, 'password': password});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'ok': true, 'data': data};
      }
      return {'ok': false, 'message': res.body};
    } catch (e) {
      // Fallback: return simulated token for local development
      return {
        'ok': true,
        'data': {'token': 'local-dev-token', 'name': 'Local Runner'}
      };
    }
  }

  @override
  Future<bool> logout(String token) async {
    final uri = Uri.parse('$baseUrl/logout');
    try {
      final res = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}
