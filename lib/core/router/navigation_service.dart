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
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigasi dan replace route sebelumnya
  Future<dynamic> navigateToAndReplace(
    String routeName, {
    Object? arguments,
  }) {
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigasi dan clear semua stack
  Future<dynamic> navigateToAndClear(String routeName) {
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  /// Navigasi ke home screen dan clear stack
  Future<dynamic> navigateToHomeAndClear() {
    return navigateToAndClear(RouteNames.home);
  }

  /// Pop current route
  void goBack() {
    final state = navigatorKey.currentState;
    if (state == null) return;
    state.pop();
  }

  /// Pop sampai route tertentu
  void popUntil(String routeName) {
    final state = navigatorKey.currentState;
    if (state == null) return;
    state.popUntil(
      ModalRoute.withName(routeName),
    );
  }

  /// Check apakah bisa pop (ada route sebelumnya)
  bool canPop() {
    final state = navigatorKey.currentState;
    if (state == null) return false;
    return state.canPop();
  }

  // --- Onboarding Navigation ---

  /// Navigate to intro page and clear stack
  Future<dynamic> navigateToIntroAndClear() {
    return navigateToAndClear(RouteNames.intro);
  }

  /// Navigate to OTP verification
  Future<dynamic> navigateToOtp() {
    return navigateToAndReplace(RouteNames.otp);
  }

  /// Navigate to biometric enable screen
  Future<dynamic> navigateToBiometric() {
    return navigateToAndReplace(RouteNames.enableBiometric);
  }

  /// Navigate to profile setup
  Future<dynamic> navigateToProfileSetup() {
    return navigateToAndReplace(RouteNames.profileSetup);
  }

  // --- Auth Navigation ---

  /// Navigate ke Login
  Future<dynamic> navigateToLogin() {
    return navigateToAndReplace(RouteNames.login);
  }

  /// Navigate to Login and clear stack
  Future<dynamic> navigateToLoginAndClear() {
    return navigateToAndClear(RouteNames.login);
  }

  /// Navigate to Register
  Future<dynamic> navigateToRegister() {
    return navigateToAndReplace(RouteNames.register);
  }

  // --- Feature Navigation ---

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

  /// Navigate ke Edit Profile
  Future<dynamic> navigateToEditProfile() {
    return navigateTo(RouteNames.editProfile);
  }

  /// Navigate ke Home
  Future<dynamic> navigateToHome() {
    return navigateTo(RouteNames.home);
  }

  /// Navigate to Run Activity
  Future<dynamic> navigateToRunActivity() {
    return navigateTo(RouteNames.runActivity);
  }

  /// Navigate to Smartwatch Sync
  Future<dynamic> navigateToStrava() {
    return navigateTo(RouteNames.strava);
  }
}
