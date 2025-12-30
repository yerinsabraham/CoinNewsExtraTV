import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Convert technical Firebase/Auth errors into friendly, human-readable messages.
String formatAuthError(Object error) {
  // FirebaseAuthException with known codes
  if (error is FirebaseAuthException) {
    final code = error.code.toLowerCase();
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address. Please check the format.';
      case 'wrong-password':
        return 'Incorrect password. Try again or reset your password.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support if this is unexpected.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'requires-recent-login':
        return 'Please re-authenticate to continue.';
      case 'account-exists-with-different-credential':
        return 'An account already exists for this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This sign-in credential is already linked to another account.';
      case 'popup-closed-by-user':
      case 'canceled':
        return 'Sign-in was canceled.';
      default:
        // If Firebase provides a message, prefer it but make it clean.
        if (error.message != null && error.message!.isNotEmpty) {
          return error.message!;
        }
    }
  }

  // GoogleSignInException mapping
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Sign-in was canceled.';
    }
    return 'Google sign-in failed. Please try again.';
  }

  // Generic Firebase exceptions (e.g., channel errors)
  if (error is FirebaseException) {
    final msg = (error.message ?? '').toLowerCase();
    if (error.plugin == 'firebase_auth') {
      if (msg.contains('channel-error')) {
        return 'There was a problem communicating with Firebase Auth. Please try again or restart the app.';
      }
      if (msg.contains('network')) {
        return 'Network error. Please check your connection.';
      }
    }
    // Fallback to provided message if any
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }

  // PlatformException mapping
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    if (code.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (code.contains('channel')) {
      return 'A system error occurred while contacting the authentication service.';
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }

  // String messages that include known firebase_auth channel errors
  if (error is String) {
    final msg = error.toLowerCase();
    if (msg.contains('firebase_auth/channel-error')) {
      return 'There was a problem communicating with Firebase Auth. Please try again.';
    }
    return error;
  }

  // Final fallback
  return 'Something went wrong. Please try again.';
}
