import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized app configuration for environment-specific values.
class AppConfig {
  AppConfig._();

  /// Build-time override (takes precedence if provided).
  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// Base URL for the API.
  /// - Release mode → https://api.runsync.id
  /// - Debug / profile on Android → http://10.0.2.2:8080  (emulator → host)
  /// - Debug / profile on iOS sim  → http://localhost:8080
  /// - Debug / profile on desktop  → http://localhost:8080
  ///
  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=https://custom.api.com
  static String get apiBaseUrl {
    if (_envOverride.isNotEmpty) return _envOverride;
    if (kReleaseMode) return 'https://api.runsync.id';
    // Android emulator uses 10.0.2.2 to reach the host machine
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }
}
