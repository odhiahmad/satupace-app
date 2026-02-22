import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Displays current location text with a capture button.
/// The parent page handles the actual GPS logic and passes [locationText] + [onCapture].
class LocationCaptureCard extends StatelessWidget {
  final String? locationText;
  final String label;
  final VoidCallback onCapture;

  const LocationCaptureCard({
    super.key,
    this.locationText,
    this.label = 'Lokasi Saat Ini',
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    const neonLime = Color(0xFFB8FF00);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neonLime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonLime.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.locationDot, color: neonLime, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationText ?? 'Belum ditetapkan',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onCapture,
            icon: const FaIcon(FontAwesomeIcons.mapPin, size: 16),
            label: const Text('Tangkap'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: neonLime,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
