import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/navigation_service.dart';
import '../../core/services/app_services.dart';
import '../../core/services/secure_storage_service.dart';
import '../../shared/components/neon_stat_card.dart';
import '../../shared/components/neon_action_button.dart';
import '../../shared/components/runner_list_card.dart';
import '../direct_match/direct_match_page.dart';
import '../group_run/group_run_page.dart';
import '../strava/strava_provider.dart';
import '../profile/profile_provider.dart';
import '../profile/profile_view_page.dart';
import '../../core/providers/chat_notification_provider.dart';

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
      const GroupRunPage(),
      const ProfileViewPage(),
    ];
  }

  void _onNavigate(int index) => setState(() => _index = index);

  void _handleTabChange(int index) => setState(() => _index = index);

  Future<void> _confirmLogout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navService = Provider.of<NavigationService>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

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
      profileProvider.clearProfile(); // Reset so next login fetches fresh data
      await auth.logout();
      navService.navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.neonLime, AppTheme.neonLimeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'SatuPace',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        elevation: 0,
        actions: [
          const ThemeToggle(),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 20),
            onPressed: _confirmLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: Consumer<ChatNotificationProvider>(
        builder: (_, notif, _) => BottomNavigationBar(
          currentIndex: _index,
          onTap: _handleTabChange,
          items: [
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house, size: 20),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: notif.matchUnread > 0,
                label: Text(notif.matchUnread > 9
                    ? '9+'
                    : '${notif.matchUnread}'),
                child: const FaIcon(FontAwesomeIcons.userGroup, size: 20),
              ),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: notif.groupUnread > 0,
                label: Text(notif.groupUnread > 9
                    ? '9+'
                    : '${notif.groupUnread}'),
                child: const FaIcon(FontAwesomeIcons.users, size: 20),
              ),
              label: 'Groups',
            ),
            const BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.user, size: 20),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home tab content
// ---------------------------------------------------------------------------

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final strava = Provider.of<StravaProvider>(context, listen: false);
    if (strava.stats == null && strava.isConnected) {
      strava.fetchStats();
    } else if (!strava.isConnected) {
      strava.loadAll();
    }

    final profile = Provider.of<ProfileProvider>(context, listen: false);
    if (profile.profile == null) {
      await profile.fetchProfile();
    }

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
        if (mounted) setState(() => _nearbyRunners = runners);
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
          _buildHeader(context, auth, navService),
          _buildQuickActions(context, navService),
          _buildNearbyRunnersSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AuthProvider auth, NavigationService navService) {
    return Container(
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
                    'Welcome back!',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.name ?? 'Runner',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Consumer<ChatNotificationProvider>(
                builder: (_, notif, _) => InkWell(
                  onTap: () => navService.navigateToNotification(),
                  borderRadius: BorderRadius.circular(25),
                  child: Badge(
                    isLabelVisible: notif.totalUnread > 0,
                    label: Text(
                        notif.totalUnread > 9 ? '9+' : '${notif.totalUnread}'),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.neonLime, AppTheme.neonLimeDark],
                        ),
                      ),
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.bell,
                            color: Colors.black87, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<StravaProvider>(
            builder: (context, strava, _) => Row(
              children: [
                NeonStatCard(
                  label: 'Runs',
                  value: '${strava.totalRuns}',
                  icon: FontAwesomeIcons.personRunning,
                ),
                const SizedBox(width: 12),
                NeonStatCard(
                  label: 'Distance',
                  value: '${strava.totalDistanceKm.toStringAsFixed(1)}km',
                  icon: FontAwesomeIcons.mapLocationDot,
                ),
                const SizedBox(width: 12),
                NeonStatCard(
                  label: 'Avg Pace',
                  value: strava.avgPace != null
                      ? strava.avgPace!.toStringAsFixed(1)
                      : '-',
                  icon: FontAwesomeIcons.gaugeHigh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, NavigationService navService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NeonActionButton(
                  icon: FontAwesomeIcons.circlePlay,
                  label: 'Start Run',
                  onPressed: navService.navigateToRunActivity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonActionButton(
                  icon: FontAwesomeIcons.userPlus,
                  label: 'Find Runners',
                  onPressed: () => widget.onNavigate?.call(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NeonActionButton(
                  icon: FontAwesomeIcons.strava,
                  label: 'Strava Sync',
                  onPressed: navService.navigateToStrava,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonActionButton(
                  icon: FontAwesomeIcons.peopleGroup,
                  label: 'My Groups',
                  onPressed: () => widget.onNavigate?.call(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyRunnersSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Runners',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => widget.onNavigate?.call(1),
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
                        color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada runner terdekat.\nPastikan lokasi sudah diset di profil.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _nearbyRunners.length,
                      itemBuilder: (context, i) {
                        final r = _nearbyRunners[i];
                        final user = r['user'] is Map
                            ? Map<String, dynamic>.from(r['user'])
                            : r;
                        final runnerName =
                            (user['name'] ?? r['name'] ?? r['full_name'] ?? 'Runner')
                                .toString();
                        final prefDist = r['preferred_distance'] ?? 0;
                        final pace = r['avg_pace'];
                        final distKm = r['distance_km'];
                        return RunnerListCard(
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
      ],
    );
  }
}
