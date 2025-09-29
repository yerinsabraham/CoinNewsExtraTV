import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/game_models.dart';

class CountdownTimerService extends ChangeNotifier {
  static final CountdownTimerService _instance = CountdownTimerService._internal();
  factory CountdownTimerService() => _instance;
  CountdownTimerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Server time synchronization
  Duration _serverOffset = Duration.zero;
  DateTime? _lastSyncTime;
  
  // Current active rounds by room ID
  final Map<String, TimedRound> _activeRounds = {};
  final Map<String, Timer> _timers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  // Getters
  Map<String, TimedRound> get activeRounds => Map.unmodifiable(_activeRounds);
  
  TimedRound? getActiveRound(String roomId) => _activeRounds[roomId];
  
  bool isRoundActive(String roomId) {
    final round = _activeRounds[roomId];
    return round != null && round.isJoinableWithServerTime(_serverTime);
  }
  
  int getSecondsRemaining(String roomId) {
    final round = _activeRounds[roomId];
    if (round == null) return 0;
    return round.getSecondsRemaining(_serverTime);
  }
  
  String getFormattedTimeRemaining(String roomId) {
    final seconds = getSecondsRemaining(roomId);
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Synchronize with server time
  Future<void> _syncServerTime() async {
    try {
      print('⏰ Synchronizing with server time...');
      final result = await _functions.httpsCallable('getServerTime').call();
      
      if (result.data['success']) {
        final serverTimeMs = result.data['serverTime'] as int;
        final serverTime = DateTime.fromMillisecondsSinceEpoch(serverTimeMs);
        final clientTime = DateTime.now();
        
        _serverOffset = serverTime.difference(clientTime);
        _lastSyncTime = clientTime;
        
        print('✅ Server time synced. Offset: ${_serverOffset.inMilliseconds}ms');
      }
    } catch (e) {
      print('❌ Failed to sync server time: $e');
      _serverOffset = Duration.zero; // Fallback to no offset
    }
  }

  // Get server-synchronized time
  DateTime get _serverTime {
    final now = DateTime.now();
    
    // Re-sync if it's been more than 5 minutes
    if (_lastSyncTime == null || now.difference(_lastSyncTime!).inMinutes > 5) {
      _syncServerTime(); // Fire and forget for next time
    }
    
    return now.add(_serverOffset);
  }

  // Initialize service
  Future<void> initialize() async {
    print('🕐 Initializing Countdown Timer Service...');
    
    try {
      // First sync server time
      await _syncServerTime();
      // Get all waiting timed rounds to find which rooms have joinable rounds
      final activeRoundsSnapshot = await _firestore
          .collection('timedRounds')
          .where('status', isEqualTo: 'waiting')
          .get();

      // Get unique room IDs from active rounds
      final Set<String> roomIds = {};
      for (final roundDoc in activeRoundsSnapshot.docs) {
        final roundData = roundDoc.data();
        final roomId = roundData['roomId'] as String?;
        if (roomId != null) {
          roomIds.add(roomId);
        }
      }

      // Start listening to active rounds for each room that has active rounds
      for (final roomId in roomIds) {
        await _startListeningToRoom(roomId);
      }
      
      // Also start listening for all room IDs that might get rounds (rookie, pro, elite)
      const allRoomIds = ['rookie', 'pro', 'elite'];
      for (final roomId in allRoomIds) {
        if (!roomIds.contains(roomId)) {
          await _startListeningToRoom(roomId);
        }
      }
      
      print('✅ Countdown Timer Service initialized for ${roomIds.length} active rounds and ${allRoomIds.length} total rooms');
    } catch (e) {
      print('❌ Error initializing Countdown Timer Service: $e');
    }
  }

  // Start listening to rounds for a specific room
  Future<void> _startListeningToRoom(String roomId) async {
    print('👂 Starting to listen to rounds for room: $roomId');
    
    // Cancel existing subscription if any
    _subscriptions[roomId]?.cancel();
    
    // Listen to most recent waiting timed rounds for this room (ordered by creation time)
    _subscriptions[roomId] = _firestore
        .collection('timedRounds')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) => _handleRoundUpdate(roomId, snapshot),
          onError: (error) => print('❌ Error listening to timed rounds for $roomId: $error'),
        );
  }

  // Handle round updates from Firestore
  void _handleRoundUpdate(String roomId, QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      // No active round for this room
      _clearRoomData(roomId);
      print('📭 No active round for room $roomId');
      return;
    }

    final roundDoc = snapshot.docs.first;
    final roundData = roundDoc.data() as Map<String, dynamic>;
    
    try {
      // Handle Firestore Timestamp fields properly
      final Map<String, dynamic> parsedData = Map<String, dynamic>.from(roundData);
      parsedData['id'] = roundDoc.id;
      
      // Convert Firestore Timestamps to ISO8601 strings
      if (roundData['roundStartTime'] is Timestamp) {
        parsedData['roundStartTime'] = (roundData['roundStartTime'] as Timestamp).toDate().toIso8601String();
      }
      if (roundData['roundEndTime'] is Timestamp) {
        parsedData['roundEndTime'] = (roundData['roundEndTime'] as Timestamp).toDate().toIso8601String();
      }
      
      final round = TimedRound.fromJson(parsedData);
      _updateActiveRound(roomId, round);
    } catch (e) {
      print('❌ Error parsing round data for $roomId: $e');
      print('   Round data: $roundData');
    }
  }

  // Update active round and manage timer
  void _updateActiveRound(String roomId, TimedRound round) {
    final previousRound = _activeRounds[roomId];
    _activeRounds[roomId] = round;

    // If this is a new round or the round changed, restart the timer
    if (previousRound == null || previousRound.id != round.id) {
      print('🔄 New round detected for $roomId: ${round.id}');
      _startCountdownTimer(roomId, round);
    }

    notifyListeners();
  }

  // Start countdown timer for a round
  void _startCountdownTimer(String roomId, TimedRound round) {
    // Cancel existing timer
    _timers[roomId]?.cancel();

    // DEBUG LOGGING - Server-synchronized timing logs
    final clientNow = DateTime.now();
    final serverNow = _serverTime;
    final clientRemaining = round.secondsRemaining;
    final serverRemaining = round.getSecondsRemaining(serverNow);
    final isJoinableClient = round.isJoinable;
    final isJoinableServer = round.isJoinableWithServerTime(serverNow);
    
    print('🔍 ROUND DEBUG for $roomId:');
    print('   Round ID: ${round.id}');
    print('   Round End: ${round.roundEndTime.toIso8601String()}');
    print('   Client Now: ${clientNow.toIso8601String()}');
    print('   Server Now: ${serverNow.toIso8601String()}');
    print('   Server Offset: ${_serverOffset.inMilliseconds}ms');
    print('   Client Remaining: ${clientRemaining}s');
    print('   Server Remaining: ${serverRemaining}s');
    print('   Client Joinable: $isJoinableClient');
    print('   Server Joinable: $isJoinableServer');

    // Use server-synchronized joinability check
    if (!isJoinableServer) {
      print('⏰ Round $roomId is not joinable (server time), skipping timer');
      return;
    }

    print('⏱️ Starting countdown timer for $roomId, ${serverRemaining} seconds remaining (server time)');

    // Create a timer that ticks every second
    _timers[roomId] = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _onTimerTick(roomId, timer),
    );
  }

  // Handle timer tick
  void _onTimerTick(String roomId, Timer timer) {
    final round = _activeRounds[roomId];
    
    if (round == null || round.isExpired) {
      print('⏰ Timer expired for room $roomId');
      timer.cancel();
      _timers.remove(roomId);
      
      // The Firestore listener will automatically pick up the next round
      return;
    }

    // Notify listeners to update UI
    notifyListeners();
  }

  // Clear room data when no active round
  void _clearRoomData(String roomId) {
    _activeRounds.remove(roomId);
    _timers[roomId]?.cancel();
    _timers.remove(roomId);
    notifyListeners();
  }

  // Join a round
  Future<Map<String, dynamic>> joinRound(String roomId, int stake, String color) async {
    try {
      final round = _activeRounds[roomId];
      
      if (round == null) {
        throw Exception('No active round for this room');
      }

      if (!round.isJoinable) {
        throw Exception('Round is no longer joinable');
      }

      // Call the Firebase function to join
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('joinBattle').call({
        'roomId': roomId,
        'stake': stake,
        'color': color,
      });

      if (result.data['success']) {
        print('✅ Successfully joined round ${round.id}');
        return {
          'success': true,
          'roundId': result.data['roundId'],
          'message': result.data['message'],
        };
      } else {
        throw Exception(result.data['error'] ?? 'Failed to join round');
      }
    } catch (e) {
      print('❌ Error joining round: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create a new round manually (for testing)
  Future<Map<String, dynamic>> createNewRound(String roomId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createNewRound').call({
        'roomId': roomId,
      });

      if (result.data['success']) {
        print('✅ Successfully created new round for room $roomId');
        return {
          'success': true,
          'roundId': result.data['roundId'],
          'message': result.data['message'],
        };
      } else {
        throw Exception(result.data['error'] ?? 'Failed to create round');
      }
    } catch (e) {
      print('❌ Error creating new round: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get round status text for UI
  String getRoundStatusText(String roomId) {
    final round = _activeRounds[roomId];
    
    if (round == null) {
      return 'No active round';
    }

    switch (round.status) {
      case RoundStatus.waiting:
        if (round.isExpired) {
          return 'Round ending...';
        }
        final playersNeeded = 2 - round.players.length;
        if (playersNeeded > 0) {
          return 'Need $playersNeeded more player${playersNeeded > 1 ? 's' : ''}';
        }
        return 'Ready to battle!';
      case RoundStatus.active:
        return 'Battle in progress...';
      case RoundStatus.completed:
        return 'Round completed';
      case RoundStatus.cancelled:
        return 'Round cancelled';
    }
  }

  // Get round status color for UI
  Color getRoundStatusColor(String roomId) {
    final round = _activeRounds[roomId];
    
    if (round == null) {
      return Colors.grey;
    }

    switch (round.status) {
      case RoundStatus.waiting:
        if (round.isExpired) {
          return Colors.orange;
        }
        return round.hasMinimumPlayers ? Colors.green : Colors.blue;
      case RoundStatus.active:
        return Colors.purple;
      case RoundStatus.completed:
        return Colors.green;
      case RoundStatus.cancelled:
        return Colors.red;
    }
  }

  // Cleanup
  @override
  void dispose() {
    print('🧹 Disposing Countdown Timer Service...');
    
    // Cancel all timers
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _activeRounds.clear();
    
    super.dispose();
  }
}
