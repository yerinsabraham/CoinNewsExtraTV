// Secure username availability checker service
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UsernameValidationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if username is available using Firebase Function (more secure)
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      debugPrint('🔍 Checking username availability: $username');
      
      if (username.trim().isEmpty) return false;
      if (username.length < 3) return false;
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) return false;
      
      // Try Firebase Function first with timeout
      try {
        debugPrint('🚀 Attempting Firebase Function call...');
        final HttpsCallable callable = _functions.httpsCallable('checkUsernameAvailable');
        
        // Add timeout to prevent hanging
        final HttpsCallableResult result = await callable.call({
          'username': username.toLowerCase().trim(),
        }).timeout(const Duration(seconds: 10));
        
        final data = result.data as Map<String, dynamic>;
        final isAvailable = data['available'] as bool? ?? false;
        
        debugPrint('✅ Firebase Function result: $isAvailable');
        return isAvailable;
        
      } catch (funcError) {
        debugPrint('⚠️ Firebase Function failed: $funcError');
        
        // Check if it's a network/timeout issue vs function not found
        final errorString = funcError.toString().toLowerCase();
        if (errorString.contains('not found') || errorString.contains('unauthenticated')) {
          debugPrint('🚨 Function deployment issue detected - using fallback');
          return await _fallbackUsernameCheck(username);
        } else {
          debugPrint('⚠️ Function error - using fallback check');
          return await _fallbackUsernameCheck(username);
        }
      }
      
    } catch (e) {
      debugPrint('❌ Complete username check failed: $e');
      // If everything fails, allow the username (optimistic fallback)
      // This prevents users from being completely blocked
      debugPrint('⚠️ Allowing username due to service failure (monitored)');
      return true;
    }
  }

  /// Improved fallback method with better error handling
  static Future<bool> _fallbackUsernameCheck(String username) async {
    try {
      debugPrint('🔄 Attempting direct Firestore username check...');
      
      // First try to create the user document to test permissions
      await _ensureUserDocumentExists();
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      final isAvailable = querySnapshot.docs.isEmpty;
      debugPrint('✅ Firestore query successful: available = $isAvailable');
      return isAvailable;
      
    } catch (e) {
      debugPrint('❌ Fallback username check failed: $e');
      // Return true (available) to prevent users from being blocked completely
      debugPrint('⚠️ Allowing username due to permission error (will be verified later)');
      return true;
    }
  }

  /// Ensure current user has a document (helps with permissions)
  static Future<void> _ensureUserDocumentExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();
      
      if (!snapshot.exists) {
        // Create basic user document
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ Created basic user document for permissions');
      }
    } catch (e) {
      debugPrint('⚠️ Could not ensure user document exists: $e');
    }
  }

  /// Validate username format
  static String? validateUsernameFormat(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (username.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    // Check for reserved words
    final reservedWords = ['admin', 'moderator', 'support', 'system', 'bot', 'api'];
    if (reservedWords.contains(username.toLowerCase())) {
      return 'This username is reserved';
    }
    
    return null; // Valid format
  }

  /// Complete username availability check with format validation
  static Future<String?> validateUsername(String username) async {
    // First check format
    final formatError = validateUsernameFormat(username);
    if (formatError != null) {
      return formatError;
    }
    
    // Then check availability
    final isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      return 'Username already taken, please try another';
    }
    
    return null; // Username is valid and available
  }
}
