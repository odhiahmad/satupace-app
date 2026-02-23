import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/components/neon_stat_card.dart';
import 'run_activity_provider.dart';

class RunActivityPage extends StatefulWidget {
  const RunActivityPage({super.key});

  @override
  State<RunActivityPage> createState() => _RunActivityPageState();
}

class _RunActivityPageState extends State<RunActivityPage> {
  final _distanceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _isTracking = false;
  bool _saving = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final provider =
        Provider.of<RunActivityProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId != null) {
      await Future.wait([
        provider.loadActivities(userId),
        provider.loadLastSyncTime(),
      ]);
    }
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _toggleTracking() {
    setState(() {
      if (_isTracking) {
        _isTracking = false;
        if (_startTime != null) {
          final elapsed = DateTime.now().difference(_startTime!);
          _durationCtrl.text =
              '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        }
      } else {
        _isTracking = true;
        _startTime = DateTime.now();
      }
    });
  }

  Future<void> _saveActivity() async {
    final distText = _distanceCtrl.text.trim();
    final durText = _durationCtrl.text.trim();

    if (distText.isEmpty || durText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jarak dan durasi terlebih dahulu.')),
      );
      return;
    }

    final distanceKm = double.tryParse(distText);
    if (distanceKm == null || distanceKm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jarak tidak valid.')),
      );
      return;
    }

    // Parse duration "mm:ss" or "mm"
    int durationSeconds;
    if (durText.contains(':')) {
      final parts = durText.split(':');
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      durationSeconds = minutes * 60 + seconds;
    } else {
      durationSeconds = (double.tryParse(durText) ?? 0).round() * 60;
    }

    if (durationSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durasi tidak valid.')),
      );
      return;
    }

    final avgPace = (durationSeconds / 60.0) / distanceKm;

    setState(() => _saving = true);
    final provider =
        Provider.of<RunActivityProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final ok = await provider.saveManualActivity(
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      avgPace: double.parse(avgPace.toStringAsFixed(2)),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // Reload stats after save
      final userId = auth.userId;
      if (userId != null) provider.loadActivities(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivitas berhasil disimpan!')),
      );
      _distanceCtrl.clear();
      _durationCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Gagal menyimpan aktivitas.')),
      );
    }
  }

  Future<void> _syncFromHealth() async {
    final provider =
        Provider.of<RunActivityProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) return;

    final count = await provider.syncFromHealth(userId: userId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.syncMessage ??
            (count > 0
                ? '$count aktivitas disinkronkan.'
                : 'Tidak ada aktivitas baru.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              Provider.of<NavigationService>(context, listen: false).goBack(),
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
        ),
        title: const Text('Aktivitas Lari'),
        centerTitle: true,
      ),
      body: Consumer<RunActivityProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats row ──────────────────────────────────────
                _buildStatsSection(context, provider),
                const SizedBox(height: 20),

                // ── Sync card ──────────────────────────────────────
                _buildSyncCard(context, provider),

                const SizedBox(height: 24),

                // ── Timer ──────────────────────────────────────────
                Text(
                  'Rekam Lari',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      _buildTimerCircle(theme),
                      const SizedBox(height: 20),
                      _buildStartStopButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Manual entry ───────────────────────────────────
                Text(
                  'Atau input manual',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _distanceCtrl,
                  label: 'Jarak',
                  hint: '5.0',
                  suffix: 'km',
                  icon: FontAwesomeIcons.route,
                  isDark: isDark,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _durationCtrl,
                  label: 'Durasi',
                  hint: '30:00',
                  suffix: 'menit:detik',
                  icon: FontAwesomeIcons.clock,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // ── Save button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveActivity,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.floppyDisk,
                            size: 16, color: Colors.white),
                    label: Text(
                      _saving ? 'Menyimpan...' : 'Simpan Aktivitas',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────

  Widget _buildStatsSection(
      BuildContext context, RunActivityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minggu Ini',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NeonStatCard(
                icon: FontAwesomeIcons.route,
                label: 'Jarak',
                value: '${provider.weeklyDistanceKm} km',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NeonStatCard(
                icon: FontAwesomeIcons.personRunning,
                label: 'Lari',
                value: '${provider.weeklyRuns}x',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NeonStatCard(
                icon: FontAwesomeIcons.gaugeHigh,
                label: 'Avg Pace',
                value: provider.weeklyAvgPace > 0
                    ? '${provider.weeklyAvgPace} /km'
                    : '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Bulan Ini — ${provider.monthlyDistanceKm} km · ${provider.monthlyRuns} lari',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildSyncCard(BuildContext context, RunActivityProvider provider) {
    final lastSync = provider.lastSyncTime;
    final syncLabel = lastSync != null
        ? 'Terakhir sync: ${_formatDate(lastSync)}'
        : 'Belum pernah sync';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.neonLime.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.heartPulse,
              size: 20, color: AppTheme.neonLime),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sync dari Health',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  syncLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          provider.syncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _syncFromHealth,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.neonLime,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Sync',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(ThemeData theme) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isTracking
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: _isTracking ? Colors.green : theme.colorScheme.primary,
          width: 3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _isTracking
                  ? FontAwesomeIcons.stopwatch
                  : FontAwesomeIcons.personRunning,
              size: 28,
              color:
                  _isTracking ? Colors.green : theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              _isTracking
                  ? _formatDuration(
                      DateTime.now().difference(_startTime ?? DateTime.now()))
                  : 'Siap',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    _isTracking ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartStopButton() {
    return SizedBox(
      width: 152,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: _toggleTracking,
        icon: FaIcon(
          _isTracking ? FontAwesomeIcons.stop : FontAwesomeIcons.play,
          size: 14,
          color: Colors.white,
        ),
        label: Text(
          _isTracking ? 'Stop' : 'Mulai Lari',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isTracking ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(icon, size: 16),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
