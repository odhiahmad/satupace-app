import '../api/api_service.dart';

class ExploreApi {
  final ApiService api;

  ExploreApi({ApiService? api}) : api = api ?? ApiService();

  /// Explore nearby runners.
  /// GET /explore/runners (JWT required)
  Future<List<Map<String, dynamic>>> getRunners({
    required double latitude,
    required double longitude,
    double? radiusKm,
    double? minPace,
    double? maxPace,
    String? preferredTime,
    String? gender,
    bool? womenOnly,
    int? limit,
    bool? excludeMatched,
    String? token,
  }) async {
    final params = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (radiusKm != null) params['radius_km'] = radiusKm.toString();
    if (minPace != null) params['min_pace'] = minPace.toString();
    if (maxPace != null) params['max_pace'] = maxPace.toString();
    if (preferredTime != null) params['preferred_time'] = preferredTime;
    if (gender != null) params['gender'] = gender;
    if (womenOnly != null) params['women_only'] = womenOnly.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (excludeMatched != null) params['exclude_matched'] = excludeMatched.toString();

    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    try {
      final res = await api.get('/explore/runners?$query', token: token);
      if (res is List) {
        return res
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  /// Explore nearby run groups.
  /// GET /explore/groups (JWT required)
  Future<List<Map<String, dynamic>>> getGroups({
    required double latitude,
    required double longitude,
    double? radiusKm,
    double? minPace,
    double? maxPace,
    bool? womenOnly,
    String? status,
    int? limit,
    String? token,
  }) async {
    final params = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (radiusKm != null) params['radius_km'] = radiusKm.toString();
    if (minPace != null) params['min_pace'] = minPace.toString();
    if (maxPace != null) params['max_pace'] = maxPace.toString();
    if (womenOnly != null) params['women_only'] = womenOnly.toString();
    if (status != null) params['status'] = status;
    if (limit != null) params['limit'] = limit.toString();

    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    try {
      final res = await api.get('/explore/groups?$query', token: token);
      if (res is List) {
        return res
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }
}
