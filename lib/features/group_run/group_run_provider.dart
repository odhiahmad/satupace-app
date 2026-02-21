import 'package:flutter/material.dart';
import '../../core/api/group_run_api.dart';
import '../../core/services/secure_storage_service.dart';

class GroupRunProvider with ChangeNotifier {
  final GroupRunApi _api;
  final SecureStorageService _storage;

  List<Map<String, dynamic>> _groups = [];
  final List<Map<String, dynamic>> _myGroups = [];
  bool _loading = false;
  String? _error;

  GroupRunProvider({
    required GroupRunApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  // Getters
  List<Map<String, dynamic>> get groups => _groups;
  List<Map<String, dynamic>> get myGroups => _myGroups;
  bool get loading => _loading;
  String? get error => _error;

  // Fetch available groups
  Future<void> fetchGroups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _groups = await _api.fetchGroups(token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Join group
  Future<bool> joinGroup(String groupId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final success = await _api.join(groupId, token: token);
      if (success) {
        // Move group from available to my groups
        final group = _groups.firstWhere(
          (g) => g['id'] == groupId,
          orElse: () => {},
        );
        if (group.isNotEmpty) {
          _myGroups.add(group);
          _groups.removeWhere((g) => g['id'] == groupId);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Leave group
  Future<bool> leaveGroup(String groupId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      // Assuming API has a leave method
      // For now, just remove from local list
      _myGroups.removeWhere((g) => g['id'] == groupId);
      _groups.add(_myGroups.firstWhere(
        (g) => g['id'] == groupId,
        orElse: () => {},
      ));
      notifyListeners();
      return true;
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
