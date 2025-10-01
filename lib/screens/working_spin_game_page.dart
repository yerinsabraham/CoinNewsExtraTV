import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class WorkingSpinGamePage extends StatefulWidget {
  const WorkingSpinGamePage({Key? key}) : super(key: key);

  @override
  _WorkingSpinGamePageState createState() => _WorkingSpinGamePageState();
}

class _WorkingSpinGamePageState extends State<WorkingSpinGamePage> {
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
    'Bonus Spin',
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
    if (prize.contains('NFT')) return const Color(0xFFE91E63);
    return const Color(0xFF8E44AD);
  }
  
  void _spinWheel() async {
    if (_maxDailySpins - _dailySpinsUsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚫 No spins remaining today! Come back tomorrow.'),
          backgroundColor: Colors.red,
        ),
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
    
    // Handle bonus spin
    if (prize == 'Bonus Spin') {
      setState(() {
        _dailySpinsUsed = max(0, _dailySpinsUsed - 1); // Give back a spin
      });
      await _saveGameData();
      _showResultDialog(prize, '🎉 Bonus Spin! You got an extra spin for today!', true);
      return;
    }
    
    // Process other prizes
    String message;
    bool isWin = true;
    
    if (prize.contains('CNE')) {
      final amountStr = prize.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '');
      final amount = int.tryParse(amountStr) ?? 0;
      message = '🎉 Congratulations! You won $amount CNE!\n\n(Note: Reward processing temporarily simplified for testing)';
    } else {
      message = '🎨 Amazing! You won an NFT!\n\nYour NFT will be sent to your wallet soon.';
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
                numberOfParticles: 30,
                maxBlastForce: 100,
                minBlastForce: 80,
                gravity: 0.3,
                colors: const [Colors.amber, Colors.green, Colors.blue, Colors.orange, Colors.pink],
              ),
            ),
          
          AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isWin 
                    ? [Color(0xFF1A1A1A), Color(0xFF2D1B69)]
                    : [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isWin ? Colors.amber : Colors.grey,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isWin ? Colors.amber : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isWin ? Colors.amber.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        isWin ? Icons.emoji_events : Icons.refresh,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      isWin ? '🎉 WINNER! 🎉' : '💫 Try Again',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isWin ? Colors.amber : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Prize display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: _getPrizeColor(prize).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _getPrizeColor(prize), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            prize.replaceAll('\\n', ' '),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getPrizeColor(prize),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (prize.contains('CNE')) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'CNE Tokens',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _confettiController.stop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWin ? Colors.amber : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Continue',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        title: const Text(
          'Spin2Earn CNE (Working Version)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Spins counter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [Color(0xFF2D1B69), Color(0xFF1A1A1A)]
                    : [Color(0xFF4A90E2), Color(0xFF50C878)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.casino, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Spins Remaining',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$remainingSpins / $_maxDailySpins',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: remainingSpins > 0 ? Colors.white : Colors.red.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: remainingSpins / _maxDailySpins,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      remainingSpins > 0 ? Colors.amber : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Fortune Wheel
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: _getPrizeColor(prizes[i]),
                              borderColor: Colors.white,
                              borderWidth: 3,
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
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Spin button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (remainingSpins > 0 && !_isSpinning) ? _spinWheel : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (remainingSpins > 0 && !_isSpinning)
                      ? const Color(0xFF006833) 
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  _isSpinning 
                      ? 'SPINNING...' 
                      : remainingSpins > 0 
                          ? 'SPIN TO WIN CNE!' 
                          : 'Come Back Tomorrow',
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info text
            Text(
              'This is a simplified working version for testing spinning mechanics.\nFirebase reward processing temporarily bypassed.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}