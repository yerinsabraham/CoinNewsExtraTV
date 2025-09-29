import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class PlayExtraService extends ChangeNotifier {
  static final PlayExtraService _instance = PlayExtraService._internal();
  factory PlayExtraService() => _instance;
  PlayExtraService._internal();

  GameState _gameState = GameState();
  GameState get gameState => _gameState;

  final List<BattleRoom> _battleRooms = [
    BattleRoom(
      id: 'rookie',
      name: 'Rookie Room',
      minStake: 10,
      maxStake: 100,
      color: Colors.green,
      icon: Icons.sports_martial_arts,
      description: 'Perfect for beginners! Win probability increases with higher stakes.',
    ),
    BattleRoom(
      id: 'pro',
      name: 'Pro Room',
      minStake: 100,
      maxStake: 500,
      color: Colors.blue,
      icon: Icons.military_tech,
      description: 'For experienced players. Higher stakes, higher rewards!',
    ),
    BattleRoom(
      id: 'elite',
      name: 'Elite Room',
      minStake: 500,
      maxStake: 1000,
      color: Colors.purple,
      icon: Icons.star,
      description: 'Elite level battles with massive stake pools.',
    ),
    BattleRoom(
      id: 'champion',
      name: 'Champion Room',
      minStake: 1000,
      maxStake: 5000,
      color: Colors.orange,
      icon: Icons.emoji_events,
      description: 'Champions only! The ultimate high-stakes battlefield.',
    ),
  ];

  List<BattleRoom> get battleRooms => _battleRooms;

  final List<String> _availableColors = [
    'blue', 'red', 'green', 'yellow', 'purple', 'orange', 'pink', 'cyan'
  ];

  // Initialize the service
  Future<void> initialize() async {
    await _loadGameState();
  }

  // Load game state from persistent storage
  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final coins = prefs.getInt('play_extra_coins') ?? 1000;
    final selectedCharacter = prefs.getString('selected_character') ?? 'blue';
    final historyJson = prefs.getStringList('transaction_history') ?? [];
    
    _gameState = GameState(
      coins: coins,
      selectedCharacter: selectedCharacter,
      transactionHistory: historyJson,
    );
    
    notifyListeners();
  }

  // Save game state to persistent storage
  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('play_extra_coins', _gameState.coins);
    await prefs.setString('selected_character', _gameState.selectedCharacter);
    await prefs.setStringList('transaction_history', _gameState.transactionHistory);
  }

  // Update coins and save
  Future<void> updateCoins(int newAmount, String reason) async {
    final oldAmount = _gameState.coins;
    final change = newAmount - oldAmount;
    final transaction = '${DateTime.now().toIso8601String()}: ${change > 0 ? '+' : ''}$change CNE - $reason';
    
    _gameState = _gameState.copyWith(
      coins: newAmount,
      transactionHistory: [..._gameState.transactionHistory, transaction],
    );
    
    await _saveGameState();
    notifyListeners();
  }

  // Add coins (tap to earn, battle wins)
  Future<void> addCoins(int amount, String reason) async {
    await updateCoins(_gameState.coins + amount, reason);
  }

  // Spend coins (battle entry)
  Future<void> spendCoins(int amount, String reason) async {
    if (_gameState.coins >= amount) {
      await updateCoins(_gameState.coins - amount, reason);
    } else {
      throw Exception('Insufficient CNE coins');
    }
  }

  // Change selected character
  Future<void> selectCharacter(String character) async {
    _gameState = _gameState.copyWith(selectedCharacter: character);
    await _saveGameState();
    notifyListeners();
  }

  // Join a battle room
  Future<Player> joinBattle(String roomId, int stakeAmount, String playerColor) async {
    final room = _battleRooms.firstWhere((r) => r.id == roomId);
    
    if (stakeAmount < room.minStake || stakeAmount > room.maxStake) {
      throw Exception('Stake amount must be between ${room.minStake} and ${room.maxStake} CNE coins');
    }
    
    if (_gameState.coins < stakeAmount) {
      throw Exception('Insufficient CNE coins');
    }

    // Spend the coins
    await spendCoins(stakeAmount, 'Joined ${room.name}');

    // Create player
    final player = Player(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: 'Player${Random().nextInt(9999)}', // TODO: Get from user profile
      avatarColor: playerColor,
      stakeAmount: stakeAmount,
      roomName: room.name,
      joinedAt: DateTime.now(),
    );

    // Update game state
    _gameState = _gameState.copyWith(
      currentPlayer: player,
      currentBattle: room,
      isInBattle: true,
    );

    notifyListeners();
    return player;
  }

  // Calculate win probability based on stake amount
  double calculateWinProbability(int stakeAmount, BattleRoom room) {
    // Base probability is 40%
    double baseProbability = 0.4;
    
    // Higher stakes increase probability (up to 80% max)
    double stakeRatio = (stakeAmount - room.minStake) / (room.maxStake - room.minStake);
    double bonusProbability = stakeRatio * 0.4; // Up to 40% bonus
    
    return (baseProbability + bonusProbability).clamp(0.4, 0.8);
  }

  // Simulate battle result
  Future<bool> simulateBattle(Player player, BattleRoom room) async {
    final probability = calculateWinProbability(player.stakeAmount, room);
    final random = Random().nextDouble();
    return random < probability;
  }

  // Complete battle and award winnings
  Future<void> completeBattle(bool won, int winAmount) async {
    if (won) {
      await addCoins(winAmount, 'Battle Victory');
    }

    _gameState = _gameState.copyWith(
      currentPlayer: null,
      currentBattle: null,
      isInBattle: false,
    );

    notifyListeners();
  }

  // Get available colors (excluding already taken ones)
  List<String> getAvailableColors(List<Player> existingPlayers) {
    final takenColors = existingPlayers.map((p) => p.avatarColor).toSet();
    return _availableColors.where((color) => !takenColors.contains(color)).toList();
  }

  // Get transaction history (formatted)
  List<String> getFormattedHistory() {
    return _gameState.transactionHistory.reversed.take(20).map((transaction) {
      final parts = transaction.split(': ');
      if (parts.length >= 2) {
        final dateTime = DateTime.parse(parts[0]);
        final details = parts[1];
        final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        return '$timeStr - $details';
      }
      return transaction;
    }).toList();
  }

  // Clear transaction history
  Future<void> clearTransactionHistory() async {
    _gameState = _gameState.copyWith(transactionHistory: []);
    await _saveGameState();
    notifyListeners();
  }
}
