import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    
    // Initialize notification service and collect FCM token after successful login
    await _initializeNotificationsAfterLogin();
    
    return result;
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
      print('Error initializing notifications after login: $e');
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
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
