import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/reward_service.dart';
import '../services/user_balance_service.dart';
import '../widgets/chat_ad_carousel.dart';

class DailyCheckinPage extends StatefulWidget {
  const DailyCheckinPage({super.key});

  @override
  State<DailyCheckinPage> createState() => _DailyCheckinPageState();
}

class _DailyCheckinPageState extends State<DailyCheckinPage> {
  bool _isLoading = false;
  bool _isClaiming = false;
  Map<String, dynamic>? _checkinStatus;
  Timer? _countdownTimer;
  Duration _timeUntilNextClaim = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadCheckinStatus();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCheckinStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user-specific status
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _checkinStatus = {'canClaim': false};
          _calculateTimeUntilNextClaim();
        });
        return;
      }

      final status = await RewardService.getDailyRewardStatus();
      
      // Enhance status with user-specific data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = user.uid;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastClaimDate = prefs.getString('daily_claim_date_$userId');
      final lastClaimTimestamp = prefs.getInt('daily_claim_timestamp_$userId');
      
      // Determine if user can claim today
      bool canClaimToday = lastClaimDate != today;
      
      // Merge server status with local user-specific data
      final enhancedStatus = {
        ...?status,
        'canClaim': canClaimToday,
        'lastClaimAt': lastClaimTimestamp,
        'lastClaimDate': lastClaimDate,
        'currentUserId': userId,
      };
      
      setState(() {
        _checkinStatus = enhancedStatus;
        _calculateTimeUntilNextClaim();
      });
    } catch (e) {
      debugPrint('Error loading checkin status: $e');
      setState(() {
        _checkinStatus = {'canClaim': false};
        _calculateTimeUntilNextClaim();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTimeUntilNextClaim() {
    if (_checkinStatus == null) return;
    
    final canClaim = _checkinStatus!['canClaim'] == true;
    if (canClaim) {
      _timeUntilNextClaim = Duration.zero;
      return;
    }
    
    // Calculate user-specific next claim time based on their last claim
    final lastClaimAt = _checkinStatus!['lastClaimAt'];
    final now = DateTime.now();
    
    if (lastClaimAt != null) {
      // Convert timestamp to DateTime (handle both milliseconds and seconds)
      DateTime lastClaim;
      if (lastClaimAt is int) {
        // If timestamp is too small, it's likely in seconds, convert to milliseconds
        final timestamp = lastClaimAt > 1000000000000 ? lastClaimAt : lastClaimAt * 1000;
        lastClaim = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (lastClaimAt is Map) {
        // Firestore Timestamp format
        final seconds = lastClaimAt['_seconds'] ?? (lastClaimAt['seconds'] ?? 0);
        lastClaim = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else {
        // Fallback to current time
        lastClaim = now;
      }
      
      // Next claim is 24 hours after last claim
      final nextClaimTime = DateTime(
        lastClaim.year,
        lastClaim.month, 
        lastClaim.day + 1,
        0, 0, 0, 0 // Reset to start of next day
      );
      
      _timeUntilNextClaim = nextClaimTime.isAfter(now) 
          ? nextClaimTime.difference(now)
          : Duration.zero;
    } else {
      // No previous claim, can claim immediately
      _timeUntilNextClaim = Duration.zero;
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    // Only start timer if there's actually a countdown needed
    if (_timeUntilNextClaim.inSeconds <= 0) {
      return; // No countdown needed
    }
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeUntilNextClaim.inSeconds > 0) {
        setState(() {
          _timeUntilNextClaim = _timeUntilNextClaim - const Duration(seconds: 1);
        });
      } else {
        // Time's up, refresh the status
        timer.cancel();
        _loadCheckinStatus();
      }
    });
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _claimDailyReward() async {
    if (_isClaiming) return;

    // Show mandatory 30-second ad before claiming reward
    final watchedAd = await _showMandatoryAd();
    if (!watchedAd) {
      return; // User cancelled or didn't watch the full ad
    }

    setState(() {
      _isClaiming = true;
    });

    try {
      final result = await RewardService.claimDailyReward();
      if (result.success) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim({
          'success': result.success,
          'reward': result.reward,
          'message': result.message,
        });

        // Save user-specific claim data
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final now = DateTime.now();
          final userId = user.uid;
          final today = now.toIso8601String().substring(0, 10);
          
          await prefs.setString('daily_claim_date_$userId', today);
          await prefs.setInt('daily_claim_timestamp_$userId', now.millisecondsSinceEpoch);
        }

        // Refresh status
        await _loadCheckinStatus();
        _calculateTimeUntilNextClaim();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily reward claimed! +${result.reward?.toStringAsFixed(2) ?? '0.00'} CNE'),
              backgroundColor: const Color(0xFF006833),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
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

  Future<bool> _showMandatoryAd() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must watch the ad
      builder: (BuildContext context) {
        return const _AdDialog();
      },
    ) ?? false;
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
                              : 'Next check-in available in:',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_checkinStatus?['canClaim'] != true && _timeUntilNextClaim.inSeconds > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[600]!, width: 1),
                            ),
                            child: Text(
                              _formatCountdown(_timeUntilNextClaim),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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

                  const SizedBox(height: 24),

                  // Banner carousel from Chat page
                  const Text(
                    'Sponsored Content',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const ChatAdCarousel(),
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

class _AdDialog extends StatefulWidget {
  const _AdDialog();

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  late YoutubePlayerController _controller;
  Timer? _adTimer;
  int _remainingSeconds = 30;
  bool _canSkip = false;
  bool _adCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'p4kmPtTU4lw', // Mandatory ad video
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: false,
        loop: false,
        hideControls: true,
      ),
    );

    // Start countdown timer
    _startAdTimer();
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        setState(() {
          _canSkip = true;
          _adCompleted = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with ad info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.ads_click,
                    color: Color(0xFF006833),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Watch this ad to claim your reward',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  if (!_canSkip)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_remainingSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video player
            Expanded(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF006833),
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFF006833),
                  handleColor: Color(0xFF006833),
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // User cancelled
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSkip
                          ? () {
                              Navigator.of(context).pop(true); // Ad completed
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canSkip 
                            ? const Color(0xFF006833) 
                            : Colors.grey[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _canSkip ? 'Continue' : 'Please wait...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
