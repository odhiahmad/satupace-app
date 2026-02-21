import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';


class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final dynamic secureStorage; // keep type dynamic to avoid import cycles in simple usage

  ApiService({
    String? baseUrl,
    Map<String, String>? headers,
    this.secureStorage,
  })  : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com'),
        defaultHeaders = headers ?? {'Content-Type': 'application/json'} {
    final parsed = Uri.tryParse(this.baseUrl);
    if (kReleaseMode && (parsed == null || parsed.scheme != 'https')) {
      throw StateError('Invalid API_BASE_URL configuration in release mode. HTTPS is required.');
    }
  }

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<Map<String, String>> _headers([String? token, Map<String, String>? headers]) async {
    final h = {...defaultHeaders, ...?headers};
    String? t = token;
    if ((t == null || t.isEmpty) && secureStorage != null) {
      try {
        // SecureStorageService has readToken()
        final read = await secureStorage.readToken();
        if (read is String && read.isNotEmpty) t = read;
      } catch (_) {
        // ignore
      }
    }
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<dynamic> get(String path, {String? token, Map<String, String>? headers}) async {
    final h = await _headers(token, headers);
    final res = await http.get(_uri(path), headers: h).timeout(const Duration(seconds: 20));
    return _process(res);
  }

  Future<dynamic> post(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.post(_uri(path), headers: h, body: body).timeout(const Duration(seconds: 20));
    return _process(res);
  }

  Future<dynamic> put(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.put(_uri(path), headers: h, body: body).timeout(const Duration(seconds: 20));
    return _process(res);
  }

  Future<dynamic> patch(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.patch(_uri(path), headers: h, body: body).timeout(const Duration(seconds: 20));
    return _process(res);
  }

  Future<dynamic> delete(String path, {String? token, Map<String, String>? headers}) async {
    final h = await _headers(token, headers);
    final res = await http.delete(_uri(path), headers: h).timeout(const Duration(seconds: 20));
    return _process(res);
  }

  dynamic _process(http.Response res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
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
