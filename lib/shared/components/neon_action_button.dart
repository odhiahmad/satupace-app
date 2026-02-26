import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';

/// A gradient action button with icon and label. Adapts to light/dark theme.
class NeonActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onPressed;

  const NeonActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final startColor = isDark ? AppTheme.neonLime : cs.primary;
    final endColor = isDark ? AppTheme.neonLimeDark : cs.primary.withValues(alpha: 0.85);
    final fgColor = isDark ? Colors.black87 : Colors.white;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: isDark ? 0.35 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            FaIcon(icon, color: fgColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: fgColor.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.arrowRight,
              color: fgColor.withValues(alpha: 0.5),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
