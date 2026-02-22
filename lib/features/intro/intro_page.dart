import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/route_names.dart';
import '../../core/services/secure_storage_service.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroSlide> _slides = const [
    _IntroSlide(
      icon: FontAwesomeIcons.personRunning,
      title: 'Find Running Buddies',
      description:
          'Connect with nearby runners who match your pace and schedule. Never run alone again!',
      color: Color(0xFF42A5F5),
    ),
    _IntroSlide(
      icon: FontAwesomeIcons.peopleGroup,
      title: 'Join Group Runs',
      description:
          'Create or join group running sessions in your area. Motivation through community!',
      color: Color(0xFF66BB6A),
    ),
    _IntroSlide(
      icon: FontAwesomeIcons.shieldHalved,
      title: 'Safe & Secure',
      description:
          'Biometric login, encrypted data, and safety features to keep you protected.',
      color: Color(0xFFAB47BC),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final storage = Provider.of<SecureStorageService>(context, listen: false);
    await storage.setIntroSeen(true);
    if (mounted) {
      final nav = Provider.of<NavigationService>(context, listen: false);
      nav.navigateToAndClear(RouteNames.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/satupace-logo-panjang.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _onGetStarted,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildSlide(_slides[i], theme),
              ),
            ),

            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? _slides[i].color
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _onGetStarted();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage < _slides.length - 1
                            ? 'Next'
                            : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FaIcon(
                        _currentPage < _slides.length - 1
                            ? FontAwesomeIcons.arrowRight
                            : FontAwesomeIcons.rocket,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_IntroSlide slide, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: FaIcon(
                slide.icon,
                size: 48,
                color: slide.color,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
