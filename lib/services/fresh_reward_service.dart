import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Clean, minimal reward service - bulletproof implementation
class FreshRewardService {
  late final FirebaseFunctions _functions;
  final _auth = FirebaseAuth.instance;

  FreshRewardService() {
    // Initialize functions with proper region and auth linkage
    _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    print('🔧 FreshRewardService initialized with region: us-central1');
    print('🔧 Firebase Auth app: ${_auth.app.name}');
    print('🔧 Firebase Functions app: ${_functions.app.name}');
  }

  /// Ensure user is authenticated and ready
  Future<User> _ensureAuthenticated() async {
    // Wait for auth state to stabilize
    await _auth.authStateChanges().first;
    
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated - please sign in first');
    }
    
    print('🔐 Auth check: User ${user.uid} authenticated');
    return user;
  }

  /// Get current user balance with explicit auth
  Future<int> getBalance() async {
    try {
      // Ensure user is authenticated and ready
      final user = await _ensureAuthenticated();
      print('📊 FreshRewardService: Getting balance for user: ${user.uid}');
      
      // Force refresh ID token to ensure it's fresh and valid
      final token = await user.getIdToken(true);
      print('🔑 Got fresh ID token length: ${token?.length ?? 0}');
      
      if (token == null || token.isEmpty) {
        throw Exception('Failed to get valid ID token');
      }
      
      // Create a completely fresh Functions instance to ensure proper auth linkage
      final freshAuth = FirebaseAuth.instance;
      final freshFunctions = FirebaseFunctions.instanceFor(
        region: 'us-central1',
        app: freshAuth.app, // Explicitly link to the same app as auth
      );
      
      print('🔧 Fresh functions app: ${freshFunctions.app.name}');
      print('🔧 Fresh auth app: ${freshAuth.app.name}');
      print('🔧 Current user: ${freshAuth.currentUser?.uid}');
      
      // Wait for auth token to propagate to Firebase SDK
      await Future.delayed(Duration(seconds: 3));
      
      // Use the fresh functions instance with manual token passing
      print('🚀 Calling getBalance function with manual token...');
      final callable = freshFunctions.httpsCallable("getBalance");
      final result = await callable.call({
        'idToken': token, // Pass token manually as backup
      });
      
      final balance = result.data["balance"] ?? 0;
      print('✅ FreshRewardService: Balance retrieved: $balance');
      return balance;
    } catch (e) {
      print('❌ FreshRewardService: Error getting balance: $e');
      print('❌ Full error details: ${e.toString()}');
      rethrow;
    }
  }

  /// Debug connection test
  Future<Map<String, dynamic>> debugConnection() async {
    try {
      print('🔧 FreshRewardService: Testing connection...');
      
      // Try to ensure auth is ready first
      try {
        final user = await _ensureAuthenticated();
        final token = await user.getIdToken(true);
        print('🔧 Auth ready: ${user.uid}, token: ${token?.substring(0, 20)}...');
      } catch (e) {
        print('🔧 Auth not ready: $e');
      }
      
      final result = await _functions.httpsCallable("debugConnection").call();
      
      print('🔧 Connection test result: ${result.data}');
      return result.data;
    } catch (e) {
      print('❌ FreshRewardService: Debug connection failed: $e');
      rethrow;
    }
  }

  /// Test balance function without auth requirement
  Future<Map<String, dynamic>> testGetBalance() async {
    try {
      print('🧪 FreshRewardService: Testing balance without auth...');
      
      String testUid = 'test-user';
      // Try to get real user ID if authenticated
      try {
        final user = _auth.currentUser;
        if (user != null) {
          testUid = user.uid;
          print('🧪 Using real user ID: $testUid');
        }
      } catch (e) {
        print('🧪 Using test user ID: $testUid');
      }
      
      final result = await _functions.httpsCallable("testGetBalance").call({
        'uid': testUid,
      });
      
      print('🧪 Test balance result: ${result.data}');
      return result.data;
    } catch (e) {
      print('❌ FreshRewardService: Test balance failed: $e');
      rethrow;
    }
  }

  /// Claim reward for specific source and amount
  Future<int> claimReward(String source, int amount) async {
    try {
      // Ensure user is authenticated and ready
      final user = await _ensureAuthenticated();
      print('🎯 FreshRewardService: Claiming reward - source: $source, amount: $amount, user: ${user.uid}');
      
      // Force refresh ID token to ensure it's fresh and valid
      final token = await user.getIdToken(true);
      print('🔑 Got fresh ID token length: ${token?.length ?? 0}');
      
      if (token == null || token.isEmpty) {
        throw Exception('Failed to get valid ID token');
      }
      
      // Create a completely fresh Functions instance to ensure proper auth linkage
      final freshAuth = FirebaseAuth.instance;
      final freshFunctions = FirebaseFunctions.instanceFor(
        region: 'us-central1',
        app: freshAuth.app, // Explicitly link to the same app as auth
      );
      
      print('🔧 Fresh functions app: ${freshFunctions.app.name}');
      print('🔧 Fresh auth app: ${freshAuth.app.name}');
      print('🔧 Current user: ${freshAuth.currentUser?.uid}');
      
      // Wait for auth token to propagate to Firebase SDK
      await Future.delayed(Duration(seconds: 3));
      
      print('🚀 Calling claimReward function with manual token...');
      final callable = freshFunctions.httpsCallable("claimReward");
      final result = await callable.call({
        "source": source,
        "amount": amount,
        'idToken': token, // Pass token manually as backup
      });
      
      final added = result.data["added"] ?? 0;
      print('✅ FreshRewardService: Reward claimed successfully: $added');
      return added;
    } catch (e) {
      print('❌ FreshRewardService: Error claiming reward: $e');
      print('❌ Full error details: ${e.toString()}');
      rethrow;
    }
  }
}