import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/route_names.dart';
import '../../shared/components/neon_stat_card.dart';
import '../../shared/components/profile_info_tile.dart';
import '../../shared/components/verification_badge.dart';
import './profile_provider.dart';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<ProfileProvider>(context, listen: false);
      p.fetchProfile();
      p.checkVerificationPhoto();
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.camera),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.image),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;
    if (!mounted) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final ok = await provider.uploadProfileImage(File(picked.path));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Foto profil berhasil diperbarui.'
            : (provider.error ?? 'Gagal upload foto.')),
      ),
    );
  }

  Future<void> _pickAndUploadVerificationPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final ok = await provider.uploadVerificationPhoto(File(picked.path));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Foto verifikasi berhasil diunggah!'
            : (provider.error ?? 'Gagal upload foto verifikasi.')),
        backgroundColor: ok ? const Color(0xFF2D5A3D) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.profile == null) {
            return _ErrorView(
              error: provider.error!,
              onRetry: provider.fetchProfile,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refreshProfile,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Hero Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ProfileHero(
                    name: provider.name,
                    email: provider.email,
                    imageUrl: provider.image,
                    isSaving: provider.saving,
                    onAvatarTap: _pickAndUploadPhoto,
                  ),
                ),

                // ── Content ───────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Statistik
                      const _SectionHeader(label: 'Statistik Lari'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          NeonStatCard(
                            icon: FontAwesomeIcons.gaugeHigh,
                            label: 'Avg Pace',
                            value: provider.avgPace != null
                                ? '${provider.avgPace!.toStringAsFixed(1)} min/km'
                                : '-',
                          ),
                          const SizedBox(width: 12),
                          NeonStatCard(
                            icon: FontAwesomeIcons.route,
                            label: 'Jarak Preferensi',
                            value: provider.preferredDistance != null
                                ? '${provider.preferredDistance} km'
                                : '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Informasi
                      const _SectionHeader(label: 'Informasi'),
                      const SizedBox(height: 10),
                      _SectionCard(
                        children: [
                          ProfileInfoTile(
                            icon: FontAwesomeIcons.envelope,
                            label: 'Email',
                            value: provider.email ?? '-',
                          ),
                          ProfileInfoTile(
                            icon: FontAwesomeIcons.phone,
                            label: 'Telepon',
                            value: provider.phoneNumber ?? '-',
                          ),
                          ProfileInfoTile(
                            icon: FontAwesomeIcons.venusMars,
                            label: 'Gender',
                            value: _formatGender(provider.gender),
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Preferensi Lari
                      const _SectionHeader(label: 'Preferensi Lari'),
                      const SizedBox(height: 10),
                      _SectionCard(
                        children: [
                          ProfileInfoTile(
                            icon: FontAwesomeIcons.clock,
                            label: 'Waktu Preferensi',
                            value: _formatPreferredTime(provider.preferredTime),
                          ),
                          ProfileInfoTile(
                            icon: FontAwesomeIcons.locationDot,
                            label: 'Lokasi',
                            value: provider.latitude != null &&
                                    provider.longitude != null
                                ? '${provider.latitude!.toStringAsFixed(4)}, ${provider.longitude!.toStringAsFixed(4)}'
                                : 'Belum diatur',
                          ),
                          ProfileInfoTile(
                            icon: FontAwesomeIcons.personDress,
                            label: 'Mode Wanita Saja',
                            value: provider.womenOnlyMode ? 'Ya' : 'Tidak',
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Verification badge
                      VerificationBadge(isVerified: provider.isVerified),
                      const SizedBox(height: 12),

                      // Verification photo section
                      _VerificationPhotoCard(
                        photoUrl: provider.verificationPhotoUrl,
                        isLoading: provider.loadingVerificationPhoto,
                        isSaving: provider.saving,
                        onUpload: _pickAndUploadVerificationPhoto,
                      ),
                      const SizedBox(height: 16),

                      // Edit profile button
                      const _EditProfileButton(),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      default:
        return gender?.isNotEmpty == true ? gender! : '-';
    }
  }

  String _formatPreferredTime(String? time) {
    switch (time?.toLowerCase()) {
      case 'morning':
        return 'Pagi';
      case 'afternoon':
        return 'Siang';
      case 'evening':
        return 'Sore';
      case 'night':
        return 'Malam';
      default:
        return time?.isNotEmpty == true ? time! : '-';
    }
  }
}

// ---------------------------------------------------------------------------
// Profile Hero Header
// ---------------------------------------------------------------------------

class _ProfileHero extends StatelessWidget {
  final String? name;
  final String? email;
  final String? imageUrl;
  final bool isSaving;
  final VoidCallback? onAvatarTap;

  const _ProfileHero({
    this.name,
    this.email,
    this.imageUrl,
    this.isSaving = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar with camera button
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: isSaving ? null : onAvatarTap,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: const Color(0xFFB8FF00).withValues(alpha: 0.65),
                      width: 2.5,
                    ),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            imageUrl!,
                            key: ValueKey(imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => const _AvatarFallback(),
                          ),
                        )
                      : const _AvatarFallback(),
                ),
              ),
              if (!isSaving)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB8FF00),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.camera,
                          size: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isSaving)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB8FF00),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Name
          Text(
            name ?? 'Runner',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Email
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              email!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FaIcon(
        FontAwesomeIcons.personRunning,
        color: Color(0xFFB8FF00),
        size: 40,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Profile Button
// ---------------------------------------------------------------------------

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => navService.navigateTo(RouteNames.editProfile),
        icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
        label: const Text('Edit Profil'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: cs.primary, width: 1.5),
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verification Photo Card
// ---------------------------------------------------------------------------

class _VerificationPhotoCard extends StatelessWidget {
  final String? photoUrl;
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onUpload;

  const _VerificationPhotoCard({
    required this.photoUrl,
    required this.isLoading,
    required this.isSaving,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPhoto
              ? const Color(0xFFB8FF00).withValues(alpha: 0.4)
              : cs.outlineVariant,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Photo thumbnail or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: isLoading
                  ? Container(
                      color: cs.surfaceContainerHighest,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : hasPhoto
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _PhotoPlaceholder(hasPhoto: false),
                        )
                      : _PhotoPlaceholder(hasPhoto: false),
            ),
          ),
          const SizedBox(width: 12),

          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto Verifikasi',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  hasPhoto
                      ? 'Foto sudah diunggah. Diperlukan untuk matching.'
                      : 'Diperlukan untuk bisa melakukan match dengan runner lain.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Upload button
          isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: onUpload,
                  icon: FaIcon(
                    hasPhoto
                        ? FontAwesomeIcons.arrowsRotate
                        : FontAwesomeIcons.camera,
                    size: 16,
                    color: const Color(0xFFB8FF00),
                  ),
                  tooltip: hasPhoto ? 'Perbarui foto' : 'Ambil foto verifikasi',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFB8FF00).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final bool hasPhoto;
  const _PhotoPlaceholder({required this.hasPhoto});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.idCard,
          size: 22,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error View
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.circleExclamation,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
