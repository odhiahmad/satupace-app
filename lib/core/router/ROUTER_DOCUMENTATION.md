## RunSync Router System Documentation

### 🏗️ Architecture Overview

The app now uses a **centralized, dynamic routing system** following Flutter best practices:

#### Key Components:

1. **`routine_names.dart`** - Centralized route name constants
   - All route paths defined in one place
   - Makes refactoring easier
   - Type-safe route references

2. **`app_router.dart`** - Route generation and creation
   - Single source of truth for route mapping
   - Handles route arguments validation
   - Error handling for missing routes

3. **`navigation_service.dart`** - Navigation abstraction layer
   - Singleton service for navigation throughout app
   - No need to pass `BuildContext` for navigation
   - Centralized navigation logic
   - Easy to test and mock

### 📍 Route Structure

```
Routes defined:
- /              → Login/Splash
- /home          → Home (bottom nav)
- /profile       → Profile Page
- /direct-match  → Direct Match/Matches
- /chat          → Chat List
- /chat-thread   → Individual Chat Thread
- /group-run     → Group Run Page
```

### 🚀 Usage Examples

#### Navigation with NavigationService

```dart
// Get the navigation service
final navService = Provider.of<NavigationService>(context, listen: false);

// Navigate to profile
navService.navigateToProfile();

// Navigate to matches
navService.navigateToMatches();

// Navigate to chat thread with argument
navService.navigateToChatThread(chatId);

// Navigate and replace (for login flow)
navService.navigateToLogin();

// Go back
navService.goBack();

// Navigate to home and clear stack
navService.navigateToHomeAndClear();
```

#### In Widgets

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);
    
    return ElevatedButton(
      onPressed: () => navService.navigateToProfile(),
      child: const Text('Go to Profile'),
    );
  }
}
```

### ✅ Benefits

1. **Centralized Management** - All routes defined in one place
2. **No BuildContext Needed** - Use navigation service directly
3. **Type-Safe** - Named constants for route names
4. **Argument Passing** - Type-safe argument passing to routes
5. **Testable** - Easy to mock NavigationService
6. **Maintainable** - Changes to route structure only require updates in one place
7. **Error Handling** - Graceful handling of invalid routes

### 🔄 Flow Examples

#### Login Flow
```dart
// After successful login
navService.navigateToHomeAndClear(); // Clears login route from stack
```

#### Chat Navigation
```dart
// From chat list to chat thread
navService.navigateToChatThread(chatId);

// Going back from thread to list
navService.goBack();
```

#### Tab Navigation
```dart
// From Home page, navigate to Matches tab
onNavigate?.call(1); // Internal state change for tab navigation
```

### 📱 Integration with State Management (Provider)

The NavigationService is provided in the Provider tree:

```dart
Provider<NavigationService>.value(value: navService),
```

Access it anywhere in the app:
```dart
final navService = Provider.of<NavigationService>(context, listen: false);
```

### 🎯 Best Practices Implemented

✅ Single NavigatorKey managed by NavigationService  
✅ Centralized route generation with AppRouter  
✅ Named routes for type safety  
✅ Route arguments validated  
✅ Error routes for debugging  
✅ No hard-coded routes throughout app  
✅ Easy authentication flow management  
✅ Stack management with clear/replace operations  

### 📝 Adding New Routes

To add a new route:

1. **Add to `route_names.dart`**:
   ```dart
   static const String newRoute = '/new-route';
   ```

2. **Add route case in `app_router.dart`**:
   ```dart
   case RouteNames.newRoute:
     return _buildRoute(
       settings: settings,
       child: const NewPage(),
     );
   ```

3. **Add navigation method in `navigation_service.dart`** (optional):
   ```dart
   Future<dynamic> navigateToNewRoute() {
     return navigateTo(RouteNames.newRoute);
   }
   ```

4. **Use in app**:
   ```dart
   navService.navigateTo(RouteNames.newRoute);
   ```

---

This routing system provides a clean, maintainable, and scalable way to handle navigation across the RunSync application.
