import 'dart:convert';
import 'package:http/http.dart' as http;

class PlayExtraBattleService {
  static const String baseUrl = 'http://localhost:4000/api';
  // For Android emulator, use: 'http://10.0.2.2:4000/api'
  // For iOS simulator, use: 'http://localhost:4000/api'
  
  // Get available battle rooms
  Future<Map<String, dynamic>> getRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rooms'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting rooms: $e');
      // Return mock data if backend is not available
      return {
        'success': true,
        'rooms': [
          {'roomId': '10-100', 'name': 'Rookie Room', 'minStake': 10, 'maxStake': 100},
          {'roomId': '100-500', 'name': 'Pro Room', 'minStake': 100, 'maxStake': 500},
          {'roomId': '500-1000', 'name': 'Elite Room', 'minStake': 500, 'maxStake': 1000},
          {'roomId': '1000-5000', 'name': 'Champion Room', 'minStake': 1000, 'maxStake': 5000},
        ]
      };
    }
  }
  
  // Create a new battle round
  Future<Map<String, dynamic>> createRound(String roomId, int minStake, int maxStake) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rounds'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'roomId': roomId,
          'deadline': DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch,
          'minStake': minStake,
          'maxStake': maxStake,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create round: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating round: $e');
      rethrow;
    }
  }
  
  // Join a battle round
  Future<Map<String, dynamic>> joinRound(String roundId, String userId, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rounds/$roundId/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'joinId': 'join_${DateTime.now().millisecondsSinceEpoch}_$userId',
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to join round: ${response.statusCode}');
      }
    } catch (e) {
      print('Error joining round: $e');
      rethrow;
    }
  }
  
  // Lock a battle round
  Future<Map<String, dynamic>> lockRound(String roundId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/rounds/$roundId/lock'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to lock round: ${response.statusCode}');
      }
    } catch (e) {
      print('Error locking round: $e');
      rethrow;
    }
  }
  
  // Reveal winner
  Future<Map<String, dynamic>> revealWinner(String roundId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/rounds/$roundId/reveal'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reveal winner: ${response.statusCode}');
      }
    } catch (e) {
      print('Error revealing winner: $e');
      rethrow;
    }
  }
  
  // Get round details
  Future<Map<String, dynamic>> getRound(String roundId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rounds/$roundId'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get round: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting round: $e');
      rethrow;
    }
  }
  
  // Get user's round history
  Future<Map<String, dynamic>> getUserRounds(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/rounds'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user rounds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user rounds: $e');
      rethrow;
    }
  }
  
  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Health check error: $e');
      return {
        'success': false,
        'error': 'Backend not available'
      };
    }
  }
}
