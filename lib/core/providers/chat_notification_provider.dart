import 'package:flutter/material.dart';

/// Lightweight in-app notification tracker for chat messages.
/// Chat pages call [addNotification] when a foreign message arrives,
/// and [markRead] when the user opens that chat.
class ChatNotificationProvider with ChangeNotifier {
  final Map<String, int> _unreadCounts = {};
  final List<Map<String, dynamic>> _notifications = [];

  static const _maxNotifications = 50;

  /// Total unread across all chats
  int get totalUnread => _unreadCounts.values.fold(0, (a, b) => a + b);

  /// Unread from direct matches (keys start with "direct:")
  int get matchUnread => _unreadCounts.entries
      .where((e) => e.key.startsWith('direct:'))
      .fold(0, (a, e) => a + e.value);

  /// Unread from group chats (keys start with "group:")
  int get groupUnread => _unreadCounts.entries
      .where((e) => e.key.startsWith('group:'))
      .fold(0, (a, e) => a + e.value);

  /// Unread count for a specific chat
  int unreadFor(String chatId) => _unreadCounts[chatId] ?? 0;

  /// Recent notifications list (newest first, max [_maxNotifications])
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);

  /// Called by a chat page when a message from someone else arrives.
  /// [chatId] format: "direct:matchId" or "group:groupId"
  void addNotification({
    required String chatId,
    required String chatName,
    required String senderName,
    required String message,
  }) {
    _unreadCounts[chatId] = (_unreadCounts[chatId] ?? 0) + 1;

    _notifications.insert(0, {
      'chat_id': chatId,
      'chat_name': chatName,
      'sender_name': senderName,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_notifications.length > _maxNotifications) {
      _notifications.removeLast();
    }

    notifyListeners();
  }

  /// Mark a chat as fully read (clears its unread count).
  void markRead(String chatId) {
    if (_unreadCounts.containsKey(chatId)) {
      _unreadCounts.remove(chatId);
      notifyListeners();
    }
  }

  /// Clear all unread counts (e.g., when user views notification page).
  void markAllRead() {
    if (_unreadCounts.isNotEmpty) {
      _unreadCounts.clear();
      notifyListeners();
    }
  }

  /// Clear everything on logout.
  void clearAll() {
    _notifications.clear();
    _unreadCounts.clear();
    notifyListeners();
  }
}
