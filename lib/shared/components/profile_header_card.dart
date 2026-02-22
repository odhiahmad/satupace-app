import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Profile avatar header with gradient background, name, and email.
class ProfileHeaderCard extends StatelessWidget {
  final String? name;
  final String? email;
  final String? imageUrl;
  final double avatarSize;

  const ProfileHeaderCard({
    super.key,
    this.name,
    this.email,
    this.imageUrl,
    this.avatarSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D5A3D).withValues(alpha: 0.7),
            const Color(0xFF1a3a26).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          _Avatar(imageUrl: imageUrl, size: avatarSize),
          const SizedBox(height: 16),
          Text(
            name ?? 'Runner',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email!,
              style: TextStyle(fontSize: 14, color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _Avatar({this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFB8FF00).withValues(alpha: 0.85),
            const Color(0xFF7FBF00).withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8FF00).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _DefaultIcon(),
              ),
            )
          : const _DefaultIcon(),
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FaIcon(FontAwesomeIcons.personRunning, color: Colors.black87, size: 44),
    );
  }
}
