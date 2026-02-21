import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/router/navigation_service.dart';
import 'core/router/route_names.dart';
import 'core/services/app_services.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/google_sign_in_service.dart';
import 'features/direct_match/direct_match_provider.dart';
import 'features/chat/chat_provider.dart';
import 'features/group_run/group_run_provider.dart';
import 'features/profile/profile_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/api/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required for auth)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize core services
  final storage = SecureStorageService();
  final initialToken = await storage.readToken();
  
  // Initialize auth services
  final authService = AuthService();
  final googleSignIn = GoogleSignInService();
  
  // Initialize remaining services (can be lazy loaded later)
  final apiService = ApiService(secureStorage: storage);
  final notificationService = NotificationService();
  
  // Start notification initialization in background
  notificationService.init().then((_) {
    // Notification service ready
  }).catchError((e) {
    print('Notification service init error: $e');
  });
  
  // Initialize AppServices
  final appServices = AppServices();
  await appServices.initialize(
    apiService: apiService,
    secureStorageService: storage,
    notificationService: notificationService,
  );

  runApp(
    MyApp(
      appServices: appServices,
      authService: authService,
      googleSignIn: googleSignIn,
      storage: storage,
      initialToken: initialToken,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppServices appServices;
  final AuthService authService;
  final GoogleSignInService googleSignIn;
  final SecureStorageService storage;
  final String? initialToken;
  final NavigationService _navService = NavigationService();

  MyApp({
    super.key,
    required this.appServices,
    required this.authService,
    required this.googleSignIn,
    required this.storage,
    this.initialToken,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Services (singleton, never rebuild)
        Provider<AppServices>.value(value: appServices),
        Provider<NavigationService>.value(value: _navService),

        // Auth (can rebuild when auth state changes)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService,
            googleSignIn,
            storage,
            initialToken: initialToken,
          ),
        ),

        // Theme (can rebuild when theme changes)
        ChangeNotifierProvider(create: (_) => AppTheme()),

        // Feature Providers (created on demand by feature pages)
        ChangeNotifierProvider(
          create: (_) => DirectMatchProvider(
            api: appServices.directMatchApi,
            storage: appServices.secureStorageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            api: appServices.chatApi,
            storage: appServices.secureStorageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupRunProvider(
            api: appServices.groupRunApi,
            storage: appServices.secureStorageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            api: appServices.profileApi,
            storage: appServices.secureStorageService,
          ),
        ),

        // Notification Service
        Provider.value(value: appServices.notificationService),
      ],
      child: _MaterialAppBuilder(navService: _navService),
    );
  }
}

/// Separate widget to rebuild only when auth/theme changes
class _MaterialAppBuilder extends StatelessWidget {
  final NavigationService navService;

  const _MaterialAppBuilder({required this.navService});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AppTheme>(
      builder: (context, auth, theme, _) => MaterialApp(
        title: 'Run Sync',
        debugShowCheckedModeBanner: false,
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.mode,
        navigatorKey: navService.navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: auth.isAuthenticated ? RouteNames.home : RouteNames.register,
      ),
    );
  }
}
