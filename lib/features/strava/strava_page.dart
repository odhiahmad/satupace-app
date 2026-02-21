import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/router/navigation_service.dart';
import '../../core/theme/app_theme.dart';
import './strava_provider.dart';

class StravaPage extends StatefulWidget {
  const StravaPage({super.key});

  @override
  State<StravaPage> createState() => _StravaPageState();
}

class _StravaPageState extends State<StravaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StravaProvider>(context, listen: false).loadAll();
    });
  }

  Future<void> _connectStrava() async {
    final provider = Provider.of<StravaProvider>(context, listen: false);
    final url = await provider.getAuthUrl();
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak bisa membuka URL autentikasi Strava'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal mendapatkan URL Strava'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectStrava() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Strava'),
        content: const Text(
            'Yakin ingin memutuskan koneksi Strava? Data aktivitas yang sudah disinkronkan akan tetap tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok =
          await Provider.of<StravaProvider>(context, listen: false).disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Strava berhasil diputuskan'
                : 'Gagal memutuskan Strava'),
            backgroundColor: ok ? const Color(0xFF2D5A3D) : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncActivities() async {
    final provider = Provider.of<StravaProvider>(context, listen: false);
    final ok = await provider.syncActivities();
    if (mounted) {
      if (ok && provider.lastSyncSummary != null) {
        final s = provider.lastSyncSummary!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sync selesai: ${s.totalSynced} baru, ${s.totalSkipped} di-skip, ${s.totalFailed} gagal'),
            backgroundColor: const Color(0xFF2D5A3D),
          ),
        );
      } else if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal sync Strava'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strava Sync'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => navService.goBack(),
        ),
      ),
      body: Consumer<StravaProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Connection Status Card ---
                _ConnectionCard(
                  isConnected: provider.isConnected,
                  connection: provider.connection,
                  onConnect: _connectStrava,
                  onDisconnect: _disconnectStrava,
                ),
                const SizedBox(height: 16),

                // --- Stats Card ---
                if (provider.isConnected) ...[
                  _StatsCard(stats: provider.stats),
                  const SizedBox(height: 16),

                  // --- Sync Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.syncing ? null : _syncActivities,
                      icon: provider.syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black87),
                            )
                          : const FaIcon(FontAwesomeIcons.arrowsRotate,
                              size: 18, color: Colors.black87),
                      label: Text(
                        provider.syncing
                            ? 'Syncing...'
                            : 'Sync dari Strava',
                        style: const TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonLime,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Activities List ---
                  Text(
                    'Aktivitas Terbaru',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (provider.activities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Belum ada aktivitas yang disinkronkan'),
                      ),
                    )
                  else
                    ...provider.activities.map(
                        (a) => _ActivityCard(activity: a)),
                ],

                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.triangleExclamation,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Connection Card ──────────────────────────────────
class _ConnectionCard extends StatelessWidget {
  final bool isConnected;
  final dynamic connection;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ConnectionCard({
    required this.isConnected,
    required this.connection,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? AppTheme.neonLime.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppTheme.neonLime.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.strava,
                    color: isConnected ? AppTheme.neonLime : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'Strava Terhubung'
                          : 'Strava Belum Terhubung',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (isConnected && connection != null)
                      Text(
                        'Athlete ID: ${connection.athleteId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? AppTheme.neonLime : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isConnected ? onDisconnect : onConnect,
              icon: FaIcon(
                isConnected
                    ? FontAwesomeIcons.linkSlash
                    : FontAwesomeIcons.link,
                size: 16,
              ),
              label: Text(isConnected ? 'Disconnect' : 'Hubungkan Strava'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isConnected ? Colors.red : AppTheme.neonLime,
                side: BorderSide(
                  color: isConnected
                      ? Colors.red.withValues(alpha: 0.5)
                      : AppTheme.neonLime.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Card ───────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final dynamic stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonLime.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                icon: FontAwesomeIcons.personRunning,
                label: 'Total Runs',
                value: '${stats.totalActivities}',
              ),
              _MiniStat(
                icon: FontAwesomeIcons.route,
                label: 'Distance',
                value: '${stats.totalDistanceKm.toStringAsFixed(1)} km',
              ),
              _MiniStat(
                icon: FontAwesomeIcons.gaugeHigh,
                label: 'Avg Pace',
                value: '${stats.avgPace.toStringAsFixed(2)} min/km',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(
                icon: FontAwesomeIcons.heartPulse,
                label: 'Avg HR',
                value: '${stats.avgHeartrate.toStringAsFixed(0)} bpm',
              ),
              _MiniStat(
                icon: FontAwesomeIcons.fire,
                label: 'Calories',
                value: '${stats.totalCalories.toStringAsFixed(0)}',
              ),
              _MiniStat(
                icon: FontAwesomeIcons.mountain,
                label: 'Elevation',
                value: '${stats.totalElevation.toStringAsFixed(0)} m',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FaIcon(icon, color: AppTheme.neonLime, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ── Activity Card ────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final dynamic activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonLime.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                activity.type == 'Run'
                    ? FontAwesomeIcons.personRunning
                    : FontAwesomeIcons.bicycle,
                color: AppTheme.neonLime,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(activity.startDate),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActivityStat(
                  label: 'Distance',
                  value: '${activity.distanceKm.toStringAsFixed(2)} km'),
              _ActivityStat(
                  label: 'Pace',
                  value: '${activity.averagePace.toStringAsFixed(2)} min/km'),
              _ActivityStat(
                  label: 'Time', value: _formatDuration(activity.movingTime)),
              if (activity.averageHeartrate > 0)
                _ActivityStat(
                    label: 'HR',
                    value:
                        '${activity.averageHeartrate.toStringAsFixed(0)} bpm'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }
}

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;

  const _ActivityStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
