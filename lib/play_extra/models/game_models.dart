import 'package:flutter/material.dart';

// Modern Battle Player Model for Rocky Rabbit Style Game
class BattlePlayer {
  final String id;
  final String username;
  final String bullType; // 'blue_bull', 'red_bull', 'gold_bull'
  final int stakeAmount;
  final String arenaId;
  final DateTime joinedAt;
  final int level;
  final int totalWins;
  final double powerMultiplier;

  BattlePlayer({
    required this.id,
    required this.username,
    required this.bullType,
    required this.stakeAmount,
    required this.arenaId,
    required this.joinedAt,
    this.level = 1,
    this.totalWins = 0,
    this.powerMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'bullType': bullType,
      'stakeAmount': stakeAmount,
      'arenaId': arenaId,
      'joinedAt': joinedAt.toIso8601String(),
      'level': level,
      'totalWins': totalWins,
      'powerMultiplier': powerMultiplier,
    };
  }

  factory BattlePlayer.fromJson(Map<String, dynamic> json) {
    return BattlePlayer(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Unknown Player',
      bullType: json['bullType'] ?? 'blue_bull',
      stakeAmount: json['stakeAmount'] ?? 0,
      arenaId: json['arenaId'] ?? '',
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      level: json['level'] ?? 1,
      totalWins: json['totalWins'] ?? 0,
      powerMultiplier: json['powerMultiplier'] ?? 1.0,
    );
  }

  // Get bull avatar asset path
  String get bullAvatarPath => 'assets/avatars/minotaur-${bullType.split('_')[0]}-NESW.png';
  
  // Calculate battle power based on stake and level
  double get battlePower => stakeAmount * powerMultiplier * (1 + (level * 0.1));
}

// Battle Arena with Different Stakes (Rocky Rabbit Style)
class BattleArena {
  final String id;
  final String name;
  final int minStake;
  final int maxStake;
  final Color themeColor;
  final IconData icon;
  final String description;
  final int maxPlayers;
  final Duration battleDuration;
  final double winMultiplier;

  const BattleArena({
    required this.id,
    required this.name,
    required this.minStake,
    required this.maxStake,
    required this.themeColor,
    required this.icon,
    required this.description,
    this.maxPlayers = 8,
    this.battleDuration = const Duration(minutes: 2),
    this.winMultiplier = 1.8,
  });

  // Check if stake amount is valid for this arena
  bool isValidStake(int amount) => amount >= minStake && amount <= maxStake;
  
  // Calculate potential winnings
  int calculateWinnings(int stake) => (stake * winMultiplier).round();
  
  // Get arena difficulty level
  String get difficultyLevel {
    if (maxStake <= 100) return 'Beginner';
    if (maxStake <= 500) return 'Intermediate';
    if (maxStake <= 1000) return 'Advanced';
    return 'Expert';
  }
}

// Battle Result with Comprehensive Data
class BattleResult {
  final String battleId;
  final String winnerId;
  final String winnerBullType;
  final List<BattlePlayer> participants;
  final int totalStakePool;
  final int winnerReward;
  final DateTime completedAt;
  final String resultType; // 'wheel_spin', 'tap_battle', 'time_attack'

  BattleResult({
    required this.battleId,
    required this.winnerId,
    required this.winnerBullType,
    required this.participants,
    required this.totalStakePool,
    required this.winnerReward,
    required this.completedAt,
    this.resultType = 'wheel_spin',
  });

  Map<String, dynamic> toJson() {
    return {
      'battleId': battleId,
      'winnerId': winnerId,
      'winnerBullType': winnerBullType,
      'participants': participants.map((p) => p.toJson()).toList(),
      'totalStakePool': totalStakePool,
      'winnerReward': winnerReward,
      'completedAt': completedAt.toIso8601String(),
      'resultType': resultType,
    };
  }

