import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  FirebaseAuth? _firebaseAuth;
  final _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInit;

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  FirebaseAuth get _auth => _firebaseAuth ??= FirebaseAuth.instance;

  Future<void> _ensureGoogleInitialized() {
    _googleInit ??= _googleSignIn.initialize();
    return _googleInit!;
  }

  /// Sign in with Google using Firebase Auth
  /// Note: This requires google_sign_in package to be properly initialized
  /// For web: Add Google OAuth client ID to Firebase config
  /// For Android: Configure OAuth in Firebase Console with SHA-1 fingerprint
  /// For iOS: Configure OAuth in Firebase Console + Info.plist
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final googleUser = _googleSignIn.supportsAuthenticate()
          ? await _googleSignIn.authenticate(scopeHint: ['email', 'profile'])
          : await (_googleSignIn.attemptLightweightAuthentication(reportAllExceptions: false)
                  ?? Future<GoogleSignInAccount?>.value(null));

      if (googleUser == null) return null;
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google sign-in failed: missing idToken.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google sign-in failed: user unavailable.');
      }

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'idToken': googleAuth.idToken,
        'accessToken': null,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up with Google (same as sign in - Firebase handles new account creation)
  Future<Map<String, dynamic>?> signUpWithGoogle() async {
    return signInWithGoogle();
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    await _googleSignIn.signOut();
    if (_firebaseAuth != null) {
      await _firebaseAuth!.signOut();
    }
  }

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth?.currentUser;
}

