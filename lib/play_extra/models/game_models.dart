import 'package:flutter/material.dart';

class Player {
  final String id;
  final String username;
  final String avatarColor; // 'blue', 'red', 'green', 'yellow', etc.
  final int stakeAmount;
  final String roomName;
  final DateTime joinedAt;

  Player({
    required this.id,
    required this.username,
    required this.avatarColor,
    required this.stakeAmount,
    required this.roomName,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarColor': avatarColor,
      'stakeAmount': stakeAmount,
      'roomName': roomName,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      username: json['username'],
      avatarColor: json['avatarColor'],
      stakeAmount: json['stakeAmount'],
      roomName: json['roomName'],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
}

class BattleRoom {
  final String id;
  final String name;
  final int minStake;
  final int maxStake;
  final Color color;
  final IconData icon;
  final String description;
  final List<Player> players;
  final int maxPlayers;
  final bool isActive;

  BattleRoom({
    required this.id,
    required this.name,
    required this.minStake,
    required this.maxStake,
    required this.color,
    required this.icon,
    required this.description,
    this.players = const [],
    this.maxPlayers = 8,
    this.isActive = true,
  });

  int get totalStakePool => players.fold(0, (sum, player) => sum + player.stakeAmount);
  bool get isFull => players.length >= maxPlayers;
  bool get hasMinimumPlayers => players.length >= 2;

  BattleRoom copyWith({
    List<Player>? players,
    bool? isActive,
  }) {
    return BattleRoom(
      id: id,
      name: name,
      minStake: minStake,
      maxStake: maxStake,
      color: color,
      icon: icon,
      description: description,
      players: players ?? this.players,
      maxPlayers: maxPlayers,
      isActive: isActive ?? this.isActive,
    );
  }
}

class BattleHistory {
  final String id;
  final String roomId;
  final bool isWinner;
  final int stake;
  final String result;
  final DateTime timestamp;

  BattleHistory({
    required this.id,
    required this.roomId,
    required this.isWinner,
    required this.stake,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'isWinner': isWinner,
      'stake': stake,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BattleHistory.fromJson(Map<String, dynamic> json) {
    return BattleHistory(
      id: json['id'],
      roomId: json['roomId'],
      isWinner: json['isWinner'],
      stake: json['stake'],
      result: json['result'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class WheelResult {
  final bool winner;
  final String color;
  final int coins;
  final String message;

  WheelResult({
    required this.winner,
    required this.color,
    required this.coins,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'winner': winner,
      'color': color,
      'coins': coins,
      'message': message,
    };
  }

  factory WheelResult.fromJson(Map<String, dynamic> json) {
    return WheelResult(
      winner: json['winner'],
      color: json['color'],
      coins: json['coins'],
      message: json['message'],
    );
  }
}

enum RoundStatus { 
  waiting,     // Round is open for joining
  active,      // Battle in progress (wheel spinning)
  completed,   // Round finished with winner
  cancelled    // Round cancelled (not enough players)
}

class TimedRound {
  final String id;
  final String roomId;
  final RoundStatus status;
  final DateTime roundStartTime;
  final DateTime roundEndTime;
  final List<Player> players;
  final String? winnerId;
  final String? resultColor;
  final int totalStake;
  final DateTime? completedAt;
  final String? cancelReason;

  TimedRound({
    required this.id,
    required this.roomId,
    required this.status,
    required this.roundStartTime,
    required this.roundEndTime,
    this.players = const [],
    this.winnerId,
    this.resultColor,
    this.totalStake = 0,
    this.completedAt,
    this.cancelReason,
  });

  // Time remaining in seconds (using server time if available)
  int get secondsRemaining {
    final now = DateTime.now();
    if (now.isAfter(roundEndTime)) return 0;
    return roundEndTime.difference(now).inSeconds;
  }
  
  // Server-synchronized time remaining (more accurate)
  int getSecondsRemaining(DateTime serverTime) {
    if (serverTime.isAfter(roundEndTime)) return 0;
    return roundEndTime.difference(serverTime).inSeconds;
  }

  // Duration of the round in seconds
  int get roundDurationSeconds {
    return roundEndTime.difference(roundStartTime).inSeconds;
  }

  bool get isJoinable => status == RoundStatus.waiting && secondsRemaining > 0;
  
  // Server-synchronized joinability check
  bool isJoinableWithServerTime(DateTime serverTime) {
    final remaining = getSecondsRemaining(serverTime);
    return status == RoundStatus.waiting && remaining > 5; // 5 second buffer
  }
  bool get hasMinimumPlayers => players.length >= 2;
  bool get isExpired => DateTime.now().isAfter(roundEndTime);

  TimedRound copyWith({
    RoundStatus? status,
    List<Player>? players,
    String? winnerId,
    String? resultColor,
    int? totalStake,
    DateTime? completedAt,
    String? cancelReason,
  }) {
    return TimedRound(
      id: id,
      roomId: roomId,
      status: status ?? this.status,
      roundStartTime: roundStartTime,
      roundEndTime: roundEndTime,
      players: players ?? this.players,
      winnerId: winnerId ?? this.winnerId,
      resultColor: resultColor ?? this.resultColor,
      totalStake: totalStake ?? this.totalStake,
      completedAt: completedAt ?? this.completedAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'status': status.name,
      'roundStartTime': roundStartTime.toIso8601String(),
      'roundEndTime': roundEndTime.toIso8601String(),
      'players': players.map((p) => p.toJson()).toList(),
      'winnerId': winnerId,
      'resultColor': resultColor,
      'totalStake': totalStake,
      'completedAt': completedAt?.toIso8601String(),
      'cancelReason': cancelReason,
    };
  }

  factory TimedRound.fromJson(Map<String, dynamic> json) {
    try {
      return TimedRound(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        status: RoundStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RoundStatus.waiting,
        ),
        roundStartTime: json['roundStartTime'] != null 
            ? DateTime.parse(json['roundStartTime'])
            : DateTime.now(),
        roundEndTime: json['roundEndTime'] != null 
            ? DateTime.parse(json['roundEndTime'])
            : DateTime.now().add(Duration(minutes: 5)),
        players: (json['players'] as List<dynamic>?)
            ?.map((p) => Player.fromJson(p))
            .toList() ?? [],
        winnerId: json['winnerId'],
        resultColor: json['resultColor'],
        totalStake: json['totalStake'] ?? 0,
        completedAt: json['completedAt'] != null 
            ? DateTime.parse(json['completedAt']) 
            : null,
        cancelReason: json['cancelReason'],
      );
    } catch (e) {
      print('❌ Error creating TimedRound from JSON: $e');
      print('   JSON data: $json');
      // Return a default round to prevent crashes
      return TimedRound(
        id: json['id'] ?? 'error',
        roomId: json['roomId'] ?? 'unknown',
        status: RoundStatus.waiting,
        roundStartTime: DateTime.now(),
        roundEndTime: DateTime.now().add(Duration(minutes: 5)),
      );
    }
  }
}

class RoundTimer {
  final Duration roundDuration;
  final DateTime? currentRoundStart;
  final DateTime? currentRoundEnd;

  RoundTimer({
    this.roundDuration = const Duration(minutes: 2),
    this.currentRoundStart,
    this.currentRoundEnd,
  });

  int get secondsRemaining {
    if (currentRoundEnd == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(currentRoundEnd!)) return 0;
    return currentRoundEnd!.difference(now).inSeconds;
  }

  bool get isActive => currentRoundEnd != null && DateTime.now().isBefore(currentRoundEnd!);
  
  String get formattedTimeRemaining {
    final seconds = secondsRemaining;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class GameState {
  final int coins;
  final String selectedCharacter;
  final Player? currentPlayer;
  final BattleRoom? currentBattle;
  final bool isInBattle;
  final List<String> transactionHistory;
  final int totalWins;
  final int totalLosses;
  final List<BattleHistory> battleHistory;

  GameState({
    this.coins = 1000,
    this.selectedCharacter = 'blue',
    this.currentPlayer,
    this.currentBattle,
    this.isInBattle = false,
    this.transactionHistory = const [],
    this.totalWins = 0,
    this.totalLosses = 0,
    this.battleHistory = const [],
  });

  GameState copyWith({
    int? coins,
    String? selectedCharacter,
    Player? currentPlayer,
    BattleRoom? currentBattle,
    bool? isInBattle,
    List<String>? transactionHistory,
    int? totalWins,
    int? totalLosses,
    List<BattleHistory>? battleHistory,
  }) {
    return GameState(
      coins: coins ?? this.coins,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      currentBattle: currentBattle ?? this.currentBattle,
      isInBattle: isInBattle ?? this.isInBattle,
      transactionHistory: transactionHistory ?? this.transactionHistory,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      battleHistory: battleHistory ?? this.battleHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'selectedCharacter': selectedCharacter,
      'currentPlayer': currentPlayer?.toJson(),
      'currentBattle': null, // Don't persist the current battle
      'isInBattle': isInBattle,
      'transactionHistory': transactionHistory,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'battleHistory': battleHistory.map((h) => h.toJson()).toList(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      coins: json['coins'] ?? 1000,
      selectedCharacter: json['selectedCharacter'] ?? 'blue',
      currentPlayer: json['currentPlayer'] != null 
          ? Player.fromJson(json['currentPlayer']) 
          : null,
      currentBattle: null, // Don't restore the current battle
      isInBattle: json['isInBattle'] ?? false,
      transactionHistory: List<String>.from(json['transactionHistory'] ?? []),
      totalWins: json['totalWins'] ?? 0,
      totalLosses: json['totalLosses'] ?? 0,
      battleHistory: (json['battleHistory'] as List<dynamic>?)
          ?.map((h) => BattleHistory.fromJson(h))
          .toList() ?? [],
    );
  }
}
