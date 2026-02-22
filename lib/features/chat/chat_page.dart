import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../shared/components/card_tile.dart';
import '../../core/router/navigation_service.dart';
import 'package:provider/provider.dart';
import './chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.fetchChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Chats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${provider.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchChats(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.chats.isEmpty) {
                    return const Center(
                      child: Text('No chats available'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.chats.length,
                    itemBuilder: (context, i) {
                      final c = provider.chats[i];
                      return CardTile(
                        title: c['peer_name'] ?? c['name'] ?? 'Unknown',
                        subtitle: c['last_message'] ?? '',
                        avatarLabel: ((c['peer_name'] ?? c['name'] ?? 'U') as String)[0],
                        onTap: () {
                          final navService = Provider.of<NavigationService>(context, listen: false);
                          navService.navigateToChatThread(c['id'] ?? '');
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ChatThreadPage extends StatefulWidget {
  final String chatId;

  const ChatThreadPage({super.key, required this.chatId});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.fetchThread(widget.chatId);
    });
  }

  Future<void> _send(ChatProvider provider) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await provider.sendMessage(widget.chatId, text);
  }

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatId),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => navService.goBack(),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          final messages = provider.getThreadMessages(widget.chatId);

          return Column(
            children: [
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMe = m['from'] == 'me';
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Card(
                              color: isMe ? Theme.of(context).colorScheme.primary.withAlpha(26) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(m['message'] ?? ''),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(hintText: 'Message'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _send(provider),
                      icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 20),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
