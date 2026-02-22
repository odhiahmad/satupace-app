import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/chat_notification_provider.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_theme.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Consumer<ChatNotificationProvider>(
            builder: (_, notif, _) {
              if (notif.totalUnread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: notif.markAllRead,
                child: const Text('Tandai semua dibaca'),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatNotificationProvider>(
        builder: (context, notif, _) {
          if (notif.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.bellSlash,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Notifikasi pesan dari match dan grup akan muncul di sini.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notif.notifications.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final n = notif.notifications[i];
              return _NotificationTile(
                notification: n,
                onTap: () => _openChat(context, n, notif),
              );
            },
          );
        },
      ),
    );
  }

  void _openChat(
    BuildContext context,
    Map<String, dynamic> notification,
    ChatNotificationProvider notif,
  ) {
    final chatId = (notification['chat_id'] ?? '').toString();
    notif.markRead(chatId);

    if (chatId.startsWith('direct:')) {
      final matchId = chatId.replaceFirst('direct:', '');
      final partnerName =
          (notification['chat_name'] ?? 'Runner').toString();
      Navigator.pushNamed(
        context,
        RouteNames.directChat,
        arguments: {'matchId': matchId, 'partnerName': partnerName},
      );
    } else if (chatId.startsWith('group:')) {
      final groupId = chatId.replaceFirst('group:', '');
      final groupName =
          (notification['chat_name'] ?? 'Grup').toString();
      Navigator.pushNamed(
        context,
        RouteNames.groupChat,
        arguments: {
          'groupId': groupId,
          'groupName': groupName,
          'myRole': '',
        },
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chatId = (notification['chat_id'] ?? '').toString();
    final chatName = (notification['chat_name'] ?? '').toString();
    final senderName = (notification['sender_name'] ?? '').toString();
    final message = (notification['message'] ?? '').toString();
    final timestamp = notification['timestamp']?.toString();

    final isDirect = chatId.startsWith('direct:');
    final icon =
        isDirect ? FontAwesomeIcons.userGroup : FontAwesomeIcons.peopleGroup;
    final iconColor = isDirect ? AppTheme.neonLime : Colors.blue[300]!;

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.1),
        ),
        child: Center(
          child: FaIcon(icon, size: 18, color: iconColor),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chatName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (timestamp != null)
            Text(
              _formatTime(timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
        ],
      ),
      subtitle: Text(
        senderName.isNotEmpty ? '$senderName: $message' : message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day &&
          dt.month == now.month &&
          dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month]}';
    } catch (_) {
      return '';
    }
  }
}
