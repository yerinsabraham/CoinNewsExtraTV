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

class GameState {
  final int coins;
  final String selectedCharacter;
  final Player? currentPlayer;
  final BattleRoom? currentBattle;
  final bool isInBattle;
  final List<String> transactionHistory;

  GameState({
    this.coins = 1000,
    this.selectedCharacter = 'blue',
    this.currentPlayer,
    this.currentBattle,
    this.isInBattle = false,
    this.transactionHistory = const [],
  });

  GameState copyWith({
    int? coins,
    String? selectedCharacter,
    Player? currentPlayer,
    BattleRoom? currentBattle,
    bool? isInBattle,
    List<String>? transactionHistory,
  }) {
    return GameState(
      coins: coins ?? this.coins,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      currentBattle: currentBattle ?? this.currentBattle,
      isInBattle: isInBattle ?? this.isInBattle,
      transactionHistory: transactionHistory ?? this.transactionHistory,
    );
  }
}
