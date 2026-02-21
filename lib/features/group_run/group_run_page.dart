import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/components/card_tile.dart';
import './group_run_provider.dart';

class GroupRunPage extends StatefulWidget {
  const GroupRunPage({super.key});

  @override
  State<GroupRunPage> createState() => _GroupRunPageState();
}

class _GroupRunPageState extends State<GroupRunPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GroupRunProvider>(context, listen: false);
      provider.fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Group Runs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<GroupRunProvider>(
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
                            onPressed: () => provider.fetchGroups(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.groups.isEmpty) {
                    return const Center(
                      child: Text('No group runs available'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.groups.length,
                    itemBuilder: (context, i) {
                      final g = provider.groups[i];
                      return CardTile(
                        title: g['name'] ?? 'Unknown',
                        subtitle: 'Scheduled at ${g['scheduled'] ?? ''} • ${g['distance'] ?? ''}',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(g['name'] ?? 'Group Run'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Distance: ${g['distance'] ?? 'N/A'} km'),
                                  const SizedBox(height: 8),
                                  Text('Scheduled: ${g['scheduled'] ?? 'N/A'}'),
                                  const SizedBox(height: 8),
                                  Text('Members: ${g['members_count'] ?? 'N/A'}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        trailing: ElevatedButton(
                          onPressed: () => provider.joinGroup(g['id'] ?? ''),
                          child: const Text('Join'),
                        ),
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
