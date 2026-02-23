import 'package:flutter/material.dart';
import 'package:run_sync/features/notification/notification_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/otp_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_view_page.dart';
import '../../features/profile/profile_edit_page.dart';
import '../../features/profile/profile_setup_page.dart';
import '../../features/direct_match/direct_match_page.dart';
import '../../features/direct_match/direct_chat_page.dart';
import '../../features/group_run/group_run_page.dart';
import '../../features/group_run/group_detail_page.dart';
import '../../features/group_run/group_chat_page.dart';
import '../../features/group_run/group_form_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/intro/intro_page.dart';
import '../../features/auth/enable_biometric_page.dart';
import '../../features/run_activity/run_activity_page.dart';
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

      case RouteNames.directChat:
        final args = settings.arguments;
        if (args is! Map) {
          return _errorRoute('Direct chat arguments are required');
        }
        return _buildRoute(
          settings: settings,
          child: DirectChatPage(
            matchId: (args['matchId'] ?? '').toString(),
            partnerName: (args['partnerName'] ?? 'Runner').toString(),
          ),
        );

      case RouteNames.groupRun:
        return _buildRoute(
          settings: settings,
          child: const GroupRunPage(),
        );

      case RouteNames.groupChat:
        final args = settings.arguments;
        if (args is! Map) {
          return _errorRoute('Group chat arguments are required');
        }
        return _buildRoute(
          settings: settings,
          child: GroupChatPage(
            groupId: (args['groupId'] ?? '').toString(),
            groupName: (args['groupName'] ?? 'Grup').toString(),
            myRole: (args['myRole'] ?? '').toString(),
          ),
        );

      case RouteNames.groupDetail:
        final args = settings.arguments;
        String groupId = '';
        String myRole = '';
        if (args is String) {
          groupId = args;
        } else if (args is Map) {
          groupId = (args['groupId'] ?? '').toString();
          myRole = (args['myRole'] ?? '').toString();
        }
        if (groupId.isEmpty) {
          return _errorRoute('Group ID is required');
        }
        return _buildRoute(
          settings: settings,
          child: GroupDetailPage(groupId: groupId, myRole: myRole),
        );

      case RouteNames.groupForm:
        final group = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings: settings,
          child: GroupFormPage(group: group),
        );

      case RouteNames.runActivity:
        return _buildRoute(
          settings: settings,
          child: const RunActivityPage(),
        );

      case RouteNames.notifications:
        return _buildRoute(
          settings: settings,
          child: const NotificationPage(),
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
