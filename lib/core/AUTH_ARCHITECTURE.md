## RunSync Architecture - Updated Structure

### 📁 Folder Organization

```
lib/
├── core/
│   ├── auth/               # Authentication business logic (MOVED HERE - Core concern)
│   │   ├── auth_provider.dart       # State management for auth (supports email + Google)
│   │   ├── auth_service.dart        # API service for email/password auth
│   │   └── google_sign_in_service.dart  # Google OAuth integration with Firebase
│   ├── router/             # Navigation & routing
│   │   ├── app_router.dart
│   │   ├── navigation_service.dart
│   │   └── route_names.dart
│   ├── services/           # Core services
│   │   ├── app_services.dart        # Service locator
│   │   ├── notification_service.dart
│   │   ├── location_service.dart
│   │   └── secure_storage_service.dart
│   ├── theme/
│   │   └── app_theme.dart           # Neon lime dark theme
│   └── api/
│       └── api_service.dart         # HTTP client wrapper
│
├── features/
│   ├── auth/               # Auth UI Pages ONLY (business logic in core/)
│   │   ├── login_page.dart          # Email + Google signin
│   │   ├── register_page.dart       # Email + Google signup (NEW)
│   │   ├── auth_provider.dart       # RE-EXPORT for backward compat
│   │   └── auth_service.dart        # RE-EXPORT for backward compat
│   ├── home/
│   │   ├── home_page.dart
│   │   └── [other home files]
│   ├── chat/
│   │   ├── chat_page.dart
│   │   ├── chat_provider.dart
│   │   └── [other chat files]
│   ├── [other features]
│   │
│   └── PROVIDERS_ARCHITECTURE.md    # Documentation
│
├── shared/
│   ├── components/
│   ├── widgets/
│   └── [shared assets]
│
├── main.dart
├── firebase_options.dart
└── [other top-level files]
```

### 🔄 Authentication Flow

#### **Email/Password Login & Signup**
1. User enters credentials in LoginPage / RegisterPage
2. AuthProvider calls AuthService.login() or signup()
3. Backend validates and returns token
4. Token stored in SecureStorageService
5. Redirect to HomePage

#### **Google Sign-In / Sign-Up**
1. User taps "Continue with Google" button
2. GoogleSignInService.signInWithGoogle() / signUpWithGoogle() called
3. Google SDK opens native picker, user selects account
4. GoogleSignInService gets access token & ID token
5. Tokens passed to Firebase via GoogleAuthProvider.credential()
6. Firebase verifies and returns FirebaseUser
7. User data stored, redirect to HomePage

### 📦 Key Files & Their Purposes

#### Core Auth (Business Logic)
- **`lib/core/auth/auth_provider.dart`** (135 lines)
  - ChangeNotifier managing authentication state
  - Methods: `login()`, `loginWithGoogle()`, `logout()`, `clearError()`
  - Getters: `isAuthenticated`, `token`, `name`, `loading`, `error`

- **`lib/core/auth/auth_service.dart`** (58 lines)
  - Implements AuthServiceBase interface
  - HTTP client for email/password authentication
  - Fallback to mock token for local development

- **`lib/core/auth/google_sign_in_service.dart`** (93 lines)
  - Singleton service wrapping google_sign_in package
  - Methods: ` signInWithGoogle()`, `signUpWithGoogle()`, `signOut()`
  - Integrates with Firebase Auth via GoogleAuthProvider

#### Auth UI (Pages)
- **`lib/features/auth/login_page.dart`** (330 lines)
  - Email/password login form
  - Google Sign-in button
  - Link to register page
  - Error handling & loading states

- **`lib/features/auth/register_page.dart`** (350 lines, NEW)
  - User registration with name, email, password
  - Password confirmation validation
  - Google Sign-up button
  - Link back to login

### 🎯 Why This Structure is Better

**Before (❌ Anti-pattern):**
```
features/auth/auth_provider.dart
features/auth/auth_service.dart
features/auth/login_page.dart
```
- Auth business logic mixed with UI feature
- Auth should be core concern, not feature-specific
- Easy to accidentally couple UI to business logic

**After (✅ Best Practice):**
```
core/auth/auth_provider.dart       ← Pure business logic
core/auth/auth_service.dart        ← Pure business logic
core/auth/google_sign_in_service.dart ← Pure business logic
features/auth/login_page.dart      ← UI layer ONLY
features/auth/register_page.dart   ← UI layer ONLY
```
- Clear separation of concerns
- Auth logic is reusable across multiply features
- Easy to test business logic independently
- Follows clean architecture principles

### 🔐 Security Considerations

1. **Token Storage**: SecureStorageService uses flutter_secure_storage (encrypted)
2. **Google OAuth**: Uses official google_sign_in package + Firebase Auth
3. **Firebase Rules**: Set up Firestore/Realtime DB rules to require authentication
4. **Environment**: Replace 'https://api.example.com' with actual backend URL

### 📱 Supported Auth Methods

✅ Email/Password (custom backend)
✅ Google Sign-In/Sign-Up (Firebase)
⏳ Future: Apple Sign-In, Facebook, Email verification

### 🚀 Using Auth in Other Features

```dart
// In any feature page
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }
    return YourFeaturePage();
  },
)

// In services
final authToken = context.read<AuthProvider>().token;
final userName = context.read<AuthProvider>().name;
```

### ⚙️ Configuration Steps

1. **Firebase Setup:**
   - Create Firebase project
   - Enable Authentication (Email/Password, Google)
   - Download google-services.json to android/app/

2. **Google Sign-In Setup:**
   - Go to Firebase Console → Authentication → Google Provider
   - Add Android SHA-1 fingerprint: `keytool -list -v -keystore ~/.android/debug.keystore`
   - Enable Google Sign-In in Firebase Console

3. **Backend Setup:**
   - Update baseURL in AuthService from 'https://api.example.com'
   - Implement /login and /logout endpoints
   - Return { "ok": true, "data": { "token": "...", "name": "..." } }

### 🧪 Testing Auth

```dart
// Test login
final authService = FakeAuthService(shouldSucceed: true);
final googleSignIn = GoogleSignInService();
final provider = AuthProvider(authService, googleSignIn, null);
final ok = await provider.login('test@example.com', 'password');
expect(ok, isTrue);
expect(provider.isAuthenticated, isTrue);
```

### Clean-up Applied
- ✅ Moved auth logic to core/auth
- ✅ Features/auth now RE-EXPORTS for backward compatibility
- ✅ Created register_page.dart for signup
- ✅ Updated test files with correct imports
- ✅ Added register route to app_router
- ✅ Fixed app_router dead code issues
