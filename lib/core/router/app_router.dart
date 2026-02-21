import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/direct_match/direct_match_page.dart';
import '../../features/group_run/group_run_page.dart';
import 'route_names.dart';

/// Route generator untuk menangani navigation
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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

      case RouteNames.home:
        return _buildRoute(
          settings: settings,
          child: const HomePage(),
        );

      case RouteNames.profile:
        return _buildRoute(
          settings: settings,
          child: const ProfilePage(),
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

      default:
        return _buildRoute(
          settings: settings,
          child: const HomePage(),
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
