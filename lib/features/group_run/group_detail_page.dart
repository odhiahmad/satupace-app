import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import './group_run_provider.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final String myRole; // 'owner', 'admin', 'member', ''

  const GroupDetailPage({
    super.key,
    required this.groupId,
    this.myRole = '',
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  Map<String, dynamic>? _group;
  bool _loading = true;
  String? _error;

  bool get _isOwner => widget.myRole == 'owner';
  bool get _isAdmin =>
      widget.myRole == 'admin' || widget.myRole == 'owner';

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<GroupRunProvider>(context, listen: false);
      final data = await provider.getGroupById(widget.groupId);
      if (mounted) {
        setState(() {
          _group = data;
          _loading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_group?['name'] ?? 'Detail Grup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 18),
              tooltip: 'Edit Grup',
              onPressed: _showEditSheet,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.circleExclamation,
                          size: 40, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadGroup,
                        icon: const FaIcon(FontAwesomeIcons.arrowsRotate,
                            size: 14),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _group == null
                  ? const Center(child: Text('Grup tidak ditemukan'))
                  : RefreshIndicator(
                      onRefresh: _loadGroup,
                      child: _buildContent(),
                    ),
    );
  }

  Widget _buildContent() {
    final g = _group!;
    final name = g['name'] ?? '';
    final status = g['status'] ?? 'open';
    final isWomenOnly = g['is_women_only'] == true;
    final pace = g['avg_pace'] as num? ?? 0;
    final minPace = g['min_pace'] as num?;
    final maxPace = g['max_pace'] as num?;
    final dist = g['preferred_distance'] ?? 0;
    final maxMember = g['max_member'] ?? 0;
    final memberCount = g['member_count'] ?? 0;
    final lat = g['latitude'] as num? ?? 0;
    final lng = g['longitude'] as num? ?? 0;
    final scheduledAt = g['scheduled_at']?.toString() ?? '';
    final createdAt = g['created_at']?.toString() ?? '';
    final creator = g['creator'] is Map
        ? Map<String, dynamic>.from(g['creator'] as Map)
        : <String, dynamic>{};

    // Pace display: show range if available, else avg
    String paceDisplay;
    if (minPace != null && maxPace != null && minPace > 0 && maxPace > 0) {
      paceDisplay =
          '${minPace.toStringAsFixed(1)} – ${maxPace.toStringAsFixed(1)} min/km';
    } else {
      paceDisplay = '${pace.toStringAsFixed(1)} min/km';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.neonLime.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              if (isWomenOnly) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.venus,
                          size: 12, color: Colors.pink),
                      SizedBox(width: 6),
                      Text('Khusus Wanita',
                          style: TextStyle(fontSize: 12, color: Colors.pink)),
                    ],
                  ),
                ),
              ],
              if (_isAdmin) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neonLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        _isOwner
                            ? FontAwesomeIcons.crown
                            : FontAwesomeIcons.shieldHalved,
                        size: 12,
                        color: AppTheme.neonLime,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOwner ? 'Owner' : 'Admin',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.neonLime),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stats Grid ──────────────────────────────
        Row(
          children: [
            Expanded(
                child: _StatCard(
              icon: FontAwesomeIcons.gaugeHigh,
              label: 'Pace',
              value: paceDisplay,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              icon: FontAwesomeIcons.route,
              label: 'Jarak',
              value: '$dist km',
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
              icon: FontAwesomeIcons.users,
              label: 'Member',
              value: '$memberCount / $maxMember',
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              icon: FontAwesomeIcons.locationDot,
              label: 'Lokasi',
              value: lat != 0
                  ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
                  : 'Belum diset',
            )),
          ],
        ),
        const SizedBox(height: 16),

        // ── Schedule ────────────────────────────────
        if (scheduledAt.isNotEmpty)
          _InfoTile(
            icon: FontAwesomeIcons.calendarDays,
            label: 'Jadwal',
            value: _formatDateFull(scheduledAt),
          ),
        const SizedBox(height: 8),
        if (createdAt.isNotEmpty)
          _InfoTile(
            icon: FontAwesomeIcons.clock,
            label: 'Dibuat',
            value: _formatDateFull(createdAt),
          ),
        const SizedBox(height: 16),

        // ── Creator ─────────────────────────────────
        if (creator.isNotEmpty) ...[
          const Text('Pembuat Grup',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.neonLime.withValues(alpha: 0.2),
                  child: Text(
                    (creator['name'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.neonLime),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(creator['name'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(creator['email'] ?? '',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[400])),
                      if (creator['gender'] != null)
                        Text(
                          creator['gender'].toString().toUpperCase(),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Admin Controls ──────────────────────────
        if (_isAdmin) ...[
          const SizedBox(height: 24),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          Text('Kelola Grup',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400])),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEditSheet,
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
              label: const Text('Edit Grup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neonLime,
                side: BorderSide(
                    color: AppTheme.neonLime.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_isOwner) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const FaIcon(FontAwesomeIcons.trash, size: 14),
                label: const Text('Hapus Grup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Edit Group Bottom Sheet ───────────────────────
  void _showEditSheet() {
    if (_group == null) return;
    final g = _group!;

    final nameCtrl = TextEditingController(text: g['name'] ?? '');
    final minPaceCtrl = TextEditingController(
        text: (g['min_pace'] as num?)?.toStringAsFixed(1) ??
            (g['avg_pace'] as num?)?.toStringAsFixed(1) ??
            '');
    final maxPaceCtrl = TextEditingController(
        text: (g['max_pace'] as num?)?.toStringAsFixed(1) ?? '');
    final distCtrl = TextEditingController(
        text: g['preferred_distance']?.toString() ?? '');
    final maxMemberCtrl = TextEditingController(
        text: g['max_member']?.toString() ?? '');
    final latCtrl = TextEditingController(
        text: (g['latitude'] as num?)?.toString() ?? '');
    final lngCtrl = TextEditingController(
        text: (g['longitude'] as num?)?.toString() ?? '');

    String status = (g['status'] ?? 'open').toString();
    bool isWomenOnly = g['is_women_only'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Grup',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Grup',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 12),

                // Pace range
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPaceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Pace',
                          suffixText: 'min/km',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxPaceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Pace',
                          suffixText: 'min/km',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Distance & Max member
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: distCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jarak (km)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxMemberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maks Member',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status
                Row(
                  children: [
                    const Text('Status: ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Open'),
                      selected: status == 'open',
                      selectedColor:
                          AppTheme.neonLime.withValues(alpha: 0.3),
                      onSelected: (v) {
                        if (v) setModalState(() => status = 'open');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Full'),
                      selected: status == 'full',
                      selectedColor:
                          Colors.orange.withValues(alpha: 0.3),
                      onSelected: (v) {
                        if (v) setModalState(() => status = 'full');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Completed'),
                      selected: status == 'completed',
                      selectedColor:
                          Colors.grey.withValues(alpha: 0.3),
                      onSelected: (v) {
                        if (v) setModalState(() => status = 'completed');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Women only toggle
                SwitchListTile(
                  title: const Text('Khusus Wanita'),
                  value: isWomenOnly,
                  activeColor: AppTheme.neonLime,
                  onChanged: (v) =>
                      setModalState(() => isWomenOnly = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final data = <String, dynamic>{
                        'name': nameCtrl.text.trim(),
                        'status': status,
                        'is_women_only': isWomenOnly,
                      };

                      final minP =
                          double.tryParse(minPaceCtrl.text.trim());
                      final maxP =
                          double.tryParse(maxPaceCtrl.text.trim());
                      if (minP != null) data['min_pace'] = minP;
                      if (maxP != null) data['max_pace'] = maxP;

                      final d = int.tryParse(distCtrl.text.trim());
                      if (d != null) data['preferred_distance'] = d;

                      final mm =
                          int.tryParse(maxMemberCtrl.text.trim());
                      if (mm != null) data['max_member'] = mm;

                      final lat =
                          double.tryParse(latCtrl.text.trim());
                      final lng =
                          double.tryParse(lngCtrl.text.trim());
                      if (lat != null) data['latitude'] = lat;
                      if (lng != null) data['longitude'] = lng;

                      final provider =
                          Provider.of<GroupRunProvider>(context,
                              listen: false);
                      final ok = await provider.updateGroup(
                          widget.groupId, data);

                      if (ok && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Grup berhasil diupdate')),
                        );
                        _loadGroup(); // Refresh detail
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Gagal update: ${provider.error ?? "Unknown error"}')),
                        );
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.floppyDisk,
                        size: 14),
                    label: const Text('Simpan Perubahan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonLime,
                      foregroundColor: Colors.black87,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete Confirmation ───────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Hapus Grup'),
        content: Text(
          'Yakin ingin menghapus grup "${_group?['name']}"?\n'
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final provider =
                  Provider.of<GroupRunProvider>(context, listen: false);
              final ok = await provider.deleteGroup(widget.groupId);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grup berhasil dihapus')),
                );
                // Pop back through chat page to group list
                Navigator.of(context).popUntil((route) {
                  return route.isFirst ||
                      route.settings.name == '/group-run' ||
                      route.settings.name == '/home';
                });
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Gagal menghapus: ${provider.error ?? "Unknown error"}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDateFull(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      const months = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]} ${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Status Badge ─────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppTheme.neonLime.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isOpen ? AppTheme.neonLime : Colors.grey,
        ),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 16, color: AppTheme.neonLime),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Info Tile ────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 16, color: AppTheme.neonLime),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
