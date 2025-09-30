import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/play_extra_service.dart';
import '../services/countdown_timer_service.dart';
import '../models/game_models.dart';
import '../../services/user_balance_service.dart';

class RoomScreen extends StatefulWidget {
  final VoidCallback? onNavigateToBattle;
  
  const RoomScreen({Key? key, this.onNavigateToBattle}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final PlayExtraService _gameService = PlayExtraService();
  final CountdownTimerService _timerService = CountdownTimerService();
  final Map<String, TextEditingController> _stakeControllers = {};
  final Map<String, String> _selectedColors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gameService.addListener(_onGameStateChanged);
    _timerService.addListener(_onTimerStateChanged);
    _initializeRooms();
  }

  Future<void> _initializeRooms() async {
    // Ensure the services are initialized
    await _gameService.initialize();
    await _timerService.initialize();
    
    // Initialize controllers for each room
    for (final room in _gameService.battleRooms) {
      _stakeControllers[room.id] = TextEditingController(text: room.minStake.toString());
      _selectedColors[room.id] = 'blue';
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _gameService.removeListener(_onGameStateChanged);
    _timerService.removeListener(_onTimerStateChanged);
    for (final controller in _stakeControllers.values) {
      controller.dispose();
    }
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
              Icons.meeting_room,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Battle Rooms',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF006833),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Consumer<UserBalanceService>(
              builder: (context, balanceService, child) {
                return Row(
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
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Battle Rooms...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info Card
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  
                  // Battle Rooms
                  if (_gameService.battleRooms.isEmpty)
                    _buildNoRoomsCard()
                  else
                    ..._gameService.battleRooms.map((room) => Column(
                      children: [
                        _buildBattleRoomCard(room, gameState),
                        const SizedBox(height: 16),
                      ],
                    )).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildNoRoomsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Battle Rooms Available',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unable to load battle rooms from Firebase.\nCheck your internet connection and Firebase setup.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeRooms();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Battle Tips',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Higher stakes = Higher win probability\n• Choose your color wisely\n• Battle starts when 2+ players join\n• Winner takes the entire stake pool',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontFamily: 'Lato',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleRoomCard(BattleRoom room, GameState gameState) {
    final stakeController = _stakeControllers[room.id]!;
    final selectedColor = _selectedColors[room.id]!;
    
    return Consumer<UserBalanceService>(
      builder: (context, balanceService, child) {
        final canAfford = balanceService.balance.unlockedBalance >= room.minStake;
    
        // Get round info from timer service
        final activeRound = _timerService.getActiveRound(room.id);
        final isRoundActive = _timerService.isRoundActive(room.id);
        final timeRemaining = _timerService.getFormattedTimeRemaining(room.id);
        final roundStatusText = _timerService.getRoundStatusText(room.id);
        final roundStatusColor = _timerService.getRoundStatusColor(room.id);
        
        return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRoundActive && canAfford ? room.color : Colors.red.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header with Countdown
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: room.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  room.icon,
                  color: room.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        color: canAfford ? Colors.white : Colors.grey[500],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(
                      'Stakes: ${room.minStake}-${room.maxStake} CNE coins',
                      style: TextStyle(
                        color: canAfford ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              // Countdown Timer
              if (isRoundActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        timeRemaining,
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
            ],
          ),
          const SizedBox(height: 16),
          
          // Round Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: roundStatusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roundStatusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isRoundActive ? Icons.people : Icons.timer_off,
                  color: roundStatusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    roundStatusText,
                    style: TextStyle(
                      color: roundStatusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                if (activeRound != null && activeRound.players.isNotEmpty)
                  Text(
                    '${activeRound.players.length} joined',
                    style: TextStyle(
                      color: roundStatusColor.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'Lato',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            room.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Lato',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          
          if (canAfford) ...[
            // Stake Input
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Stake',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: stakeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '${room.minStake} - ${room.maxStake}',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixText: 'CNE',
                          suffixStyle: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Color Selection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Color',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildColorSelector(room.id, selectedColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Win Probability Display
            _buildWinProbability(room, stakeController),
            const SizedBox(height: 20),
            
            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isRoundActive ? () => _joinTimedBattle(room) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRoundActive ? room.color : Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRoundActive ? Icons.casino : Icons.timer_off,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRoundActive ? 'Join Round' : 'Round Closed',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need at least ${room.minStake} CNE coins to join',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildColorSelector(String roomId, String selectedColor) {
    final colors = ['blue', 'red', 'green', 'yellow'];
    final colorMap = {
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
    };

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: colors.map((color) {
          final isSelected = selectedColor == color;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColors[roomId] = color;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? colorMap[color]!.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected ? Border.all(color: colorMap[color]!, width: 2) : null,
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorMap[color],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWinProbability(BattleRoom room, TextEditingController controller) {
    final stakeAmount = int.tryParse(controller.text) ?? room.minStake;
    final probability = _gameService.calculateWinProbability(stakeAmount, room);
    final probabilityPercent = (probability * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'Win Probability: $probabilityPercent%',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const Spacer(),
          Icon(
            probabilityPercent >= 70 ? Icons.sentiment_very_satisfied :
            probabilityPercent >= 50 ? Icons.sentiment_satisfied :
            Icons.sentiment_neutral,
            color: Colors.green,
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _joinTimedBattle(BattleRoom room) async {
    final stakeController = _stakeControllers[room.id]!;
    final stakeAmount = int.tryParse(stakeController.text) ?? room.minStake;
    final selectedColor = _selectedColors[room.id]!;
    
    // Get real CNE balance
    final balanceService = Provider.of<UserBalanceService>(context, listen: false);
    final availableBalance = balanceService.balance.unlockedBalance;

    // Validation
    if (stakeAmount < room.minStake || stakeAmount > room.maxStake) {
      _showError('Stake must be between ${room.minStake} and ${room.maxStake} CNE coins');
      return;
    }

    if (stakeAmount > availableBalance) {
      _showError('Insufficient CNE coins. Available: ${availableBalance.toStringAsFixed(1)} CNE');
      return;
    }

    if (!_timerService.isRoundActive(room.id)) {
      _showError('No active round available. Wait for the next round to start.');
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Colors.black87,
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(width: 16),
              Text(
                'Joining round...',
                style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
              ),
            ],
          ),
        ),
      );
    }

    try {
      // Use the timer service to join the round
      final result = await _timerService.joinRound(room.id, stakeAmount, selectedColor);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${room.name}! Waiting for round to start...'),
              backgroundColor: const Color(0xFF006833),
              action: SnackBarAction(
                label: 'Watch Battle',
                textColor: Colors.white,
                onPressed: () {
                  widget.onNavigateToBattle?.call();
                },
              ),
            ),
          );
          
          // Note: CNE balance deduction should be handled by RewardService
          // For now, we skip the local PlayExtra balance update
          
        } else {
          _showError(result['error'] ?? 'Failed to join round');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
