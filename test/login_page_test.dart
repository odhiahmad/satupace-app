import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:run_sync/core/auth/auth_provider.dart';
import 'package:run_sync/core/auth/auth_service.dart';
import 'package:run_sync/core/auth/google_sign_in_service.dart';
import 'package:run_sync/features/auth/login_page.dart';
import 'package:run_sync/core/router/navigation_service.dart';

class FakeAuthService implements AuthServiceBase {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return {'ok': true, 'data': {'token': 'fake-token', 'name': 'Widget Runner'}};
  }

  @override
  Future<bool> logout(String token) async {
    return true;
  }
}

void main() {
  testWidgets('LoginPage signs in and updates AuthProvider', (WidgetTester tester) async {
    final authService = FakeAuthService();
    final googleSignIn = GoogleSignInService();
    final authProvider = AuthProvider(authService, googleSignIn, null);
    final navService = NavigationService();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<NavigationService>.value(value: navService),
      ],
      child: MaterialApp(home: const LoginPage()),
    ));

    // Enter email & password
    await tester.enterText(find.byType(TextFormField).at(0), 'x@y.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');

    // Tap sign in
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Wait for async login
    await tester.pump(const Duration(milliseconds: 50));

    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.name, equals('Widget Runner'));
  });
}
