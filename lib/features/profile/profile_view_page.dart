import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/route_names.dart';
import '../../shared/components/profile_header_card.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always fetch fresh data when the profile tab is opened
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => navService.goBack(),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 20),
            onPressed: () => navService.navigateTo(RouteNames.editProfile),
            tooltip: 'Edit Profil',
          ),
        ],
      ),
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  ProfileHeaderCard(
                    name: provider.name,
                    email: provider.email,
                    imageUrl: provider.image,
                  ),
                  const SizedBox(height: 24),
                  _StatsRow(provider: provider),
                  const SizedBox(height: 16),
                  _InfoCard(provider: provider),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: VerificationBadge(isVerified: provider.isVerified),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.circleExclamation,
              size: 48, color: Colors.red),
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
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ProfileProvider provider;

  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ProfileProvider provider;

  const _InfoCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Profil',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
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
              ),
              ProfileInfoTile(
                icon: FontAwesomeIcons.clock,
                label: 'Waktu Preferensi',
                value: _formatPreferredTime(provider.preferredTime),
              ),
              ProfileInfoTile(
                icon: FontAwesomeIcons.locationDot,
                label: 'Lokasi',
                value: provider.latitude != null && provider.longitude != null
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
        ),
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
