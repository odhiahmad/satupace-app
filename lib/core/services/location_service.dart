import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check and request location permission. Returns the current permission status.
  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[LocationService] current permission: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[LocationService] after request: $permission');
    }

    return permission;
  }

  /// Returns a human-readable error if location can't be obtained, or null if OK.
  Future<String?> diagnose() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services (GPS) are disabled. Please enable them in Settings.';
    }

    final permission = await checkAndRequestPermission();
    if (permission == LocationPermission.denied) {
      return 'Location permission denied. Please grant permission.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location permission permanently denied. Please enable it in app Settings.';
    }

    return null; // all good
  }

  Future<Position?> getCurrentPosition({LocationAccuracy accuracy = LocationAccuracy.high}) async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS/location service is disabled');
        return null;
      }

      final permission = await checkAndRequestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] permission denied: $permission');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
      debugPrint('[LocationService] got position: ${pos.latitude}, ${pos.longitude}');
      return pos;
    } catch (e) {
      debugPrint('[LocationService] error: $e');
      return null;
    }
  }
}
