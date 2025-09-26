import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/chat_ad_carousel.dart';
import '../theme/app_colors.dart';

class Spin2EarnGamePage extends StatefulWidget {
  const Spin2EarnGamePage({Key? key}) : super(key: key);

  @override
  _Spin2EarnGamePageState createState() => _Spin2EarnGamePageState();
}

class _Spin2EarnGamePageState extends State<Spin2EarnGamePage> {
  int _userCNE = 0;
  int _dailySpinsUsed = 0;
  int _maxDailySpins = 3;
  
  // Fortune wheel controller
  StreamController<int> controller = StreamController<int>();
  int _lastSelectedIndex = 0;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Prize items
  final List<String> prizes = [
    '1 CNE',
    'Try Again',
    '5 CNE',
    'Try Again',
    '10 CNE',
    'Try Again',
    '25 CNE',
    'Bonus Spin',
    '50 CNE',
    'Try Again',
  ];
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadGameData();
  }
  
  @override
  void dispose() {
    controller.close();
    _confettiController.dispose();
    super.dispose();
  }
  
  Color _getPrizeColor(String prize) {
    if (prize.contains('50 CNE')) return Colors.amber;
    if (prize.contains('25 CNE')) return Colors.orange;
    if (prize.contains('10 CNE')) return Colors.green;
    if (prize.contains('5 CNE')) return Colors.blue;
    if (prize.contains('1 CNE')) return Colors.purple;
    if (prize.contains('Bonus Spin')) return Colors.pink;
    return Colors.grey; // Try Again
  }
  
  void _spinWheel() {
    final remainingSpins = _maxDailySpins - _dailySpinsUsed;
    if (remainingSpins <= 0) {
      _showMessage('No spins remaining today! Come back tomorrow.');
      return;
    }
    
    // Weighted random selection
    final selectedIndex = _getWeightedRandomIndex();
    _lastSelectedIndex = selectedIndex;
    
    setState(() {
      _dailySpinsUsed++;
    });
    
    // Save the updated spin count
    _saveGameData();
    
    // Trigger the wheel animation
    controller.add(selectedIndex);
  }
  
  int _getWeightedRandomIndex() {
    // Prize probabilities (higher weight = more likely)
    final weights = [
      10, // 1 CNE (10% chance)
      30, // Try Again (30% chance)
      15, // 5 CNE (15% chance)
      25, // Try Again (25% chance)
      8,  // 10 CNE (8% chance)
      20, // Try Again (20% chance)
      5,  // 25 CNE (5% chance)
      3,  // Bonus Spin (3% chance)
      2,  // 50 CNE (2% chance)
      15, // Try Again (15% chance)
    ];
    
    final totalWeight = weights.fold(0, (sum, weight) => sum + weight);
    final random = (DateTime.now().millisecondsSinceEpoch % totalWeight);
    
    int cumulativeWeight = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulativeWeight += weights[i];
      if (random < cumulativeWeight) {
        return i;
      }
    }
    
    return 1; // Fallback to "Try Again"
  }
  
  void _handleSpinResult() {
    // Use the stored selected index
    final prize = prizes[_lastSelectedIndex];
    _processPrizeResult(prize);
  }
  
  void _processPrizeResult(String prize) {
    if (prize.contains('CNE')) {
      // Extract CNE amount
      final amount = int.tryParse(prize.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      setState(() {
        _userCNE += amount;
      });
      _saveGameData();
      _showResultDialog(prize, 'Congratulations! You won $amount CNE!', true);
    } else if (prize == 'Bonus Spin') {
      setState(() {
        _dailySpinsUsed = (_dailySpinsUsed - 1).clamp(0, _maxDailySpins);
      });
      _saveGameData();
      _showResultDialog(prize, 'Lucky! You got a bonus spin!', true);
    } else {
      // Try Again
      _showResultDialog(prize, 'Better luck next time! Try your next spin.', false);
    }
  }
  
  void _showResultDialog(String prize, String message, bool isWin) {
    // Trigger confetti for wins
    if (isWin) {
      _confettiController.play();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          // Confetti overlay
          if (isWin)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14159 / 2, // Down
                emissionFrequency: 0.3,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 80,
                gravity: 0.3,
                colors: const [
                  Colors.amber,
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.pink,
                ],
              ),
            ),
          
          // Dialog
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isWin ? '🎉 Winner!' : '💫 Try Again',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isWin ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prize,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isWin ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                if (isWin) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          'Balance: $_userCNE CNE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Color(0xFF006833)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // Persistence methods
  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _userCNE = prefs.getInt('cne_balance') ?? 0;
      _dailySpinsUsed = prefs.getInt('daily_spins_used') ?? 0;
    });
    
    // Check if it's a new day
    final lastSpinDate = prefs.getString('last_spin_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    if (lastSpinDate != today) {
      // Reset daily spins for new day
      setState(() {
        _dailySpinsUsed = 0;
      });
      await _saveGameData();
    }
  }
  
  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    await prefs.setInt('cne_balance', _userCNE);
    await prefs.setInt('daily_spins_used', _dailySpinsUsed);
    await prefs.setString('last_spin_date', today);
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingSpins = _maxDailySpins - _dailySpinsUsed;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Spin2Earn'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$_userCNE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat-style Ad Carousel (exact replica)
          const ChatAdCarousel(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Spins remaining counter
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Daily Spins Remaining',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$remainingSpins / $_maxDailySpins',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: remainingSpins > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Fortune Wheel
                  Container(
                    width: 300,
                    height: 300,
                    child: FortuneWheel(
                      selected: controller.stream,
                      items: [
                        for (int i = 0; i < prizes.length; i++) 
                          FortuneItem(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                prizes[i],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: _getPrizeColor(prizes[i]),
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                          ),
                      ],
                      onAnimationEnd: () {
                        // Handle spin result
                        _handleSpinResult();
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Spin button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: remainingSpins > 0 ? _spinWheel : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: remainingSpins > 0 
                            ? const Color(0xFF006833) 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        remainingSpins > 0 ? 'SPIN NOW!' : 'No Spins Left',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}