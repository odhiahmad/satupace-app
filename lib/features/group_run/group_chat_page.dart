import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/route_names.dart';
import '../../core/api/chat_api.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart' as auth;
import '../../core/services/app_services.dart';
import '../../core/services/secure_storage_service.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String myRole; // 'owner', 'admin', 'member'

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.myRole,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  String? _myUserId;
  String? _myName; // cached from secure storage
  bool _wsConnected = false;

  /// IDs of messages sent by ME — ONLY ever added to, never removed.
  /// Includes both local_ placeholders AND server-confirmed IDs.
  final Set<String> _ownIds = {};

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;

  // ── Typing indicator state ─────────────────────────
  /// userId → displayName untuk user yang sedang mengetik
  final Map<String, String> _typingUsers = {};
  /// Timer per-user: auto-hapus setelah 5 detik tanpa update
  final Map<String, Timer> _typingTimers = {};
  /// Timer debounce sebelum kirim stop_typing ke server
  Timer? _sendStopTypingTimer;

  late final ChatApi _chatApi;
  late final SecureStorageService _storage;

  @override
  void initState() {
    super.initState();
    final appServices = AppServices();
    _chatApi = appServices.chatApi;
    _storage = appServices.secureStorageService;
    _init();
    _msgCtrl.addListener(_onTextChanged);
  }

  Future<void> _init() async {
    _myUserId = await _storage.readUserId();
    _myName = await _storage.readUserName();
    // Fallback: read userId from AuthProvider if secure storage returned null
    if (mounted && (_myUserId == null || _myUserId!.isEmpty)) {
      final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
      _myUserId = authProvider.userId;
      if (_myUserId != null && _myUserId!.isNotEmpty) {
        await _storage.writeUserId(_myUserId!);
      }
    }
    // Last resort: decode the JWT to extract user_id claim
    if (_myUserId == null || _myUserId!.isEmpty) {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            // Pad base64url to a multiple of 4
            var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
            switch (payload.length % 4) {
              case 2: payload += '=='; break;
              case 3: payload += '='; break;
              default: break;
            }
            final decoded = jsonDecode(
              utf8.decode(base64Decode(payload)),
            ) as Map<String, dynamic>;
            final jwtUid = decoded['user_id']?.toString() ?? decoded['sub']?.toString();
            if (jwtUid != null && jwtUid.isNotEmpty) {
              _myUserId = jwtUid;
              await _storage.writeUserId(jwtUid);
            }
          }
        } catch (e) {
          debugPrint('[CHAT] JWT decode error: $e');
        }
      }
    }
    if (mounted && (_myName == null || _myName!.isEmpty)) {
      final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
      _myName = authProvider.name;
      if (_myName != null && _myName!.isNotEmpty) {
        await _storage.writeUserName(_myName!);
      }
    }
    debugPrint('[CHAT] _myUserId=$_myUserId _myName=$_myName');
    await _loadHistory();
    _connectWs();
  }

  // ── Load chat history via REST ─────────────────────
  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _storage.readToken();
      final msgs =
          await _chatApi.getGroupChat(widget.groupId, token: token);
      debugPrint('[CHAT] Loaded ${msgs.length} history messages');
      if (mounted) {
        // Register history message IDs that belong to me in _ownIds
        for (final m in msgs) {
          final sid = (m['sender_id'] ?? '').toString();
          final id = (m['id'] ?? '').toString();
          if (_myUserId != null && sid == _myUserId && id.isNotEmpty) {
            _ownIds.add(id);
          }
        }
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── WebSocket connection ───────────────────────────
  void _connectWs() async {
    try {
      final token = await _storage.readToken();
      if (token == null) return;

      // Cancel any existing subscription before reconnecting
      await _wsSub?.cancel();
      _wsSub = null;

      final wsUrl = _chatApi.getGroupWebSocketUrl(widget.groupId);
      final uri = Uri.parse('$wsUrl?token=$token');

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      // Subscribe to stream BEFORE awaiting ready so no messages are missed
      _wsSub = channel.stream.listen(
        (data) {
          try {
            debugPrint('[WS RAW] $data');
            // Handle both String and binary (List<int>) frames
            final String raw;
            if (data is String) {
              raw = data;
            } else if (data is List<int>) {
              raw = String.fromCharCodes(data);
            } else {
              debugPrint('[WS] Unknown data type: ${data.runtimeType}');
              return;
            }
            final decoded = jsonDecode(raw);
            Map<String, dynamic>? msg;

            if (decoded is Map) {
              msg = Map<String, dynamic>.from(decoded);
              // Handle nested format: {"type": "message", "data": {...}}
              if (msg.containsKey('data') && msg['data'] is Map) {
                msg = Map<String, dynamic>.from(msg['data'] as Map);
              }
            }

            if (msg != null) {
              // ── Handle typing events (not chat messages) ──
              final msgType = (msg['type'] ?? '').toString();
              if (msgType == 'typing') {
                final typerId = (msg['sender_id'] ?? msg['user_id'] ?? '').toString();
                // Always skip own typing echo
                if (typerId.isEmpty || typerId == _myUserId) return;
                final typerName = (msg['sender_name'] ?? msg['name'] ?? '')
                    .toString()
                    .trim();
                final displayName = typerName.isNotEmpty
                    ? typerName
                    : (typerId.length >= 8 ? 'User ...${typerId.substring(typerId.length - 4)}' : 'Seseorang');
                _addTypingUser(typerId, displayName);
                return;
              }
              if (msgType == 'stop_typing') {
                final typerId = (msg['sender_id'] ?? msg['user_id'] ?? '').toString();
                if (typerId.isNotEmpty) _removeTypingUser(typerId);
                return;
              }

              // ── System event (joined / left) ─────────────
              if (msgType == 'system') {
                final action = (msg['action'] ?? '').toString();
                final name = (msg['sender_name'] ?? msg['name'] ?? 'Seseorang').toString();
                final onlineCount = msg['online_count'];
                String label;
                if (action == 'joined') {
                  label = '$name bergabung ke grup';
                } else if (action == 'left') {
                  label = '$name meninggalkan grup';
                } else {
                  label = '$name: $action';
                }
                if (onlineCount != null) label += ' ($onlineCount online)';
                if (mounted) {
                  setState(() => _messages.add({
                    'id': 'sys_${DateTime.now().millisecondsSinceEpoch}',
                    'is_system': true,
                    'message': label,
                    'created_at': msg?['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                  }));
                  _scrollToBottom();
                }
                return;
              }

              // Accept: no type field, type="message", or type="chat"
              if (msgType.isNotEmpty && msgType != 'message' && msgType != 'chat') {
                debugPrint('[WS] Ignored unknown type: $msgType');
                return;
              }

              final normalized = _normalizeWsMessage(msg);
              final wsContent = normalized['message']?.toString() ?? '';
              final wsSenderId = normalized['sender_id']?.toString() ?? '';
              final wsId = normalized['id']?.toString() ?? '';

              if (wsContent.isEmpty) return;

              // If there's a local optimistic placeholder, always replace it first
              // (only the local device ever adds local_ ids, so this is safe)
              final localIdx = _messages.indexWhere(
                (m) => (m['id'] as String? ?? '').startsWith('local_'),
              );
              if (localIdx != -1) {
                debugPrint('[WS] Replacing local placeholder with server msg id=$wsId sender=$wsSenderId');
                // Add server ID to ownIds (keep local id too — both owned)
                if (wsId.isNotEmpty) _ownIds.add(wsId);
                // Force sender_id = _myUserId to make the comparison fallback reliable
                final serverMsg = {
                  ...normalized,
                  'sender_id': _myUserId ?? wsSenderId,
                };
                if (mounted) {
                  setState(() => _messages[localIdx] = serverMsg);
                  _scrollToBottom();
                }
                return;
              }

              // No local placeholder — this is a message from another user
              if (wsSenderId == _myUserId) {
                // Own echo but no placeholder (e.g. sent from another device) — skip duplicate
                debugPrint('[WS] Own echo without placeholder, skipping');
                return;
              }

              if (mounted) {
                setState(() => _messages.add(normalized));
                _scrollToBottom();
              }
            }
          } catch (e) {
            debugPrint('[WS ERROR] Failed to parse message: $e — raw: $data');
          }
        },
        onError: (e) {
          debugPrint('[WS ERROR] Stream error: $e');
          if (mounted) setState(() => _wsConnected = false);
        },
        onDone: () {
          if (mounted) {
            setState(() => _wsConnected = false);
            // Reconnect after delay
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _connectWs();
            });
          }
        },
      );

      // Wait for handshake to complete before marking as connected/allowing sends
      await channel.ready;
      debugPrint('[WS] Connected to $uri');
      if (mounted) setState(() => _wsConnected = true);
    } catch (e) {
      debugPrint('[WS ERROR] Failed to connect: $e');
      if (mounted) setState(() => _wsConnected = false);
    }
  }

  Map<String, dynamic> _normalizeWsMessage(Map<String, dynamic> msg) {
    final senderId =
        (msg['sender_id'] ?? msg['user_id'] ?? msg['from'] ?? '').toString();
    return {
      'id': (msg['id'] ?? '').toString(),
      'sender_id': senderId,
      'sender_name':
          (msg['sender_name'] ?? msg['name'] ?? msg['user_name'] ?? '')
              .toString(),
      'message': (msg['message'] ?? msg['content'] ?? '').toString(),
      'created_at':
          msg['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  // ── Typing indicator logic ───────────────────────
  void _onTextChanged() {
    if (!_wsConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'typing',
      if (_myName != null) 'sender_name': _myName,
    }));
    // Ensure we never show our own typing indicator (in case of echo)
    if (_myUserId != null) _removeTypingUser(_myUserId!);
    // Reset stop-typing debounce timer (3 s of silence → stop)
    _sendStopTypingTimer?.cancel();
    _sendStopTypingTimer = Timer(const Duration(seconds: 3), () {
      if (_wsConnected && _channel != null) {
        _channel!.sink.add(jsonEncode({'type': 'stop_typing'}));
      }
    });
  }

  void _addTypingUser(String userId, String name) {
    // Cancel previous auto-remove timer for this user
    _typingTimers[userId]?.cancel();
    if (mounted) setState(() => _typingUsers[userId] = name);
    // Auto-remove after 5 s if no fresh typing event arrives
    _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
      _removeTypingUser(userId);
    });
  }

  void _removeTypingUser(String userId) {
    _typingTimers[userId]?.cancel();
    _typingTimers.remove(userId);
    if (mounted) setState(() => _typingUsers.remove(userId));
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _channel == null || !_wsConnected) return;

    // Stop the typing indicator immediately when message is sent
    _sendStopTypingTimer?.cancel();
    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'stop_typing'}));
    }

    // Optimistically add message locally so it appears immediately
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _ownIds.add(localId); // permanent — never removed
    final localMsg = {
      'id': localId,
      'sender_id': _myUserId ?? '',
      'sender_name': _myName ?? 'Anda',
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(localMsg);
    });
    _scrollToBottom();

    // Server expects {type, message, sender_name}
    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'message': text,
      if (_myName != null) 'sender_name': _myName,
    }));
    _msgCtrl.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sendStopTypingTimer?.cancel();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    _wsSub?.cancel();
    _channel?.sink.close();
    _msgCtrl.removeListener(_onTextChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _goToDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.groupName,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: _wsConnected ? Colors.greenAccent : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _wsConnected ? 'Online' : 'Connecting...',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleInfo, size: 20),
            tooltip: 'Detail Grup',
            onPressed: _goToDetail,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.circleExclamation,
                                size: 40, color: Colors.red),
                            const SizedBox(height: 12),
                            Text('Error: $_error',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadHistory,
                              icon: const FaIcon(
                                  FontAwesomeIcons.arrowsRotate,
                                  size: 14),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(FontAwesomeIcons.comments,
                                    size: 48,
                                    color:
                                        Colors.grey.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text('Belum ada pesan',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Mulai percakapan grup!',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) =>
                                _buildMessage(_messages[i]),
                          ),
          ),

          // Typing indicator
          if (_typingUsers.isNotEmpty) _buildTypingIndicator(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final names = _typingUsers.values.toList();
    final String label;
    if (names.length == 1) {
      label = '${names[0]} sedang mengetik...';
    } else if (names.length == 2) {
      label = '${names[0]} dan ${names[1]} sedang mengetik...';
    } else {
      label = '${names.length} orang sedang mengetik...';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.transparent,
      child: Row(
        children: [
          _TypingDots(),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _goToDetail() {
    Navigator.pushNamed(
      context,
      RouteNames.groupDetail,
      arguments: {
        'groupId': widget.groupId,
        'myRole': widget.myRole,
      },
    );
  }

  // ── Message bubble ─────────────────────────────────
  Widget _buildMessage(Map<String, dynamic> msg) {    // ── System message (joined / left) ──
    if (msg['is_system'] == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (msg['message'] ?? '').toString(),
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // ── Chat bubble ──
    final msgId = (msg['id'] ?? '').toString();
    final senderId = (msg['sender_id'] ?? '').toString();
    final isMe = _ownIds.contains(msgId) ||
        (senderId.isNotEmpty && _myUserId != null && senderId.trim() == _myUserId!.trim());
    debugPrint('[BUBBLE] id=$msgId senderId=$senderId myUserId=$_myUserId ownIds=$_ownIds isMe=$isMe');
    final senderName = (msg['sender_name'] ?? '').toString();
    final message = (msg['message'] ?? msg['content'] ?? '').toString();
    final createdAt = msg['created_at'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.neonLime.withValues(alpha: 0.15)
              : AppTheme.darkSurfaceVariant.withValues(alpha: 0.7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
          border: Border.all(
            color: isMe
                ? AppTheme.neonLime.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neonLime.withValues(alpha: 0.8),
                  ),
                ),
              ),
            Text(message, style: const TextStyle(fontSize: 14)),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(createdAt.toString()),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.darkSurfaceVariant,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.neonLime,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const FaIcon(FontAwesomeIcons.paperPlane,
                    size: 18, color: Colors.black87),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── Animated typing dots ────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot peaks at a different phase
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[400]!.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
