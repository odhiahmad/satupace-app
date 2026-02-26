import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/route_names.dart';
import './direct_match_provider.dart';

class DirectMatchPage extends StatefulWidget {
  const DirectMatchPage({super.key});

  @override
  State<DirectMatchPage> createState() => _DirectMatchPageState();
}

class _DirectMatchPageState extends State<DirectMatchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<DirectMatchProvider>(context, listen: false);
      p.fetchCandidates();
      p.fetchMatches();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.heart,
                    color: AppTheme.neonLime, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Matches',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Consumer<DirectMatchProvider>(
                  builder: (_, p, _) {
                    final count = p.pendingMatches.length;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count permintaan',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.orange),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Tab bar ──────────────────────────────────────────────────
            TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.neonLime,
              labelColor: AppTheme.neonLime,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Temukan Runner'),
                Tab(text: 'Match Saya'),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _FindTab(),
                  _MatchesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Find Runners (candidates) ────────────────────────────────────────

class _FindTab extends StatelessWidget {
  const _FindTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectMatchProvider>(
      builder: (context, provider, _) {
        if (provider.loadingCandidates) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.candidatesError != null) {
          return _ErrorView(
            message: provider.candidatesError!,
            onRetry: provider.fetchCandidates,
          );
        }

        if (provider.candidates.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.personRunning,
                    size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Tidak ada kandidat runner saat ini',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'Pastikan lokasi dan profil lari sudah diset.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.fetchCandidates,
          child: ListView.builder(
            itemCount: provider.candidates.length,
            itemBuilder: (context, i) =>
                _CandidateCard(candidate: provider.candidates[i]),
          ),
        );
      },
    );
  }
}

class _CandidateCard extends StatefulWidget {
  final Map<String, dynamic> candidate;
  const _CandidateCard({required this.candidate});

  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  bool _sending = false;

