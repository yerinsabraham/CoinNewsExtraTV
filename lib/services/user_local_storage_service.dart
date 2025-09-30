import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage user-specific local storage and handle account switching
class UserLocalStorageService {
  static const String _currentUserKey = 'current_logged_in_user';
  
  /// Check if user switched and clear old user data if needed
  static Future<void> handleUserSwitch() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      // User logged out, clear all data
      await clearAllUserData();
      return;
    }
    
    final currentUserId = currentUser.uid;
    final lastLoggedInUser = prefs.getString(_currentUserKey);
    
    if (lastLoggedInUser != null && lastLoggedInUser != currentUserId) {
      // User switched accounts, clear previous user's local data
      await clearUserSpecificData(lastLoggedInUser);
      print('🔄 Cleared local data for previous user: $lastLoggedInUser');
    }
    
    // Update current user
    await prefs.setString(_currentUserKey, currentUserId);
    print('✅ Set current user to: $currentUserId');
  }
  
  /// Clear all user data (on logout)
  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all keys and remove user-specific ones
    final keys = prefs.getKeys();
    final userDataKeys = keys.where((key) => 
      key.contains('_') && // User-specific keys contain underscores
      (key.contains('daily_spins_used_') ||
       key.contains('last_spin_date_') ||
       key.contains('last_') || // RewardService rate limits
       key.startsWith('user_') ||
       key.contains('checkin_'))
    ).toList();
    
    for (final key in userDataKeys) {
      await prefs.remove(key);
    }
    
    await prefs.remove(_currentUserKey);
    print('🗑️ Cleared all user data on logout');
  }
  
  /// Clear specific user's data
  static Future<void> clearUserSpecificData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove spin data for specific user
    await prefs.remove('daily_spins_used_$userId');
    await prefs.remove('last_spin_date_$userId');
    
    // Remove rate limit data for specific user (RewardService)
    final keys = prefs.getKeys();
    final userRateLimitKeys = keys.where((key) => key.endsWith('_$userId')).toList();
    
    for (final key in userRateLimitKeys) {
      await prefs.remove(key);
    }
    
    print('🗑️ Cleared local data for user: $userId');
  }
  
  /// Get user-specific key for SharedPreferences
  static Future<String?> getUserSpecificKey(String baseKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    return '${baseKey}_${user.uid}';
  }
  
  /// Initialize service (call on app startup)
  static Future<void> initialize() async {
    await handleUserSwitch();
  }
  
  /// Debug method to check current user data isolation
  static Future<void> debugUserDataIsolation() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('🔍 DEBUG: No user logged in');
      return;
    }
    
    final userId = currentUser.uid;
    print('🔍 DEBUG: Current user data for $userId:');
    print('   - Daily spins used: ${prefs.getInt('daily_spins_used_$userId') ?? 0}');
    print('   - Last spin date: ${prefs.getString('last_spin_date_$userId') ?? 'never'}');
    
    // Check for any old global keys (should be cleaned up)
    final globalSpins = prefs.getInt('daily_spins_used');
    final globalDate = prefs.getString('last_spin_date');
    
    if (globalSpins != null || globalDate != null) {
      print('⚠️ WARNING: Found old global keys - should be cleaned up!');
      print('   - Global spins: $globalSpins');
      print('   - Global date: $globalDate');
    } else {
      print('✅ No global keys found - data properly isolated');
    }
  }
}
