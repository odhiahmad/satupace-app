import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:run_sync/core/auth/auth_provider.dart';
import 'package:run_sync/core/auth/auth_service.dart';
import 'package:run_sync/features/auth/login_page.dart';
import 'package:run_sync/core/router/navigation_service.dart';

class FakeAuthService implements AuthServiceBase {
  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return {
      'ok': true,
      'data': {
        'token': 'fake-token',
        'refresh_token': 'fake-refresh',
        'name': 'Widget Runner',
      }
    };
  }

  @override
  Future<Map<String, dynamic>> register(String name, String email, String phoneNumber, String gender, String password) async {
    return {'ok': true, 'data': {'message': 'OTP sent'}};
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    return {'ok': true, 'data': {'token': 'verified', 'refresh_token': 'r'}};
  }

  @override
  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    return {'ok': true, 'data': {'message': 'OTP resent'}};
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return {'ok': true, 'data': {'token': 'refreshed'}};
  }

  @override
  Future<bool> registerFcmToken(String token, String fcmToken) async {
    return true;
  }

  @override
  Future<bool> logout(String token) async {
    return true;
  }
}

void main() {
  testWidgets('LoginPage signs in and updates AuthProvider', (WidgetTester tester) async {
    final authService = FakeAuthService();
    final authProvider = AuthProvider(authService, null);
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
    await tester.pump(const Duration(seconds: 2));

    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.name, equals('Widget Runner'));
  });
}
