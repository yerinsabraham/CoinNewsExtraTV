import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;

  // Web Client ID for Android serverClientId
  static const String? _androidWebClientId =
      '889552494681-52shssr5ar3pvde98g6u485j3o0e2ula.apps.googleusercontent.com';
  // iOS client ID from GoogleService-Info.plist - SDK reads it automatically
  static const String? _iosClientId =
      '889552494681-11gfg580lk58u8hbsglf5i1ircamougq.apps.googleusercontent.com';

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    try {
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

      await GoogleSignIn.instance.initialize(
        // iOS reads clientId from GoogleService-Info.plist automatically
        clientId: isIOS ? null : _androidWebClientId,
        // Android uses web client as serverClientId; iOS doesn't need it for basic auth
        serverClientId: isAndroid ? _androidWebClientId : null,
      );
      _googleInitialized = true;
      debugPrint('✅ Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Google Sign-In initialization error: $e');
      _googleInitialized = true; // Mark as initialized even if it fails
    }
  }

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔑 Starting Google Sign-In...');
      await _ensureGoogleInitialized();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        debugPrint('❌ Google Sign-In authenticate() not supported on this platform');
        throw FirebaseAuthException(
          code: 'unavailable',
          message: 'Google sign-in is not supported on this platform.',
        );
      }

      debugPrint('🔑 Calling authenticate()...');
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      debugPrint('✅ Got Google account: ${account.email}');

      // In v7, authentication contains only idToken; that's sufficient for Firebase.
      final GoogleSignInAuthentication authentication = account.authentication;
      debugPrint('🔑 Got authentication tokens');
      
      if (authentication.idToken == null) {
        debugPrint('❌ No idToken received from Google');
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google sign-in failed to provide authentication token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: authentication.idToken,
      );
      debugPrint('🔑 Created Firebase credential');

      final result = await _auth.signInWithCredential(credential);
      debugPrint('✅ Successfully signed in with Firebase: ${result.user?.email}');
      
      await _initializeNotificationsAfterLogin();
      return result;
    } on GoogleSignInException catch (e) {
      debugPrint('❌ GoogleSignInException: code=${e.code}');
      // Convert GoogleSignInException to FirebaseAuthException for consistent error handling
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'Sign-in was canceled.',
        );
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-error',
        message: 'Google sign-in failed. Please check your configuration.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error during Google sign-in: $e');
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'An unexpected error occurred during Google sign-in.',
      );
    }
  }

  // Email/Password sign-in
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    // Initialize notification service and collect FCM token after successful login
    await _initializeNotificationsAfterLogin();
    
    return result;
  }

  // Initialize notifications after login
  static Future<void> _initializeNotificationsAfterLogin() async {
    try {
      // Ensure notification service is initialized
      if (!NotificationService().isInitialized) {
        await NotificationService().initialize();
      }
    } catch (e) {
      debugPrint('Error initializing notifications after login: $e');
    }
  }

  // Email/Password sign-up
  static Future<UserCredential> createUserWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    // Clear FCM token before signing out
    await NotificationService().clearFCMToken();
    
    // sign out from both providers
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
