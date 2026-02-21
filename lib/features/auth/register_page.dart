import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/navigation_service.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../../shared/widgets/loading_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignUp(BuildContext context, AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // For now, just use login endpoint (typically you'd have a register endpoint)
    // TODO: Add proper register endpoint to backend
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && context.mounted) {
      // Show beautiful loading screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingPage(message: 'Setting up your profile...'),
      );

      // Wait for loading animation
      await Future.delayed(const Duration(milliseconds: 1500));

      if (context.mounted) {
        final navService = Provider.of<NavigationService>(context, listen: false);
        navService.navigateToHomeAndClear();
      }
    }
  }

  Future<void> _handleGoogleSignUp(
      BuildContext context, AuthProvider auth, NavigationService nav) async {
    final ok = await auth.loginWithGoogle();
    if (ok && context.mounted) {
      // Show beautiful loading screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingPage(message: 'Welcome to RunSync...'),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const ThemeToggle(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logo and branding
                  Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
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
                          size: 50,
                          color: isDark ? AppTheme.darkBg : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          'Join RunSync',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your running journey',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Registration form
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

                      // Registration form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name field
                            TextFormField(
                              controller: _nameCtrl,
                              enabled: !auth.loading,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'John Doe',
                                prefixIcon: const Icon(Icons.person_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Name required';
                                if (v.length < 2) return 'Name too short';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email field
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
                            const SizedBox(height: 16),

                            // Confirm password field
                            TextFormField(
                              controller: _confirmPassCtrl,
                              enabled: !auth.loading,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Confirm password';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Sign up button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.loading
                                    ? null
                                    : () => _handleEmailSignUp(context, auth),
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
                                        'Create Account',
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

                      // Google Sign-up button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: auth.loading
                              ? null
                              : () =>
                                  _handleGoogleSignUp(context, auth, navService),
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
                              Text('Sign up with Google'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider for login section
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
                              'Already have an account?',
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

                      // Login button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () =>
                              navService.navigateTo('login'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: AppTheme.neonLime,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.neonLime,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Footer text
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
