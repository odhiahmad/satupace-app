## RunSync Providers & Services Architecture

### 📱 Overview

The app now has a clean, organized architecture with:
- **Feature-specific Providers** for state management
- **Centralized AppServices** for dependency injection
- **API Services** for backend communication
- **Core Services** for sharing functionality (location, notifications, storage)

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────┐
│      UI Layer (Pages)            │
│  (Uses Providers via Consumer)   │
└────────────────┬──────────────────┘
                 │
┌────────────────▼──────────────────┐
│    Provider Layer (State Mgmt)     │
│  DirectMatchProvider               │
│  ChatProvider                      │
│  GroupRunProvider                  │
│  ProfileProvider                   │
│  AuthProvider                      │
│  AppTheme                          │
└────────────────┬──────────────────┘
                 │
┌────────────────▼──────────────────┐
│    AppServices (Dependency Mgmt)   │
│  - Service Locator                 │
│  - Initializes all services        │
└────────────────┬──────────────────┘
                 │
┌────────────────▼──────────────────┐
│    API & Core Services Layer       │
│  API Services (Chat, Match, etc)   │
│  SecureStorageService              │
│  NotificationService               │
│  LocationService                   │
└────────────────┬──────────────────┘
                 │
┌────────────────▼──────────────────┐
│    External Libraries              │
│  Firebase, Geolocator, etc         │
└────────────────────────────────────┘
```

---

## 📦 Providers

### 1️⃣ **DirectMatchProvider**
Location: `lib/features/direct_match/direct_match_provider.dart`

Manages direct match feature state:
```dart
// State
- matches: List<Map<String, dynamic>>
- loading: bool
- error: String?

// Methods
- fetchMatches(): Future<void>
- acceptMatch(String matchId): Future<bool>
- rejectMatch(String matchId): Future<bool>
- clearError(): void
```

**Usage in Widget:**
```dart
Consumer<DirectMatchProvider>(
  builder: (context, provider, _) {
    return ListView.builder(
      itemCount: provider.matches.length,
      itemBuilder: (_, i) {
        return Card(
          child: Text(provider.matches[i]['name']),
        );
      },
    );
  },
)
```

---

### 2️⃣ **ChatProvider**
Location: `lib/features/chat/chat_provider.dart`

Manages chat feature state:
```dart
// State
- chats: List<Map<String, dynamic>>
- _threads: Map<String, List<Map>>
- loading: bool
- error: String?

// Methods
- fetchChats(): Future<void>
- fetchThread(String chatId): Future<void>
- sendMessage(String chatId, String message): Future<bool>
- getThreadMessages(String chatId): List<Map>
- clearError(): void
- clearThread(String chatId): void
```

**Usage:**
```dart
// In ChatPage
Consumer<ChatProvider>(
  builder: (context, provider, _) {
    return provider.loading
      ? CircularProgressIndicator()
      : ListView.builder(
          itemCount: provider.chats.length,
          itemBuilder: (_, i) => ChatCard(data: provider.chats[i]),
        );
  },
)

// In ChatThreadPage
final messages = provider.getThreadMessages(chatId);
provider.sendMessage(chatId, messageText);
```

---

### 3️⃣ **GroupRunProvider**
Location: `lib/features/group_run/group_run_provider.dart`

Manages group runs feature:
```dart
// State
- groups: List<Map<String, dynamic>>
- myGroups: List<Map<String, dynamic>>
- loading: bool
- error: String?

// Methods
- fetchGroups(): Future<void>
- joinGroup(String groupId): Future<bool>
- leaveGroup(String groupId): Future<bool>
- clearError(): void
```

---

### 4️⃣ **ProfileProvider**
Location: `lib/features/profile/profile_provider.dart`

Manages user profile:
```dart
// State
- profile: Map<String, dynamic>?
- loading: bool
- saving: bool
- error: String?

// Getters for convenience
- name, email, avgPace, preferredDistance, latitude, longitude

// Methods
- fetchProfile(): Future<void>
- updateProfile(Map<String, dynamic>): Future<bool>
- updateName(String): Future<bool>
- updateEmail(String): Future<bool>
- updatePace(double): Future<bool>
- updatePreferredDistance(int): Future<bool>
- updateLocation(double, double): Future<bool>
- clearError(): void
```

---

## 🔧 AppServices (Service Locator)

Location: `lib/core/services/app_services.dart`

Singleton pattern for dependency injection:

```dart
class AppServices {
  // Single instance
  static final AppServices _instance = AppServices._internal();

  // Services
  late ApiService apiService;
  late ChatApi chatApi;
  late DirectMatchApi directMatchApi;
  late GroupRunApi groupRunApi;
  late ProfileApi profileApi;
  late SecureStorageService secureStorageService;
  late NotificationService notificationService;
  late LocationService locationService;

  // Initialize once in main()
  Future<void> initialize({
    required ApiService apiService,
    required SecureStorageService secureStorageService,
    required NotificationService notificationService,
  }) async { ... }

