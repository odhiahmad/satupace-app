import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:run_sync/core/theme/app_theme.dart';

class LoadingPage extends StatefulWidget {
  final String? message;

  const LoadingPage({
    super.key,
    this.message = 'Getting ready...',
  });

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _bobController;

  @override
  void initState() {
    super.initState();

    // Main rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Bob up and down
    _bobController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBg.withValues(alpha: 0.95),
                AppTheme.darkBg.withValues(alpha: 0.98),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon with rotation, pulse, and bob effects
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _rotationController,
                    _pulseController,
                    _bobController,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        _bobController.value * 15 - 7.5,
                      ),
                      child: Transform.rotate(
                        angle: _rotationController.value * 2 * 3.14159,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.1)
                              .animate(_pulseController),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonLime
                                      .withValues(alpha: _pulseController.value * 0.6),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              FontAwesomeIcons.heartPulse,
                              size: 60,
                              color: AppTheme.neonLime,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                // Message text
                Text(
                  widget.message ?? 'Getting ready...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Animated dots below text
                SizedBox(
                  width: 100,
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final delay = index * 0.15;
                          final progress = (_pulseController.value + delay) % 1.0;
                          final opacity = (progress < 0.5)
                              ? progress * 2
                              : (1 - progress) * 2;

                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.neonLime
                                  .withValues(alpha: opacity.clamp(0, 1)),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
