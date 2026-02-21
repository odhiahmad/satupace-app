import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'google_sign_in_service.dart';
import 'biometric_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthServiceBase _authService;
  final GoogleSignInService _googleSignIn;
  final BiometricService _biometric;
  final SecureStorageService? _storage;
  final NotificationService? _notificationService;

  AuthProvider(
    this._authService,
    this._googleSignIn,
    this._storage, {
    BiometricService? biometric,
    NotificationService? notificationService,
    String? initialToken,
    String? initialName,
  })  : _biometric = biometric ?? BiometricService(),
        _notificationService = notificationService {
    if (initialToken != null && initialToken.isNotEmpty) {
      _token = initialToken;
      _isAuthenticated = true;
    }
    _name = initialName;
  }

  bool _isAuthenticated = false;
  String? _token;
  String? _refreshToken;
  String? _name;
  String? _userId;
  String? _email;
  bool _loading = false;
  String? _error;
  bool _biometricEnabled = false;
  bool _needsProfileSetup = false;
  bool _needsOtpVerification = false;
  String? _pendingOtpPhone;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get name => _name;
  String? get userId => _userId;
  String? get email => _email;
  bool get loading => _loading;
  String? get error => _error;
  bool get biometricEnabled => _biometricEnabled;
  bool get needsProfileSetup => _needsProfileSetup;
  bool get needsOtpVerification => _needsOtpVerification;
  String? get pendingOtpPhone => _pendingOtpPhone;

  /// Initialize auth state from secure storage on app start.
  Future<void> initializeAuth() async {
    if (_storage == null) return;

    _token = await _storage.readToken();
    _refreshToken = await _storage.readRefreshToken();
    _biometricEnabled = await _storage.isBiometricEnabled();
    _userId = await _storage.readUserId();

    if (_token != null && _token!.isNotEmpty) {
      _isAuthenticated = true;
      _needsProfileSetup = !(await _storage.isProfileSetupDone());
    }
    notifyListeners();
  }

  /// Try to auto-login with biometric.
  Future<bool> loginWithBiometric() async {
    if (_storage == null) return false;

    final enabled = await _storage.isBiometricEnabled();
    if (!enabled) return false;

    final refreshTk = await _storage.readRefreshToken();
    if (refreshTk == null || refreshTk.isEmpty) return false;

    final authenticated = await _biometric.authenticate(
      reason: 'Authenticate to login to RunSync',
    );
    if (!authenticated) return false;

    return await _doRefreshToken(refreshTk);
  }

  /// Refresh access token using stored refresh token.
  Future<bool> refreshAccessToken() async {
    if (_storage == null) return false;
    final refreshTk = _refreshToken ?? await _storage.readRefreshToken();
    if (refreshTk == null || refreshTk.isEmpty) return false;
    return await _doRefreshToken(refreshTk);
  }

  Future<bool> _doRefreshToken(String refreshTk) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.refreshToken(refreshTk);
      if (res['ok'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _token = (data['token'] ?? data['access_token']) as String?;
        final newRefresh = data['refresh_token'] as String?;
        if (newRefresh != null && newRefresh.isNotEmpty) {
          _refreshToken = newRefresh;
          await _storage?.writeRefreshToken(newRefresh);
        }
        _name = data['name'] as String? ?? _name;
        _userId = (data['user_id'] ?? data['id'])?.toString() ?? _userId;
        _isAuthenticated = true;

        if (_token != null) {
          await _storage?.writeToken(_token!);
        }
        await _registerFcmToken();
        notifyListeners();
        return true;
      } else {
        await _clearLocalSession();
        _error = (res['message'] as String?) ?? 'Session expired';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to restore session. Please login again.';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login with email or phone number & password.
  Future<bool> login(String identifier, String password) async {
    final normalizedId = identifier.trim();
    if (normalizedId.isEmpty) {
      _error = 'Please enter your email or phone number.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _error = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.login(normalizedId, password);
      if (res['ok'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        await _handleAuthSuccess(data, normalizedId);
        return true;
      } else {
        _error = (res['message'] as String?) ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to login. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Register a new user.
  Future<bool> register(String name, String email, String phoneNumber, String gender, String password) async {
    final normalizedEmail = email.trim();
    final normalizedPhone = phoneNumber.trim();
    if (name.trim().isEmpty) {
      _error = 'Please enter your name.';
      notifyListeners();
      return false;
    }
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _error = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (normalizedPhone.isEmpty) {
      _error = 'Please enter your phone number.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _error = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }
    if (gender.isEmpty) {
      _error = 'Please select your gender.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.register(name.trim(), normalizedEmail, normalizedPhone, gender, password);
      if (res['ok'] == true) {
        _pendingOtpPhone = normalizedPhone;
        _needsOtpVerification = true;
        notifyListeners();
        return true;
      } else {
        _error = (res['message'] as String?) ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to register. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Verify OTP after registration.
  Future<bool> verifyOtp(String otpCode) async {
    if (_pendingOtpPhone == null) {
      _error = 'No pending verification.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.verifyOtp(_pendingOtpPhone!, otpCode);
      if (res['ok'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        await _handleAuthSuccess(data, _pendingOtpPhone!);
        _needsOtpVerification = false;
        _needsProfileSetup = true;
        _pendingOtpPhone = null;
        notifyListeners();
        return true;
      } else {
        _error = (res['message'] as String?) ?? 'Invalid OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to verify. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Resend OTP to the pending phone number.
  Future<bool> resendOtp() async {
    if (_pendingOtpPhone == null) {
      _error = 'No pending verification.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.resendOtp(_pendingOtpPhone!);
      if (res['ok'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = (res['message'] as String?) ?? 'Failed to resend OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to resend OTP. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login with Google.
  Future<bool> loginWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signInWithGoogle();

      if (googleUser == null) {
        _error = 'Google sign-in cancelled';
        notifyListeners();
        return false;
      }

      _token = googleUser['idToken'] ?? googleUser['accessToken'];
      if (_token == null || (_token as String).isEmpty) {
        _error = 'Google login failed: token unavailable.';
        notifyListeners();
        return false;
      }
      _name = googleUser['displayName'] ?? googleUser['email'];
      _email = googleUser['email'] as String?;
      _userId = googleUser['uid'] as String?;
      _isAuthenticated = true;

      if (_token != null && _storage != null) {
        await _storage.writeToken(_token!);
      }
      if (_userId != null) {
        await _storage?.writeUserId(_userId!);
      }
      await _registerFcmToken();

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Google login failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Enable biometric login.
  Future<bool> enableBiometric() async {
    final supported = await _biometric.isDeviceSupported();
    if (!supported) {
      _error = 'Biometric not supported on this device.';
      notifyListeners();
      return false;
    }

    final canCheck = await _biometric.canCheckBiometrics();
    if (!canCheck) {
      _error = 'No biometric credentials enrolled.';
      notifyListeners();
      return false;
    }

    final authenticated = await _biometric.authenticate(
      reason: 'Verify to enable biometric login',
    );
    if (!authenticated) {
      _error = 'Biometric verification failed.';
      notifyListeners();
      return false;
    }

    if (_refreshToken != null && _storage != null) {
      await _storage.writeRefreshToken(_refreshToken!);
      await _storage.setBiometricEnabled(true);
      _biometricEnabled = true;
      notifyListeners();
      return true;
    }

    _error = 'No refresh token available for biometric setup.';
    notifyListeners();
    return false;
  }

  /// Disable biometric login.
  Future<void> disableBiometric() async {
    await _storage?.setBiometricEnabled(false);
    _biometricEnabled = false;
    notifyListeners();
  }

  /// Check if biometric is available and enabled.
  Future<bool> canUseBiometric() async {
    if (_storage == null) return false;
    final enabled = await _storage.isBiometricEnabled();
    if (!enabled) return false;
    return await _biometric.isDeviceSupported();
  }

  /// Get biometric type label.
  Future<String> getBiometricLabel() async {
    return await _biometric.getBiometricLabel();
  }

  /// Mark profile setup as done.
  Future<void> markProfileSetupDone() async {
    _needsProfileSetup = false;
    await _storage?.setProfileSetupDone(true);
    notifyListeners();
  }

  /// Handle successful auth response.
  Future<void> _handleAuthSuccess(Map<String, dynamic> data, String email) async {
    _token = (data['token'] ?? data['access_token']) as String?;
    _refreshToken = data['refresh_token'] as String?;
    _name = data['name'] as String? ?? email;
    _email = email;
    _userId = (data['user_id'] ?? data['id'])?.toString();
    _isAuthenticated = true;

    if (_token != null && _storage != null) {
      await _storage.writeToken(_token!);
    }
    if (_refreshToken != null && _storage != null) {
      await _storage.writeRefreshToken(_refreshToken!);
    }
    if (_userId != null) {
      await _storage?.writeUserId(_userId!);
    }

    await _registerFcmToken();
    notifyListeners();
  }

  /// Register FCM token with backend.
  Future<void> _registerFcmToken() async {
    if (_token == null || _notificationService == null) return;
    try {
      final fcmToken = await _notificationService.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _authService.registerFcmToken(_token!, fcmToken);
      }
    } catch (_) {
      // Non-critical; don't block auth flow
    }
  }

  /// Logout.
  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _clearLocalSession();
    _loading = false;
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    _token = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _name = null;
    _email = null;
    _userId = null;
    _error = null;
    _biometricEnabled = false;
    _needsProfileSetup = false;
    _needsOtpVerification = false;
    _pendingOtpPhone = null;

    if (_storage != null) {
      await _storage.clearAll();
    }
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
