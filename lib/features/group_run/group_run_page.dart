import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/route_names.dart';
import './group_run_provider.dart';

class GroupRunPage extends StatefulWidget {
  const GroupRunPage({super.key});

  @override
  State<GroupRunPage> createState() => _GroupRunPageState();
}

class _GroupRunPageState extends State<GroupRunPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GroupRunProvider>(context, listen: false);
      provider.fetchExploreGroups();
      provider.fetchMyGroups();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Filter bottom sheet ────────────────────────────
  void _showFilterSheet() async {
    final provider = Provider.of<GroupRunProvider>(context, listen: false);
    final current = Map<String, String>.from(provider.filters);

    String status = current['status'] ?? '';
    bool womenOnly = current['women_only'] == 'true';
    final minPaceCtrl =
        TextEditingController(text: current['min_pace'] ?? '');
    final maxPaceCtrl =
        TextEditingController(text: current['max_pace'] ?? '');
    final maxDistCtrl =
        TextEditingController(text: current['max_distance'] ?? '');
    final radiusCtrl =
        TextEditingController(text: current['radius_km'] ?? '20');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.filter,
                            size: 18, color: AppTheme.neonLime),
                        const SizedBox(width: 10),
                        const Text('Filter Grup',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              status = '';
                              womenOnly = false;
                              minPaceCtrl.clear();
                              maxPaceCtrl.clear();
                              maxDistCtrl.clear();
                              radiusCtrl.text = '20';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status
                    const Text('Status',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['', 'open', 'closed', 'cancelled']
                          .map((s) => ChoiceChip(
                                label: Text(
                                    s.isEmpty ? 'Semua' : s[0].toUpperCase() + s.substring(1)),
                                selected: status == s,
                                selectedColor:
                                    AppTheme.neonLime.withValues(alpha: 0.3),
                                onSelected: (_) =>
                                    setSheetState(() => status = s),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Women only
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Khusus Wanita',
                          style: TextStyle(fontSize: 14)),
                      value: womenOnly,
                      activeTrackColor: AppTheme.neonLime,
                      onChanged: (v) =>
                          setSheetState(() => womenOnly = v),
                    ),
                    const SizedBox(height: 8),

                    // Pace range
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPaceCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Min Pace',
                                suffixText: 'min/km'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxPaceCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Max Pace',
                                suffixText: 'min/km'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Max distance
                    TextField(
                      controller: maxDistCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Max Jarak', suffixText: 'km'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Only radius field remains
                    TextField(
                      controller: radiusCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Radius', suffixText: 'km'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Apply
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final f = <String, String>{};
                          if (status.isNotEmpty) f['status'] = status;
                          if (womenOnly) f['women_only'] = 'true';
                          if (minPaceCtrl.text.trim().isNotEmpty) {
                            f['min_pace'] = minPaceCtrl.text.trim();
                          }
                          if (maxPaceCtrl.text.trim().isNotEmpty) {
                            f['max_pace'] = maxPaceCtrl.text.trim();
                          }
                          if (maxDistCtrl.text.trim().isNotEmpty) {
                            f['max_distance'] = maxDistCtrl.text.trim();
                          }
                          if (radiusCtrl.text.trim().isNotEmpty) {
                            f['radius_km'] = radiusCtrl.text.trim();
                          }
                          provider.applyFilters(f);
                          Navigator.of(ctx).pop();
                        },
                        icon: const FaIcon(FontAwesomeIcons.magnifyingGlass,
                            size: 14),
                        label: const Text('Terapkan Filter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonLime,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateDialog() async {
    final result = await Navigator.pushNamed(
      context,
      RouteNames.groupForm,
    );
    if (result == true && mounted) {
      // Refresh handled by provider
    }
  }

  void _showEditDialog(Map<String, dynamic> group) async {
    final result = await Navigator.pushNamed(
      context,
      RouteNames.groupForm,
      arguments: group,
    );
    if (result == true && mounted) {
      // Refresh handled by provider
    }
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Grup'),
        content: Text('Yakin ingin menghapus "${group['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = Provider.of<GroupRunProvider>(context, listen: false);
      final ok = await provider.deleteGroup(group['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ok ? 'Grup berhasil dihapus' : 'Gagal menghapus grup'),
            backgroundColor: ok ? const Color(0xFF2D5A3D) : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinGroup(String groupId) async {
    final provider = Provider.of<GroupRunProvider>(context, listen: false);
    final ok = await provider.joinGroup(groupId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Berhasil bergabung ke grup' : 'Gagal bergabung'),
          backgroundColor: ok ? const Color(0xFF2D5A3D) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.peopleGroup,
                    color: Color(0xFFB8FF00), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Group Runs',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Consumer<GroupRunProvider>(
                  builder: (_, provider, __) {
                    final visibleEntries = provider.filters.entries
                        .where((e) => e.key != 'latitude' && e.key != 'longitude')
                        .toList();
                    final hasFilter = visibleEntries.isNotEmpty;
                    return IconButton(
                      onPressed: _showFilterSheet,
                      icon: FaIcon(
                        hasFilter
                            ? FontAwesomeIcons.filterCircleXmark
                            : FontAwesomeIcons.filter,
                        color: hasFilter ? AppTheme.neonLime : Colors.grey,
                        size: 18,
                      ),
                      tooltip: 'Filter',
                    );
                  },
                ),
                IconButton(
                  onPressed: _showCreateDialog,
                  icon: const FaIcon(FontAwesomeIcons.plus,
                      color: Color(0xFFB8FF00), size: 20),
                  tooltip: 'Buat Grup',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter chips summary
            Consumer<GroupRunProvider>(
              builder: (_, provider, __) {
                final visibleEntries = provider.filters.entries
                    .where((e) => e.key != 'latitude' && e.key != 'longitude')
                    .toList();
                if (visibleEntries.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...visibleEntries.map((e) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              label: Text('${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 11)),
                              deleteIcon:
                                  const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                final updated =
                                    Map<String, String>.from(provider.filters)
                                      ..remove(e.key);
                                provider.applyFilters(updated);
                              },
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  AppTheme.neonLime.withValues(alpha: 0.12),
                              side: BorderSide.none,
                            ),
                          )),
                      ActionChip(
                        label: const Text('Hapus semua',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () => provider.clearFilters(),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // Tabs
            TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.neonLime,
              labelColor: AppTheme.neonLime,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Explore'),
                Tab(text: 'Grup Saya'),
              ],
            ),
            const SizedBox(height: 8),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildExploreTab(),
                  _buildMyGroupsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.neonLime,
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.black87),
      ),
    );
  }

  // ── Explore tab ────────────────────────────────────
  Widget _buildExploreTab() {
    return Consumer<GroupRunProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.circleExclamation,
                    size: 40, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: ${provider.error}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchExploreGroups(),
                  icon:
                      const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (provider.groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.peopleGroup,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('Belum ada grup lari'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                  label: const Text('Buat Grup Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonLime,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchExploreGroups(),
          child: ListView.builder(
            itemCount: provider.groups.length,
            itemBuilder: (context, i) {
              final g = provider.groups[i];
              return _GroupCard(
                group: g,
                showActions: false,
                onJoin: () => _joinGroup(g['id'] ?? ''),
                onEdit: () => _showEditDialog(g),
                onDelete: () => _deleteGroup(g),
              );
            },
          ),
        );
      },
    );
  }

  // ── My Groups tab ──────────────────────────────────
  Widget _buildMyGroupsTab() {
    return Consumer<GroupRunProvider>(
      builder: (context, provider, _) {
        if (provider.loadingMy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.folderOpen,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('Belum ada grup yang kamu buat'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                  label: const Text('Buat Grup Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonLime,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchMyGroups(),
          child: ListView.builder(
            itemCount: provider.myGroups.length,
            itemBuilder: (context, i) {
              final g = provider.myGroups[i];
              final myRole = (g['my_role'] ?? '').toString();
              return _GroupCard(
                group: g,
                showActions: true,
                myRole: myRole,
                onJoin: () => _joinGroup(g['id'] ?? ''),
                onEdit: () => _showEditDialog(g),
                onDelete: () => _deleteGroup(g),
                onDetail: () => Navigator.pushNamed(
                  context,
                  RouteNames.groupChat,
                  arguments: {
                    'groupId': g['id'] ?? '',
                    'groupName': g['name'] ?? 'Grup',
                    'myRole': g['my_role'] ?? '',
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Group Card ─────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool showActions;
  final String myRole; // 'owner', 'admin', 'member', ''
  final VoidCallback onJoin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDetail;

  const _GroupCard({
    required this.group,
    this.showActions = false,
    this.myRole = '',
    required this.onJoin,
    required this.onEdit,
    required this.onDelete,
    this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final name = group['name'] ?? 'Unknown';
    final minPace = group['min_pace'] as num? ?? 0;
    final maxPace = group['max_pace'] as num? ?? 0;
    final dist = group['preferred_distance'] ?? 0;
    final maxMember = group['max_member'] ?? 0;
    final memberCount = group['member_count'] ?? 0;
    final status = group['status'] ?? 'open';
    final isWomenOnly = group['is_women_only'] == true;
    final scheduledAt = group['scheduled_at'];
    final role = myRole.isNotEmpty ? myRole : (group['my_role'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'open'
              ? AppTheme.neonLime.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (isWomenOnly)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Wanita',
                      style: TextStyle(fontSize: 10, color: Colors.pink)),
                ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'open'
                      ? AppTheme.neonLime.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: status == 'open' ? AppTheme.neonLime : Colors.grey,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats
          Row(
            children: [
              _TagChip(
                  icon: FontAwesomeIcons.gaugeHigh,
                  text: '${minPace.toInt()}-${maxPace.toInt()} min/km'),
              const SizedBox(width: 10),
              _TagChip(icon: FontAwesomeIcons.route, text: '$dist km'),
              const SizedBox(width: 10),
              _TagChip(
                  icon: FontAwesomeIcons.users,
                  text: '$memberCount/$maxMember'),
            ],
          ),
          const SizedBox(height: 6),

          // Schedule & creator
          if (scheduledAt != null && scheduledAt.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.calendarDays,
                      size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(_formatSchedule(scheduledAt.toString()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
          if (role.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: role == 'owner'
                      ? AppTheme.neonLime.withValues(alpha: 0.15)
                      : role == 'admin'
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: role == 'owner'
                        ? AppTheme.neonLime
                        : role == 'admin'
                            ? Colors.orange
                            : Colors.blue[300],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              if (showActions)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const FaIcon(FontAwesomeIcons.comments, size: 14),
                    label: const Text('Chat Grup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonLime,
                      side: BorderSide(
                          color: AppTheme.neonLime.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
              else if (status == 'open')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonLime,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (showActions) ...[
                const SizedBox(width: 8),
                if (myRole == 'admin' || myRole == 'owner')
                  IconButton(
                    onPressed: onEdit,
                    icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                    tooltip: 'Edit',
                    style:
                        IconButton.styleFrom(foregroundColor: AppTheme.neonLime),
                  ),
                if (myRole == 'owner')
                  IconButton(
                    onPressed: onDelete,
                    icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                    tooltip: 'Hapus',
                    style: IconButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatSchedule(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TagChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 11, color: AppTheme.neonLime),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }
}
