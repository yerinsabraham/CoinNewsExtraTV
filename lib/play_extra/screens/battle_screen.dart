import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/play_extra_service.dart';
import '../services/countdown_timer_service.dart';
import '../models/game_models.dart';
import '../../services/user_balance_service.dart';

class BattleScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRooms;
  
  const BattleScreen({Key? key, this.onNavigateToRooms}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with TickerProviderStateMixin {
  final PlayExtraService _gameService = PlayExtraService();
  final CountdownTimerService _timerService = CountdownTimerService();
  
  late AnimationController _wheelAnimationController;
  late Animation<double> _wheelAnimation;
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;
  
  bool _isSpinning = false;
  String? _winningColor;
  List<Player> _mockPlayers = [];

  @override
  void initState() {
    super.initState();
    _gameService.addListener(_onGameStateChanged);
    _timerService.addListener(_onTimerStateChanged);
    
    // Initialize timer service to ensure it's listening to rounds
    _timerService.initialize();
    
    _wheelAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _wheelAnimation = Tween<double>(
      begin: 0,
      end: 6.28318530718 * 6, // 6 full rotations
    ).animate(CurvedAnimation(
      parent: _wheelAnimationController,
      curve: Curves.decelerate,
    ));

    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _arrowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.elasticOut,
    ));

    _generateMockPlayers();
  }

  @override
  void dispose() {
    _gameService.removeListener(_onGameStateChanged);
    _timerService.removeListener(_onTimerStateChanged);
    _wheelAnimationController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTimerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _generateMockPlayers() {
    final colors = ['blue', 'red', 'green', 'yellow', 'purple', 'orange'];
    final rooms = ['Rookie Room', 'Pro Room', 'Elite Room', 'Champion Room'];
    final random = Random();
    
    _mockPlayers = List.generate(random.nextInt(4) + 2, (index) {
      return Player(
        id: 'player_$index',
        username: 'Player${1000 + index}',
        avatarColor: colors[index % colors.length],
        stakeAmount: [50, 150, 300, 750, 1500][random.nextInt(5)],
        roomName: rooms[random.nextInt(rooms.length)],
        joinedAt: DateTime.now().subtract(Duration(minutes: random.nextInt(10))),
      );
    });

    // Add current player if in battle
    final currentPlayer = _gameService.gameState.currentPlayer;
    if (currentPlayer != null) {
      _mockPlayers.insert(0, currentPlayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _gameService.gameState;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(
              Icons.casino,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Battle Arena',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        actions: [
          Consumer<UserBalanceService>(
            builder: (context, balanceService, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006833),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${balanceService.balance.unlockedBalance.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Always show the real-time round status and countdown
            _buildRoundStatusCard(),
            const SizedBox(height: 20),
            
            // Always show battle wheel and players if there are active players
            if (_getAllActivePlayers().isNotEmpty) ...[
              // Battle Wheel (shows current active battle)
              _buildBattleWheel(),
              const SizedBox(height: 20),
              _buildLivePlayerList(),
              const SizedBox(height: 20),
              
              // Show spin button only if user is in battle
              if (gameState.isInBattle)
                _buildSpinButton(),
            ] else ...[
              // Live Battle Preview (when user is not in battle)
              _buildLiveBattlePreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattleWheel() {
    final totalStake = _getAllActivePlayers().fold(0, (sum, player) => sum + player.stakeAmount);
    
    // Get current room info from the current player
    final currentPlayer = _gameService.gameState.currentPlayer;
    final roomId = currentPlayer?.roomName?.toLowerCase().replaceAll(' room', '') ?? 'rookie';
    
    // Get round information from timer service
    final activeRound = _timerService.getActiveRound(roomId);
    final isRoundActive = _timerService.isRoundActive(roomId);
    final timeRemaining = _timerService.getFormattedTimeRemaining(roomId);
    final secondsRemaining = _timerService.getSecondsRemaining(roomId);
    
    // Determine battle status
    String battleStatus;
    Color statusColor;
    if (isRoundActive && activeRound != null) {
      battleStatus = _isSpinning ? 'Battle in Progress!' : 'Round Active - Join Now!';
      statusColor = Colors.orange;
    } else {
      battleStatus = 'Waiting for Next Round';
      statusColor = Colors.grey;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            battleStatus,
            style: TextStyle(
              color: statusColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          
          // Show countdown timer when round is not active
          if (!isRoundActive && secondsRemaining <= 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Next round will start soon...',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Show active round countdown
          if (isRoundActive && activeRound != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Round ends in: $timeRemaining',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Text(
            'Total Stake Pool: $totalStake CNE coins',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 24),
          
          // Wheel with Arrow
          Stack(
            alignment: Alignment.center,
            children: [
              // Arrow (pointer)
              Positioned(
                top: 0,
                child: AnimatedBuilder(
                  animation: _arrowAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _arrowAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Wheel
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: _buildAnimatedWheel(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
            
          if (_isSpinning)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Spinning...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
            
          if (_winningColor != null)
            _buildWinResult(),
        ],
      ),
    );
  }

  Widget _buildAnimatedWheel() {
    return AnimatedBuilder(
      animation: _wheelAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _wheelAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: WheelPainter(players: _getAllActivePlayers()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinResult() {
    final activePlayers = _getAllActivePlayers();
    if (activePlayers.isEmpty) {
      return Container(); // No active players, no results to show
    }
    
    final winner = activePlayers.firstWhere(
      (p) => p.avatarColor == _winningColor,
      orElse: () => activePlayers.first,
    );
    final isCurrentPlayerWinner = winner.id == _gameService.gameState.currentPlayer?.id;
    final totalWinnings = activePlayers.fold(0, (sum, player) => sum + player.stakeAmount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentPlayerWinner 
            ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
            : [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlayerWinner ? Colors.green : Colors.red,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCurrentPlayerWinner ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated trophy/sad icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            child: Icon(
              isCurrentPlayerWinner ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
              size: 48,
              color: isCurrentPlayerWinner ? Colors.yellow : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          
          // Win/Loss text with animation
          Text(
            isCurrentPlayerWinner ? '🎉 VICTORY!' : '💔 DEFEAT',
            style: TextStyle(
              color: isCurrentPlayerWinner ? Colors.green : Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Winner details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Winner: ${winner.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getColorFromName(_winningColor!),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Winning Color: ${_winningColor?.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isCurrentPlayerWinner 
                    ? 'You won $totalWinnings CNE coins!' 
                    : 'You lost ${_gameService.gameState.currentPlayer?.stakeAmount ?? 0} CNE coins',
                  style: TextStyle(
                    color: isCurrentPlayerWinner ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetBattle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Switch to Room tab to join another room
                  },
                  icon: const Icon(Icons.meeting_room),
                  label: const Text('New Room'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    final colorMap = {
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
    };
    return colorMap[colorName] ?? Colors.grey;
  }

  Widget _buildLivePlayerList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Live Players',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._buildPlayersList(),
        ],
      ),
    );
  }

  List<Player> _getAllActivePlayers() {
    final allPlayers = <Player>[];
    for (final round in _timerService.activeRounds.values) {
      allPlayers.addAll(round.players);
    }
    return allPlayers;
  }

  List<Widget> _buildPlayersList() {
    final allPlayers = _getAllActivePlayers();
    
    if (allPlayers.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Column(
            children: [
              Icon(Icons.people_outline, color: Colors.grey[400], size: 32),
              const SizedBox(height: 8),
              Text(
                'No Active Players',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join a round from the Rooms tab to see players here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ),
      ];
    }
    
    return allPlayers.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      return _buildPlayerCard(player, index);
    }).toList();
  }

  Widget _buildPlayerCard(Player player, int index) {
    final isCurrentPlayer = player.id == _gameService.gameState.currentPlayer?.id;
    final colorMap = {
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
    };
    final playerColor = colorMap[player.avatarColor] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? const Color(0xFF006833).withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: isCurrentPlayer ? Border.all(color: const Color(0xFF006833), width: 2) : null,
      ),
      child: Row(
        children: [
          // Player Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: playerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: playerColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/avatars/minotaur-${player.avatarColor}-NESW.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_martial_arts,
                    size: 20,
                    color: playerColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.username,
                      style: TextStyle(
                        color: isCurrentPlayer ? const Color(0xFF006833) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    if (isCurrentPlayer) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006833),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${player.roomName} • ${player.stakeAmount} CNE',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          // Color indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: playerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBattleCard() {
    // Check all rooms for any active rounds or upcoming rounds
    final rooms = ['rookie', 'pro', 'elite'];
    String nextRoundInfo = '';
    String? earliestRoom;
    int shortestWait = 999999;
    
    for (final roomId in rooms) {
      final isActive = _timerService.isRoundActive(roomId);
      final timeRemaining = _timerService.getSecondsRemaining(roomId);
      
      if (isActive) {
        nextRoundInfo = 'Active rounds available! Check the Rooms tab.';
        break;
      } else if (timeRemaining > 0 && timeRemaining < shortestWait) {
        shortestWait = timeRemaining;
        earliestRoom = roomId;
        final minutes = timeRemaining ~/ 60;
        final seconds = timeRemaining % 60;
        nextRoundInfo = 'Next round in ${earliestRoom?.toUpperCase()}: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    }
    
    if (nextRoundInfo.isEmpty) {
      nextRoundInfo = 'Waiting for new rounds to be created...';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.casino,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          
          const Text(
            'No Active Battle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Join a battle room to start spinning the wheel and compete with other players!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Next round info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nextRoundInfo,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: widget.onNavigateToRooms,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006833),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Browse Rooms',
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBattlePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Battle Arena',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.casino, size: 48, color: Colors.blue),
                const SizedBox(height: 12),
                const Text(
                  'Ready to Battle?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join an active round from the Rooms tab to start battling with other players!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.onNavigateToRooms,
                  icon: const Icon(Icons.meeting_room),
                  label: const Text('Browse Rooms'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectatorPlayerCard(Player player) {
    final colorMap = {
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
    };
    final playerColor = colorMap[player.avatarColor] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: playerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: playerColor, width: 2),
            ),
            child: Icon(
              Icons.sports_martial_arts,
              size: 16,
              color: playerColor,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  '${player.stakeAmount} CNE • ${player.roomName}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    if (_isSpinning || _winningColor != null) {
      return Container(); // Don't show button while spinning or after result
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _spinWheel,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, size: 24),
            SizedBox(width: 8),
            Text(
              'SPIN THE WHEEL!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _spinWheel() async {
    setState(() {
      _isSpinning = true;
      _winningColor = null;
    });

    // Start wheel animation
    _wheelAnimationController.reset();
    _wheelAnimationController.forward();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 4000));

    // Determine winner from active players
    final activePlayers = _getAllActivePlayers();
    if (activePlayers.isEmpty) {
      return; // No active players, can't spin
    }
    
    final random = Random();
    _winningColor = activePlayers[random.nextInt(activePlayers.length)].avatarColor;

    // Animate arrow
    _arrowAnimationController.reset();
    _arrowAnimationController.forward();

    // Check if current player won
    final currentPlayer = _gameService.gameState.currentPlayer;
    if (currentPlayer != null && currentPlayer.avatarColor == _winningColor) {
      final totalWinnings = activePlayers.fold(0, (sum, player) => sum + player.stakeAmount);
      await _gameService.completeBattle(true, totalWinnings);
    } else {
      await _gameService.completeBattle(false, 0);
    }

    setState(() {
      _isSpinning = false;
    });

    // Show immediate result popup
    _showBattleResultPopup(currentPlayer?.avatarColor == _winningColor);
  }

  Future<void> _showBattleResultPopup(bool won) async {
    final totalWinnings = _getAllActivePlayers().fold(0, (sum, player) => sum + player.stakeAmount);
    final stakeAmount = _gameService.gameState.currentPlayer?.stakeAmount ?? 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: won ? Colors.green : Colors.red,
            width: 3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            Icon(
              won ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
              size: 64,
              color: won ? Colors.yellow : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            
            Text(
              won ? '🎉 CONGRATULATIONS!' : '💔 BETTER LUCK NEXT TIME',
              style: TextStyle(
                color: won ? Colors.green : Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (won ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    won 
                      ? 'You won the battle!'
                      : 'You lost this round',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: won ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        won 
                          ? '+$totalWinnings CNE coins'
                          : '-$stakeAmount CNE coins',
                        style: TextStyle(
                          color: won ? Colors.green : Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006833),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetBattle() {
    setState(() {
      _winningColor = null;
      _isSpinning = false;
    });
    _generateMockPlayers();
  }

  // NEW: Always show real-time round status and countdown
  Widget _buildRoundStatusCard() {
    // Check all rooms for active rounds or upcoming rounds
    final rooms = ['rookie', 'pro', 'elite'];
    final List<Map<String, dynamic>> roomStatus = [];
    
    for (final roomId in rooms) {
      final isActive = _timerService.isRoundActive(roomId);
      final timeRemaining = _timerService.getSecondsRemaining(roomId);
      final formattedTime = _timerService.getFormattedTimeRemaining(roomId);
      final activeRound = _timerService.getActiveRound(roomId);
      
      roomStatus.add({
        'roomId': roomId,
        'roomName': roomId.toUpperCase(),
        'isActive': isActive,
        'timeRemaining': timeRemaining,
        'formattedTime': formattedTime,
        'playersCount': activeRound?.players.length ?? 0,
      });
    }
    
    // Find the best status to show
    final activeRooms = roomStatus.where((r) => r['isActive'] == true).toList();
    final upcomingRooms = roomStatus.where((r) => r['timeRemaining'] > 0 && !r['isActive']).toList();
    
    String statusText;
    String timerText;
    Color statusColor;
    IconData statusIcon;
    
    if (activeRooms.isNotEmpty) {
      // Show active rounds
      statusText = 'Active Rounds Available!';
      statusColor = Colors.orange;
      statusIcon = Icons.play_circle_filled;
      timerText = '${activeRooms.length} room${activeRooms.length > 1 ? 's' : ''} accepting players';
    } else if (upcomingRooms.isNotEmpty) {
      // Show next round
      upcomingRooms.sort((a, b) => a['timeRemaining'].compareTo(b['timeRemaining']));
      final nextRoom = upcomingRooms.first;
      statusText = 'Next Round Starting Soon';
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
      timerText = '${nextRoom['roomName']} in ${nextRoom['formattedTime']}';
    } else {
      statusText = 'No Active Rounds';
      statusColor = Colors.grey;
      statusIcon = Icons.pause_circle_filled;
      timerText = 'Waiting for new rounds to be created...';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timerText,
                      style: TextStyle(
                        color: statusColor.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (activeRooms.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            
            // Show active rooms details
            ...activeRooms.map((room) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${room['roomName']} Room',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  Text(
                    'Ends: ${room['formattedTime']}',
                    style: TextStyle(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (room['playersCount'] > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${room['playersCount']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            )).toList(),
            
            const SizedBox(height: 12),
            Text(
              'Go to Rooms tab to join a battle!',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Player> players;

  WheelPainter({required this.players});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final colorMap = {
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
    };

    if (players.isEmpty) return;

    final segmentAngle = (2 * pi) / players.length;

    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final color = colorMap[player.avatarColor] ?? Colors.grey;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final startAngle = i * segmentAngle - (pi / 2);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );
    }

    // Draw center
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 20, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 20, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
