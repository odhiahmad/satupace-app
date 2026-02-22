import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/route_names.dart';
import '../../core/services/secure_storage_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    // Start checking auth after animation begins
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _checkAuthState();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nav = Provider.of<NavigationService>(context, listen: false);
    final storage = Provider.of<SecureStorageService>(context, listen: false);

    // 1. Check if first time (intro not seen)
    final seenIntro = await storage.hasSeenIntro();
    if (!seenIntro) {
      if (mounted) nav.navigateToIntroAndClear();
      return;
    }

    // 2. Initialize auth state
    await auth.initializeAuth();

    // 3. If we have a token, try to refresh or biometric
    if (auth.isAuthenticated) {
      // Try biometric first
      final canBio = await auth.canUseBiometric();
      if (canBio) {
        final bioOk = await auth.loginWithBiometric();
        if (bioOk && mounted) {
          if (auth.needsProfileSetup) {
            nav.navigateToAndClear(RouteNames.profileSetup);
          } else {
            nav.navigateToHomeAndClear();
          }
          return;
        }
      }

      // Try silent refresh
      final refreshed = await auth.refreshAccessToken();
      if (refreshed && mounted) {
        if (auth.needsProfileSetup) {
          nav.navigateToAndClear(RouteNames.profileSetup);
        } else {
          nav.navigateToHomeAndClear();
        }
        return;
      }
    }

    // 4. No valid session → go to login
    if (mounted) nav.navigateToLoginAndClear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Image.asset(
                  'assets/images/satupace-icon.png',
                  width: 110,
                  height: 110,
                ),
                const SizedBox(height: 28),
                // Logo text (horizontal)
                Image.asset(
                  'assets/images/satupace-logo-panjang.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'Find Your Running Buddy',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.7),
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
}
