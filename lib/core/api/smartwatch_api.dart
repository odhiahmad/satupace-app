import 'dart:convert';
import '../api/api_service.dart';

class SmartwatchApi {
  final ApiService api;

  SmartwatchApi({ApiService? api}) : api = api ?? ApiService();

  /// Register a smartwatch device.
  /// POST /smartwatch/devices (JWT required)
  /// Body: {device_name, device_type, device_id}
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String deviceType,
    required String deviceId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'device_name': deviceName,
      'device_type': deviceType,
      'device_id': deviceId,
    };
    final res = await api.post('/smartwatch/devices', token: token, body: jsonEncode(body));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get registered smartwatch devices.
  /// GET /smartwatch/devices (JWT required)
  Future<List<Map<String, dynamic>>> getDevices({String? token}) async {
    try {
      final res = await api.get('/smartwatch/devices', token: token);
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

  /// Delete a smartwatch device.
  /// DELETE /smartwatch/devices/:id (JWT required)
  Future<bool> deleteDevice(String id, {String? token}) async {
    try {
      await api.delete('/smartwatch/devices/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get stats for a smartwatch device.
  /// GET /smartwatch/devices/:id/stats (JWT required)
  Future<Map<String, dynamic>> getDeviceStats(String id, {String? token}) async {
    final res = await api.get('/smartwatch/devices/$id/stats', token: token);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Sync smartwatch data.
  /// POST /smartwatch/sync (JWT required)
  /// Body: {device_id, distance, duration, heart_rate_avg, heart_rate_max, calories, steps, synced_at}
  Future<Map<String, dynamic>> syncData(Map<String, dynamic> data, {String? token}) async {
    final res = await api.post('/smartwatch/sync', token: token, body: jsonEncode(data));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Batch sync smartwatch data.
  /// POST /smartwatch/sync/batch (JWT required)
  Future<Map<String, dynamic>> syncBatch(List<Map<String, dynamic>> data, {String? token}) async {
    final res = await api.post('/smartwatch/sync/batch', token: token, body: jsonEncode(data));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Get sync history.
  /// GET /smartwatch/sync/history (JWT required)
  Future<List<Map<String, dynamic>>> getSyncHistory({String? token}) async {
    try {
      final res = await api.get('/smartwatch/sync/history', token: token);
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
