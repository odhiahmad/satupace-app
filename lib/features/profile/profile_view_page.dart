import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/route_names.dart';
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
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.circleExclamation,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchProfile(),
                    icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // --- Header Section ---
                  _buildHeader(context, provider, isDark),
                  const SizedBox(height: 24),

                  // --- Stats Cards ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          context,
                          icon: FontAwesomeIcons.gaugeHigh,
                          label: 'Avg Pace',
                          value: provider.avgPace != null
                              ? '${provider.avgPace!.toStringAsFixed(1)} min/km'
                              : '-',
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context,
                          icon: FontAwesomeIcons.route,
                          label: 'Jarak Preferensi',
                          value: provider.preferredDistance != null
                              ? '${provider.preferredDistance} km'
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Detail Info ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informasi Profil',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold)),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: FontAwesomeIcons.envelope,
                              label: 'Email',
                              value: provider.email ?? '-',
                            ),
                            _buildInfoRow(
                              context,
                              icon: FontAwesomeIcons.phone,
                              label: 'Telepon',
                              value: provider.phoneNumber ?? '-',
                            ),
                            _buildInfoRow(
                              context,
                              icon: FontAwesomeIcons.venusMars,
                              label: 'Gender',
                              value: _formatGender(provider.gender),
                            ),
                            _buildInfoRow(
                              context,
                              icon: FontAwesomeIcons.clock,
                              label: 'Waktu Preferensi',
                              value: _formatPreferredTime(provider.preferredTime),
                            ),
                            _buildInfoRow(
                              context,
                              icon: FontAwesomeIcons.locationDot,
                              label: 'Lokasi',
                              value: provider.latitude != null &&
                                      provider.longitude != null
                                  ? '${provider.latitude!.toStringAsFixed(4)}, ${provider.longitude!.toStringAsFixed(4)}'
                                  : 'Belum diatur',
                            ),
                            _buildInfoRow(
                              context,
                              icon: FontAwesomeIcons.personDress,
                              label: 'Mode Wanita Saja',
                              value: provider.womenOnlyMode ? 'Ya' : 'Tidak',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Verification Badge ---
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: provider.isVerified
                            ? const Color(0xFFB8FF00).withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: provider.isVerified
                              ? const Color(0xFFB8FF00).withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            provider.isVerified
                                ? FontAwesomeIcons.circleCheck
                                : FontAwesomeIcons.triangleExclamation,
                            color: provider.isVerified
                                ? const Color(0xFFB8FF00)
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            provider.isVerified
                                ? 'Akun Terverifikasi'
                                : 'Akun Belum Terverifikasi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: provider.isVerified
                                  ? const Color(0xFFB8FF00)
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  // --- Header with Avatar ---
  Widget _buildHeader(
      BuildContext context, ProfileProvider provider, bool isDark) {
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
          // Avatar
          Container(
            width: 100,
            height: 100,
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
            child: provider.image != null && provider.image!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      provider.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: FaIcon(FontAwesomeIcons.personRunning,
                            color: Colors.black87, size: 44),
                      ),
                    ),
                  )
                : const Center(
                    child: FaIcon(FontAwesomeIcons.personRunning,
                        color: Colors.black87, size: 44),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            provider.name ?? 'Runner',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            provider.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[300]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Stat Card ---
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFB8FF00).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB8FF00).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: const Color(0xFFB8FF00), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Info Row ---
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: FaIcon(icon, size: 16, color: const Color(0xFFB8FF00)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[800]),
      ],
    );
  }

  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return '-';
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      default:
        return gender;
    }
  }

  String _formatPreferredTime(String? time) {
    if (time == null || time.isEmpty) return '-';
    switch (time.toLowerCase()) {
      case 'morning':
        return 'Pagi';
      case 'afternoon':
        return 'Siang';
      case 'evening':
        return 'Sore';
      case 'night':
        return 'Malam';
      default:
        return time;
    }
  }
}
