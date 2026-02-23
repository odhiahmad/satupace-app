import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constansts/app_config.dart';


class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final dynamic secureStorage; // keep type dynamic to avoid import cycles in simple usage

  /// Whether a token refresh is currently in flight (prevents loops).
  bool _refreshing = false;

  ApiService({
    String? baseUrl,
    Map<String, String>? headers,
    this.secureStorage,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        defaultHeaders = headers ?? {'Content-Type': 'application/json'} {
    final parsed = Uri.tryParse(this.baseUrl);
    if (kReleaseMode && (parsed == null || parsed.scheme != 'https')) {
      throw StateError('Invalid API base URL in release mode. HTTPS is required.');
    }
  }

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<Map<String, String>> _headers([String? token, Map<String, String>? headers]) async {
    final h = {...defaultHeaders, ...?headers};
    String? t = token;
    if ((t == null || t.isEmpty) && secureStorage != null) {
      try {
        final read = await secureStorage.readToken();
        if (read is String && read.isNotEmpty) t = read;
      } catch (_) {
        // ignore
      }
    }
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  // ─── Public HTTP methods ───

  Future<dynamic> get(String path, {String? token, Map<String, String>? headers}) async {
    final h = await _headers(token, headers);
    final res = await http.get(_uri(path), headers: h).timeout(const Duration(seconds: 20));
    return _processWithRetry(res, 'GET', path, token: token, headers: headers);
  }

  Future<dynamic> post(String path, {String? token, Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 20)}) async {
    final h = await _headers(token, headers);
    final res = await http.post(_uri(path), headers: h, body: body).timeout(timeout);
    return _processWithRetry(res, 'POST', path, token: token, headers: headers, body: body);
  }

  Future<dynamic> put(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.put(_uri(path), headers: h, body: body).timeout(const Duration(seconds: 20));
    return _processWithRetry(res, 'PUT', path, token: token, headers: headers, body: body);
  }

  Future<dynamic> patch(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.patch(_uri(path), headers: h, body: body).timeout(const Duration(seconds: 20));
    return _processWithRetry(res, 'PATCH', path, token: token, headers: headers, body: body);
  }

  Future<dynamic> delete(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.delete(_uri(path), headers: h, body: body).timeout(const Duration(seconds: 20));
    return _processWithRetry(res, 'DELETE', path, token: token, headers: headers, body: body);
  }

  // ─── Auto Refresh Token on 401 ───

  /// Process response; if 401, attempt a token refresh and retry once.
  Future<dynamic> _processWithRetry(
    http.Response res,
    String method,
    String path, {
    String? token,
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (res.statusCode == 401 && !_refreshing && secureStorage != null) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request with the new token
        final h = await _headers(null, headers);
        final retryRes = await _retry(method, path, h, body);
        return _process(retryRes);
      }
    }
    return _process(res);
  }

  /// Attempt to refresh the access token using the stored refresh token.
  Future<bool> _tryRefreshToken() async {
    _refreshing = true;
    try {
      final refreshToken = await secureStorage.readRefreshToken();
      if (refreshToken == null || (refreshToken as String).isEmpty) return false;

      final uri = Uri.parse('$baseUrl/auth/refresh-token');
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final status = body['status'] as bool? ?? false;
        if (!status) return false;

        final data = body['data'] as Map<String, dynamic>? ?? body;
        final newToken = (data['token'] ?? data['access_token']) as String?;
        final newRefresh = data['refresh_token'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          await secureStorage.writeToken(newToken);
        }
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await secureStorage.writeRefreshToken(newRefresh);
        }
        return newToken != null && newToken.isNotEmpty;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// Re-execute an HTTP request with the given method.
  Future<http.Response> _retry(String method, String path, Map<String, String> h, Object? body) {
    final uri = _uri(path);
    switch (method) {
      case 'POST':
        return http.post(uri, headers: h, body: body).timeout(const Duration(seconds: 20));
      case 'PUT':
        return http.put(uri, headers: h, body: body).timeout(const Duration(seconds: 20));
      case 'PATCH':
        return http.patch(uri, headers: h, body: body).timeout(const Duration(seconds: 20));
      case 'DELETE':
        return http.delete(uri, headers: h).timeout(const Duration(seconds: 20));
      default:
        return http.get(uri, headers: h).timeout(const Duration(seconds: 20));
    }
  }

  // ─── Response processing ───

  dynamic _process(http.Response res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) {
      if (res.body.isEmpty) return null;
      try {
        final decoded = jsonDecode(res.body);
        // Auto-unwrap standard Go backend response: {status, message, data}
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('status') &&
            decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      } catch (_) {
        return res.body;
      }
    }
    String message = 'Request failed';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final apiMessage = decoded['message'] ?? decoded['error'];
        if (apiMessage is String && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
    } catch (_) {
      // ignore malformed body
    }
    throw ApiException(code, message);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
