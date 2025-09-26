import 'package:flutter/material.dart';
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
                  
                  // Placeholder for wheel (coming next)
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'Wheel Coming Soon',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Spin button placeholder
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: null, // Disabled for now
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Spin Now',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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