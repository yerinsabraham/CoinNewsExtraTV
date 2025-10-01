import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/user_balance_service.dart';
import '../services/reward_service.dart';

class UltimateSpinGamePage extends StatefulWidget {
  const UltimateSpinGamePage({Key? key}) : super(key: key);

  @override
  _UltimateSpinGamePageState createState() => _UltimateSpinGamePageState();
}

class _UltimateSpinGamePageState extends State<UltimateSpinGamePage>
    with TickerProviderStateMixin {
  
  // Core game state
  int _dailySpinsUsed = 0;
  int _maxDailySpins = 3;
  bool _isSpinning = false;
  bool _isProcessing = false;
  int _selectedIndex = 0;
  
  // Controllers - Using persistent stream as suggested
  final StreamController<int> _wheelController = StreamController<int>.broadcast();
  late ConfettiController _confettiController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScale;
  
  // Game data
  final List<SpinPrize> _prizes = [
    SpinPrize(label: '1,000\nCNE', value: 1000, color: Color(0xFFFFD700), weight: 1),
    SpinPrize(label: '500\nCNE', value: 500, color: Color(0xFFFF6B35), weight: 3),
    SpinPrize(label: '200\nCNE', value: 200, color: Color(0xFF9B59B6), weight: 8),
    SpinPrize(label: '100\nCNE', value: 100, color: Color(0xFF3498DB), weight: 15),
    SpinPrize(label: '75\nCNE', value: 75, color: Color(0xFF2ECC71), weight: 20),
    SpinPrize(label: '50\nCNE', value: 50, color: Color(0xFFE67E22), weight: 25),
    SpinPrize(label: '25\nCNE', value: 25, color: Color(0xFF1ABC9C), weight: 20),
    SpinPrize(label: '10\nCNE', value: 10, color: Color(0xFF95A5A6), weight: 15),
    SpinPrize(label: 'Bonus\nSpin', value: -1, color: Color(0xFFE91E63), weight: 8),
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadGameData();
  }
  
  void _initializeControllers() {
    // _wheelController is now initialized as final field
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _wheelController.close();
    _confettiController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        if (mounted) {
          setState(() {
            _dailySpinsUsed = 0;
          });
        }
        return;
      }
      
      final userId = user.uid;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastSpinDate = prefs.getString('last_spin_date_$userId') ?? '';
      
      int spinsUsed = prefs.getInt('daily_spins_used_$userId') ?? 0;
      
      // Reset spins for new day
      if (lastSpinDate != today) {
        spinsUsed = 0;
        await prefs.setString('last_spin_date_$userId', today);
        await prefs.setInt('daily_spins_used_$userId', 0);
      }
      
      if (mounted) {
        setState(() {
          _dailySpinsUsed = spinsUsed;
        });
      }
    } catch (e) {
      print('🔥 Error loading game data: $e');
    }
  }

  Future<void> _saveGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) return;
      
      final userId = user.uid;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      await prefs.setInt('daily_spins_used_$userId', _dailySpinsUsed);
      await prefs.setString('last_spin_date_$userId', today);
    } catch (e) {
      print('🔥 Error saving game data: $e');
    }
  }
  
  Future<void> _spinWheel() async {
    // Validate spin availability
    if (_maxDailySpins - _dailySpinsUsed <= 0) {
      _showNoSpinsDialog();
      return;
    }
    
    if (_isSpinning || _isProcessing) return;
    
    // Add haptic feedback
    await HapticFeedback.mediumImpact();
    
    // Animate button
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
    
    // Set spinning state
    setState(() {
      _isSpinning = true;
      _dailySpinsUsed++;
    });
    
    // Save immediately
    await _saveGameData();
    
    // Calculate winning index with weighted probability
    final selectedIndex = _getWeightedRandomIndex();
    
    // Use postFrame callback to ensure widget rebuild completes before emitting stream event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_wheelController.isClosed) {
        setState(() {
          _selectedIndex = selectedIndex;
        });
        _wheelController.add(selectedIndex);
      }
    });
  }
  
  int _getWeightedRandomIndex() {
    final weights = _prizes.map((p) => p.weight).toList();
    final totalWeight = weights.fold(0, (sum, weight) => sum + weight);
    final random = Random().nextInt(totalWeight);
    
    int cumulativeWeight = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulativeWeight += weights[i];
      if (random < cumulativeWeight) {
        return i;
      }
    }
    return 4; // Fallback to middle prize
  }
  
  Future<void> _handleSpinResult() async {
    if (!mounted) return;
    
    setState(() {
      // _isSpinning already set to false in onAnimationEnd
      _isProcessing = true;
    });
    
    // Add delay for dramatic effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final prize = _prizes[_selectedIndex];
    
    try {
      // Handle bonus spin
      if (prize.value == -1) {
        if (mounted) {
          setState(() {
            _dailySpinsUsed = max(0, _dailySpinsUsed - 1);
            _isProcessing = false;
          });
        }
        await _saveGameData();
        await _showResultDialog(prize, true);
        return;
      }
      
      // Process CNE reward
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      
      // Try to claim reward through Firebase Functions (but don't block UI if it fails)
      bool rewardClaimed = false;
      try {
        final result = await RewardService.claimSpinReward(prize.value.toDouble()).timeout(
          const Duration(seconds: 5),
        );
        
        if (result.success) {
          print('🎰 SUCCESS: Spin reward claimed via Firebase: ${prize.value} CNE');
          await balanceService.processRewardClaim({
            'success': true,
            'reward': prize.value.toDouble(),
            'message': 'Spin reward claimed successfully',
          });
          
          // Add to recent transactions for immediate UI feedback
          balanceService.addRecentTransaction({
            'type': 'spin2earn',
            'amount': prize.value.toDouble(),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          
          // Force balance refresh to update all pages
          await balanceService.refreshAll();
          rewardClaimed = true;
        }
      } catch (e) {
        print('🔥 Reward processing failed: $e');
        // If Firebase fails, still add reward locally to prevent user frustration
        print('🎰 FALLBACK: Adding ${prize.value} CNE reward locally due to Firebase error');
        await balanceService.processRewardClaim({
          'success': true,
          'reward': prize.value.toDouble(),
          'message': 'Spin reward added locally (Firebase connection issues)',
        });
        
        // Add to recent transactions for immediate UI feedback
        balanceService.addRecentTransaction({
          'type': 'spin2earn',
          'amount': prize.value.toDouble(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        // Force balance refresh
        await balanceService.refreshAll();
        rewardClaimed = true;
      }
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      
      await _showResultDialog(prize, true, rewardProcessed: rewardClaimed);
      
    } catch (e) {
      print('🔥 Error in spin result: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        await _showResultDialog(prize, false);
      }
    }
  }
  
  Future<void> _showResultDialog(SpinPrize prize, bool isWin, {bool rewardProcessed = false}) async {
    if (!mounted) return;
    
    if (isWin) {
      _confettiController.play();
      await HapticFeedback.heavyImpact();
    }
    
    String message;
    if (prize.value == -1) {
      message = '🎉 Amazing! You got a bonus spin!\n\nYour spins remaining has been increased by 1!';
    } else {
      message = rewardProcessed 
          ? '🎉 Congratulations! You won ${prize.value} CNE!\n\n💰 Reward has been added to your balance!'
          : '🎉 Congratulations! You won ${prize.value} CNE!\n\n⏳ Processing reward... (may take a moment)';
    }
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button during dialog
        child: Stack(
          children: [
            if (isWin)
              Positioned.fill(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  maxBlastForce: 100,
                  minBlastForce: 80,
                  gravity: 0.3,
                  colors: [
                    Colors.amber,
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.pink,
                    Colors.purple
                  ],
                ),
              ),
            
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: min(MediaQuery.of(context).size.width * 0.9, 350),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isWin 
                        ? [Color(0xFF1A1A1A), Color(0xFF2D1B69)]
                        : [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isWin ? Colors.amber : Colors.grey,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isWin ? Colors.amber : Colors.grey).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated prize icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Transform.rotate(
                                angle: value * 2 * pi,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: prize.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: prize.color.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    prize.value == -1 ? Icons.refresh : Icons.emoji_events,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Title
                        Text(
                          isWin ? '🎉 WINNER! 🎉' : '💫 Try Again Tomorrow',
                          style: TextStyle(
                            fontSize: 28,
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
                            color: prize.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: prize.color, width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                prize.label.replaceAll('\n', ' '),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: prize.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (prize.value > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CNE Tokens',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 16,
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
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Continue button with animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: value > 0.8 ? () {
                                    _confettiController.stop();
                                    Navigator.of(context).pop();
                                  } : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: prize.color,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(27),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'Continue',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoSpinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'No Spins Left',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'You\'ve used all your daily spins!\n\nCome back tomorrow for 3 fresh spins.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.orange, fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingSpins = _maxDailySpins - _dailySpinsUsed;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Spin2Earn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGameData,
          ),
        ],
      ),
      body: user == null ? _buildAuthRequired() : _buildGameContent(remainingSpins, isDark),
    );
  }

  Widget _buildAuthRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Please sign in to play Spin2Earn',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(int remainingSpins, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Enhanced spins counter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [Color(0xFF2D1B69), Color(0xFF1A1A1A)]
                  : [Color(0xFF4A90E2), Color(0xFF50C878)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.casino, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Daily Spins Remaining',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: remainingSpins.toDouble()),
                  builder: (context, value, child) {
                    return Text(
                      '${value.toInt()} / $_maxDailySpins',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: remainingSpins > 0 ? Colors.white : Colors.red.shade300,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: remainingSpins / _maxDailySpins),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remainingSpins > 0 ? Colors.amber : Colors.red,
                      ),
                      minHeight: 6,
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Enhanced Fortune Wheel
          Expanded(
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: FortuneWheel(
                  selected: _wheelController.stream, // Always listen to the same persistent stream
                  animateFirst: false,
                  duration: const Duration(seconds: 4), // Fixed duration for consistency
                  curve: Curves.decelerate,
                  items: [
                    for (int i = 0; i < _prizes.length; i++) 
                      FortuneItem(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _prizes[i].label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        style: FortuneItemStyle(
                          color: _prizes[i].color,
                          borderColor: Colors.white,
                          borderWidth: 4,
                        ),
                      ),
                  ],
                  onAnimationEnd: () async {
                    if (_isSpinning && mounted) {
                      // Reset spinning state first, then handle result
                      setState(() {
                        _isSpinning = false;
                      });
                      await _handleSpinResult();
                    }
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Enhanced spin button
          AnimatedBuilder(
            animation: _buttonScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _buttonScale.value,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: (remainingSpins > 0 && !_isSpinning && !_isProcessing) 
                        ? _spinWheel 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (remainingSpins > 0 && !_isSpinning && !_isProcessing)
                          ? const Color(0xFF006833) 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 10,
                    ),
                    child: _isProcessing 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'PROCESSING...',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            _isSpinning 
                                ? 'SPINNING...' 
                                : remainingSpins > 0 
                                    ? '🎰 SPIN TO WIN CNE! 🎰' 
                                    : '⏰ Come Back Tomorrow',
                            style: TextStyle(
                              fontSize: _isSpinning ? 18 : 20, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SpinPrize {
  final String label;
  final int value;
  final Color color;
  final int weight;
  
  const SpinPrize({
    required this.label,
    required this.value,
    required this.color,
    required this.weight,
  });
}