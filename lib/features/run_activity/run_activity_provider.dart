import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/run_activity_api.dart';
import '../../core/models/entities.dart';
import '../../core/services/health_service.dart';
import '../../core/services/secure_storage_service.dart';

const _kLastHealthSync = 'last_health_sync';

class RunActivityProvider extends ChangeNotifier {
  final RunActivityApi _api;
  final HealthService _healthService;
  final SecureStorageService _storage;

  RunActivityProvider({
    required RunActivityApi api,
    required HealthService healthService,
    required SecureStorageService storage,
  })  : _api = api,
        _healthService = healthService,
        _storage = storage;

  List<RunActivityEntity> _activities = [];
  bool _loading = false;
  bool _syncing = false;
  String? _error;
  String? _syncMessage;
  DateTime? _lastSyncTime;

  // ── Weekly stats ─────────────────────────────────────────────────
  double weeklyDistanceKm = 0;
  int weeklyRuns = 0;
  double weeklyAvgPace = 0;

  // ── Monthly stats ────────────────────────────────────────────────
  double monthlyDistanceKm = 0;
  int monthlyRuns = 0;
  double monthlyAvgPace = 0;

  // ── Getters ──────────────────────────────────────────────────────
  List<RunActivityEntity> get activities => List.unmodifiable(_activities);
  bool get loading => _loading;
  bool get syncing => _syncing;
  String? get error => _error;
  String? get syncMessage => _syncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get healthSupported => _healthService.isSupported;

  // ── Load activities from backend ─────────────────────────────────
  Future<void> loadActivities(String userId) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      final raw = await _api.getUserActivities(userId, token: token);
      _activities = raw
          .map((e) => RunActivityEntity.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _computeStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Save manual activity ─────────────────────────────────────────
  Future<bool> saveManualActivity({
    required double distanceKm,
    required int durationSeconds,
    required double avgPace,
    int calories = 0,
  }) async {
    try {
      final token = await _storage.readToken();
      await _api.createActivity(
        {
          'distance': distanceKm,
          'duration': durationSeconds,
          'avg_pace': avgPace,
          'calories': calories,
          'source': 'manual',
        },
        token: token,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Sync from health ─────────────────────────────────────────────
  /// Reads running workouts from Apple Health / Google Health Connect
  /// and saves any new ones to the backend.
  /// Returns the number of newly synced activities.
  Future<int> syncFromHealth({required String userId}) async {
    if (_syncing) return 0;
    _syncing = true;
    _syncMessage = null;
    _error = null;
    notifyListeners();

    int count = 0;
    try {
      // Request permissions
      final granted = await _healthService.requestPermissions();
      if (!granted) {
        _syncMessage = 'Izin Health tidak diberikan.';
        return 0;
      }

      // Read last sync time
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt(_kLastHealthSync);
      final since = lastSyncMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
          : null;

      // Fetch workouts from device
      final workouts =
          await _healthService.fetchRunningWorkouts(since: since);

      if (workouts.isEmpty) {
        _syncMessage = 'Tidak ada aktivitas baru untuk disinkronkan.';
        return 0;
      }

      // Save each workout to backend
      final token = await _storage.readToken();
      final source = _healthService.source;

      for (final w in workouts) {
        try {
          await _api.createActivity(
            {
              'distance': w['distance_km'],
              'duration': w['duration_seconds'],
              'avg_pace': w['avg_pace'],
              'calories': w['calories'],
              'source': source,
            },
            token: token,
          );
          count++;
        } catch (e) {
          debugPrint('[Health Sync] Failed to save workout: $e');
        }
      }

      // Update last sync time
      final now = DateTime.now();
      await prefs.setInt(_kLastHealthSync, now.millisecondsSinceEpoch);
      _lastSyncTime = now;

      // Reload activities + recompute stats
      await loadActivities(userId);

      _syncMessage = count > 0
          ? '$count aktivitas berhasil disinkronkan.'
          : 'Tidak ada aktivitas baru.';
    } catch (e) {
      _error = e.toString();
      _syncMessage = 'Gagal sinkronisasi: $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }

    return count;
  }

  // ── Load last sync time from prefs ───────────────────────────────
  Future<void> loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastHealthSync);
    if (ms != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(ms);
      notifyListeners();
    }
  }

  // ── Internal: compute weekly / monthly stats ─────────────────────
  void _computeStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final monthStart = DateTime(now.year, now.month, 1);

    double wDist = 0, mDist = 0;
    double wPaceSum = 0, mPaceSum = 0;
    int wCount = 0, mCount = 0;

    for (final a in _activities) {
      if (a.createdAt == null) continue;
      final dt = DateTime.tryParse(a.createdAt!);
      if (dt == null) continue;

      final isThisWeek = !dt.isBefore(weekStartDay);
      final isThisMonth = !dt.isBefore(monthStart);

      if (isThisWeek) {
        wDist += a.distance;
        if (a.avgPace > 0) wPaceSum += a.avgPace;
        wCount++;
      }
      if (isThisMonth) {
        mDist += a.distance;
        if (a.avgPace > 0) mPaceSum += a.avgPace;
        mCount++;
      }
    }

    weeklyDistanceKm = double.parse(wDist.toStringAsFixed(2));
    weeklyRuns = wCount;
    weeklyAvgPace =
        wCount > 0 ? double.parse((wPaceSum / wCount).toStringAsFixed(2)) : 0;

    monthlyDistanceKm = double.parse(mDist.toStringAsFixed(2));
    monthlyRuns = mCount;
    monthlyAvgPace =
        mCount > 0 ? double.parse((mPaceSum / mCount).toStringAsFixed(2)) : 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
