import 'package:flutter/material.dart';
import '../../core/api/direct_match_api.dart';
import '../../core/services/secure_storage_service.dart';

class DirectMatchProvider with ChangeNotifier {
  final DirectMatchApi _api;
  final SecureStorageService _storage;

  List<Map<String, dynamic>> _matches = [];
  bool _loading = false;
  String? _error;

  DirectMatchProvider({
    required DirectMatchApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  // Getters
  List<Map<String, dynamic>> get matches => _matches;
  bool get loading => _loading;
  String? get error => _error;

  // Fetch matches
  Future<void> fetchMatches() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _matches = await _api.fetchMatches(token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Accept match
  Future<bool> acceptMatch(String matchId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final success = await _api.accept(matchId, token: token);
      if (success) {
        _matches.removeWhere((m) => m['id'] == matchId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reject match
  Future<bool> rejectMatch(String matchId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final success = await _api.reject(matchId, token: token);
      if (success) {
        _matches.removeWhere((m) => m['id'] == matchId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
