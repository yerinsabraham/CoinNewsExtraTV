import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayExtraScreen extends StatefulWidget {
  const PlayExtraScreen({Key? key}) : super(key: key);

  @override
  State<PlayExtraScreen> createState() => _PlayExtraScreenState();
}

class _PlayExtraScreenState extends State<PlayExtraScreen> with TickerProviderStateMixin {
  int coins = 1000; // Starting coins for testing
  bool isTapping = false;
  String selectedCharacter = 'blue'; // blue or red bull
  int selectedRoom = 0; // 0: 10-100, 1: 100-500, 2: 500-1000, 3: 1000-5000
  bool isInBattle = false;
  bool isSpinning = false;
  bool showFloatingCoins = false;
  bool showBattleResult = false;
  late AnimationController _wheelAnimationController;
  late Animation<double> _wheelAnimation;

  @override
  void initState() {
    super.initState();
    _loadCoins();
    _loadSelectedCharacter();
    _wheelAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _wheelAnimation = Tween<double>(
      begin: 0,
      end: 6.28318530718 * 4, // 4 full rotations (2π * 4)
    ).animate(CurvedAnimation(
      parent: _wheelAnimationController,
      curve: Curves.decelerate,
    ));
  }

  @override
  void dispose() {
    _wheelAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('play_extra_coins') ?? 1000;
    });
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('play_extra_coins', coins);
  }

  Future<void> _loadSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCharacter = prefs.getString('selected_character') ?? 'blue';
    });
  }

  Future<void> _saveSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_character', selectedCharacter);
  }
  
  final List<Map<String, dynamic>> battleRooms = [
    {'name': 'Rookie Room', 'range': '10-100', 'min': 10, 'max': 100, 'color': Colors.green, 'icon': Icons.sports_martial_arts},
    {'name': 'Pro Room', 'range': '100-500', 'min': 100, 'max': 500, 'color': Colors.blue, 'icon': Icons.military_tech},
    {'name': 'Elite Room', 'range': '500-1000', 'min': 500, 'max': 1000, 'color': Colors.purple, 'icon': Icons.star},
    {'name': 'Champion Room', 'range': '1000-5000', 'min': 1000, 'max': 5000, 'color': Colors.orange, 'icon': Icons.emoji_events},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Play Extra - Battle Arena',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
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
                  '$coins',
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Character Selection Section
              _buildCharacterSelection(),
              const SizedBox(height: 24),
              
              // Battle Rooms Section
              _buildBattleRooms(),
              const SizedBox(height: 24),
              
              // Tap to Earn Section (for earning coins)
              _buildTapToEarn(),
              const SizedBox(height: 24),
              
              // Battle Wheel Section
              if (isInBattle) _buildBattleWheel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterSelection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF006833), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Choose Your Bull',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCharacterOption('blue', 'Blue Bull', Icons.sports_martial_arts, Colors.blue),
              _buildCharacterOption('red', 'Red Bull', Icons.sports_martial_arts, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterOption(String character, String name, IconData icon, Color color) {
    bool isSelected = selectedCharacter == character;
    return GestureDetector(
      onTap: () {
        setState(() => selectedCharacter = character);
        _saveSelectedCharacter();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006833).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF006833) : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(32),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/avatars/minotaur-$character-NESW.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      icon,
                      size: 48,
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
                color: isSelected ? const Color(0xFF006833) : Colors.white,
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

  Widget _buildBattleRooms() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.casino, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
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
          const SizedBox(height: 16),
          ...battleRooms.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> room = entry.value;
            return _buildBattleRoomCard(index, room);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBattleRoomCard(int index, Map<String, dynamic> room) {
    bool isSelected = selectedRoom == index;
    bool canAfford = coins >= room['min'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: canAfford ? () => setState(() => selectedRoom = index) : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? room['color'].withOpacity(0.2) : Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? room['color'] : (canAfford ? Colors.grey[600]! : Colors.red.withOpacity(0.5)),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: room['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  room['icon'],
                  color: room['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'],
                      style: TextStyle(
                        color: canAfford ? Colors.white : Colors.grey[500],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(
                      'Stakes: ${room['range']} CNE coins',
                      style: TextStyle(
                        color: canAfford ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                ElevatedButton(
                  onPressed: canAfford ? _joinBattle : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join Battle'),
                ),
              if (!canAfford)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Need more CNE coins',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapToEarn() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_martial_arts,
                size: 32,
                color: selectedCharacter == 'blue' ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tap to Earn CNE Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Tap Button with Bull Character
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
            onTapDown: (_) {
              setState(() => isTapping = true);
            },
            onTapUp: (_) {
              setState(() {
                isTapping = false;
                coins += 5; // Earn 5 coins per tap
                showFloatingCoins = true;
              });
              _saveCoins(); // Save coins to persistent storage
              // Hide floating animation after delay
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) {
                  setState(() {
                    showFloatingCoins = false;
                  });
                }
              });
            },
            onTapCancel: () {
              setState(() => isTapping = false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isTapping 
                  ? const Color(0xFF004D24) 
                  : const Color(0xFF006833),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006833).withOpacity(0.5),
                    blurRadius: isTapping ? 20 : 10,
                    spreadRadius: isTapping ? 5 : 2,
                  ),
                ],
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/avatars/minotaur-$selectedCharacter-NESW.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.sports_martial_arts,
                        size: 48,
                        color: selectedCharacter == 'blue' ? Colors.blue : Colors.red,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Floating +5 animation
          if (showFloatingCoins)
            Positioned(
              top: 20,
              child: AnimatedOpacity(
                opacity: showFloatingCoins ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  '+5',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
          
          const SizedBox(height: 16),
          Text(
            'Tap your ${selectedCharacter == 'blue' ? 'Blue' : 'Red'} Bull to earn CNE coins!',
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

  Widget _buildBattleWheel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Battle in Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),
          
          // Animated spinning wheel
          Container(
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
            child: AnimatedBuilder(
              animation: _wheelAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _wheelAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withOpacity(0.8),
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(color: Colors.orange, width: 4),
                    ),
                    child: Stack(
                      children: [
                        // Wheel segments
                        ...List.generate(8, (index) {
                          return Positioned.fill(
                            child: Transform.rotate(
                              angle: (index * 0.7853981634), // 45 degrees each
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: CustomPaint(
                                  painter: WheelSegmentPainter(
                                    color: index % 2 == 0 ? Colors.orange : Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        // Center icon
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            child: const Icon(
                              Icons.casino,
                              size: 30,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isSpinning ? null : _spinWheel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(isSpinning ? 'Spinning...' : 'Spin for Winner!'),
          ),
        ],
      ),
    );
  }

  void _joinBattle() async {
    try {
      final room = battleRooms[selectedRoom];
      setState(() {
        isInBattle = true;
        coins -= (room['min'] as int); // Deduct coins
      });
      _saveCoins(); // Save coins to persistent storage
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedCharacter == 'blue' ? 'Blue' : 'Red'} Bull joined ${room['name']}! Staked ${room['min'] as int} CNE coins.'),
          backgroundColor: const Color(0xFF006833),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join battle: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _spinWheel() async {
    setState(() {
      isSpinning = true;
    });
    
    // Start wheel animation
    _wheelAnimationController.reset();
    _wheelAnimationController.forward();
    
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));
    
    // Simple win/lose logic (60% chance to win)
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    final won = random < 6; // 60% win rate
    final room = battleRooms[selectedRoom];
    
    setState(() {
      isSpinning = false;
      isInBattle = false;
      showBattleResult = true;
      if (won) {
        coins += (room['min'] as int) * 2; // Win double the stake
      }
    });
    
    if (won) {
      _saveCoins(); // Save coins to persistent storage when won
    }
    
    // Show result dialog with delay for dramatic effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          won ? '🎉 Victory!' : '💔 Defeat',
          style: TextStyle(
            color: won ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 64,
              color: won ? Colors.yellow : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              won 
                ? 'Your ${selectedCharacter == 'blue' ? 'Blue' : 'Red'} Bull won ${(room['min'] as int) * 2} CNE coins!'
                : 'Better luck next time! Your bull fought bravely.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue', style: TextStyle(color: Color(0xFF006833))),
          ),
        ],
      ),
    );
  }
}

class WheelSegmentPainter extends CustomPainter {
  final Color color;

  WheelSegmentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw a pie slice (45 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.39269908169, // -22.5 degrees
      0.7853981634,   // 45 degrees
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
