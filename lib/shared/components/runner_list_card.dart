import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';

/// A card displaying a nearby runner's info.
class RunnerListCard extends StatelessWidget {
  final String name;
  final String distance;
  final String pace;
  final String location;

  const RunnerListCard({
    super.key,
    required this.name,
    required this.distance,
    required this.pace,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonLime.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.neonLime, AppTheme.neonLimeDark],
              ),
            ),
            child: const Center(
              child: FaIcon(FontAwesomeIcons.user, color: Colors.black87, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(distance, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    Text(' • $pace', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonLime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
            ),
            child: Text(
              location,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.neonLime,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
