import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/reward_service.dart';
// import '../services/user_balance_service.dart';

class SimpleSpinGamePage extends StatefulWidget {
  const SimpleSpinGamePage({Key? key}) : super(key: key);

  @override
  _SimpleSpinGamePageState createState() => _SimpleSpinGamePageState();
}

class _SimpleSpinGamePageState extends State<SimpleSpinGamePage> {
  int _dailySpinsUsed = 0;
  int _maxDailySpins = 3;
  
  StreamController<int> controller = StreamController<int>.broadcast();
  int _selectedIndex = 0;
  bool _isSpinning = false;
  
  late ConfettiController _confettiController;
  
  final List<String> prizes = [
    '1,000 CNE',
    '500 CNE',
    '200 CNE',
    '100 CNE',
    '50 CNE',
    '25 CNE',
    '10 CNE',
    'NFT',
    'NFT',
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
    if (prize.contains('1,000')) return const Color(0xFFFFD700);
    if (prize.contains('500')) return const Color(0xFFFF6B35);
    if (prize.contains('200')) return const Color(0xFF9B59B6);
    if (prize.contains('100')) return const Color(0xFF3498DB);
    if (prize.contains('50')) return const Color(0xFF2ECC71);
    if (prize.contains('25')) return const Color(0xFFE67E22);
    if (prize.contains('10')) return const Color(0xFF1ABC9C);
    return const Color(0xFFE91E63);
  }
  
  void _spinWheel() async {
    if (_maxDailySpins - _dailySpinsUsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No spins remaining today!')),
      );
      return;
    }
    
    if (_isSpinning) return;
    
    final selectedIndex = _getWeightedRandomIndex();
    
    setState(() {
      _selectedIndex = selectedIndex;
      _isSpinning = true;
      _dailySpinsUsed++;
    });
    
    await _saveGameData();
    controller.add(selectedIndex);
  }
  
  int _getWeightedRandomIndex() {
    final weights = [1, 4, 10, 20, 30, 15, 10, 5, 5];
    final totalWeight = weights.fold(0, (sum, weight) => sum + weight);
    final random = Random().nextInt(totalWeight);
    
    int cumulativeWeight = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulativeWeight += weights[i];
      if (random < cumulativeWeight) {
        return i;
      }
    }
    return 4;
  }
  
  Future<void> _handleSpinResult() async {
    setState(() {
      _isSpinning = false;
    });
    
    final prize = prizes[_selectedIndex];
    await _processPrizeResult(prize);
  }
  
  Future<void> _processPrizeResult(String prize) async {
    String message;
    bool isWin = false;
    
    if (prize.contains('CNE')) {
      final amountStr = prize.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '');
      final amount = int.tryParse(amountStr) ?? 0;
      
      try {
        final result = await RewardService.claimGameReward(
          gameType: 'spin_wheel',
          gameId: 'spin_${DateTime.now().millisecondsSinceEpoch}',
          rewardAmount: amount.toDouble(),
          metadata: {
            'prize': prize,
            'spinIndex': _selectedIndex,
          },
        );
        
        if (result.success) {
          isWin = true;
          message = 'Congratulations! You won $amount CNE!';
          // Balance refresh temporarily disabled
        } else {
          message = 'Error: ${result.message}';
        }
      } catch (e) {
        message = 'Error processing reward: $e';
      }
    } else {
      isWin = true;
      message = 'Amazing! You won an NFT!';
    }
    
    _showResultDialog(prize, message, isWin);
  }
  
  void _showResultDialog(String prize, String message, bool isWin) {
    if (isWin) {
      _confettiController.play();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          if (isWin)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14159 / 2,
                emissionFrequency: 0.3,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 80,
                gravity: 0.3,
                colors: const [Colors.amber, Colors.green, Colors.blue, Colors.orange, Colors.pink],
              ),
            ),
          
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
                    color: isWin ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.of(context).pop();
                },
                child: const Text('Continue', style: TextStyle(color: Color(0xFF006833))),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      setState(() {
        _dailySpinsUsed = 0;
      });
      return;
    }
    
    final userId = user.uid;
    setState(() {
      _dailySpinsUsed = prefs.getInt('daily_spins_used_$userId') ?? 0;
    });
    
    final lastSpinDate = prefs.getString('last_spin_date_$userId') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastSpinDate != today) {
      setState(() {
        _dailySpinsUsed = 0;
      });
      await _saveGameData();
    }
  }

  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) return;
    
    final userId = user.uid;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    await prefs.setInt('daily_spins_used_$userId', _dailySpinsUsed);
    await prefs.setString('last_spin_date_$userId', today);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingSpins = _maxDailySpins - _dailySpinsUsed;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Spin2Earn CNE'),
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
                const Text(
                  '0.0',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Spins counter
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
            SizedBox(
              width: 300,
              height: 300,
              child: FortuneWheel(
                selected: _isSpinning ? controller.stream : const Stream<int>.empty(),
                animateFirst: false,
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
                  if (_isSpinning) {
                    _handleSpinResult();
                  }
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Spin button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (remainingSpins > 0 && !_isSpinning) ? _spinWheel : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (remainingSpins > 0 && !_isSpinning)
                      ? const Color(0xFF006833) 
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  _isSpinning 
                      ? 'SPINNING...' 
                      : remainingSpins > 0 
                          ? 'SPIN NOW!' 
                          : 'No Spins Left',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}