  // Reset on logout
  Future<void> reset() async {
    await secureStorageService.deleteToken();
  }
}
```

**Usage:**
```dart
// Access anywhere
final appServices = Provider.of<AppServices>(context, listen: false);
final chatApi = appServices.chatApi;
final location = appServices.locationService;
```

---

## 🚀 Initialization in main.dart

```dart
Future<void> main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // 3. Initialize services
  final notificationService = NotificationService();
  await notificationService.init();

  final storage = SecureStorageService();
  final initialToken = await storage.readToken();
  final apiService = ApiService(secureStorage: storage);

  // 4. Initialize AppServices
  final appServices = AppServices();
  await appServices.initialize(
    apiService: apiService,
    secureStorageService: storage,
    notificationService: notificationService,
  );

  // 5. Run app
  runApp(MyApp(appServices: appServices, initialToken: initialToken));
}
```

---

## 📡 Data Flow Example

### Chat Feature Flow:

1. **User opens Chat Page**
   ```
   initState() 
     → WidgetsBinding.addPostFrameCallback() 
       → provider.fetchChats()
   ```

2. **Provider fetches data**
   ```
   fetchChats() {
     _loading = true;
     notifyListeners();
     
     token = await storage.readToken();
     _chats = await api.fetchChats(token: token);
     
     _loading = false;
     notifyListeners();
   }
   ```

3. **UI rebuilds with Consumer**
   ```
   Consumer<ChatProvider>(
     builder: (_, provider, __) {
       if (provider.loading) return Spinner;
       if (provider.error) return Error widget;
       return ListView(provider.chats);
     }
   )
   ```

4. **User taps chat**
   ```
   onTap: () {
     navService.navigateToChatThread(chatId);
     provider.fetchThread(chatId);
   }
   ```

5. **Thread loads and displays**
   ```
   messages = provider.getThreadMessages(chatId);
   ListView(messages);
   ```

6. **User sends message**
   ```
   onPressed: () {
     provider.sendMessage(chatId, message);
     // Provider updates _threads[chatId]
     // UI automatically rebuilds
   }
   ```

---

## ✅ Benefits of This Architecture

| Feature | Benefit |
|---------|---------|
| **Separation of Concerns** | UI logic separate from business logic |
| **Easy Testing** | Mock providers and services for unit tests |
| **Code Reusability** | Providers can be used in multiple screens |
| **State Management** | Automatic UI updates with Provider |
| **Dependency Injection** | AppServices manages all dependencies |
| **Single Source of Truth** | Each provider owns its feature's state |
| **Error Handling** | Centralized error states in providers |
| **Offline Support** | Providers can cache data locally |

---

## 🔄 Provider Usage Patterns

### Pattern 1: Read-Only (Consumer)
```dart
Consumer<DirectMatchProvider>(
  builder: (_, provider, __) => Text(provider.matches.length.toString()),
)
```

### Pattern 2: With State Change (Selector)
```dart
Selector<DirectMatchProvider, bool>(
  selector: (_, provider) => provider.loading,
  builder: (_, isLoading, __) => 
    isLoading ? Spinner() : Content(),
)
```

### Pattern 3: Direct Access (least common)
```dart
final provider = Provider.of<DirectMatchProvider>(context);
provider.acceptMatch(id);
```

### Pattern 4: Multiple Providers
```dart
Consumer2<ChatProvider, NotificationService>(
  builder: (_, chat, notif, __) {
    // Use both providers
  },
)
```

---

## 🐛 Error Handling

Each provider has built-in error handling:

```dart
try {
  // Fetch data
  _matches = await _api.fetchMatches(token: token);
} catch (e) {
  _error = e.toString();
  notifyListeners();
  
  // UI shows error widget with Retry button
  ElevatedButton(
    onPressed: () => provider.fetchMatches(),
    child: Text('Retry'),
  )
}
```

---

## 📝 Adding a New Feature

To add a new feature (e.g., "Events"):

1. **Create EventsProvider**
   ```dart
   class EventsProvider with ChangeNotifier {
     List<Map> _events = [];
     bool _loading = false;
     String? _error;
     
     Future<void> fetchEvents() { ... }
   }
   ```

2. **Add to AppServices**
   ```dart
   late EventsApi eventsApi;
   // Initialize in initialize()
   eventsApi = EventsApi(api: apiService);
   ```

3. **Add to main.dart providers**
   ```dart
   ChangeNotifierProvider(
     create: (_) => EventsProvider(
       api: appServices.eventsApi,
       storage: appServices.secureStorageService,
     ),
   ),
   ```

4. **Create EventsPage with Consumer**
   ```dart
   Consumer<EventsProvider>(
     builder: (_, provider, __) {
       // Use provider.events, provider.loading, etc
     },
   )
   ```

---

## 🎯 Best Practices

✅ **DO:**
- Use `listen: false` when you only need one-time values
- Use `Consumer` when UI needs to rebuild
- Keep providers focused on one feature
- Handle errors in providers
- Use AppServices for dependency injection

❌ **DON'T:**
- Access providers in initState (use addPostFrameCallback)
- Update state directly (use async methods)
- Hold context in providers
- Make providers dependent on each other
- Ignore error states in UI

---

This architecture provides a scalable, maintainable, and testable foundation for the RunSync app! 🚀
