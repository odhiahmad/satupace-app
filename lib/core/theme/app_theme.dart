import 'package:flutter/material.dart';

class AppTheme with ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Neon Lime Primary Color
  static const Color neonLime = Color(0xFF32FF00);
  static const Color neonLimeDark = Color(0xFF2FD700);
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color darkSurface = Color(0xFF1A1F3A);
  static const Color darkSurfaceVariant = Color(0xFF2D3250);

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: neonLime,
          brightness: Brightness.light,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: neonLime,
          brightness: Brightness.dark,
          surface: darkSurface,
          onSurface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: neonLime,
          unselectedItemColor: Colors.grey[500],
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
