import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'core/auth/biometric_service.dart';
import 'features/direct_match/direct_match_provider.dart';
import 'features/chat/chat_provider.dart';
import 'features/group_run/group_run_provider.dart';
import 'features/profile/profile_provider.dart';
import 'features/strava/strava_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/location_service.dart';
import 'core/api/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required for auth)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize core services
  final storage = SecureStorageService();
  
  // Initialize auth services
  final authService = AuthService();
  final biometricService = BiometricService();
  
  // Initialize remaining services
  final apiService = ApiService(secureStorage: storage);
  final notificationService = NotificationService();
  
  // Start notification initialization in background
  notificationService.init().then((_) {
    // Notification service ready
  }).catchError((e) {
    if (kDebugMode) {
      debugPrint('Notification service init error: $e');
    }
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
      biometricService: biometricService,
      notificationService: notificationService,
      storage: storage,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppServices appServices;
  final AuthService authService;
  final BiometricService biometricService;
  final NotificationService notificationService;
  final SecureStorageService storage;
  final NavigationService _navService = NavigationService();

  MyApp({
    super.key,
    required this.appServices,
    required this.authService,
    required this.biometricService,
    required this.notificationService,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Services (singleton, never rebuild)
        Provider<AppServices>.value(value: appServices),
        Provider<NavigationService>.value(value: _navService),
        Provider<SecureStorageService>.value(value: storage),
        Provider<LocationService>(create: (_) => LocationService()),

        // Auth (can rebuild when auth state changes)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService,
            storage,
            biometric: biometricService,
            notificationService: notificationService,
            profileApi: appServices.profileApi,
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
            exploreApi: appServices.exploreApi,
            storage: appServices.secureStorageService,
            locationService: LocationService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            api: appServices.profileApi,
            storage: appServices.secureStorageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StravaProvider(
            api: appServices.stravaApi,
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
    return Consumer<AppTheme>(
      builder: (context, theme, _) => MaterialApp(
        title: 'Run Sync',
        debugShowCheckedModeBanner: false,
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.mode,
        navigatorKey: navService.navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: RouteNames.splash,
      ),
    );
  }
}
