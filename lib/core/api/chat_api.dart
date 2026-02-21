import 'dart:convert';
import '../api/api_service.dart';

class ChatApi {
  final ApiService api;

  ChatApi({ApiService? api}) : api = api ?? ApiService();

  Future<List<Map<String, dynamic>>> fetchChats({String? token}) async {
    try {
      final res = await api.get('/chats', token: token);
      if (res is List) return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      // fallback mock data
      return List.generate(
        6,
        (i) => {
          'id': 'chat_$i',
          'name': 'Runner ${i + 1}',
          'last_message': 'See you at 6am',
        },
      );
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchThread(String chatId, {String? token}) async {
    try {
      final res = await api.get('/chats/$chatId/messages', token: token);
      if (res is List) return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [
        {'from': 'other', 'message': 'Hi, are you joining?'},
        {'from': 'me', 'message': 'Yes, see you there!'},
      ];
    }
    return [];
  }

  Future<void> sendMessage(String chatId, String message, {String? token}) async {
    try {
      await api.post('/chats/$chatId/messages', token: token, body: jsonEncode({'message': message}));
    } catch (_) {
      // ignore in UI for now
    }
  }
}
