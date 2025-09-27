import 'package:flutter/material.dart';
import '../services/play_extra_service.dart';
import '../models/game_models.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final PlayExtraService _gameService = PlayExtraService();

  @override
  void initState() {
    super.initState();
    _gameService.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _gameService.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _clearActivities() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear Activities',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'This will clear all transaction history. Are you sure?',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await _gameService.clearTransactionHistory();
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
        title: Row(
          children: [
            Icon(
              Icons.analytics,
              color: const Color(0xFF006833),
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Game Stats',
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
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.red,
              size: 24,
            ),
            tooltip: 'Quit Game',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(gameState),
            const SizedBox(height: 20),
            
            // Coin Balance Card
            _buildCoinBalanceCard(gameState),
            const SizedBox(height: 20),
            
            // Character Selection
            _buildCharacterSelection(gameState),
            const SizedBox(height: 20),
            
            // Transaction History
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(GameState gameState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF006833), width: 2),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: gameState.selectedCharacter == 'blue' 
                  ? Colors.blue.withOpacity(0.2) 
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: gameState.selectedCharacter == 'blue' ? Colors.blue : Colors.red,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(37),
              child: Image.asset(
                'assets/avatars/minotaur-${gameState.selectedCharacter}-NESW.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_martial_arts,
                    size: 40,
                    color: gameState.selectedCharacter == 'blue' ? Colors.blue : Colors.red,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            '${gameState.selectedCharacter == 'blue' ? 'Blue' : 'Red'} Bull Warrior',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Level ${(gameState.transactionHistory.length / 10 + 1).floor()}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBalanceCard(GameState gameState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF006833),
            const Color(0xFF004D24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006833).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                'CNE Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            '${gameState.coins}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSelection(GameState gameState) {
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
          const Text(
            'Select Your Bull',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildCharacterOption('blue', 'Blue Bull', Colors.blue, gameState),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCharacterOption('red', 'Red Bull', Colors.red, gameState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterOption(String character, String name, Color color, GameState gameState) {
    bool isSelected = gameState.selectedCharacter == character;
    
    return GestureDetector(
      onTap: () => _gameService.selectCharacter(character),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[600]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/avatars/minotaur-$character-NESW.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.sports_martial_arts,
                      size: 40,
                      color: color,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              name,
              style: TextStyle(
                color: isSelected ? color : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final history = _gameService.getFormattedHistory();
    
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
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              if (history.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearActivities,
                  icon: const Icon(Icons.clear_all, color: Colors.red, size: 16),
                  label: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (history.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            )
          else
            ...history.map((transaction) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    transaction.contains('+') ? Icons.add_circle : Icons.remove_circle,
                    color: transaction.contains('+') ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }
}
