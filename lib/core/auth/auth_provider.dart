import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'google_sign_in_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthServiceBase _authService;
  final GoogleSignInService _googleSignIn;
  final SecureStorageService? _storage;

  AuthProvider(
    this._authService,
    this._googleSignIn,
    this._storage, {
    String? initialToken,
    String? initialName,
  }) {
    if (initialToken != null && initialToken.isNotEmpty) {
      _token = initialToken;
      _isAuthenticated = true;
    }
    _name = initialName;
  }

  bool _isAuthenticated = false;
  String? _token;
  String? _name;
  bool _loading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get name => _name;
  bool get loading => _loading;
  String? get error => _error;

  /// Login dengan email & password
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.login(email, password);
      if (res['ok'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _token = data['token'] as String?;
        _name = data['name'] as String? ?? email;
        _isAuthenticated = true;

        if (_token != null && _storage != null) {
          await _storage.writeToken(_token!);
        }
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login dengan Google
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

      // TODO: Send Google token to your backend for verification
      // For now, we'll use the idToken as the auth token
      _token = googleUser['idToken'];
      _name = googleUser['displayName'] ?? googleUser['email'];
      _isAuthenticated = true;

      if (_token != null && _storage != null) {
        await _storage.writeToken(_token!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }
      await _googleSignIn.signOut();

      _token = null;
      _isAuthenticated = false;
      _name = null;
      _error = null;

      if (_storage != null) {
        await _storage.deleteToken();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
