import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_models.dart';
import '../../services/play_extra_firebase_service.dart';

class PlayExtraService extends ChangeNotifier {
  static final PlayExtraService _instance = PlayExtraService._internal();
  factory PlayExtraService() => _instance;
  PlayExtraService._internal();

  // Firebase service
  final PlayExtraFirebaseService _firebaseService = PlayExtraFirebaseService();

  GameState _gameState = GameState();
  GameState get gameState => _gameState;

  // Real-time listeners
  StreamSubscription<DocumentSnapshot>? _currentRoundListener;
  StreamSubscription<QuerySnapshot>? _userBattlesListener;

  // Battle rooms will now be loaded from Firebase
  List<BattleRoom> _battleRooms = [];
  List<BattleRoom> get battleRooms => _battleRooms;

  // Current round tracking
  String? _currentRoundId;
  String? get currentRoundId => _currentRoundId;

  // User authentication check
  bool get isUserAuthenticated => FirebaseAuth.instance.currentUser != null;
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Initialize service and load data from Firebase
  Future<void> initialize() async {
    print('🎮 Initializing Play Extra Service with Firebase...');
    
    // Load persistent data
    await _loadGameState();
    
    // Load battle rooms from Firebase
    await _loadBattleRooms();
    
    // Set up real-time listeners
    _setupRealtimeListeners();
    
    print('✅ Play Extra Service initialized');
  }

  // Load battle rooms from Firebase
  Future<void> _loadBattleRooms() async {
    try {
      final result = await _firebaseService.getRooms();
      
      if (result['success']) {
        _battleRooms = (result['rooms'] as List).map((roomData) {
          return BattleRoom(
            id: roomData['roomId'],
            name: roomData['name'],
            minStake: roomData['minStake'],
            maxStake: roomData['maxStake'],
            color: _getColorForRoom(roomData['roomId']),
            icon: _getIconForRoom(roomData['roomId']),
            description: roomData['description'] ?? 'Battle room',
          );
        }).toList();
        
        notifyListeners();
        print('✅ Loaded ${_battleRooms.length} battle rooms from Firebase');
      } else {
        print('❌ Failed to load battle rooms: ${result['error']}');
        _loadFallbackRooms();
      }
    } catch (e) {
      print('❌ Error loading battle rooms: $e');
      _loadFallbackRooms();
    }
  }

  // Fallback rooms if Firebase fails
  void _loadFallbackRooms() {
    _battleRooms = [
      BattleRoom(
        id: 'rookie',
        name: 'Rookie Room',
        minStake: 10,
        maxStake: 100,
        color: Colors.green,
        icon: Icons.sports_martial_arts,
        description: 'Perfect for beginners!',
      ),
      BattleRoom(
        id: 'pro',
        name: 'Pro Room',
        minStake: 100,
        maxStake: 500,
        color: Colors.blue,
        icon: Icons.shield,
        description: 'For experienced players',
      ),
      BattleRoom(
        id: 'elite',
        name: 'Elite Room',
        minStake: 500,
        maxStake: 5000,
        color: Colors.purple,
        icon: Icons.diamond,
        description: 'High stakes battles',
      ),
    ];
    notifyListeners();
  }

