import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/play_extra_service.dart';
import '../models/game_models.dart';

class RoomScreen extends StatefulWidget {
  final VoidCallback? onNavigateToBattle;
  
  const RoomScreen({Key? key, this.onNavigateToBattle}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final PlayExtraService _gameService = PlayExtraService();
  final Map<String, TextEditingController> _stakeControllers = {};
  final Map<String, String> _selectedColors = {};

  @override
  void initState() {
    super.initState();
    _gameService.addListener(_onGameStateChanged);
    
    // Initialize controllers for each room
    for (final room in _gameService.battleRooms) {
      _stakeControllers[room.id] = TextEditingController(text: room.minStake.toString());
      _selectedColors[room.id] = 'blue';
    }
  }

  @override
  void dispose() {
    _gameService.removeListener(_onGameStateChanged);
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${gameState.coins}',
                  style: const TextStyle(
                    color: Colors.white,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Info Card
            _buildInfoCard(),
            const SizedBox(height: 20),
            
            // Battle Rooms
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
    final canAfford = gameState.coins >= room.minStake;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? room.color : Colors.red.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header
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
            ],
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
                onPressed: () => _joinBattle(room),
                style: ElevatedButton.styleFrom(
                  backgroundColor: room.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.casino, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Join Battle',
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

  Future<void> _joinBattle(BattleRoom room) async {
    final stakeController = _stakeControllers[room.id]!;
    final stakeAmount = int.tryParse(stakeController.text) ?? room.minStake;
    final selectedColor = _selectedColors[room.id]!;

    if (stakeAmount < room.minStake || stakeAmount > room.maxStake) {
      _showError('Stake must be between ${room.minStake} and ${room.maxStake} CNE coins');
      return;
    }

    if (stakeAmount > _gameService.gameState.coins) {
      _showError('Insufficient CNE coins');
      return;
    }

    try {
      await _gameService.joinBattle(room.id, stakeAmount, selectedColor);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${room.name}! Ready to battle.'),
            backgroundColor: const Color(0xFF006833),
            action: SnackBarAction(
              label: 'Battle Now',
              textColor: Colors.white,
              onPressed: () {
                widget.onNavigateToBattle?.call();
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
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
