import 'package:flutter_test/flutter_test.dart';
import 'package:run_sync/core/auth/auth_provider.dart';
import 'package:run_sync/core/auth/auth_service.dart';
import 'package:run_sync/core/auth/google_sign_in_service.dart';

class FakeAuthService implements AuthServiceBase {
  bool shouldSucceed;

  FakeAuthService({this.shouldSucceed = true});

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldSucceed) {
      return {'ok': true, 'data': {'token': 'fake-token', 'name': 'Test User'}};
    }
    return {'ok': false, 'message': 'invalid'};
  }

  @override
  Future<bool> logout(String token) async {
    await Future.delayed(const Duration(milliseconds: 5));
    return true;
  }
}

void main() {
  test('AuthProvider login success', () async {
    final authService = FakeAuthService(shouldSucceed: true);
    final googleSignIn = GoogleSignInService();
    final provider = AuthProvider(authService, googleSignIn, null);
    final ok = await provider.login('a@b.com', 'pass');
    expect(ok, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.token, equals('fake-token'));
    expect(provider.name, equals('Test User'));
  });

  test('AuthProvider login failure', () async {
    final authService = FakeAuthService(shouldSucceed: false);
    final googleSignIn = GoogleSignInService();
    final provider = AuthProvider(authService, googleSignIn, null);
    final ok = await provider.login('a@b.com', 'pass');
    expect(ok, isFalse);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.token, isNull);
  });

  test('AuthProvider logout clears state', () async {
    final authService = FakeAuthService(shouldSucceed: true);
    final googleSignIn = GoogleSignInService();
    final provider = AuthProvider(authService, googleSignIn, null);
    await provider.login('a@b.com', 'p');
    expect(provider.isAuthenticated, isTrue);
    await provider.logout();
    expect(provider.isAuthenticated, isFalse);
    expect(provider.token, isNull);
  });
}
