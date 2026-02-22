import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../shared/components/card_tile.dart';
import './direct_match_provider.dart';

class DirectMatchPage extends StatefulWidget {
  const DirectMatchPage({super.key});

  @override
  State<DirectMatchPage> createState() => _DirectMatchPageState();
}

class _DirectMatchPageState extends State<DirectMatchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DirectMatchProvider>(context, listen: false);
      provider.fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.heart, color: Color(0xFFB8FF00), size: 24),
                const SizedBox(width: 12),
                const Text('Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<DirectMatchProvider>(
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
                            onPressed: () => provider.fetchMatches(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.matches.isEmpty) {
                    return const Center(
                      child: Text('No matches available'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.matches.length,
                    itemBuilder: (context, i) {
                      final m = provider.matches[i];
                      return CardTile(
                        title: m['display_name'] ?? m['name'] ?? 'Unknown',
                        subtitle: 'Preferred: ${m['preferred_distance'] ?? 0} km',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(m['display_name'] ?? m['name'] ?? 'Runner'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Preferred Distance: ${m['preferred_distance'] ?? 'N/A'} km'),
                                  const SizedBox(height: 8),
                                  Text('Avg Pace: ${m['avg_pace'] ?? 'N/A'} min/km'),
                                  const SizedBox(height: 8),
                                  Text('Status: ${m['status'] ?? 'pending'}'),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => provider.rejectMatch(m['id'] ?? ''),
                              icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => provider.acceptMatch(m['id'] ?? ''),
                              icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB8FF00),
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ],
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
