import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/chat_notification_provider.dart';
import '../../core/router/route_names.dart';
import '../../core/services/app_services.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/theme/app_theme.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage =
          Provider.of<SecureStorageService>(context, listen: false);
      final api =
          Provider.of<AppServices>(context, listen: false).notificationApi;
      final token = await storage.readToken();
      final items = await api.getNotifications(token: token, limit: 50);
      if (mounted) setState(() => _notifications = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final storage =
        Provider.of<SecureStorageService>(context, listen: false);
    final api =
        Provider.of<AppServices>(context, listen: false).notificationApi;
    final chatNotif =
        Provider.of<ChatNotificationProvider>(context, listen: false);
    try {
      final token = await storage.readToken();
      await api.markAllAsRead(token: token);
      if (mounted) {
        setState(() {
          _notifications =
              _notifications.map((n) => {...n, 'is_read': true}).toList();
        });
      }
    } catch (_) {}
    chatNotif.markAllRead();
  }

  Future<void> _markRead(String id) async {
    final storage =
        Provider.of<SecureStorageService>(context, listen: false);
    final api =
        Provider.of<AppServices>(context, listen: false).notificationApi;
    try {
      final token = await storage.readToken();
      await api.markAsRead([id], token: token);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            if (n['id']?.toString() == id) return {...n, 'is_read': true};
            return n;
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai semua dibaca'),
            ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 18),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation,
                size: 40, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Gagal memuat notifikasi'),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    final chatNotif =
        Provider.of<ChatNotificationProvider>(context, listen: false);
    final inApp = chatNotif.notifications;

    if (_notifications.isEmpty && inApp.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.bellSlash,
                size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada notifikasi',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'Notifikasi pesan dan aktivitas akan muncul di sini.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // In-app chat notifications
          if (inApp.isNotEmpty) ...[
            _SectionLabel(label: 'Pesan Baru'),
            ...inApp.map((n) => _ChatNotifTile(
                  notification: n,
                  onTap: () => _openChat(context, n),
                )),
            const Divider(height: 24),
          ],

          // Backend notifications
          if (_notifications.isNotEmpty) ...[
            _SectionLabel(label: 'Aktivitas'),
            ..._notifications.map((n) => _BackendNotifTile(
                  notification: n,
                  onTap: () async {
                    final id = n['id']?.toString() ?? '';
                    if (n['is_read'] != true && id.isNotEmpty) {
                      await _markRead(id);
                    }
                    if (mounted) _navigateFromNotif(context, n);
                  },
                )),
          ],
        ],
      ),
    );
  }

  void _openChat(
      BuildContext context, Map<String, dynamic> notification) {
    final chatId = (notification['chat_id'] ?? '').toString();
    Provider.of<ChatNotificationProvider>(context, listen: false)
        .markRead(chatId);

    if (chatId.startsWith('direct:')) {
      Navigator.pushNamed(context, RouteNames.directChat, arguments: {
        'matchId': chatId.replaceFirst('direct:', ''),
        'partnerName': (notification['chat_name'] ?? 'Runner').toString(),
      });
    } else if (chatId.startsWith('group:')) {
      Navigator.pushNamed(context, RouteNames.groupChat, arguments: {
        'groupId': chatId.replaceFirst('group:', ''),
        'groupName': (notification['chat_name'] ?? 'Grup').toString(),
        'myRole': '',
      });
    }
  }

  void _navigateFromNotif(
      BuildContext context, Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString();
    final refType = (n['ref_type'] ?? '').toString();
    final refId = (n['ref_id'] ?? '').toString();

    // Chat messages
    if (type == 'direct_message' && refId.isNotEmpty) {
      Navigator.pushNamed(context, RouteNames.directChat,
          arguments: {'matchId': refId, 'partnerName': ''});
      return;
    }
    if (type == 'group_message' && refId.isNotEmpty) {
      Navigator.pushNamed(context, RouteNames.groupChat,
          arguments: {'groupId': refId, 'groupName': '', 'myRole': ''});
      return;
    }

    // Match notifications
    if (refType == 'match') {
      if (refId.isNotEmpty && type == 'match_accepted') {
        Navigator.pushNamed(context, RouteNames.directChat,
            arguments: {'matchId': refId, 'partnerName': ''});
      } else {
        Navigator.pushNamed(context, RouteNames.directMatch);
      }
      return;
    }

    // Group notifications → group detail
    if (refType == 'group' && refId.isNotEmpty) {
      Navigator.pushNamed(context, RouteNames.groupDetail,
          arguments: {'groupId': refId, 'myRole': ''});
      return;
    }
    if (refType == 'group') {
      Navigator.pushNamed(context, RouteNames.groupRun);
      return;
    }

    // Activity notifications
    if (type == 'activity_logged') {
      Navigator.pushNamed(context, RouteNames.runActivity);
      return;
    }

    // Account / safety notifications
    if (type == 'profile_incomplete' ||
        type == 'account_verified' ||
        type == 'password_changed' ||
        type == 'email_change_request' ||
        type == 'user_reported' ||
        type == 'user_blocked' ||
        type == 'auto_suspended') {
      Navigator.pushNamed(context, RouteNames.profile);
      return;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ChatNotifTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  const _ChatNotifTile(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chatId = (notification['chat_id'] ?? '').toString();
    final chatName = (notification['chat_name'] ?? '').toString();
    final senderName = (notification['sender_name'] ?? '').toString();
    final message = (notification['message'] ?? '').toString();
    final timestamp = notification['timestamp']?.toString();
    final isDirect = chatId.startsWith('direct:');
    final iconColor =
        isDirect ? AppTheme.neonLime : Colors.blue[300]!;

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: _Avatar(
        icon: isDirect
            ? FontAwesomeIcons.userGroup
            : FontAwesomeIcons.peopleGroup,
        color: iconColor,
      ),
      title: Row(children: [
        Expanded(
          child: Text(chatName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (timestamp != null)
          Text(_fmtTime(timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
      subtitle: Text(
        senderName.isNotEmpty ? '$senderName: $message' : message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      ),
      trailing: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppTheme.neonLime),
      ),
    );
  }
}

class _BackendNotifTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  const _BackendNotifTile(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (notification['title'] ?? '').toString();
    final body = (notification['body'] ?? '').toString();
    final isRead = notification['is_read'] == true;
    final createdAt = notification['created_at']?.toString();
    final type = (notification['type'] ?? '').toString();

    final iconData = _iconFor(type);
    final iconColor = _colorFor(type);

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: _Avatar(icon: iconData, color: iconColor),
      title: Row(children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (createdAt != null)
          Text(_fmtTime(createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
      subtitle: Text(
        body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 12,
            color: isRead ? Colors.grey[500] : Colors.grey[400]),
      ),
      trailing: isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: iconColor),
            ),
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('match')) return FontAwesomeIcons.userGroup;
    if (type.contains('group')) return FontAwesomeIcons.peopleGroup;
    if (type.contains('chat') || type.contains('message')) {
      return FontAwesomeIcons.message;
    }
    if (type.contains('activity')) {
      return FontAwesomeIcons.personRunning;
    }
    if (type.contains('safety') || type.contains('report')) {
      return FontAwesomeIcons.shieldHalved;
    }
    return FontAwesomeIcons.bell;
  }

  Color _colorFor(String type) {
    if (type.contains('match')) return AppTheme.neonLime;
    if (type.contains('group')) return Colors.blue[300]!;
    if (type.contains('chat') || type.contains('message')) {
      return Colors.teal[300]!;
    }
    if (type.contains('activity')) {
      return Colors.orange[300]!;
    }
    if (type.contains('safety')) return Colors.red[300]!;
    return Colors.grey[400]!;
  }
}

class _Avatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Avatar({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Center(child: FaIcon(icon, size: 18, color: color)),
    );
  }
}

String _fmtTime(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month]}';
  } catch (_) {
    return '';
  }
}
