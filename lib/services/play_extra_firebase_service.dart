import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayExtraFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get available battle rooms from Firestore
  Future<Map<String, dynamic>> getRooms() async {
    try {
      final roomsSnapshot = await _firestore
          .collection('rooms')
          .where('active', isEqualTo: true)
          .orderBy('minStake')
          .get();

      final rooms = roomsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'roomId': doc.id,
          'name': data['name'] ?? 'Unknown Room',
          'minStake': data['minStake'] ?? 0,
          'maxStake': data['maxStake'] ?? 0,
          'description': data['description'] ?? '',
          'maxPlayers': data['maxPlayers'] ?? 4,
          'colors': data['colors'] ?? ['red', 'blue', 'green', 'yellow'],
        };
      }).toList();

      return {
        'success': true,
        'rooms': rooms,
      };
    } catch (e) {
      print('Error getting rooms from Firebase: $e');
      return {
        'success': false,
        'error': e.toString(),
        'rooms': [],
      };
    }
  }

  // Join a battle room using Cloud Function
  Future<Map<String, dynamic>> joinBattle({
    required String roomId,
    required int stake,
    required String color,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final callable = _functions.httpsCallable('joinBattle');
      final result = await callable.call({
        'roomId': roomId,
        'stake': stake,
        'color': color,
      });

      return {
        'success': true,
        'roundId': result.data['roundId'],
        'message': result.data['message'] ?? 'Battle joined successfully',
      };
    } catch (e) {
      print('Error joining battle: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get active rounds that user can join
  Future<Map<String, dynamic>> getActiveRounds() async {
    try {
      final callable = _functions.httpsCallable('getActiveRounds');
      final result = await callable.call();

      return {
        'success': true,
        'rounds': result.data['rounds'] ?? [],
      };
    } catch (e) {
      print('Error getting active rounds: $e');
      return {
        'success': false,
        'error': e.toString(),
        'rounds': [],
      };
    }
  }

  // Get active rounds for a specific room
  Future<Map<String, dynamic>> getActiveRoundsForRoom(String roomId) async {
    try {
      final activeRounds = await _firestore
          .collection('timedRounds')
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'active')
          .where('endsAt', isGreaterThan: Timestamp.now())
          .orderBy('endsAt')
          .get();

      final rounds = activeRounds.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'roomId': data['roomId'],
          'status': data['status'],
          'startsAt': data['startsAt'],
          'endsAt': data['endsAt'],
          'duration': data['duration'],
          'participants': data['participants'] ?? [],
          'totalStake': data['totalStake'] ?? 0,
          'minPlayers': data['minPlayers'] ?? 2,
          'maxPlayers': data['maxPlayers'] ?? 8,
        };
      }).toList();

      return {
        'success': true,
        'rounds': rounds,
      };
    } catch (e) {
      print('Error getting active rounds for room: $e');
      return {
        'success': false,
        'error': e.toString(),
        'rounds': [],
      };
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final callable = _functions.httpsCallable('getUserStats');
      final result = await callable.call();

      return {
        'success': true,
        'stats': result.data['stats'] ?? {
          'coinBalance': 0,
          'wins': 0,
          'losses': 0,
          'totalBattles': 0,
          'recentBattles': [],
        },
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'success': false,
        'error': e.toString(),
        'stats': {
          'coinBalance': 0,
          'wins': 0,
          'losses': 0,
          'totalBattles': 0,
          'recentBattles': [],
        },
      };
    }
  }

  // Listen to real-time round updates
  Stream<DocumentSnapshot> listenToRound(String roundId) {
    return _firestore.collection('rounds').doc(roundId).snapshots();
  }

  // Listen to user's battle history
  Stream<QuerySnapshot> listenToUserBattles() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('rounds')
        .where('players', arrayContainsAny: [
          {'uid': currentUserId}
        ])
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // Listen to active rounds in a specific room
  Stream<QuerySnapshot> listenToRoomRounds(String roomId) {
    return _firestore
        .collection('rounds')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['waiting', 'active'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Listen to active timed rounds
  Stream<QuerySnapshot> listenToActiveTimedRounds() {
    return _firestore
        .collection('timedRounds')
        .where('status', isEqualTo: 'active')
        .where('endsAt', isGreaterThan: Timestamp.now())
        .orderBy('endsAt')
        .snapshots();
  }

  // Listen to active timed rounds for a specific room
  Stream<QuerySnapshot> listenToRoomTimedRounds(String roomId) {
    return _firestore
        .collection('timedRounds')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'active')
        .where('endsAt', isGreaterThan: Timestamp.now())
        .orderBy('endsAt')
        .snapshots();
  }

  // Listen to a specific timed round
  Stream<DocumentSnapshot> listenToTimedRound(String roundId) {
    return _firestore.collection('timedRounds').doc(roundId).snapshots();
  }

  // Start a battle (for testing - normally triggered automatically)
  Future<Map<String, dynamic>> startBattle(String roundId) async {
    try {
      // This would normally be triggered automatically by Cloud Functions
      // when enough players join. For testing purposes, we can manually trigger it.
      final roundRef = _firestore.collection('rounds').doc(roundId);
      await roundRef.update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Battle started successfully',
      };
    } catch (e) {
      print('Error starting battle: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Spin wheel (this will be handled by Cloud Functions automatically)
  Future<Map<String, dynamic>> spinWheel(String roundId) async {
    try {
      // In the real implementation, this would be handled automatically
      // by the startBattle Cloud Function trigger. For now, return a mock response.
      
      // Listen for the round to be completed
      final roundDoc = await _firestore.collection('rounds').doc(roundId).get();
      
      if (!roundDoc.exists) {
        throw Exception('Round not found');
      }

      final roundData = roundDoc.data()!;
      
      return {
        'success': true,
        'winner': roundData['winner'],
        'resultColor': roundData['resultColor'],
        'totalStake': roundData['totalStake'],
        'status': roundData['status'],
      };
    } catch (e) {
      print('Error spinning wheel: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get user's join history
  Future<Map<String, dynamic>> getUserJoins() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final joinsSnapshot = await _firestore
          .collection('joins')
          .where('uid', isEqualTo: currentUserId)
          .orderBy('joinedAt', descending: true)
          .limit(50)
          .get();

      final joins = joinsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'roundId': data['roundId'],
          'stake': data['stake'],
          'color': data['color'],
          'joinedAt': data['joinedAt'],
        };
      }).toList();

      return {
        'success': true,
        'joins': joins,
      };
    } catch (e) {
      print('Error getting user joins: $e');
      return {
        'success': false,
        'error': e.toString(),
        'joins': [],
      };
    }
  }

  // Clear user activities (soft delete - hide from UI)
  Future<Map<String, dynamic>> clearActivities() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // In a real implementation, you might want to add a 'hidden' field
      // instead of actually deleting the records for audit purposes
      // For now, we'll just return success as this is mainly a UI operation
      
      return {
        'success': true,
        'message': 'Activities cleared successfully',
      };
    } catch (e) {
      print('Error clearing activities: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Test Firebase connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Try to read from Firestore
      final testDoc = await _firestore.collection('rooms').limit(1).get();
      
      // Check if user is authenticated
      final user = _auth.currentUser;
      
      return {
        'success': true,
        'firestore': 'connected',
        'auth': user != null ? 'authenticated' : 'not authenticated',
        'userId': user?.uid,
        'roomsAvailable': testDoc.docs.length,
      };
    } catch (e) {
      print('Error testing Firebase connection: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
