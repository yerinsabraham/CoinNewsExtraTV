import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../services/user_balance_service.dart';

class DailyCheckinPage extends StatefulWidget {
  const DailyCheckinPage({super.key});

  @override
  State<DailyCheckinPage> createState() => _DailyCheckinPageState();
}

class _DailyCheckinPageState extends State<DailyCheckinPage> {
  bool _isLoading = false;
  bool _isClaiming = false;
  Map<String, dynamic>? _checkinStatus;

  @override
  void initState() {
    super.initState();
    _loadCheckinStatus();
  }

  Future<void> _loadCheckinStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await RewardService.getDailyRewardStatus();
      setState(() {
        _checkinStatus = status;
      });
    } catch (e) {
      debugPrint('Error loading checkin status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _claimDailyReward() async {
    if (_isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    try {
      final result = await RewardService.claimDailyReward();
      if (result != null && result['success'] == true) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim(result);

        // Refresh status
        await _loadCheckinStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily reward claimed! +${result['rewardAmount']} CNE'),
              backgroundColor: const Color(0xFF006833),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to claim daily reward'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error claiming daily reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isClaiming = false;
      });
    }
  }

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
          'Daily Check-in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006833),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006833), Color(0xFF005029)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              FeatherIcons.calendar,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Daily Check-in',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  Text(
                                    'Maintain your streak to earn more!',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusItem(
                              'Current Streak',
                              '${_checkinStatus?['currentStreak'] ?? 0} days',
                              FeatherIcons.zap,
                            ),
                            _buildStatusItem(
                              'Best Streak',
                              '${_checkinStatus?['bestStreak'] ?? 0} days',
                              FeatherIcons.award,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Check-in status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _checkinStatus?['canClaim'] == true
                              ? FeatherIcons.gift
                              : FeatherIcons.checkCircle,
                          color: _checkinStatus?['canClaim'] == true
                              ? const Color(0xFF006833)
                              : Colors.grey,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _checkinStatus?['canClaim'] == true
                              ? 'Ready to Check-in!'
                              : 'Already Checked-in Today',
                          style: TextStyle(
                            color: _checkinStatus?['canClaim'] == true
                                ? Colors.white
                                : Colors.grey[400],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _checkinStatus?['canClaim'] == true
                              ? 'Claim your daily reward and continue your streak!'
                              : 'Come back tomorrow for your next reward',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (_checkinStatus?['canClaim'] == true)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isClaiming ? null : _claimDailyReward,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006833),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isClaiming
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(FeatherIcons.gift),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Claim ${_checkinStatus?['rewardAmount'] ?? 10} CNE',
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Streak calendar (last 7 days)
                  _buildStreakCalendar(),

                  const SizedBox(height: 24),

                  // Rewards information
                  _buildRewardsInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCalendar() {
    final checkinHistory = _checkinStatus?['recentCheckins'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Check-ins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final dayIndex = 6 - index; // Show last 7 days in reverse
              final isCheckedIn = dayIndex < checkinHistory.length;
              
              return Column(
                children: [
                  Text(
                    _getDayName(dayIndex),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCheckedIn
                          ? const Color(0xFF006833)
                          : Colors.grey[800],
                      border: Border.all(
                        color: isCheckedIn
                            ? const Color(0xFF006833)
                            : Colors.grey[600]!,
                        width: 2,
                      ),
                    ),
                    child: isCheckedIn
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reward Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          _buildRewardItem('Daily Check-in', '10 CNE', 'Every day'),
          _buildRewardItem('7-day Streak Bonus', '50 CNE', 'Weekly'),
          _buildRewardItem('30-day Streak Bonus', '200 CNE', 'Monthly'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  FeatherIcons.info,
                  color: Color(0xFF006833),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Missing a day resets your streak to 0. Check-in within 24 hours to maintain your streak!',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
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

  Widget _buildRewardItem(String title, String reward, String frequency) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            FeatherIcons.gift,
            color: Color(0xFF006833),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  frequency,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          Text(
            reward,
            style: const TextStyle(
              color: Color(0xFF006833),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int dayIndex) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday - 1; // Monday = 0
    final dayOfWeek = (today - dayIndex) % 7;
    return days[dayOfWeek < 0 ? dayOfWeek + 7 : dayOfWeek];
  }
}
