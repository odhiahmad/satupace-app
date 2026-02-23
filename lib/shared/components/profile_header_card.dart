import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Profile avatar header with gradient background, name, and email.
class ProfileHeaderCard extends StatelessWidget {
  final String? name;
  final String? email;
  final String? imageUrl;
  final double avatarSize;
  final VoidCallback? onAvatarTap;

  const ProfileHeaderCard({
    super.key,
    this.name,
    this.email,
    this.imageUrl,
    this.avatarSize = 100,
    this.onAvatarTap,
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
          _AvatarWithEdit(
            imageUrl: imageUrl,
            size: avatarSize,
            onTap: onAvatarTap,
          ),
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

class _AvatarWithEdit extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const _AvatarWithEdit({this.imageUrl, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
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
                key: ValueKey(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const _DefaultIcon(),
              ),
            )
          : const _DefaultIcon(),
    );

    if (onTap == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(onTap: onTap, child: avatar),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFB8FF00),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.camera,
                    size: 14, color: Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FaIcon(FontAwesomeIcons.personRunning,
          color: Colors.black87, size: 44),
    );
  }
}
