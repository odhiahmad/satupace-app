import 'package:flutter/material.dart';
import 'route_names.dart';

/// Service untuk navigasi aplikasi
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  late GlobalKey<NavigatorState> navigatorKey;

  NavigationService._internal() {
    navigatorKey = GlobalKey<NavigatorState>();
  }

  factory NavigationService() {
    return _instance;
  }

  /// Navigasi ke route dengan nama
  Future<dynamic> navigateTo(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigasi dan replace route sebelumnya
  Future<dynamic> navigateToAndReplace(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigasi ke home screen dan clear stack
  Future<dynamic> navigateToHomeAndClear() {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      RouteNames.home,
      (route) => false,
    );
  }

  /// Pop current route
  void goBack() {
    return navigatorKey.currentState!.pop();
  }

  /// Pop sampai route tertentu
  void popUntil(String routeName) {
    return navigatorKey.currentState!.popUntil(
      ModalRoute.withName(routeName),
    );
  }

  /// Check apakah bisa pop (ada route sebelumnya)
  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  /// Navigate ke Direct Match (Matches tab)
  Future<dynamic> navigateToMatches() {
    return navigateTo(RouteNames.directMatch);
  }

  /// Navigate ke Group Runs (Groups tab)
  Future<dynamic> navigateToGroups() {
    return navigateTo(RouteNames.groupRun);
  }

  /// Navigate ke Chat
  Future<dynamic> navigateToChat() {
    return navigateTo(RouteNames.chat);
  }

  /// Navigate ke Chat Thread
  Future<dynamic> navigateToChatThread(String chatId) {
    return navigateTo(
      RouteNames.chatThread,
      arguments: chatId,
    );
  }

  /// Navigate ke Profile
  Future<dynamic> navigateToProfile() {
    return navigateTo(RouteNames.profile);
  }

  /// Navigate ke Home
  Future<dynamic> navigateToHome() {
    return navigateTo(RouteNames.home);
  }

  /// Navigate ke Login
  Future<dynamic> navigateToLogin() {
    return navigateToAndReplace(RouteNames.login);
  }
}