  // Helper methods for room display
  Color _getColorForRoom(String roomId) {
    switch (roomId) {
      case 'rookie':
        return Colors.green;
      case 'pro':
        return Colors.blue;
      case 'elite':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForRoom(String roomId) {
    switch (roomId) {
      case 'rookie':
        return Icons.sports_martial_arts;
      case 'pro':
        return Icons.shield;
      case 'elite':
        return Icons.diamond;
      default:
        return Icons.games;
    }
  }

  // Set up real-time listeners for user battles and current round
  void _setupRealtimeListeners() {
    if (!isUserAuthenticated) return;

    // Listen to user's battle history
    _userBattlesListener = _firebaseService.listenToUserBattles().listen(
      (snapshot) {
        _updateBattleHistory(snapshot);
      },
      onError: (error) {
        print('❌ Error listening to user battles: $error');
      },
    );
  }

  // Update battle history from Firebase snapshot
  void _updateBattleHistory(QuerySnapshot snapshot) {
    try {
      final battles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BattleHistory(
          id: doc.id,
          roomId: data['roomId'] ?? '',
          isWinner: data['winner'] == currentUserId,
          stake: _getUserStakeFromRound(data, currentUserId ?? ''),
          result: data['resultColor'] ?? 'unknown',
          timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      _gameState = _gameState.copyWith(battleHistory: battles);
      _saveGameState();
      notifyListeners();
    } catch (e) {
      print('❌ Error updating battle history: $e');
    }
  }

  // Helper to get user's stake from round data
  int _getUserStakeFromRound(Map<String, dynamic> roundData, String userId) {
    final players = roundData['players'] as List?;
    if (players == null) return 0;

    for (final player in players) {
      if (player['uid'] == userId) {
        return player['stake'] ?? 0;
      }
    }
    return 0;
  }

  // Join a battle using Firebase
  Future<bool> joinBattle(String roomId, int stake, String color) async {
    if (!isUserAuthenticated) {
      print('❌ User not authenticated');
      return false;
    }

    try {
      print('🎮 Joining battle: Room=$roomId, Stake=$stake, Color=$color');
      
      final result = await _firebaseService.joinBattle(
        roomId: roomId,
        stake: stake,
        color: color,
      );

      if (result['success']) {
        _currentRoundId = result['roundId'];
        
        // Set up listener for this specific round
        _listenToCurrentRound(_currentRoundId!);
        
        print('✅ Successfully joined battle: ${result['message']}');
        return true;
      } else {
        print('❌ Failed to join battle: ${result['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Error joining battle: $e');
      return false;
    }
  }

  // Listen to current round updates
  void _listenToCurrentRound(String roundId) {
    _currentRoundListener?.cancel();
    
    _currentRoundListener = _firebaseService.listenToRound(roundId).listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          _handleRoundUpdate(roundId, data);
        }
      },
      onError: (error) {
        print('❌ Error listening to round $roundId: $error');
      },
    );
  }

  // Handle round updates from Firebase
  void _handleRoundUpdate(String roundId, Map<String, dynamic> data) {
    final status = data['status'] as String?;
    
    print('🔄 Round $roundId updated: Status=$status');
    
    if (status == 'completed') {
      // Battle completed, handle results
      final winner = data['winner'] as String?;
      final resultColor = data['resultColor'] as String?;
      final totalStake = data['totalStake'] as int?;
      
      _handleBattleCompletion(
        roundId: roundId,
        winner: winner,
        resultColor: resultColor ?? 'unknown',
        totalStake: totalStake ?? 0,
      );
    }
    
    notifyListeners();
  }

  // Handle battle completion
  void _handleBattleCompletion({
    required String roundId,
    String? winner,
    required String resultColor,
    required int totalStake,
  }) {
    final isWinner = winner == currentUserId;
    
    print('🎉 Battle completed: Winner=$winner, Color=$resultColor, IsWinner=$isWinner');
    
    // Update game state
    if (isWinner) {
      _gameState = _gameState.copyWith(
        totalWins: _gameState.totalWins + 1,
        coins: _gameState.coins + totalStake, // Add winnings
      );
    } else {
      _gameState = _gameState.copyWith(
        totalLosses: _gameState.totalLosses + 1,
      );
    }
    
    _saveGameState();
    _currentRoundId = null;
    _currentRoundListener?.cancel();
    
    notifyListeners();
  }

  // Spin wheel (handled automatically by Firebase Functions)
  Future<WheelResult> spinWheel() async {
    if (_currentRoundId == null) {
      return WheelResult(
        winner: false,
        color: 'red',
        coins: 0,
        message: 'No active battle found',
      );
    }

    try {
      // The wheel spinning is handled automatically by Firebase Functions
      // We just need to wait for the round to be completed
      print('🎡 Waiting for wheel result...');
      
      // Return a placeholder - the real result will come through the listener
      return WheelResult(
        winner: false,
        color: 'spinning',
        coins: 0,
        message: 'Wheel is spinning...',
      );
    } catch (e) {
      print('❌ Error spinning wheel: $e');
      return WheelResult(
        winner: false,
        color: 'red',
        coins: 0,
        message: 'Error spinning wheel',
      );
    }
  }

  // Get user statistics from Firebase
  Future<void> refreshStats() async {
    if (!isUserAuthenticated) return;

    try {
      final result = await _firebaseService.getUserStats();
      
      if (result['success']) {
        final stats = result['stats'];
        _gameState = _gameState.copyWith(
          coins: stats['coinBalance'] ?? _gameState.coins,
          totalWins: stats['wins'] ?? _gameState.totalWins,
          totalLosses: stats['losses'] ?? _gameState.totalLosses,
        );
        
        _saveGameState();
        notifyListeners();
        print('✅ Stats refreshed from Firebase');
      }
    } catch (e) {
      print('❌ Error refreshing stats: $e');
    }
  }

  // Clear activities
  Future<void> clearActivities() async {
    try {
      await _firebaseService.clearActivities();
      
      _gameState = _gameState.copyWith(
        battleHistory: [],
      );
      
      _saveGameState();
      notifyListeners();
      print('✅ Activities cleared');
    } catch (e) {
      print('❌ Error clearing activities: $e');
    }
  }

  // Load game state from local storage
  Future<void> _loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = prefs.getString('game_state');
      
      if (gameStateJson != null) {
        final data = json.decode(gameStateJson);
        _gameState = GameState.fromJson(data);
        print('✅ Game state loaded from local storage');
      } else {
        print('📋 No saved game state found, starting fresh');
      }
    } catch (e) {
      print('❌ Error loading game state: $e');
    }
  }

  // Save game state to local storage
  Future<void> _saveGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = json.encode(_gameState.toJson());
      await prefs.setString('game_state', gameStateJson);
    } catch (e) {
      print('❌ Error saving game state: $e');
    }
  }

  // Test Firebase connection
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    return await _firebaseService.testConnection();
  }

  // Dispose of listeners
  @override
  void dispose() {
    _currentRoundListener?.cancel();
    _userBattlesListener?.cancel();
    super.dispose();
  }

  // Legacy methods for backward compatibility
  List<BattleRoom> getRooms() => _battleRooms;
  
  int get coins => _gameState.coins;
  int get totalWins => _gameState.totalWins;
  int get totalLosses => _gameState.totalLosses;
  List<BattleHistory> get battleHistory => _gameState.battleHistory;
}
