import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition({LocationAccuracy accuracy = LocationAccuracy.high}) async {
    try {
      final ok = await requestPermission();
      if (!ok) return null;
      return await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: accuracy));
    } catch (_) {
      return null;
    }
  }
}
