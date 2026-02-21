import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme>(context);
    final isDark = appTheme.mode == ThemeMode.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      onPressed: () => appTheme.toggle(),
      tooltip: 'Toggle theme',
    );
  }
}
