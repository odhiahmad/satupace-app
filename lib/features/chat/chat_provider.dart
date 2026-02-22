import 'package:flutter/material.dart';
import '../../core/api/chat_api.dart';
import '../../core/services/secure_storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatApi _api;
  final SecureStorageService _storage;

  List<Map<String, dynamic>> _chats = [];
  final Map<String, List<Map<String, dynamic>>> _threads = {};
  bool _loading = false;
  String? _error;

  ChatProvider({
    required ChatApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  // Getters
  List<Map<String, dynamic>> get chats => _chats;
  bool get loading => _loading;
  String? get error => _error;

  List<Map<String, dynamic>> getThreadMessages(String chatId) {
    return _threads[chatId] ?? [];
  }

  // Fetch all chats
  Future<void> fetchChats() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _chats = await _api.fetchChats(token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Fetch thread messages
  Future<void> fetchThread(String chatId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      _threads[chatId] = await _api.fetchThread(chatId, token: token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Send message
  Future<bool> sendMessage(String chatId, String message) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');

      await _api.sendMessage(chatId, message, token: token);

      // Add message to local thread
      _threads[chatId] ??= [];
      _threads[chatId]!.add({
        'from': 'me',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear thread
  void clearThread(String chatId) {
    _threads.remove(chatId);
    notifyListeners();
  }
}
