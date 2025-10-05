import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      
      // Use HTTP endpoint instead of callable function for better auth handling
      const String baseUrl = 'https://us-central1-coinnewsextratv-9c75a.cloudfunctions.net';
      final Uri url = Uri.parse('$baseUrl/getBalanceHttp');
      
      print('🚀 Calling HTTP getBalance endpoint...');
      
      // Make HTTP request with proper authentication
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('� HTTP Response status: ${response.statusCode}');
      print('� HTTP Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final balance = responseData['balance'] ?? 0;
          print('✅ FreshRewardService: Balance retrieved: $balance');
          return balance;
        } else {
          throw Exception('Get balance failed: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('HTTP ${response.statusCode}: ${errorData['error'] ?? 'Network error'}');
      }
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
      
      // Use HTTP endpoint instead of callable function for better auth handling
      const String baseUrl = 'https://us-central1-coinnewsextratv-9c75a.cloudfunctions.net';
      final Uri url = Uri.parse('$baseUrl/claimRewardHttp');
      
      print('🚀 Calling HTTP claimReward endpoint...');
      
      // Make HTTP request with proper authentication
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'source': source,
          'amount': amount,
        }),
      );
      
      print('📡 HTTP Response status: ${response.statusCode}');
      print('📡 HTTP Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final claimedAmount = responseData['amount'] ?? amount;
          print('✅ FreshRewardService: Reward claimed successfully: $claimedAmount');
          return claimedAmount;
        } else {
          throw Exception('Claim failed: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('HTTP ${response.statusCode}: ${errorData['error'] ?? 'Network error'}');
      }
    } catch (e) {
      print('❌ FreshRewardService: Error claiming reward: $e');
      print('❌ Full error details: ${e.toString()}');
      rethrow;
    }
  }
}