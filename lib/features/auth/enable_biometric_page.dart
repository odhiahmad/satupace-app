import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/route_names.dart';

class EnableBiometricPage extends StatefulWidget {
  const EnableBiometricPage({super.key});

  @override
  State<EnableBiometricPage> createState() => _EnableBiometricPageState();
}

class _EnableBiometricPageState extends State<EnableBiometricPage> {
  String _biometricLabel = 'Biometric';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricLabel();
  }

  Future<void> _loadBiometricLabel() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final label = await auth.getBiometricLabel();
    if (mounted) setState(() => _biometricLabel = label);
  }

  Future<void> _enableBiometric() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.enableBiometric();
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_biometricLabel login enabled!')),
        );
      }
      _navigateNext();
    }
  }

  void _skipBiometric() {
    _navigateNext();
  }

  void _navigateNext() {
    final nav = Provider.of<NavigationService>(context, listen: false);
    nav.navigateToAndClear(RouteNames.profileSetup);
  }

  IconData get _biometricIcon {
    switch (_biometricLabel) {
      case 'Face ID':
        return FontAwesomeIcons.faceSmile;
      case 'Fingerprint':
        return FontAwesomeIcons.fingerprint;
      default:
        return FontAwesomeIcons.shieldHalved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: FaIcon(
                    _biometricIcon,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Enable $_biometricLabel',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use $_biometricLabel to quickly and securely sign in to RunSync next time.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Enable button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _enableBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(_biometricIcon, size: 18, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Enable $_biometricLabel',
                              style: const TextStyle(
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
              TextButton(
                onPressed: _skipBiometric,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
