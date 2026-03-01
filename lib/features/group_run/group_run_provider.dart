import 'package:flutter/material.dart';
import '../../core/api/group_run_api.dart';
import '../../core/api/explore_api.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/location_service.dart';

class GroupRunProvider with ChangeNotifier {
  final GroupRunApi _api;
  final ExploreApi _exploreApi;
  final SecureStorageService _storage;
  final LocationService _locationService;

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = false;
  bool _loadingMy = false;
  bool _loadingSchedules = false;
  bool _saving = false;
  String? _error;

  // Active filters
  Map<String, String> _filters = {};

  GroupRunProvider({
    required GroupRunApi api,
    required ExploreApi exploreApi,
    required SecureStorageService storage,
    required LocationService locationService,
  })  : _api = api,
        _exploreApi = exploreApi,
        _storage = storage,
        _locationService = locationService;

  // Getters
  List<Map<String, dynamic>> get groups => _groups;
  List<Map<String, dynamic>> get myGroups => _myGroups;
  List<Map<String, dynamic>> get schedules => _schedules;
  bool get loading => _loading;
  bool get loadingMy => _loadingMy;
  bool get loadingSchedules => _loadingSchedules;
  bool get saving => _saving;
  String? get error => _error;
  Map<String, String> get filters => _filters;

  // Set filters and re-fetch
  Future<void> applyFilters(Map<String, String> newFilters) async {
    _filters = newFilters;
    notifyListeners();
    await fetchExploreGroups();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
    fetchExploreGroups();
  }

  // Fetch available groups (with filters and default location)
  Future<void> fetchGroups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      // Get current location and add to filters if not already present
      final filtersWithLocation = Map<String, String>.from(_filters);
      
      if (!filtersWithLocation.containsKey('latitude') && 
          !filtersWithLocation.containsKey('longitude')) {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          filtersWithLocation['latitude'] = position.latitude.toString();
          filtersWithLocation['longitude'] = position.longitude.toString();
        }
      }

      // Set default radius to 20 km if not specified
      if (!filtersWithLocation.containsKey('radius_km')) {
        filtersWithLocation['radius_km'] = '20';
      }

      _groups = await _api.fetchGroups(token: token, filters: filtersWithLocation);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Fetch explore groups using current location + active filters
  Future<void> fetchExploreGroups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      // Use lat/lng from filters if provided, otherwise fall back to GPS
      double? latitude = double.tryParse(_filters['latitude'] ?? '');
      double? longitude = double.tryParse(_filters['longitude'] ?? '');

      if (latitude == null || longitude == null) {
        final position = await _locationService.getCurrentPosition();
        if (position == null) {
          throw Exception('Tidak dapat mendapatkan lokasi saat ini');
        }
        latitude = position.latitude;
        longitude = position.longitude;
      }

      // Parse optional filter params
      final radiusKm = double.tryParse(_filters['radius_km'] ?? '') ?? 20;
      final minPace = double.tryParse(_filters['min_pace'] ?? '');
      final maxPace = double.tryParse(_filters['max_pace'] ?? '');
      final womenOnly = _filters['women_only'] == 'true' ? true : null;
      final status = (_filters['status']?.isNotEmpty == true) ? _filters['status'] : null;

      // Persist resolved values back into _filters so the filter sheet shows them
      _filters['latitude'] = latitude.toString();
      _filters['longitude'] = longitude.toString();
      _filters['radius_km'] ??= radiusKm.toStringAsFixed(0);

      _groups = await _exploreApi.getGroups(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        minPace: minPace,
        maxPace: maxPace,
        womenOnly: womenOnly,
        status: status,
        token: token,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Fetch groups created by current user
  Future<void> fetchMyGroups() async {
    _loadingMy = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _myGroups = await _api.fetchMyGroups(token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loadingMy = false;
      notifyListeners();
    }
  }

  // Create group, lalu buat schedules jika ada
  Future<bool> createGroup(
    Map<String, dynamic> data, {
    List<Map<String, dynamic>>? schedules,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final result = await _api.createGroup(data, token: token);
      final groupId = result['id']?.toString();

      if (groupId != null && groupId.isNotEmpty && schedules != null) {
        for (final sch in schedules) {
          await _api.createSchedule(groupId, sch, token: token);
        }
      }

      await fetchExploreGroups();
      await fetchMyGroups();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // Update group
  Future<bool> updateGroup(String groupId, Map<String, dynamic> data) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final ok = await _api.updateGroup(groupId, data, token: token);
      if (ok) {
        await fetchExploreGroups();
        await fetchMyGroups();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // Delete group
  Future<bool> deleteGroup(String groupId) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final ok = await _api.deleteGroup(groupId, token: token);
      if (ok) {
        _groups.removeWhere((g) => g['id'] == groupId);
        _myGroups.removeWhere((g) => g['id'] == groupId);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // Join group
  Future<bool> joinGroup(String groupId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      final success = await _api.join(groupId, token: token);
      if (success) await fetchExploreGroups();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get group by ID
  Future<Map<String, dynamic>> getGroupById(String groupId) async {
    final token = await _storage.readToken();
    if (token == null) throw Exception('Token not found');
    return await _api.getGroupById(groupId, token: token);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Schedule methods ────────────────────────────────

  Future<void> fetchSchedules(String groupId) async {
    _loadingSchedules = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      _schedules = await _api.getSchedules(groupId, token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loadingSchedules = false;
      notifyListeners();
    }
  }

  Future<bool> createSchedule(String groupId, int dayOfWeek, String startTime) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final result = await _api.createSchedule(
        groupId,
        {'day_of_week': dayOfWeek, 'start_time': startTime},
        token: token,
      );
      if (result.isNotEmpty) {
        await fetchSchedules(groupId);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule(
    String groupId,
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final ok = await _api.updateSchedule(scheduleId, data, token: token);
      if (ok) await fetchSchedules(groupId);
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSchedule(String groupId, String scheduleId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final ok = await _api.deleteSchedule(scheduleId, token: token);
      if (ok) {
        _schedules.removeWhere((s) => s['id'] == scheduleId);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
