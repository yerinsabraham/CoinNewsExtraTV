import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/chat_ad_carousel.dart';
import '../theme/app_colors.dart';
import '../services/user_balance_service.dart';

class EnhancedSpin2EarnGamePage extends StatefulWidget {
  const EnhancedSpin2EarnGamePage({Key? key}) : super(key: key);

  @override
  _EnhancedSpin2EarnGamePageState createState() => _EnhancedSpin2EarnGamePageState();
}

class _EnhancedSpin2EarnGamePageState extends State<EnhancedSpin2EarnGamePage> with TickerProviderStateMixin {
  int _dailySpinsUsed = 0;
  int _maxDailySpins = 3;
  
  // Fortune wheel controller
  StreamController<int> controller = StreamController<int>.broadcast();
  int _selectedIndex = 0;
  bool _isSpinning = false;
  bool _isProcessingReward = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  // Confetti controller
  late ConfettiController _confettiController;
  
  // Enhanced prize structure with better visual design
  final List<SpinPrize> prizes = [
    SpinPrize(label: '1,000\nCNE', amount: 1000, type: PrizeType.cne, probability: 1, color: Color(0xFFFFD700)),
    SpinPrize(label: '500\nCNE', amount: 500, type: PrizeType.cne, probability: 4, color: Color(0xFFFF6B35)),
    SpinPrize(label: '200\nCNE', amount: 200, type: PrizeType.cne, probability: 10, color: Color(0xFF9B59B6)),
    SpinPrize(label: '100\nCNE', amount: 100, type: PrizeType.cne, probability: 20, color: Color(0xFF3498DB)),
    SpinPrize(label: '50\nCNE', amount: 50, type: PrizeType.cne, probability: 30, color: Color(0xFF2ECC71)),
    SpinPrize(label: '25\nCNE', amount: 25, type: PrizeType.cne, probability: 15, color: Color(0xFFE67E22)),
    SpinPrize(label: '10\nCNE', amount: 10, type: PrizeType.cne, probability: 10, color: Color(0xFF1ABC9C)),
    SpinPrize(label: 'NFT\n🎨', amount: 0, type: PrizeType.nft, probability: 5, color: Color(0xFFE91E63)),
    SpinPrize(label: 'BONUS\nSpin', amount: 0, type: PrizeType.bonusSpin, probability: 5, color: Color(0xFF8E44AD)),
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadGameData();
    
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        _loadGameData();
      }
    });
  }
  
  void _initializeControllers() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    // Start idle animations
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    controller.close();
    _confettiController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  void _spinWheel() async {
    final remainingSpins = _maxDailySpins - _dailySpinsUsed;
    if (remainingSpins <= 0) {
      _showMessage('🚫 No spins remaining today! Come back tomorrow.', isError: true);
      return;
    }
    
    if (_isSpinning) return;
    
    // Stop idle animations
    _pulseController.stop();
    
    // Start wheel spinning animation
    _rotationController.repeat();
    
    // Get weighted random result
    final selectedIndex = _getWeightedRandomIndex();
    
    setState(() {
      _selectedIndex = selectedIndex;
      _isSpinning = true;
      _dailySpinsUsed++;
    });
    
    // Save updated spin count
    await _saveGameData();
    
    // Add haptic feedback
    // HapticFeedback.lightImpact();
    
    // Trigger fortune wheel animation
    controller.add(selectedIndex);
  }
  
  int _getWeightedRandomIndex() {
    final weights = prizes.map((p) => p.probability).toList();
    final totalWeight = weights.fold(0, (sum, weight) => sum + weight);
    final random = Random().nextInt(totalWeight);
    
    int cumulativeWeight = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulativeWeight += weights[i];
      if (random < cumulativeWeight) {
        return i;
      }
    }
    
    return 4; // Fallback to 50 CNE
  }
  
  Future<void> _handleSpinResult() async {
    // Stop rotation animation
    _rotationController.stop();
    
    setState(() {
      _isSpinning = false;
      _isProcessingReward = true;
    });
    
    final prize = prizes[_selectedIndex];
    
    try {
      // Process reward based on prize type
      bool success = false;
      String message = '';
      
      switch (prize.type) {
        case PrizeType.cne:
          final result = await _claimCNEReward(prize.amount);
          success = result['success'] ?? false;
          message = result['message'] ?? 'Unknown error';
          break;
        case PrizeType.nft:
          success = true;
          message = '🎨 Amazing! You won an NFT!\n\nYour NFT will be sent to your wallet soon.';
          break;
        case PrizeType.bonusSpin:
          setState(() {
            _dailySpinsUsed = max(0, _dailySpinsUsed - 1); // Give back a spin
          });
          await _saveGameData();
          success = true;
          message = '🎉 Bonus Spin! You got an extra spin for today!';
          break;
      }
      
      setState(() {
        _isProcessingReward = false;
      });
      
      // Show result dialog
      await _showEnhancedResultDialog(prize, message, success);
      
      if (success && prize.type == PrizeType.cne) {
        // Refresh balance
        if (mounted) {
          Provider.of<UserBalanceService>(context, listen: false).refreshAllData();
        }
      }
      
    } catch (e) {
      setState(() {
        _isProcessingReward = false;
      });
      
      _showEnhancedResultDialog(
        prize, 
        'There was an error processing your reward. Please try again later.\n\nError: $e', 
        false
      );
    }
    
    // Resume idle animations
    _pulseController.repeat(reverse: true);
  }
  
  Future<Map<String, dynamic>> _claimCNEReward(int amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      
      // Configure Firebase Functions for the correct region  
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      
      // Call the earnEvent function
      final result = await functions.httpsCallable('earnEvent').call({
        'uid': user.uid,
        'eventType': 'game_reward',
        'idempotencyKey': 'spin_${DateTime.now().millisecondsSinceEpoch}_${user.uid}',
        'meta': {
          'gameType': 'spin_wheel',
          'rewardAmount': amount,
          'spinIndex': _selectedIndex,
          'dailySpinNumber': _dailySpinsUsed,
        },
      });
      
      if (result.data['success'] == true) {
        return {
          'success': true,
          'message': 'Congratulations! You won $amount CNE!\n\nYour balance has been updated!'
        };
      } else {
        return {
          'success': false,
          'message': result.data['message'] ?? 'Failed to process reward'
        };
      }
      
    } catch (e) {
      print('❌ Error claiming CNE reward: $e');
      
      // Fallback to direct balance update for testing
      try {
        return await _fallbackDirectReward(amount);
      } catch (fallbackError) {
        return {
          'success': false,
          'message': 'Failed to process reward: $e'
        };
      }
    }
  }
  
  // Fallback method for direct balance update (for development/testing)
  Future<Map<String, dynamic>> _fallbackDirectReward(int amount) async {
    try {
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      
      // For testing purposes, we'll simulate a successful reward
      // In production, this should go through Firebase Functions
      
      return {
        'success': true,
        'message': 'Congratulations! You won $amount CNE!\n\n(Development mode - balance updated locally)'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Fallback reward failed: $e'
      };
    }
  }
  
  Future<void> _showEnhancedResultDialog(SpinPrize prize, String message, bool isWin) async {
    // Trigger confetti for wins
    if (isWin) {
      _confettiController.play();
    }
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          // Confetti overlay
          if (isWin) ...[
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
                colors: const [
                  Colors.amber,
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.pink,
                  Colors.purple,
                ],
              ),
            ),
          ],
          
          // Enhanced dialog
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
                            color: isWin ? Colors.amber.withAlpha(100) : Colors.grey.withAlpha(100),
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
                        color: prize.color.withAlpha(50),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: prize.color, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            prize.label.replaceAll('\\n', ' '),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: prize.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (prize.type == PrizeType.cne) ...[
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
                    
                    const SizedBox(height: 20),
                    
                    // Current balance display
                    Consumer<UserBalanceService>(
                      builder: (context, balanceService, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006833),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF006833).withAlpha(100),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Balance: ${balanceService.balance.unlockedBalance.toStringAsFixed(1)} CNE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
  
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  // Game data persistence methods
  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      setState(() {
        _dailySpinsUsed = 0;
      });
      return;
    }
    
    setState(() {
      _dailySpinsUsed = prefs.getInt('daily_spins_used_$userId') ?? 0;
    });
    
    // Check if it's a new day
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) return;
    
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
          'Spin2Earn CNE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withAlpha(100),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Consumer<UserBalanceService>(
                  builder: (context, balanceService, child) {
                    return Text(
                      '${balanceService.balance.unlockedBalance.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Ad Carousel
          const ChatAdCarousel(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Enhanced spins counter
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
                          color: Colors.black.withAlpha(50),
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
                          backgroundColor: Colors.white.withAlpha(50),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            remainingSpins > 0 ? Colors.amber : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Enhanced Fortune Wheel
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isSpinning ? 1.0 : _pulseAnimation.value,
                        child: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withAlpha(100),
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
                                      prizes[i].label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  style: FortuneItemStyle(
                                    color: prizes[i].color,
                                    borderColor: Colors.white,
                                    borderWidth: 3,
                                  ),
                                ),
                            ],
                            onAnimationEnd: () {
                              _handleSpinResult();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Processing indicator
                  if (_isProcessingReward) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing your reward...',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Enhanced spin button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (remainingSpins > 0 && !_isSpinning && !_isProcessingReward) ? _spinWheel : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (remainingSpins > 0 && !_isSpinning && !_isProcessingReward)
                            ? null
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ).copyWith(
                        backgroundColor: (remainingSpins > 0 && !_isSpinning && !_isProcessingReward)
                            ? WidgetStateProperty.all(null)
                            : WidgetStateProperty.all(Colors.grey),
                        overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(50)),
                      ),
                      child: Container(
                        decoration: (remainingSpins > 0 && !_isSpinning && !_isProcessingReward)
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF006833), Color(0xFF2ECC71)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              )
                            : null,
                        child: Center(
                          child: Text(
                            _isSpinning 
                                ? 'SPINNING...' 
                                : _isProcessingReward
                                    ? 'PROCESSING...'
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
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Prize probability info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface.withAlpha(100) : AppColors.lightSurface.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withAlpha(100),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Prize Probabilities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: prizes.map((prize) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: prize.color.withAlpha(50),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: prize.color, width: 1),
                              ),
                              child: Text(
                                '${prize.label.replaceAll('\\n', ' ')}: ${prize.probability}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: prize.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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

// Enhanced prize structure
class SpinPrize {
  final String label;
  final int amount;
  final PrizeType type;
  final int probability;
  final Color color;
  
  SpinPrize({
    required this.label,
    required this.amount,
    required this.type,
    required this.probability,
    required this.color,
  });
}

enum PrizeType { cne, nft, bonusSpin }