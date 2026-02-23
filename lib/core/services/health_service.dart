import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Service to read running workout data from Apple Health (iOS) or
/// Google Health Connect (Android).
class HealthService {
  static final HealthService _instance = HealthService._internal();
  HealthService._internal();
  factory HealthService() => _instance;

  static const _workoutTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// Returns true if health permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      Health().configure();
      final granted = await Health().requestAuthorization(
        _workoutTypes,
        permissions: _permissions,
      );
      return granted;
    } catch (e) {
      debugPrint('[Health] requestPermissions error: $e');
      return false;
    }
  }

  /// Returns true if the platform supports health data reading.
  bool get isSupported => Platform.isIOS || Platform.isAndroid;

  /// Source string based on platform.
  String get source => Platform.isIOS ? 'apple_health' : 'google_health';

  /// Fetch running workouts from [since] until now.
  /// Returns a list of maps ready to POST to the backend:
  ///   { distance_km, duration_seconds, avg_pace, calories, started_at }
  Future<List<Map<String, dynamic>>> fetchRunningWorkouts({
    DateTime? since,
  }) async {
    if (!isSupported) return [];

    final end = DateTime.now();
    final start = since ?? end.subtract(const Duration(days: 90));

    try {
      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );

      final workouts = <Map<String, dynamic>>[];

      for (final point in data) {
        final val = point.value;
        if (val is! WorkoutHealthValue) continue;
        if (val.workoutActivityType != HealthWorkoutActivityType.RUNNING) {
          continue;
        }

        final durationSec =
            point.dateTo.difference(point.dateFrom).inSeconds;
        if (durationSec <= 0) continue;

        final distanceM = val.totalDistance ?? 0;
        final distanceKm = distanceM / 1000;
        if (distanceKm <= 0) continue;

        final paceMinPerKm = (durationSec / 60.0) / distanceKm;

        workouts.add({
          'distance_km': double.parse(distanceKm.toStringAsFixed(3)),
          'duration_seconds': durationSec,
          'avg_pace': double.parse(paceMinPerKm.toStringAsFixed(2)),
          'calories': (val.totalEnergyBurned ?? 0).round(),
          'started_at': point.dateFrom.toIso8601String(),
        });
      }

      return workouts;
    } catch (e) {
      debugPrint('[Health] fetchRunningWorkouts error: $e');
      return [];
    }
  }
}
