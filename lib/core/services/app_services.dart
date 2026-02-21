/// Central service locator/container for all application services
library;
import '../api/api_service.dart';
import '../api/chat_api.dart';
import '../api/direct_match_api.dart';
import '../api/group_run_api.dart';
import '../api/profile_api.dart';
import '../api/run_activity_api.dart';
import '../api/safety_api.dart';
import '../api/explore_api.dart';
import '../api/media_api.dart';
import '../api/smartwatch_api.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class AppServices {
  static final AppServices _instance = AppServices._internal();

  late final ApiService apiService;
  late final ChatApi chatApi;
  late final DirectMatchApi directMatchApi;
  late final GroupRunApi groupRunApi;
  late final ProfileApi profileApi;
  late final RunActivityApi runActivityApi;
  late final SafetyApi safetyApi;
  late final ExploreApi exploreApi;
  late final MediaApi mediaApi;
  late final SmartwatchApi smartwatchApi;
  late final SecureStorageService secureStorageService;
  late final NotificationService notificationService;
  late final LocationService locationService;

  AppServices._internal();

  factory AppServices() => _instance;

  /// Initialize all services
  Future<void> initialize({
    required ApiService apiService,
    required SecureStorageService secureStorageService,
    required NotificationService notificationService,
  }) async {
    this.apiService = apiService;
    this.secureStorageService = secureStorageService;
    this.notificationService = notificationService;

    // Initialize API services
    chatApi = ChatApi(api: apiService);
    directMatchApi = DirectMatchApi(api: apiService);
    groupRunApi = GroupRunApi(api: apiService);
    profileApi = ProfileApi(api: apiService);
    runActivityApi = RunActivityApi(api: apiService);
    safetyApi = SafetyApi(api: apiService);
    exploreApi = ExploreApi(api: apiService);
    mediaApi = MediaApi(api: apiService);
    smartwatchApi = SmartwatchApi(api: apiService);

    // Initialize other services
    locationService = LocationService();
  }

  /// Reset all services (for logout, etc)
  Future<void> reset() async {
    // Clear storage
    await secureStorageService.deleteToken();
  }
}
