import '../api/api_service.dart';

class ChatApi {
  final ApiService api;

  ChatApi({ApiService? api}) : api = api ?? ApiService();

  /// Get direct chat messages for a match.
  /// GET /chats/direct/:matchId (JWT required)
  Future<List<Map<String, dynamic>>> getDirectChat(String matchId, {String? token}) async {
    try {
      final res = await api.get('/chats/direct/$matchId', token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeMessage(item is Map ? Map<String, dynamic>.from(item) : const {}))
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
  }

  /// Get group chat messages.
  /// GET /chats/group/:groupId (JWT required)
  Future<List<Map<String, dynamic>>> getGroupChat(String groupId, {String? token}) async {
    try {
      final res = await api.get('/chats/group/$groupId', token: token);
      if (res is List) {
        return res
            .map((item) => _normalizeMessage(item is Map ? Map<String, dynamic>.from(item) : const {}))
            .toList();
      }
    } catch (_) {
      rethrow;
    }
    return [];
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

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> input) {
    final sender = (input['sender_id'] ?? input['from'] ?? 'other').toString();
    return {
      'id': (input['id'] ?? '').toString(),
      'sender_id': sender,
      'message': (input['message'] ?? input['content'] ?? '').toString(),
      'created_at': input['created_at']?.toString(),
      'from': sender == 'me' ? 'me' : 'other',
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
