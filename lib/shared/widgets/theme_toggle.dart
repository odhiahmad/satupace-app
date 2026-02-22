import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme?>(context, listen: false);
    final isDark = appTheme?.mode == ThemeMode.dark;
    return IconButton(
      icon: FaIcon(isDark ? FontAwesomeIcons.moon : FontAwesomeIcons.sun, size: 20),
      onPressed: appTheme == null ? null : () => appTheme.toggle(),
      tooltip: 'Toggle theme',
    );
  }
}