  factory BattleResult.fromJson(Map<String, dynamic> json) {
    return BattleResult(
      battleId: json['battleId'] ?? '',
      winnerId: json['winnerId'] ?? '',
      winnerBullType: json['winnerBullType'] ?? 'blue_bull',
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => BattlePlayer.fromJson(p))
          .toList() ?? [],
      totalStakePool: json['totalStakePool'] ?? 0,
      winnerReward: json['winnerReward'] ?? 0,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      resultType: json['resultType'] ?? 'wheel_spin',
    );
  }
}

// Player Stats and Progression
class PlayerStats {
  final String playerId;
  final int totalBattles;
  final int totalWins;
  final int totalLosses;
  final int highestWin;
  final int totalCNEEarned;
  final int currentStreak;
  final int bestStreak;
  final DateTime lastPlayed;
  final Map<String, int> arenaWins; // Arena ID -> Win count

  PlayerStats({
    required this.playerId,
    this.totalBattles = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.highestWin = 0,
    this.totalCNEEarned = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    DateTime? lastPlayed,
    this.arenaWins = const {},
  }) : lastPlayed = lastPlayed ?? DateTime.now();

  // Calculate win rate
  double get winRate => totalBattles > 0 ? totalWins / totalBattles : 0.0;
  
  // Get player rank based on performance
  String get playerRank {
    if (totalWins >= 100) return 'Champion';
    if (totalWins >= 50) return 'Expert';
    if (totalWins >= 20) return 'Advanced';
    if (totalWins >= 5) return 'Intermediate';
    return 'Beginner';
  }
  
  // Calculate player level
  int get playerLevel => (totalWins / 10).floor() + 1;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'totalBattles': totalBattles,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'highestWin': highestWin,
      'totalCNEEarned': totalCNEEarned,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastPlayed': lastPlayed.toIso8601String(),
      'arenaWins': arenaWins,
    };
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerId: json['playerId'] ?? '',
      totalBattles: json['totalBattles'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      totalLosses: json['totalLosses'] ?? 0,
      highestWin: json['highestWin'] ?? 0,
      totalCNEEarned: json['totalCNEEarned'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.parse(json['lastPlayed'])
          : DateTime.now(),
      arenaWins: Map<String, int>.from(json['arenaWins'] ?? {}),
    );
  }
}

// Active Battle Session
class BattleSession {
  final String sessionId;
  final String arenaId;
  final List<BattlePlayer> players;
  final BattleSessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration timeLimit;
  final String? winnerId;

  BattleSession({
    required this.sessionId,
    required this.arenaId,
    required this.players,
    required this.status,
    required this.startTime,
    this.endTime,
    this.timeLimit = const Duration(minutes: 2),
    this.winnerId,
  });

