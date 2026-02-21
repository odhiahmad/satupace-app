import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/navigation_service.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../../shared/widgets/loading_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin(BuildContext context, AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && context.mounted) {
      // Show beautiful loading screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingPage(message: 'Getting you ready...'),
      );

      // Wait for loading animation
      await Future.delayed(const Duration(milliseconds: 1500));

      if (context.mounted) {
        final navService = Provider.of<NavigationService>(context, listen: false);
        navService.navigateToHomeAndClear();
      }
    }
  }

  Future<void> _handleGoogleLogin(
      BuildContext context, AuthProvider auth, NavigationService nav) async {
    final ok = await auth.loginWithGoogle();
    if (ok && context.mounted) {
      // Show beautiful loading screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingPage(message: 'Syncing your profile...'),
      );

      // Wait for loading animation
      await Future.delayed(const Duration(milliseconds: 1500));

      if (context.mounted) {
        nav.navigateToHomeAndClear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navService = Provider.of<NavigationService>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      ThemeToggle(),
                    ],
                  ),
                      const SizedBox(height: 24),

                      // Logo and branding
                      Column(
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.neonLime,
                                  AppTheme.neonLimeDark,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.directions_run,
                              size: 60,
                              color: isDark ? AppTheme.darkBg : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppTheme.neonLime,
                                AppTheme.neonLimeDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'RunSync',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect. Run. Sync.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                  // Login form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message
                      if (auth.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  auth.error ?? 'An error occurred',
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                              InkWell(
                                onTap: () => auth.clearError(),
                                child: const Icon(Icons.close, color: Colors.red, size: 18),
                              ),
                            ],
                          ),
                        ),

                      // Email field
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              enabled: !auth.loading,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'runner@example.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passCtrl,
                              enabled: !auth.loading,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password required';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Email login button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.loading
                                    ? null
                                    : () => _handleEmailLogin(context, auth),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: auth.loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[400],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Sign-in button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: auth.loading
                              ? null
                              : () =>
                                  _handleGoogleLogin(context, auth, navService),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.g_mobiledata,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text('Continue with Google'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Footer
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                navService.navigateTo('register'),
                            child: Text(
                              'Sign up',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neonLime,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
