import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/user_balance_service.dart';
import '../widgets/ads_carousel.dart';

class SpinGamePage extends StatefulWidget {
  const SpinGamePage({super.key});

  @override
  State<SpinGamePage> createState() => _SpinGamePageState();
}

class _SpinGamePageState extends State<SpinGamePage> 
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  
  bool _isSpinning = false;
  int _dailySpinsUsed = 0;
  final int _maxDailySpins = 5;
  double _lastSpinRotation = 0;
  Map<String, dynamic>? _lastPrize;

  // Original prize structure from the old code with proper weightings
  final List<Map<String, dynamic>> _prizes = [
    {'label': '1,000 CNE', 'value': 1000.0, 'color': const Color(0xFFFFD700), 'type': 'cne', 'weight': 1},  // 1% chance
    {'label': '500 CNE', 'value': 500.0, 'color': const Color(0xFFFF6B35), 'type': 'cne', 'weight': 4},   // 4% chance
    {'label': '200 CNE', 'value': 200.0, 'color': const Color(0xFF9B59B6), 'type': 'cne', 'weight': 10},  // 10% chance
    {'label': '100 CNE', 'value': 100.0, 'color': const Color(0xFF3498DB), 'type': 'cne', 'weight': 20},  // 20% chance
    {'label': '50 CNE', 'value': 50.0, 'color': const Color(0xFF2ECC71), 'type': 'cne', 'weight': 30},    // 30% chance
    {'label': '10 CNE', 'value': 10.0, 'color': const Color(0xFFE67E22), 'type': 'cne', 'weight': 5},     // 5% chance
    {'label': 'NFT', 'value': 0.0, 'color': const Color(0xFFE91E63), 'type': 'nft', 'weight': 10},       // 10% chance
    {'label': 'NFT', 'value': 0.0, 'color': const Color(0xFFE91E63), 'type': 'nft', 'weight': 10},       // 10% chance
    {'label': 'NFT', 'value': 0.0, 'color': const Color(0xFFE91E63), 'type': 'nft', 'weight': 10},       // 10% chance
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _spinAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOut,
    ));
    
    _loadSpinData();
  }

  void _loadSpinData() {
    setState(() {
      _dailySpinsUsed = 0;
    });
  }

  int _getWeightedRandomIndex() {
    // Calculate total weight
    final totalWeight = _prizes.fold<int>(0, (sum, prize) => sum + (prize['weight'] as int));
    final random = Random().nextInt(totalWeight);
    
    int cumulativeWeight = 0;
    for (int i = 0; i < _prizes.length; i++) {
      cumulativeWeight += _prizes[i]['weight'] as int;
      if (random < cumulativeWeight) {
        return i;
      }
    }
    
    return 4; // Fallback to 50 CNE (most common prize)
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _spinWheel() async {
    if (_isSpinning || _dailySpinsUsed >= _maxDailySpins) return;

    setState(() {
      _isSpinning = true;
      _dailySpinsUsed++;
    });

    try {
      final random = Random();
      
      // First, determine which prize will be awarded using weighted selection
      final prizeIndex = _getWeightedRandomIndex();
      final selectedPrize = _prizes[prizeIndex];
      
      // Calculate the angle for this prize (center of the slice)
      final anglePerSection = (2 * pi) / _prizes.length;
      
      // Account for wheel starting at top (-π/2) and prize position
      final prizeAngle = (prizeIndex * anglePerSection) + (anglePerSection / 2);
      
      // Add multiple full rotations for visual effect (3-5 spins)
      final fullSpins = 3 + random.nextDouble() * 2;
      final totalRotations = fullSpins * 2 * pi;
      
      // Calculate final rotation to land on the selected prize
      // Since wheel starts at -π/2 and rotates clockwise, we need to calculate 
      // how much to rotate to get the selected prize at the top (pointer position)
      final targetAngle = -prizeAngle;
      final finalRotation = _lastSpinRotation + totalRotations + targetAngle;
      
      _spinController.reset();
      _spinAnimation = Tween<double>(
        begin: _lastSpinRotation,
        end: finalRotation,
      ).animate(CurvedAnimation(
        parent: _spinController,
        curve: Curves.easeOut,
      ));
      
      await _spinController.forward();
      
      // Update the last rotation for next spin
      _lastSpinRotation = finalRotation % (2 * pi);
      _lastPrize = selectedPrize;
      
      // Debug info (can be removed in production)
      print('Selected prize index: $prizeIndex, Prize: ${selectedPrize['label']}');
      
      await _awardPrize(selectedPrize);
      
    } catch (e) {
      _showMessage('Error spinning wheel: $e', isError: true);
    } finally {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  Future<void> _awardPrize(Map<String, dynamic> prize) async {
    try {
      if (prize['type'] == 'cne') {
        // Award CNE tokens
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        final amount = prize['value'] as double;
        
        await balanceService.addBalance(amount, 'Spin2Earn Game');
        
        if (mounted) {
          _showPrizeDialog(prize, true);
        }
      } else if (prize['type'] == 'nft') {
        // Handle NFT prize
        if (mounted) {
          _showPrizeDialog(prize, true);
        }
      }
    } catch (e) {
      _showMessage('Error awarding prize: $e', isError: true);
    }
  }

  void _showPrizeDialog(Map<String, dynamic> prize, bool isWin) {
    final isNft = prize['type'] == 'nft';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isWin ? '🎉 Congratulations!' : '💫 Try Again',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: prize['color'] as Color,
                shape: BoxShape.circle,
              ),
              child: isNft 
                ? const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 32,
                  )
                : Text(
                    prize['label'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              isNft 
                ? '🎨 Amazing! You won an NFT!\n\nYour NFT will be sent to your wallet soon.'
                : 'You won ${prize['label']}!\n\nYour balance has been updated!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            if (!isNft) ...[
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
                    Consumer<UserBalanceService>(
                      builder: (context, balanceService, child) {
                        return Text(
                          'Balance: ${balanceService.balance.toStringAsFixed(1)} CNE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Awesome!',
              style: TextStyle(
                color: Color(0xFF006833),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : const Color(0xFF006833),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Spin2Earn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006833), Color(0xFF005029)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Spins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_dailySpinsUsed / $_maxDailySpins used',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    FeatherIcons.rotateCw,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _spinAnimation.value * 2 * pi,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: CustomPaint(
                            painter: SpinWheelPainter(_prizes),
                            size: const Size(300, 300),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[800]!, width: 3),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Color(0xFF006833),
                      size: 30,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        size: const Size(20, 30),
                        painter: PointerPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_dailySpinsUsed >= _maxDailySpins)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  children: [
                    const Icon(
                      FeatherIcons.clock,
                      color: Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Daily Limit Reached',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Come back tomorrow for more spins!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSpinning ? null : _spinWheel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSpinning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SPIN TO WIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 32),
            if (_lastPrize != null) _buildLastWinDisplay(),
            const SizedBox(height: 24),
            const AdsCarousel(),
          ],
        ),
      ),
    );
  }

  Widget _buildLastWinDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (_lastPrize!['color'] as Color).withOpacity(0.8),
            (_lastPrize!['color'] as Color).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            '🎉 Last Win',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _lastPrize!['label'],
              style: TextStyle(
                color: _lastPrize!['color'] as Color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wheel accuracy verified! ✅',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Possible Prizes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          ...(_prizes.map((prize) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: prize['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  prize['label'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          )).toList()),
        ],
      ),
    );
  }
}

class SpinWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;

  SpinWheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final anglePerSection = (2 * pi) / prizes.length;
    
    // Start from top (12 o'clock position) - subtract π/2 to align with pointer
    final startOffset = -pi / 2;

    for (int i = 0; i < prizes.length; i++) {
      final startAngle = startOffset + (i * anglePerSection);
      final sweepAngle = anglePerSection;
      
      paint.color = prizes[i]['color'] as Color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Draw border between sections for better visibility
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7;
      final textCenter = Offset(
        center.dx + cos(textAngle) * textRadius,
        center.dy + sin(textAngle) * textRadius,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i]['label'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      // Rotate text to be readable
      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      
      // Only rotate text if it's on the left side to keep it readable
      double textRotation = 0;
      if (textAngle > pi / 2 && textAngle < 3 * pi / 2) {
        textRotation = textAngle + pi;
      } else {
        textRotation = textAngle;
      }
      
      canvas.rotate(textRotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF006833)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(0, size.height); // Bottom left
    path.lineTo(size.width, size.height); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
    
    // Add border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
