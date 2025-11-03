import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// NUCLEAR SOLUTION - HTTP Direct service that bypasses Flutter Firebase SDK completely
/// This uses direct HTTP calls to Firebase Functions avoiding the buggy SDK middleware
class HttpDirectService {
  final _auth = FirebaseAuth.instance;
  // Updated URLs from Firebase Functions v2 deployment
  final String _getBalanceUrl = 'https://getbalancehttp-ftg3tdhi7q-uc.a.run.app';
  final String _claimRewardUrl = 'https://claimrewardhttp-ftg3tdhi7q-uc.a.run.app';

  /// Get balance using direct HTTP call (bypasses Flutter Firebase SDK)
  Future<int> getBalance() async {
    try {
      // Ensure user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🚀 HttpDirect: Getting balance for user: ${user.uid}');

      // Get fresh ID token
      final idToken = await user.getIdToken(true);
      print('🔑 HttpDirect: Got ID token length: ${idToken?.length ?? 0}');

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get valid ID token');
      }

      // Make direct HTTP call to Firebase Function
      final url = Uri.parse(_getBalanceUrl);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      print('🌐 HttpDirect: Response status: ${response.statusCode}');
      print('🌐 HttpDirect: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final balance = data['balance'] ?? 0;
          print('✅ HttpDirect: Balance retrieved successfully: $balance');
          return balance;
        } else {
          throw Exception('Server returned success=false: ${data['error']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HttpDirect: Error getting balance: $e');
      rethrow;
    }
  }

  /// Claim reward using direct HTTP call (bypasses Flutter Firebase SDK)
  Future<int> claimReward(String source, int amount) async {
    try {
      // Ensure user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🎯 HttpDirect: Claiming reward - source: $source, amount: $amount, user: ${user.uid}');

      // Get fresh ID token
      final idToken = await user.getIdToken(true);
      print('🔑 HttpDirect: Got ID token length: ${idToken?.length ?? 0}');

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get valid ID token');
      }

      // Make direct HTTP call to Firebase Function
      final url = Uri.parse(_claimRewardUrl);
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'source': source,
          'amount': amount,
        }),
      );

      print('🌐 HttpDirect: Response status: ${response.statusCode}');
      print('🌐 HttpDirect: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final added = data['added'] ?? 0;
          print('✅ HttpDirect: Reward claimed successfully: $added');
          return added;
        } else {
          throw Exception('Server returned success=false: ${data['error']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HttpDirect: Error claiming reward: $e');
      rethrow;
    }
  }

  /// Test connection to the HTTP Direct endpoints
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔧 HttpDirect: Testing connection...');
      
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'connected': false,
          'error': 'User not authenticated',
          'method': 'http-direct'
        };
      }

      // Just test the balance endpoint
      final balance = await getBalance();
      
      return {
        'connected': true,
        'balance': balance,
        'method': 'http-direct',
        'uid': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ HttpDirect: Connection test failed: $e');
      return {
        'connected': false,
        'error': e.toString(),
        'method': 'http-direct'
      };
    }
  }
}