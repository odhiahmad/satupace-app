import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/navigation_service.dart';
import '../../core/services/app_services.dart';
import '../../core/services/secure_storage_service.dart';
import '../../shared/components/neon_action_button.dart';
import '../../shared/components/neon_stat_card.dart';
import '../../shared/components/runner_list_card.dart';
import '../direct_match/direct_match_page.dart';
import '../group_run/group_run_page.dart';
import '../profile/profile_provider.dart';
import '../profile/profile_view_page.dart';
import '../run_activity/run_activity_provider.dart';
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
      profileProvider.clearProfile();
      await auth.logout();
      navService.navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/satupace-logo-panjang.png',
          height: 32,
          fit: BoxFit.contain,
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
                label: Text(notif.matchUnread > 9 ? '9+' : '${notif.matchUnread}'),
                child: const FaIcon(FontAwesomeIcons.userGroup, size: 20),
              ),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: notif.groupUnread > 0,
                label: Text(notif.groupUnread > 9 ? '9+' : '${notif.groupUnread}'),
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
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider = Provider.of<RunActivityProvider>(context, listen: false);

    if (profile.profile == null) {
      await profile.fetchProfile();
    }

    final userId = auth.userId;
    if (userId != null) {
      activityProvider.loadActivities(userId);
    }

    await _loadNearbyRunners();
  }

  Future<void> _refresh() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider = Provider.of<RunActivityProvider>(context, listen: false);

    await profile.refreshProfile();

    final userId = auth.userId;
    if (userId != null) {
      activityProvider.loadActivities(userId);
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

      if (lat != null && lng != null && lat != 0 && lng != 0) {
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Welcome Banner ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _WelcomeBanner(
              name: auth.name,
              onNotificationTap: () => navService.navigateToNotification(),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Actions
                const _HomeSectionHeader(label: 'Aksi Cepat'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NeonActionButton(
                        icon: FontAwesomeIcons.userPlus,
                        label: 'Temukan Runner',
                        subtitle: 'Cari pasangan lari',
                        onPressed: () => widget.onNavigate?.call(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonActionButton(
                        icon: FontAwesomeIcons.peopleGroup,
                        label: 'Grup Lari',
                        subtitle: 'Bergabung atau buat',
                        onPressed: () => widget.onNavigate?.call(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Weekly Stats
                _buildWeeklyStats(context),

                // Nearby Runners
                _buildNearbyRunnersSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(BuildContext context) {
    return Consumer<RunActivityProvider>(
      builder: (_, provider, _) {
        if (provider.weeklyRuns == 0 && !provider.loading) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HomeSectionHeader(label: 'Minggu Ini'),
            const SizedBox(height: 10),
            Row(
              children: [
                NeonStatCard(
                  icon: FontAwesomeIcons.route,
                  label: 'Jarak',
                  value: '${provider.weeklyDistanceKm} km',
                ),
                const SizedBox(width: 8),
                NeonStatCard(
                  icon: FontAwesomeIcons.personRunning,
                  label: 'Sesi Lari',
                  value: '${provider.weeklyRuns}x',
                ),
                const SizedBox(width: 8),
                NeonStatCard(
                  icon: FontAwesomeIcons.gaugeHigh,
                  label: 'Avg Pace',
                  value: provider.weeklyAvgPace > 0
                      ? '${provider.weeklyAvgPace} /km'
                      : '-',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildNearbyRunnersSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _HomeSectionHeader(label: 'Runner Terdekat'),
            TextButton(
              onPressed: () => widget.onNavigate?.call(1),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loadingRunners)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_nearbyRunners.isEmpty)
          _EmptyRunnersCard(isDark: isDark, cs: cs)
        else
          ...(_nearbyRunners.map((r) {
            final user = r['user'] is Map
                ? Map<String, dynamic>.from(r['user'])
                : r;
            final runnerName =
                (user['name'] ?? r['name'] ?? r['full_name'] ?? 'Runner')
                    .toString();
            final prefDist = r['preferred_distance'] ?? 0;
            final pace = r['avg_pace'];
            final distKm = r['distance_km'];
            final imageUrl = (r['image'] ?? user['image'])?.toString();

            return RunnerListCard(
              name: runnerName,
              distance: '$prefDist km',
              pace: pace != null
                  ? '${(pace as num).toStringAsFixed(1)} min/km'
                  : '-',
              location: distKm != null
                  ? '${(distKm as num).toStringAsFixed(1)} km'
                  : '-',
              imageUrl: imageUrl,
            );
          })),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome Banner
// ---------------------------------------------------------------------------

class _WelcomeBanner extends StatelessWidget {
  final String? name;
  final VoidCallback onNotificationTap;

  const _WelcomeBanner({this.name, required this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkSurfaceVariant]
              : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name ?? 'Runner',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Ayo temukan teman lari hari ini!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Consumer<ChatNotificationProvider>(
            builder: (_, notif, _) => GestureDetector(
              onTap: onNotificationTap,
              child: Badge(
                isLabelVisible: notif.totalUnread > 0,
                label: Text(
                  notif.totalUnread > 9 ? '9+' : '${notif.totalUnread}',
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.bell,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty runners state
// ---------------------------------------------------------------------------

class _EmptyRunnersCard extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;

  const _EmptyRunnersCard({required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          FaIcon(FontAwesomeIcons.locationDot, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Tidak ada runner terdekat',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan lokasi sudah diset di profil kamu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _HomeSectionHeader extends StatelessWidget {
  final String label;
  const _HomeSectionHeader({required this.label});

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
