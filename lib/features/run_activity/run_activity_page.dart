import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/router/navigation_service.dart';

class RunActivityPage extends StatefulWidget {
  const RunActivityPage({super.key});

  @override
  State<RunActivityPage> createState() => _RunActivityPageState();
}

class _RunActivityPageState extends State<RunActivityPage> {
  final _distanceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isTracking = false;
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toggleTracking() {
    setState(() {
      if (_isTracking) {
        // Stop
        _isTracking = false;
        if (_startTime != null) {
          _elapsed = DateTime.now().difference(_startTime!);
          _durationCtrl.text =
              '${_elapsed.inMinutes}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        }
      } else {
        // Start
        _isTracking = true;
        _startTime = DateTime.now();
        _elapsed = Duration.zero;
      }
    });
  }

  Future<void> _saveActivity() async {
    if (_distanceCtrl.text.isEmpty && _durationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter distance or duration')),
      );
      return;
    }

    // TODO: Save to backend via RunActivityApi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Run activity saved!')),
    );

    if (mounted) {
      final nav = Provider.of<NavigationService>(context, listen: false);
      nav.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            final nav =
                Provider.of<NavigationService>(context, listen: false);
            nav.goBack();
          },
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
        ),
        title: const Text('Run Activity'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracking section
            Center(
              child: Column(
                children: [
                  // Timer display
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTracking
                          ? Colors.green.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isTracking
                            ? Colors.green
                            : theme.colorScheme.primary,
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
                            size: 32,
                            color: _isTracking
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isTracking
                                ? _formatDuration(DateTime.now()
                                    .difference(_startTime ?? DateTime.now()))
                                : 'Ready',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isTracking
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start/Stop button
                  SizedBox(
                    width: 160,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: FaIcon(
                        _isTracking
                            ? FontAwesomeIcons.stop
                            : FontAwesomeIcons.play,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isTracking ? 'Stop Run' : 'Start Run',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Manual entry section
            Text(
              'Or enter manually',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Distance
            TextFormField(
              controller: _distanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Distance',
                hintText: '5.0',
                suffixText: 'km',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.route, size: 18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Duration',
                hintText: '30:00',
                suffixText: 'min:sec',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.clock, size: 18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How was your run?',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.noteSticky, size: 18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.floppyDisk,
                        size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