  Future<void> _sendRequest() async {
    final provider = Provider.of<DirectMatchProvider>(context, listen: false);
    debugPrint('[MATCH] Data kandidat: ${widget.candidate}');
    final userId = (widget.candidate['user_id'] ?? '').toString();
    debugPrint('[MATCH] Tombol Match diklik untuk userId: $userId');
    if (userId.isEmpty) {
      debugPrint('[MATCH] userId kosong, tidak mengirim request');
      return;
    }
    setState(() => _sending = true);
    final ok = await provider.sendMatchRequest(userId);
    debugPrint('[MATCH] Hasil kirim request: $ok');
    if (mounted) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Permintaan match terkirim!'
              : 'Gagal mengirim permintaan'),
          backgroundColor: ok ? const Color(0xFF2D5A3D) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final name = (c['name'] ?? 'Runner').toString();
    final pace = c['avg_pace'] as num?;
    final dist = c['preferred_distance'];
    final compatibility = c['compatibility'] as num?;
    final distKm = c['distance_km'] as num?;
    final isVerified = c['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.neonLime.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonLime.withValues(alpha: 0.15),
              border: Border.all(
                  color: AppTheme.neonLime.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonLime),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const FaIcon(FontAwesomeIcons.circleCheck,
                          size: 12, color: AppTheme.neonLime),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  children: [
                    if (pace != null)
                      _Tag(
                          icon: FontAwesomeIcons.gaugeHigh,
                          text: '${pace.toStringAsFixed(1)} min/km'),
                    if (dist != null)
                      _Tag(
                          icon: FontAwesomeIcons.route,
                          text: '$dist km'),
                    if (distKm != null)
                      _Tag(
                          icon: FontAwesomeIcons.locationDot,
                          text: '${distKm.toStringAsFixed(1)} km away'),
                  ],
                ),
                if (compatibility != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Kompatibilitas: ${(compatibility * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.neonLime.withValues(alpha: 0.8)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Button
          _sending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : ElevatedButton.icon(
                  onPressed: _sendRequest,
                  icon: const FaIcon(FontAwesomeIcons.userPlus, size: 12),
                  label:
                      const Text('Match', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonLime,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Tab 2: My Matches ────────────────────────────────────────────────────────

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectMatchProvider>(
      builder: (context, provider, _) {
        if (provider.loadingMatches) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.matchesError != null) {
          return _ErrorView(
            message: provider.matchesError!,
            onRetry: provider.fetchMatches,
          );
        }

        final myId = provider.myUserId ?? '';
        final pending = provider.pendingMatches;
        final accepted = provider.acceptedMatches;

        // Split pending: incoming = I am user_2 (receiver), outgoing = I am user_1 (sender)
        // If myId is unknown, treat all pending as incoming (show accept/reject so user can act)
        final List<Map<String, dynamic>> incoming;
        final List<Map<String, dynamic>> outgoing;
        if (myId.isEmpty) {
          incoming = List.of(pending);
          outgoing = [];
        } else {
          incoming = pending
              .where((m) => (m['user_2_id'] ?? '').toString() == myId)
              .toList();
          outgoing = pending
              .where((m) => (m['user_1_id'] ?? '').toString() == myId)
              .toList();
        }

        if (pending.isEmpty && accepted.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.heartCrack,
                    size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada match',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'Temukan runner di tab sebelah dan kirim match request!',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.fetchMatches,
          child: ListView(
            children: [
              // ── Incoming: others invited me → show Accept / Reject ─────
              if (incoming.isNotEmpty) ...[
                _SectionHeader(
                  icon: FontAwesomeIcons.bell,
                  label: 'Permintaan Masuk (${incoming.length})',
                  color: Colors.orange,
                ),
                ...incoming.map(
                  (m) => _PendingMatchCard(match: m, isSender: false),
                ),
                const Divider(height: 24),
              ],

              // ── Outgoing: I invited someone → waiting for their reply ──
              if (outgoing.isNotEmpty) ...[
                _SectionHeader(
                  icon: FontAwesomeIcons.paperPlane,
                  label: 'Permintaan Terkirim (${outgoing.length})',
                  color: Colors.blueGrey,
                ),
                ...outgoing.map(
                  (m) => _PendingMatchCard(match: m, isSender: true),
                ),
                const Divider(height: 24),
              ],

              // ── Accepted — tap to chat ─────────────────────────────────
              if (accepted.isNotEmpty) ...[
                if (incoming.isNotEmpty || outgoing.isNotEmpty)
                  _SectionHeader(
                    icon: FontAwesomeIcons.comments,
                    label: 'Match Saya (${accepted.length})',
                    color: AppTheme.neonLime,
                  ),
                ...accepted.map((m) => _AcceptedMatchCard(match: m)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PendingMatchCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final bool isSender;
  const _PendingMatchCard({required this.match, required this.isSender});

  @override
  State<_PendingMatchCard> createState() => _PendingMatchCardState();
}

class _PendingMatchCardState extends State<_PendingMatchCard> {
  bool _busy = false;

  Future<void> _accept() async {
    final p = Provider.of<DirectMatchProvider>(context, listen: false);
    setState(() => _busy = true);
    final ok = await p.acceptMatch(widget.match['id'] ?? '');
    if (mounted) {
      setState(() => _busy = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match diterima! Kamu sudah bisa chat.'),
            backgroundColor: Color(0xFF2D5A3D),
          ),
        );
      }
    }
  }

  Future<void> _reject() async {
    final p = Provider.of<DirectMatchProvider>(context, listen: false);
    setState(() => _busy = true);
    await p.rejectMatch(widget.match['id'] ?? '');
    if (mounted) setState(() => _busy = false);
  }

  String _formatSentAt(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'hari ini ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day} ${months[dt.month]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.match['partner_name'] ?? 'Runner').toString();
    final sentAt = _formatSentAt(widget.match['created_at']);
    final avatarColor = widget.isSender ? Colors.blueGrey : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: avatarColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: avatarColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: widget.isSender
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.paperPlane,
                              size: 10, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          const Text(
                            'Permintaan match telah terkirim',
                            style: TextStyle(
                                fontSize: 11, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      if (sentAt.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Dikirim $sentAt · Menunggu konfirmasi dari $name',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '$name mengajak kamu untuk match',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (widget.isSender)
            // Outgoing: visual "Terkirim" badge with checkmark
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    FaIcon(FontAwesomeIcons.check,
                        size: 9, color: Colors.blueGrey),
                    SizedBox(width: 4),
                    Text(
                      'Terkirim',
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Incoming: receiver can Accept or Reject
            OutlinedButton(
              onPressed: _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Tolak', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonLime,
                foregroundColor: Colors.black87,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
                  const Text('Terima', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcceptedMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  const _AcceptedMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final name = (match['partner_name'] ?? 'Runner').toString();
    final matchId = (match['id'] ?? '').toString();
    final matchedAt = match['matched_at']?.toString();
    final photoUrl = match['partner_verification_photo']?.toString();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        RouteNames.directChat,
        arguments: {
          'matchId': matchId,
          'partnerName': name,
        },
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.neonLime.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasPhoto
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.neonLime.withValues(alpha: 0.3),
                          AppTheme.neonLime.withValues(alpha: 0.1),
                        ],
                      ),
                border: Border.all(
                    color: AppTheme.neonLime.withValues(alpha: 0.4)),
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neonLime),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neonLime),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    matchedAt != null
                        ? 'Match sejak ${_formatDate(matchedAt)}'
                        : 'Tap untuk chat',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.comments,
                  size: 16, color: AppTheme.neonLime),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          FaIcon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 10, color: AppTheme.neonLime),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.circleExclamation,
              size: 40, color: Colors.red),
          const SizedBox(height: 12),
          Text('Error: $message', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon:
                const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