  // Time remaining in session
  Duration get timeRemaining {
    if (status == BattleSessionStatus.completed) return Duration.zero;
    final elapsed = DateTime.now().difference(startTime);
    final remaining = timeLimit - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Check if session can accept more players
  bool get canJoin => status == BattleSessionStatus.waiting && players.length < 8;
  
  // Total stake pool
  int get totalStakePool => players.fold(0, (sum, player) => sum + player.stakeAmount);

  // Format time remaining as MM:SS
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Global Battle Round System (Rocky Rabbit Style)
class GlobalBattleRound {
  final String roundId;
  final DateTime startTime;
  final Duration joinWindow; // 2 minutes to join
  final Duration battleDuration; // 30 seconds to spin
  final GlobalBattleStatus status;
  final List<BattlePlayer> players;
  final int maxPlayers; // 10 players max
  final BattlePlayer? winner;
  final DateTime? finishTime;
  
  GlobalBattleRound({
    required this.roundId,
    required this.startTime,
    this.joinWindow = const Duration(minutes: 2),
    this.battleDuration = const Duration(seconds: 30),
    this.status = GlobalBattleStatus.accepting,
    this.players = const [],
    this.maxPlayers = 10,
    this.winner,
    this.finishTime,
  });
  
  Duration get timeRemaining {
    final now = DateTime.now();
    switch (status) {
      case GlobalBattleStatus.accepting:
        final joinDeadline = startTime.add(joinWindow);
        final remaining = joinDeadline.difference(now);
        return remaining.isNegative ? Duration.zero : remaining;
      case GlobalBattleStatus.battling:
        final battleStart = startTime.add(joinWindow);
        final battleEnd = battleStart.add(battleDuration);
        final remaining = battleEnd.difference(now);
        return remaining.isNegative ? Duration.zero : remaining;
      default:
        return Duration.zero;
    }
  }
  
  String get formattedTimeRemaining {
    final duration = timeRemaining;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  bool get canJoin => status == GlobalBattleStatus.accepting && 
                      players.length < maxPlayers &&
                      timeRemaining.inSeconds > 0;
  
  bool get canStartBattle => status == GlobalBattleStatus.accepting &&
                            players.length >= 2 &&
                            timeRemaining.inSeconds <= 0;
}

enum GlobalBattleStatus {
  accepting,   // Accepting players (2-minute join window)
  battling,    // Battle in progress (spinning wheel)
  finished,    // Battle completed, showing results
  preparing,   // Brief pause before next round
}

enum BattleSessionStatus {
  waiting,    // Waiting for players
  active,     // Battle in progress
  completed,  // Battle finished
  cancelled,  // Battle cancelled
}

// Game Configuration and Constants
class PlayExtraConfig {
  static const List<BattleArena> defaultArenas = [
    BattleArena(
      id: 'rookie_ring',
      name: 'Rookie Ring',
      minStake: 10,
      maxStake: 100,
      themeColor: Colors.green,
      icon: Icons.sports_martial_arts,
      description: 'Perfect for beginners! Low stakes, high fun!',
      winMultiplier: 1.8,
    ),
    BattleArena(
      id: 'warrior_arena',
      name: 'Warrior Arena',
      minStake: 100,
      maxStake: 500,
      themeColor: Colors.blue,
      icon: Icons.shield,
      description: 'For seasoned fighters. Medium stakes, bigger rewards!',
      winMultiplier: 1.9,
    ),
    BattleArena(
      id: 'champion_colosseum',
      name: 'Champion Colosseum',
      minStake: 500,
      maxStake: 2000,
      themeColor: Colors.purple,
      icon: Icons.emoji_events,
      description: 'Elite battles for champions. High stakes, massive rewards!',
      winMultiplier: 2.0,
    ),
    BattleArena(
      id: 'legend_battlefield',
      name: 'Legend Battlefield',
      minStake: 2000,
      maxStake: 10000,
      themeColor: Colors.orange,
      icon: Icons.military_tech,
      description: 'Only for legends! Maximum stakes, ultimate glory!',
      winMultiplier: 2.2,
    ),
  ];

  static const List<String> bullTypes = [
    'blue_bull',
    'red_bull',
    'green_bull',
    'yellow_bull',
    'purple_bull',
    'orange_bull',
  ];

  static const Map<String, String> bullNames = {
    'blue_bull': 'Thunder Bull',
    'red_bull': 'Fire Bull',
    'green_bull': 'Forest Bull',
    'yellow_bull': 'Lightning Bull',
    'purple_bull': 'Shadow Bull',
    'orange_bull': 'Flame Bull',
  };

  static const Map<String, Color> bullColors = {
    'blue_bull': Colors.blue,
    'red_bull': Colors.red,
    'green_bull': Colors.green,
    'yellow_bull': Colors.yellow,
    'purple_bull': Colors.purple,
    'orange_bull': Colors.orange,
  };

  // Battle mechanics constants  
  static const int defaultCoins = 1000;
  static const int maxPlayersPerBattle = 10; // 10 players max as requested
  static const Duration battleTimeout = Duration(minutes: 2);
  static const Duration joinTimeLimit = Duration(minutes: 2); // 2-minute join window
}