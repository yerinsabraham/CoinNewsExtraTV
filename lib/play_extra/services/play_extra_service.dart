import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class PlayExtraService extends ChangeNotifier {
  static final PlayExtraService _instance = PlayExtraService._internal();
  factory PlayExtraService() => _instance;
  PlayExtraService._internal();

  // Player State
  PlayerStats _playerStats = PlayerStats(playerId: 'default_player');
  String _selectedBullType = 'blue_bull';
  int _playerCoins = PlayExtraConfig.defaultCoins;
  
  // Current Battle State
  BattleSession? _currentBattle;
  BattlePlayer? _currentPlayer;
  
  // Battle History
  List<BattleResult> _battleHistory = [];

  // Getters
  PlayerStats get playerStats => _playerStats;
  String get selectedBullType => _selectedBullType;
  int get playerCoins => _playerCoins;
  BattleSession? get currentBattle => _currentBattle;
  BattlePlayer? get currentPlayer => _currentPlayer;
  List<BattleResult> get battleHistory => _battleHistory;
  List<BattleArena> get availableArenas => PlayExtraConfig.defaultArenas;
  
  bool get isInBattle => _currentBattle != null && _currentPlayer != null;
  
  // Initialize the service
  Future<void> initialize() async {
    await _loadPlayerData();
    print('🎮 Play Extra Service initialized!');
  }

  // Load player data from storage
  Future<void> _loadPlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load coins
      _playerCoins = prefs.getInt('play_extra_coins') ?? PlayExtraConfig.defaultCoins;
      
      // Load selected bull
      _selectedBullType = prefs.getString('selected_bull_type') ?? 'blue_bull';
      
      // Load player stats
      final statsJson = prefs.getString('player_stats');
      if (statsJson != null) {
        _playerStats = PlayerStats.fromJson(json.decode(statsJson));
      }
      
      // Load battle history
      final historyJson = prefs.getString('battle_history');
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List;
        _battleHistory = historyList.map((item) => BattleResult.fromJson(item)).toList();
      }
      
      print('✅ Player data loaded: $_playerCoins CNE, Bull: $_selectedBullType');
    } catch (e) {
      print('❌ Error loading player data: $e');
    }
  }

  // Save player data to storage
  Future<void> _savePlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('play_extra_coins', _playerCoins);
      await prefs.setString('selected_bull_type', _selectedBullType);
      await prefs.setString('player_stats', json.encode(_playerStats.toJson()));
      await prefs.setString('battle_history', json.encode(_battleHistory.map((b) => b.toJson()).toList()));
      
      notifyListeners();
    } catch (e) {
      print('❌ Error saving player data: $e');
    }
  }

  // Select Bull Character
  Future<void> selectBull(String bullType) async {
    if (PlayExtraConfig.bullTypes.contains(bullType)) {
      _selectedBullType = bullType;
      await _savePlayerData();
      print('🐂 Bull selected: ${PlayExtraConfig.bullNames[bullType]}');
    }
  }

  // Join Battle Arena
  Future<bool> joinBattle(String arenaId, int stakeAmount, String userId, String username) async {
    try {
      // Find arena
      final arena = PlayExtraConfig.defaultArenas.firstWhere((a) => a.id == arenaId);
      
      // Validate stake amount
      if (!arena.isValidStake(stakeAmount)) {
        throw Exception('Invalid stake amount for ${arena.name}');
      }
      
      // Check if player has enough coins
      if (stakeAmount > _playerCoins) {
        throw Exception('Insufficient CNE tokens');
      }
      
      // Deduct stake from player coins
      _playerCoins -= stakeAmount;
      
      // Create battle player
      _currentPlayer = BattlePlayer(
        id: userId,
        username: username,
        bullType: _selectedBullType,
        stakeAmount: stakeAmount,
        arenaId: arenaId,
        joinedAt: DateTime.now(),
        level: _playerStats.playerLevel,
        totalWins: _playerStats.totalWins,
      );
      
      // Add AI opponents immediately for demo (in real app, wait for real players)
      final aiOpponents = _generateAIOpponents(arenaId, 3);
      
      // Create battle session with all players
      _currentBattle = BattleSession(
        sessionId: 'battle_${DateTime.now().millisecondsSinceEpoch}',
        arenaId: arenaId,
        players: [_currentPlayer!, ...aiOpponents],
        status: BattleSessionStatus.waiting,
        startTime: DateTime.now(),
        timeLimit: const Duration(minutes: 2), // 2 minute waiting period
      );
      
      await _savePlayerData();
      
      print('⚔️ Joined battle: ${arena.name} with $stakeAmount CNE');
      print('👥 ${_currentBattle!.players.length} players in battle');
      return true;
      
    } catch (e) {
      print('❌ Error joining battle: $e');
      return false;
    }
  }

  // Start Battle (Rocky Rabbit Style Wheel Spin)
  Future<BattleResult> startBattle() async {
    if (_currentBattle == null || _currentPlayer == null) {
      throw Exception('No active battle to start');
    }
    
    // Update battle status
    _currentBattle = BattleSession(
      sessionId: _currentBattle!.sessionId,
      arenaId: _currentBattle!.arenaId,
      players: _currentBattle!.players,
      status: BattleSessionStatus.active,
      startTime: _currentBattle!.startTime,
      timeLimit: _currentBattle!.timeLimit,
    );
    
    // Simulate battle with wheel mechanics
    return await _simulateBattleWheel();
  }

  // Simulate Rocky Rabbit Style Battle Wheel
  Future<BattleResult> _simulateBattleWheel() async {
    if (_currentBattle == null || _currentPlayer == null) {
      throw Exception('No active battle');
    }
    
    final arena = PlayExtraConfig.defaultArenas.firstWhere((a) => a.id == _currentBattle!.arenaId);
    final random = Random();
    
    // Add some AI opponents for demo
    final aiOpponents = _generateAIOpponents(_currentBattle!.arenaId, 3);
    final allPlayers = [_currentPlayer!, ...aiOpponents];
    
    // Calculate win probability based on stake amount and player level
    final playerPower = _currentPlayer!.battlePower;
    final totalPower = allPlayers.fold(0.0, (sum, player) => sum + player.battlePower);
    final winProbability = playerPower / totalPower;
    
    // Determine winner (with some randomness for excitement)
    final isPlayerWinner = random.nextDouble() < (winProbability * 0.7 + 0.15); // 15-85% chance
    
    final winner = isPlayerWinner ? _currentPlayer! : aiOpponents[random.nextInt(aiOpponents.length)];
    final totalStake = allPlayers.fold(0, (sum, player) => sum + player.stakeAmount);
    final winnerReward = arena.calculateWinnings(totalStake ~/ 2); // Winner takes calculated portion
    
    // Create battle result
    final result = BattleResult(
      battleId: _currentBattle!.sessionId,
      winnerId: winner.id,
      winnerBullType: winner.bullType,
      participants: allPlayers,
      totalStakePool: totalStake,
      winnerReward: winnerReward,
      completedAt: DateTime.now(),
      resultType: 'wheel_spin',
    );
    
    // Update player stats and coins if winner
    if (isPlayerWinner) {
      _playerCoins += winnerReward;
      _updatePlayerStats(true, winnerReward, _currentPlayer!.stakeAmount);
      print('🎉 Victory! Won $winnerReward CNE tokens!');
    } else {
      _updatePlayerStats(false, 0, _currentPlayer!.stakeAmount);
      print('😞 Defeat! Better luck next time!');
    }
    
    // Add to battle history
    _battleHistory.insert(0, result); // Add to beginning for recent-first display
    if (_battleHistory.length > 50) {
      _battleHistory = _battleHistory.take(50).toList(); // Keep last 50 battles
    }
    
    // Clear current battle
    _currentBattle = null;
    _currentPlayer = null;
    
    await _savePlayerData();
    
    return result;
  }

  // Generate AI Opponents for Battle
  List<BattlePlayer> _generateAIOpponents(String arenaId, int count) {
    final random = Random();
    final arena = PlayExtraConfig.defaultArenas.firstWhere((a) => a.id == arenaId);
    final opponents = <BattlePlayer>[];
    
    final aiNames = ['CryptoBull', 'TradingPro', 'BullRider', 'CoinMaster', 'BlockChamp'];
    
    for (int i = 0; i < count; i++) {
      final stake = arena.minStake + random.nextInt(arena.maxStake - arena.minStake);
      final bullType = PlayExtraConfig.bullTypes[random.nextInt(PlayExtraConfig.bullTypes.length)];
      
      opponents.add(BattlePlayer(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}_$i',
        username: '${aiNames[random.nextInt(aiNames.length)]}${random.nextInt(999)}',
        bullType: bullType,
        stakeAmount: stake,
        arenaId: arenaId,
        joinedAt: DateTime.now().subtract(Duration(seconds: random.nextInt(60))),
        level: 1 + random.nextInt(10),
        totalWins: random.nextInt(100),
      ));
    }
    
    return opponents;
  }

  // Update Player Statistics
  void _updatePlayerStats(bool won, int cneEarned, int stakeAmount) {
    final newStats = PlayerStats(
      playerId: _playerStats.playerId,
      totalBattles: _playerStats.totalBattles + 1,
      totalWins: _playerStats.totalWins + (won ? 1 : 0),
      totalLosses: _playerStats.totalLosses + (won ? 0 : 1),
      highestWin: won ? max(_playerStats.highestWin, cneEarned) : _playerStats.highestWin,
      totalCNEEarned: _playerStats.totalCNEEarned + cneEarned,
      currentStreak: won ? _playerStats.currentStreak + 1 : 0,
      bestStreak: won ? max(_playerStats.bestStreak, _playerStats.currentStreak + 1) : _playerStats.bestStreak,
      lastPlayed: DateTime.now(),
      arenaWins: Map<String, int>.from(_playerStats.arenaWins)
        ..update(_currentBattle?.arenaId ?? 'unknown', (value) => value + (won ? 1 : 0), ifAbsent: () => won ? 1 : 0),
    );
    
    _playerStats = newStats;
  }

  // Leave Current Battle
  Future<void> leaveBattle() async {
    if (_currentBattle != null && _currentPlayer != null) {
      // Return staked coins if battle hasn't started
      if (_currentBattle!.status == BattleSessionStatus.waiting) {
        _playerCoins += _currentPlayer!.stakeAmount;
        print('💰 Stake returned: ${_currentPlayer!.stakeAmount} CNE');
      }
      
      _currentBattle = null;
      _currentPlayer = null;
      await _savePlayerData();
    }
  }

  // Get Formatted Battle History for UI
  List<String> getFormattedBattleHistory() {
    return _battleHistory.map((battle) {
      final isWinner = battle.winnerId == _playerStats.playerId;
      final result = isWinner ? 'WON' : 'LOST';
      final amount = isWinner ? '+${battle.winnerReward}' : '-${battle.participants.firstWhere((p) => p.id == _playerStats.playerId, orElse: () => BattlePlayer(id: '', username: '', bullType: 'blue_bull', stakeAmount: 0, arenaId: '', joinedAt: DateTime.now())).stakeAmount}';
      final arenaName = PlayExtraConfig.defaultArenas
          .firstWhere((a) => a.id == battle.participants.first.arenaId, orElse: () => PlayExtraConfig.defaultArenas.first)
          .name;
      
      return '$result $arenaName: $amount CNE';
    }).toList();
  }

  // Add CNE Tokens (for testing or rewards)
  Future<void> addCoins(int amount) async {
    _playerCoins += amount;
    await _savePlayerData();
    print('💰 Added $amount CNE tokens');
  }

  // Get Player Rank Color
  Color getPlayerRankColor() {
    switch (_playerStats.playerRank) {
      case 'Champion': return Colors.amber;
      case 'Expert': return Colors.purple;
      case 'Advanced': return Colors.blue;
      case 'Intermediate': return Colors.green;
      default: return Colors.grey;
    }
  }

}