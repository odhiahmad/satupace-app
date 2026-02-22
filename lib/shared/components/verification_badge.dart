import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Displays verified or unverified account status.
class VerificationBadge extends StatelessWidget {
  final bool isVerified;

  const VerificationBadge({super.key, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    const neonLime = Color(0xFFB8FF00);
    final color = isVerified ? neonLime : Colors.orange;
    final label = isVerified ? 'Akun Terverifikasi' : 'Akun Belum Terverifikasi';
    final icon = isVerified
        ? FontAwesomeIcons.circleCheck
        : FontAwesomeIcons.triangleExclamation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
