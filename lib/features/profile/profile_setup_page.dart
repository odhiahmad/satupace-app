import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/router/navigation_service.dart';
import '../../features/profile/profile_provider.dart';
import '../../shared/widgets/loading_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _paceCtrl = TextEditingController(text: '6.0');
  final _distanceCtrl = TextEditingController(text: '5');
  String _preferredTime = 'morning';
  bool _womenOnly = false;
  bool _saving = false;

  @override
  void dispose() {
    _paceCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      await profileProvider.updateProfile({
        'avg_pace': double.tryParse(_paceCtrl.text) ?? 6.0,
        'preferred_distance': int.tryParse(_distanceCtrl.text) ?? 5,
        'preferred_time': _preferredTime,
        'women_only_mode': _womenOnly,
      });

      await auth.markProfileSetupDone();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const LoadingPage(message: 'Profile ready! Let\'s go!'),
        );
        await Future.delayed(const Duration(milliseconds: 1200));

        if (mounted) {
          final nav =
              Provider.of<NavigationService>(context, listen: false);
          nav.navigateToHomeAndClear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skipSetup() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.markProfileSetupDone();
    if (mounted) {
      final nav = Provider.of<NavigationService>(context, listen: false);
      nav.navigateToHomeAndClear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.personRunning,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Setup Runner Profile',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your running preferences\nso we can find the best running buddies for you',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Average Pace
                    _buildSectionLabel(theme, FontAwesomeIcons.gauge,
                        'Average Pace (min/km)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _paceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '6.0',
                        suffixText: 'min/km',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final pace = double.tryParse(v);
                        if (pace == null || pace < 2 || pace > 15) {
                          return 'Enter a pace between 2-15 min/km';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Preferred Distance
                    _buildSectionLabel(
                        theme, FontAwesomeIcons.route, 'Preferred Distance (km)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _distanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '5',
                        suffixText: 'km',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final d = int.tryParse(v);
                        if (d == null || d < 1 || d > 100) {
                          return 'Enter a distance between 1-100 km';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Preferred Time
                    _buildSectionLabel(
                        theme, FontAwesomeIcons.clock, 'Preferred Running Time'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _preferredTime,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'morning',
                            child: Text('🌅 Morning (5am - 9am)')),
                        DropdownMenuItem(
                            value: 'afternoon',
                            child: Text('☀️ Afternoon (12pm - 4pm)')),
                        DropdownMenuItem(
                            value: 'evening',
                            child: Text('🌇 Evening (4pm - 7pm)')),
                        DropdownMenuItem(
                            value: 'night',
                            child: Text('🌙 Night (7pm - 10pm)')),
                      ],
                      onChanged: (v) =>
                          setState(() => _preferredTime = v ?? 'morning'),
                    ),
                    const SizedBox(height: 20),

                    // Women Only Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.venus,
                              size: 18,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Women Only Mode',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Only match with female runners',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _womenOnly,
                            onChanged: (v) => setState(() => _womenOnly = v),
                            activeThumbColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.check,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save & Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Skip button
                    Center(
                      child: TextButton(
                        onPressed: _skipSetup,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color
                                ?.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, IconData icon, String label) {
    return Row(
      children: [
        FaIcon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
