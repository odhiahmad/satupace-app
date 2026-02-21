import 'package:flutter/material.dart';
import '../../core/api/strava_api.dart';
import '../../core/models/entities.dart';
import '../../core/services/secure_storage_service.dart';

class StravaProvider with ChangeNotifier {
  final StravaApi _api;
  final SecureStorageService _storage;

  StravaConnectionEntity? _connection;
  StravaStatsEntity? _stats;
  List<StravaActivityEntity> _activities = [];
  StravaSyncSummaryEntity? _lastSyncSummary;
  bool _loading = false;
  bool _syncing = false;
  String? _error;

  StravaProvider({
    required StravaApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  // --- Getters ---
  StravaConnectionEntity? get connection => _connection;
  StravaStatsEntity? get stats => _stats;
  List<StravaActivityEntity> get activities => _activities;
  StravaSyncSummaryEntity? get lastSyncSummary => _lastSyncSummary;
  bool get loading => _loading;
  bool get syncing => _syncing;
  String? get error => _error;
  bool get isConnected => _connection?.isConnected == true;

  /// Avg pace from Strava stats (min/km).
  double? get avgPace {
    if (_stats != null && _stats!.avgPace > 0) return _stats!.avgPace;
    return null;
  }

  /// Total runs count.
  int get totalRuns => _stats?.totalActivities ?? 0;

  /// Total distance in km.
  double get totalDistanceKm => _stats?.totalDistanceKm ?? 0;

  /// Total duration in seconds.
  int get totalDuration => _stats?.totalDuration ?? 0;

  // --- Get auth URL ---
  Future<String?> getAuthUrl() async {
    _error = null;
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final url = await _api.getAuthUrl(token: token);
      return url.isNotEmpty ? url : null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // --- Send OAuth callback ---
  Future<bool> sendCallback(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      await _api.callback(code, token: token);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Fetch connection ---
  Future<void> fetchConnection() async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final raw = await _api.getConnection(token: token);
      if (raw.isNotEmpty) {
        _connection = StravaConnectionEntity.fromJson(raw);
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // --- Fetch stats ---
  Future<void> fetchStats() async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final raw = await _api.getStats(token: token);
      if (raw.isNotEmpty) {
        _stats = StravaStatsEntity.fromJson(raw);
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // --- Fetch activities ---
  Future<void> fetchActivities({int limit = 20}) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final raw = await _api.getActivities(limit: limit, token: token);
      _activities =
          raw.map((a) => StravaActivityEntity.fromJson(a)).toList();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // --- Sync from Strava ---
  Future<bool> syncActivities() async {
    _syncing = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final raw = await _api.sync(token: token);
      if (raw.isNotEmpty) {
        _lastSyncSummary = StravaSyncSummaryEntity.fromJson(raw);
      }
      // Refresh stats & activities after sync
      await fetchStats();
      await fetchActivities();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  // --- Disconnect ---
  Future<bool> disconnect() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token tidak ditemukan');
      final ok = await _api.disconnect(token: token);
      if (ok) {
        _connection = null;
        _stats = null;
        _activities = [];
        _lastSyncSummary = null;
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- Load all ---
  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    await fetchConnection();
    if (isConnected) {
      await fetchStats();
      await fetchActivities();
    }

    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
