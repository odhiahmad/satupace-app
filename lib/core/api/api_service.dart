import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final dynamic secureStorage; // keep type dynamic to avoid import cycles in simple usage

  ApiService({this.baseUrl = 'https://api.example.com', Map<String, String>? headers, this.secureStorage})
      : defaultHeaders = headers ?? {'Content-Type': 'application/json'};

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
    final res = await http.get(_uri(path), headers: h);
    return _process(res);
  }

  Future<dynamic> post(String path, {String? token, Map<String, String>? headers, Object? body}) async {
    final h = await _headers(token, headers);
    final res = await http.post(_uri(path), headers: h, body: body);
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
    throw ApiException(code, res.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
