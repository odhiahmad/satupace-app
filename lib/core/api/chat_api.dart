import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

class ChatApi {
  final ApiService api;

  ChatApi({ApiService? api}) : api = api ?? ApiService();

  /// Get direct chat messages for a match.
  /// GET /chats/direct/:matchId (JWT required)
  Future<List<Map<String, dynamic>>> getDirectChat(String matchId, {String? token}) async {
    try {
      final res = await api.get('/chats/direct/$matchId', token: token);
      debugPrint('[ChatApi] getDirectChat raw type=${res.runtimeType}');
      return _extractList(res);
    } catch (e) {
      rethrow;
    }
  }

  /// Get group chat messages.
  /// GET /chats/group/:groupId (JWT required)
  Future<List<Map<String, dynamic>>> getGroupChat(String groupId, {String? token}) async {
    try {
      final res = await api.get('/chats/group/$groupId', token: token);
      debugPrint('[ChatApi] getGroupChat raw type=${res.runtimeType} value=$res');
      return _extractList(res);
    } catch (e) {
      debugPrint('[ChatApi] getGroupChat error: $e');
      rethrow;
    }
  }

  /// Delete a chat message.
  /// DELETE /chats/messages/:messageId (JWT required)
  Future<bool> deleteMessage(String messageId, {String? token}) async {
    try {
      await api.delete('/chats/messages/$messageId', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get the WebSocket URL for direct chat.
  /// ws://host/ws/direct/:matchId
  String getDirectWebSocketUrl(String matchId) {
    final wsBase = api.baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws/direct/$matchId';
  }

  /// Get the WebSocket URL for group chat.
  /// ws://host/ws/group/:groupId
  String getGroupWebSocketUrl(String groupId) {
    final wsBase = api.baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws/group/$groupId';
  }

  /// Extract a list of messages from various possible response shapes:
  /// - List directly
  /// - Map with key 'messages', 'data', or 'items' containing a List
  List<Map<String, dynamic>> _extractList(dynamic res) {
    List<dynamic>? list;
    if (res is List) {
      list = res;
    } else if (res is Map) {
      // Try common wrapper keys
      for (final key in ['messages', 'data', 'items', 'chats']) {
        if (res[key] is List) {
          list = res[key] as List;
          break;
        }
      }
    }
    if (list == null) return [];
    return list
        .map((item) => _normalizeMessage(item is Map ? Map<String, dynamic>.from(item) : const {}))
        .toList();
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> input) {
    final sender = (input['sender_id'] ?? input['from'] ?? '').toString();
    return {
      'id': (input['id'] ?? '').toString(),
      'sender_id': sender,
      'sender_name': (input['sender_name'] ?? input['name'] ?? '').toString(),
      'message': (input['message'] ?? input['content'] ?? '').toString(),
      'created_at': input['created_at']?.toString(),
    };
  }

  // Backward compatibility
  Future<List<Map<String, dynamic>>> fetchChats({String? token}) async {
    // No direct equivalent — caller should use getDirectChat or getGroupChat
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchThread(String chatId, {String? token}) async {
    return getDirectChat(chatId, token: token);
  }

  Future<void> sendMessage(String chatId, String message, {String? token}) async {
    // Messages are sent via WebSocket, not REST
    // This is kept for backward compatibility; will be a no-op
  }
}
