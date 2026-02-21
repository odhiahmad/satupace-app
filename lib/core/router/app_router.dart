import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/otp_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_view_page.dart';
import '../../features/profile/profile_edit_page.dart';
import '../../features/profile/profile_setup_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/direct_match/direct_match_page.dart';
import '../../features/group_run/group_run_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/intro/intro_page.dart';
import '../../features/auth/enable_biometric_page.dart';
import '../../features/run_activity/run_activity_page.dart';
import '../../features/strava/strava_page.dart';
import 'route_names.dart';

/// Route generator untuk menangani navigation
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _buildRoute(
          settings: settings,
          child: const SplashPage(),
        );

      case RouteNames.intro:
        return _buildRoute(
          settings: settings,
          child: const IntroPage(),
        );

      case RouteNames.login:
        return _buildRoute(
          settings: settings,
          child: const LoginPage(),
        );

      case RouteNames.register:
        return _buildRoute(
          settings: settings,
          child: const RegisterPage(),
        );

      case RouteNames.otp:
        return _buildRoute(
          settings: settings,
          child: const OtpPage(),
        );

      case RouteNames.enableBiometric:
        return _buildRoute(
          settings: settings,
          child: const EnableBiometricPage(),
        );

      case RouteNames.profileSetup:
        return _buildRoute(
          settings: settings,
          child: const ProfileSetupPage(),
        );

      case RouteNames.home:
        return _buildRoute(
          settings: settings,
          child: const HomePage(),
        );

      case RouteNames.profile:
        return _buildRoute(
          settings: settings,
          child: const ProfileViewPage(),
        );

      case RouteNames.editProfile:
        return _buildRoute(
          settings: settings,
          child: const ProfileEditPage(),
        );

      case RouteNames.directMatch:
        return _buildRoute(
          settings: settings,
          child: const DirectMatchPage(),
        );

      case RouteNames.chat:
        return _buildRoute(
          settings: settings,
          child: const ChatPage(),
        );

      case RouteNames.chatThread:
        final chatId = settings.arguments as String?;
        if (chatId == null) {
          return _errorRoute('Chat ID is required');
        }
        return _buildRoute(
          settings: settings,
          child: ChatThreadPage(chatId: chatId),
        );

      case RouteNames.groupRun:
        return _buildRoute(
          settings: settings,
          child: const GroupRunPage(),
        );

      case RouteNames.runActivity:
        return _buildRoute(
          settings: settings,
          child: const RunActivityPage(),
        );

      case RouteNames.strava:
        return _buildRoute(
          settings: settings,
          child: const StravaPage(),
        );

      default:
        return _buildRoute(
          settings: settings,
          child: const SplashPage(),
        );
    }
  }

  /// Build material page route
  static MaterialPageRoute<dynamic> _buildRoute({
    required RouteSettings settings,
    required Widget child,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => child,
    );
  }

  /// Error route handler
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Route error: $message'),
        ),
      ),
    );
  }
}
