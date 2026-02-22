import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/navigation_service.dart';
import '../../core/services/app_services.dart';
import '../../core/services/secure_storage_service.dart';
import '../chat/chat_page.dart';
import '../direct_match/direct_match_page.dart';
import '../group_run/group_run_page.dart';
import '../strava/strava_provider.dart';
import '../profile/profile_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeView(onNavigate: _onNavigate),
      const DirectMatchPage(),
      const ChatPage(),
      const GroupRunPage(),
    ];
  }

  void _onNavigate(int index) {
    setState(() => _index = index);
  }

  void _handleTabChange(int index) {
    if (_index == index && index != 0) {
      // Same tab tapped - could scroll to top if needed
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final navService = Provider.of<NavigationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.neonLime, AppTheme.neonLimeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'RunSync',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        elevation: 0,
        actions: [
          const ThemeToggle(),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 20),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Apakah kamu yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await auth.logout();
                navService.navigateToLogin();
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _handleTabChange,
        items: const [
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house, size: 20), label: 'Home'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.userGroup, size: 20), label: 'Matches'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.comments, size: 20), label: 'Chats'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.users, size: 20), label: 'Groups'),
        ],
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  final Function(int)? onNavigate;

  const _HomeView({this.onNavigate});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  List<Map<String, dynamic>> _nearbyRunners = [];
  bool _loadingRunners = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load Strava stats
    final strava = Provider.of<StravaProvider>(context, listen: false);
    if (strava.stats == null && strava.isConnected) {
      strava.fetchStats();
    } else if (!strava.isConnected) {
      strava.loadAll();
    }

    // Ensure profile is fetched first (needed for lat/lng)
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    if (profile.profile == null) {
      await profile.fetchProfile();
    }

    // Load nearby runners
    await _loadNearbyRunners();
  }

  Future<void> _loadNearbyRunners() async {
    if (_loadingRunners) return;
    setState(() => _loadingRunners = true);

    try {
      final appServices = Provider.of<AppServices>(context, listen: false);
      final storage = Provider.of<SecureStorageService>(context, listen: false);
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final token = await storage.readToken();

      final lat = profile.latitude;
      final lng = profile.longitude;

      if (lat != null && lng != null) {
        final runners = await appServices.exploreApi.getRunners(
          latitude: lat,
          longitude: lng,
          limit: 5,
          token: token,
        );
        if (mounted) {
          setState(() => _nearbyRunners = runners);
        }
      }
    } catch (e) {
      debugPrint('Failed to load nearby runners: $e');
    } finally {
      if (mounted) setState(() => _loadingRunners = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final navService = Provider.of<NavigationService>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkSurface,
                  AppTheme.darkSurfaceVariant.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${auth.name ?? 'Runner'}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        navService.navigateToProfile();
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: 50,
                        height: 50,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.neonLime, AppTheme.neonLimeDark],
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.user, color: Colors.black87, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick stats from Strava
                Consumer<StravaProvider>(
                  builder: (context, strava, _) {
                    return Row(
                      children: [
                        _StatCard(
                          label: 'Runs',
                          value: '${strava.totalRuns}',
                          icon: FontAwesomeIcons.personRunning,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Distance',
                          value: '${strava.totalDistanceKm.toStringAsFixed(1)}km',
                          icon: FontAwesomeIcons.mapLocationDot,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Avg Pace',
                          value: strava.avgPace != null
                              ? strava.avgPace!.toStringAsFixed(1)
                              : '-',
                          icon: FontAwesomeIcons.gaugeHigh,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: FontAwesomeIcons.circlePlay,
                        label: 'Start Run',
                        onPressed: () {
                          navService.navigateToRunActivity();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: FontAwesomeIcons.userPlus,
                        label: 'Find Runners',
                        onPressed: () {
                          widget.onNavigate?.call(1); // Navigate to Direct Match
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: FontAwesomeIcons.strava,
                        label: 'Strava Sync',
                        onPressed: () {
                          navService.navigateToStrava();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: FontAwesomeIcons.peopleGroup,
                        label: 'My Groups',
                        onPressed: () {
                          widget.onNavigate?.call(3); // Navigate to Group Runs
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nearby runners section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Runners',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onNavigate?.call(1); // Navigate to Direct Match to see all matches
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(color: AppTheme.neonLime),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _loadingRunners
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _nearbyRunners.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurfaceVariant
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                              'Tidak ada runner terdekat. Pastikan lokasi sudah diset di profil.'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _nearbyRunners.length,
                        itemBuilder: (context, i) {
                          final r = _nearbyRunners[i];
                          // Backend may nest user info and profile fields
                          final user =
                              r['user'] is Map ? Map<String, dynamic>.from(r['user']) : r;
                          final runnerName = (user['name'] ?? r['name'] ?? r['full_name'] ?? 'Runner')
                              .toString();
                          final prefDist = r['preferred_distance'] ?? 0;
                          final pace = r['avg_pace'];
                          final distKm = r['distance_km'];
                          return _RunnerCard(
                            name: runnerName,
                            distance: '$prefDist km',
                            pace: pace != null
                                ? '${(pace as num).toStringAsFixed(1)} min/km'
                                : '-',
                            location: distKm != null
                                ? '${(distKm as num).toStringAsFixed(1)}km away'
                                : '-',
                          );
                        },
                      ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.neonLime.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, color: AppTheme.neonLime, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.neonLime,
              AppTheme.neonLimeDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonLime.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: Colors.black87, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunnerCard extends StatelessWidget {
  final String name;
  final String distance;
  final String pace;
  final String location;

  const _RunnerCard({
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
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      distance,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      ' • $pace',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonLime.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.neonLime.withValues(alpha: 0.3),
              ),
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
