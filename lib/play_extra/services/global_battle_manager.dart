import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

// Global Battle Manager - Rocky Rabbit Style Continuous Battles
class GlobalBattleManager extends ChangeNotifier {
  static final GlobalBattleManager _instance = GlobalBattleManager._internal();
  factory GlobalBattleManager() => _instance;
  GlobalBattleManager._internal();

  GlobalBattleRound? _currentRound;
  Timer? _roundTimer;
  bool _isInitialized = false;

  // Getters
  GlobalBattleRound? get currentRound => _currentRound;
  bool get hasActiveBattle => _currentRound != null;
  bool get canJoinBattle => _currentRound?.canJoin ?? false;
  bool get isBattleInProgress => _currentRound?.status == GlobalBattleStatus.battling;

  // Initialize the global battle system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🌍 Initializing Global Battle Manager...');
    _startNewRound();
    _isInitialized = true;
  }

  // Start a new battle round
  void _startNewRound() {
    final roundId = 'round_${DateTime.now().millisecondsSinceEpoch}';
    _currentRound = GlobalBattleRound(
      roundId: roundId,
      startTime: DateTime.now(),
      players: [],
    );
    
    print('🎯 New battle round started: $roundId');
    print('⏱️ Players have 2 minutes to join!');
    
    _startRoundTimer();
    notifyListeners();
  }

  // Start the timer for the current round
  void _startRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentRound == null) return;
      
      final round = _currentRound!;
      
      // Handle phase transitions
      switch (round.status) {
        case GlobalBattleStatus.accepting:
          if (round.timeRemaining.inSeconds <= 0) {
            _transitionToBattlePhase();
          }
          break;
          
        case GlobalBattleStatus.battling:
          if (round.timeRemaining.inSeconds <= 0) {
            _transitionToFinishedPhase();
          }
          break;
          
        case GlobalBattleStatus.finished:
          // Show results for 10 seconds, then start new round
          Timer(const Duration(seconds: 10), () {
            _startNewRound();
          });
          break;
          
        case GlobalBattleStatus.preparing:
          // Brief pause, then start new round
          Timer(const Duration(seconds: 3), () {
            _startNewRound();
          });
          break;
      }
      
      notifyListeners();
    });
  }

  // Transition from accepting to battling phase
  void _transitionToBattlePhase() {
    if (_currentRound == null) return;
    
    final players = _currentRound!.players;
    
    if (players.length >= 2) {
      print('⚔️ Battle starting with ${players.length} players!');
      _currentRound = GlobalBattleRound(
        roundId: _currentRound!.roundId,
        startTime: _currentRound!.startTime,
        status: GlobalBattleStatus.battling,
        players: players,
      );
      
      // Auto-start battle wheel after 5 seconds
      Timer(const Duration(seconds: 5), () {
        _simulateWheelSpin();
      });
    } else {
      print('❌ Not enough players, cancelling battle...');
      _startNewRound(); // Start immediately if no players
    }
    
    notifyListeners();
  }

  // Simulate the wheel spin and determine winner
  void _simulateWheelSpin() {
    if (_currentRound?.players.isEmpty ?? true) return;
    
    final players = _currentRound!.players;
    final random = math.Random();
    
    // Calculate weighted chances based on stake amounts
    final totalStake = players.fold(0, (sum, player) => sum + player.stakeAmount);
    double randomValue = random.nextDouble() * totalStake;
    
    BattlePlayer? winner;
    double cumulativeWeight = 0;
    
    for (final player in players) {
      cumulativeWeight += player.stakeAmount;
      if (randomValue <= cumulativeWeight) {
        winner = player;
        break;
      }
    }
    
    winner ??= players[random.nextInt(players.length)]; // Fallback
    
    print('🎉 Winner: ${winner.username} (${winner.bullType})');
    
    // Update round with winner
    _currentRound = GlobalBattleRound(
      roundId: _currentRound!.roundId,
      startTime: _currentRound!.startTime,
      status: GlobalBattleStatus.finished,
      players: players,
      winner: winner,
      finishTime: DateTime.now(),
    );
    
    notifyListeners();
  }

  // Transition to finished phase
  void _transitionToFinishedPhase() {
    if (_currentRound == null) return;
    
    _currentRound = GlobalBattleRound(
      roundId: _currentRound!.roundId,
      startTime: _currentRound!.startTime,
      status: GlobalBattleStatus.finished,
      players: _currentRound!.players,
      winner: _currentRound!.winner,
      finishTime: DateTime.now(),
    );
    
    notifyListeners();
  }

  // Player joins the current battle round
  Future<bool> joinBattle(BattlePlayer player) async {
    if (!canJoinBattle) {
      print('❌ Cannot join battle: ${_currentRound?.status}');
      return false;
    }
    
    final round = _currentRound!;
    
    // Check if player already joined
    if (round.players.any((p) => p.id == player.id)) {
      print('❌ Player already in battle: ${player.username}');
      return false;
    }
    
    // Add player to the round
    final updatedPlayers = [...round.players, player];
    
    _currentRound = GlobalBattleRound(
      roundId: round.roundId,
      startTime: round.startTime,
      status: round.status,
      players: updatedPlayers,
    );
    
    print('✅ ${player.username} joined battle! (${updatedPlayers.length}/${PlayExtraConfig.maxPlayersPerBattle})');
    
    notifyListeners();
    return true;
  }

  // Check if a specific player is in the current battle
  bool isPlayerInBattle(String playerId) {
    return _currentRound?.players.any((p) => p.id == playerId) ?? false;
  }

  // Get current player from battle
  BattlePlayer? getCurrentPlayer(String playerId) {
    return _currentRound?.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw StateError('Player not found'),
    );
  }

  // Leave current battle (only during accepting phase)
  bool leaveBattle(String playerId) {
    if (_currentRound?.status != GlobalBattleStatus.accepting) {
      return false; // Can't leave during battle or finished phases
    }
    
    final round = _currentRound!;
    final updatedPlayers = round.players.where((p) => p.id != playerId).toList();
    
    _currentRound = GlobalBattleRound(
      roundId: round.roundId,
      startTime: round.startTime,
      status: round.status,
      players: updatedPlayers,
    );
    
    print('👋 Player left battle (${updatedPlayers.length} remaining)');
    notifyListeners();
    return true;
  }

  // Get battle status for UI
  String getBattleStatusText() {
    if (_currentRound == null) return 'No active battle';
    
    switch (_currentRound!.status) {
      case GlobalBattleStatus.accepting:
        return 'Join Battle - ${_currentRound!.formattedTimeRemaining} left';
      case GlobalBattleStatus.battling:
        return 'Battle in Progress';
      case GlobalBattleStatus.finished:
        return 'Battle Finished - ${_currentRound!.winner?.username ?? "Unknown"} Won!';
      case GlobalBattleStatus.preparing:
        return 'Preparing Next Battle...';
    }
  }

  // Get battle status color for UI
  Color getBattleStatusColor() {
    if (_currentRound == null) return Colors.grey;
    
    switch (_currentRound!.status) {
      case GlobalBattleStatus.accepting:
        return Colors.green;
      case GlobalBattleStatus.battling:
        return Colors.orange;
      case GlobalBattleStatus.finished:
        return Colors.blue;
      case GlobalBattleStatus.preparing:
        return Colors.purple;
    }
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }
}