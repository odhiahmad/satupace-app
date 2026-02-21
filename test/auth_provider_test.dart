import 'package:flutter_test/flutter_test.dart';
import 'package:run_sync/core/auth/auth_provider.dart';
import 'package:run_sync/core/auth/auth_service.dart';

class FakeAuthService implements AuthServiceBase {
  bool shouldSucceed;

  FakeAuthService({this.shouldSucceed = true});

  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldSucceed) {
      return {
        'ok': true,
        'data': {
          'token': 'fake-token',
          'refresh_token': 'fake-refresh',
          'name': 'Test User',
          'user_id': '123',
        }
      };
    }
    return {'ok': false, 'message': 'invalid'};
  }

  @override
  Future<Map<String, dynamic>> register(String name, String email, String phoneNumber, String gender, String password) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldSucceed) {
      return {'ok': true, 'data': {'message': 'OTP sent'}};
    }
    return {'ok': false, 'message': 'Registration failed'};
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldSucceed) {
      return {
        'ok': true,
        'data': {
          'token': 'verified-token',
          'refresh_token': 'verified-refresh',
          'name': phoneNumber,
          'user_id': '456',
        }
      };
    }
    return {'ok': false, 'message': 'Invalid OTP'};
  }

  @override
  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldSucceed) {
      return {'ok': true, 'data': {'message': 'OTP resent'}};
    }
    return {'ok': false, 'message': 'Failed to resend'};
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldSucceed) {
      return {
        'ok': true,
        'data': {
          'token': 'refreshed-token',
          'refresh_token': 'new-refresh',
        }
      };
    }
    return {'ok': false, 'message': 'Session expired'};
  }

  @override
  Future<bool> registerFcmToken(String token, String fcmToken) async {
    return true;
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
    final provider = AuthProvider(authService, null);
    final ok = await provider.login('a@b.com', 'password');
    expect(ok, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.token, equals('fake-token'));
    expect(provider.name, equals('Test User'));
  });

  test('AuthProvider login failure', () async {
    final authService = FakeAuthService(shouldSucceed: false);
    final provider = AuthProvider(authService, null);
    final ok = await provider.login('a@b.com', 'password');
    expect(ok, isFalse);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.token, isNull);
  });

  test('AuthProvider logout clears state', () async {
    final authService = FakeAuthService(shouldSucceed: true);
    final provider = AuthProvider(authService, null);
    await provider.login('a@b.com', 'password');
    expect(provider.isAuthenticated, isTrue);
    await provider.logout();
    expect(provider.isAuthenticated, isFalse);
    expect(provider.token, isNull);
  });

  test('AuthProvider register then verify OTP', () async {
    final authService = FakeAuthService(shouldSucceed: true);
    final provider = AuthProvider(authService, null);

    // Register
    final regOk = await provider.register('New User', 'new@user.com', '+628123456', 'male', 'pass123');
    expect(regOk, isTrue);
    expect(provider.needsOtpVerification, isTrue);
    expect(provider.pendingOtpPhone, '+628123456');

    // Verify OTP
    final otpOk = await provider.verifyOtp('123456');
    expect(otpOk, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.token, equals('verified-token'));
    expect(provider.needsOtpVerification, isFalse);
    expect(provider.needsProfileSetup, isTrue);
  });

  test('AuthProvider validates email and password', () async {
    final authService = FakeAuthService(shouldSucceed: true);
    final provider = AuthProvider(authService, null);

    // Invalid email
    var ok = await provider.login('', 'password');
    expect(ok, isFalse);
    expect(provider.error, isNotNull);

    // Short password
    provider.clearError();
    ok = await provider.login('a@b.com', '12345');
    expect(ok, isFalse);
    expect(provider.error, contains('6'));
  });
}
