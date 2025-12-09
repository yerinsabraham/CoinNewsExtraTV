import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';
import '../services/user_balance_service.dart';
import '../data/video_data.dart';
import '../widgets/ads_carousel.dart';

class DailyCheckinPage extends StatefulWidget {
  const DailyCheckinPage({super.key});

  @override
  State<DailyCheckinPage> createState() => _DailyCheckinPageState();
}

class _DailyCheckinPageState extends State<DailyCheckinPage> {
  bool _isLoading = false;
  bool _isClaiming = false;
  bool _canClaim = true;
  int _currentStreak = 0;
  int _bestStreak = 0;
  Timer? _countdownTimer;
  Duration _timeUntilNextClaim = Duration.zero;
  final double _rewardAmount = 28.0; // Updated CNE reward for 1-10K tier

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
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _canClaim = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = user.uid;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastClaimDate = prefs.getString('daily_claim_date_$userId');
      final lastClaimTimestamp = prefs.getInt('daily_claim_timestamp_$userId');
      
      _currentStreak = prefs.getInt('daily_streak_$userId') ?? 0;
      _bestStreak = prefs.getInt('best_streak_$userId') ?? 0;
      
      bool canClaimToday = lastClaimDate != today;
      
      setState(() {
        _canClaim = canClaimToday;
        _calculateTimeUntilNextClaim(lastClaimTimestamp);
      });
    } catch (e) {
      debugPrint('Error loading checkin status: $e');
      setState(() => _canClaim = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTimeUntilNextClaim(int? lastClaimTimestamp) {
    if (_canClaim) {
      _timeUntilNextClaim = Duration.zero;
      return;
    }
    
    if (lastClaimTimestamp != null) {
      // Next claim should be exactly 24 hours after the last claim time
      final lastClaim = DateTime.fromMillisecondsSinceEpoch(lastClaimTimestamp);
      final nextClaimTime = lastClaim.add(const Duration(hours: 24));

      final now = DateTime.now();
      _timeUntilNextClaim = nextClaimTime.isAfter(now)
          ? nextClaimTime.difference(now)
          : Duration.zero;
    } else {
      _timeUntilNextClaim = Duration.zero;
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    if (_timeUntilNextClaim.inSeconds <= 0) return;
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeUntilNextClaim.inSeconds > 0) {
        setState(() {
          _timeUntilNextClaim = _timeUntilNextClaim - const Duration(seconds: 1);
        });
      } else {
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

    // Show mandatory 30-second video before claiming reward
    final watchedVideo = await _showMandatoryVideo();
    if (!watchedVideo) {
      return; // User cancelled or didn't watch the full video
    }

    setState(() => _isClaiming = true);

    try {
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(_rewardAmount, 'Daily check-in reward');

      // Save user-specific claim data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final userId = user.uid;
        final today = now.toIso8601String().substring(0, 10);
        
        // Update streak
        final newStreak = _currentStreak + 1;
        final newBestStreak = newStreak > _bestStreak ? newStreak : _bestStreak;
        
        await prefs.setString('daily_claim_date_$userId', today);
        await prefs.setInt('daily_claim_timestamp_$userId', now.millisecondsSinceEpoch);
        await prefs.setInt('daily_streak_$userId', newStreak);
        await prefs.setInt('best_streak_$userId', newBestStreak);
        
        setState(() {
          _currentStreak = newStreak;
          _bestStreak = newBestStreak;
        });
      }

      await _loadCheckinStatus();
      _calculateTimeUntilNextClaim(DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily reward claimed! +${_rewardAmount.toStringAsFixed(0)} CNE'),
            backgroundColor: const Color(0xFF006833),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming daily reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isClaiming = false);
    }
  }

  Future<bool> _showMandatoryVideo() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must watch the video
      builder: (BuildContext context) {
        return const _VideoDialog();
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
              child: CircularProgressIndicator(color: Color(0xFF006833)),
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
                              Icons.calendar_today,
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
                              '$_currentStreak days',
                              FeatherIcons.zap,
                            ),
                            _buildStatusItem(
                              'Best Streak',
                              '$_bestStreak days',
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
                          _canClaim
                              ? FeatherIcons.gift
                              : FeatherIcons.checkCircle,
                          color: _canClaim
                              ? const Color(0xFF006833)
                              : Colors.grey,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _canClaim
                              ? 'Ready to Check-in!'
                              : 'Already Checked-in Today',
                          style: TextStyle(
                            color: _canClaim
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
                          _canClaim
                              ? 'Claim your daily reward and continue your streak!'
                              : 'Next check-in available in:',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!_canClaim && _timeUntilNextClaim.inSeconds > 0) ...[
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
                        if (_canClaim)
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
                                          'Claim ${_rewardAmount.toStringAsFixed(0)} CNE',
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

                  // Rewards information
                  _buildRewardsInfo(),

                  const SizedBox(height: 24),

                  // Banner carousel
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

                  const AdsCarousel(),
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
          _buildRewardItem('Daily Check-in', '28 CNE', 'Every day'),
          _buildRewardItem('7-day Streak Bonus', '196 CNE', 'Weekly'),
          _buildRewardItem('30-day Streak Bonus', '840 CNE', 'Monthly'),
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
}

class _VideoDialog extends StatefulWidget {
  const _VideoDialog();

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late YoutubePlayerController _controller;
  Timer? _videoTimer;
  int _remainingSeconds = 30;
  bool _canSkip = false;
  bool _videoCompleted = false;

  @override
  void initState() {
    super.initState();
    
    // Get a random video from video data
    final videos = VideoData.getAllVideos();
    String videoId = videos.isNotEmpty ? videos.first.youtubeId.trim() : 'p4kmPtTU4lw';
    
    // Validate video ID
    if (videoId.isEmpty) {
      videoId = 'dQw4w9WgXcQ';
      debugPrint('⚠️ No video ID found, using fallback: $videoId');
    }
    
    debugPrint('📺 Daily checkin initializing player with video ID: $videoId');
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: false,
        loop: false,
        hideControls: true,
        useHybridComposition: true,
      ),
    );

    // Add error handling
    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('❌ Daily Checkin Video Error: ${_controller.value.errorCode}');
      } else if (_controller.value.isReady && !_controller.value.isPlaying) {
        debugPrint('✅ Daily checkin video ready, attempting autoplay...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!(_controller.value.isPlaying)) {
            _controller.play();
          }
        });
      }
    });

    // Start countdown timer
    _startVideoTimer();
  }

  void _startVideoTimer() {
    _videoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        setState(() {
          _canSkip = true;
          _videoCompleted = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _videoTimer?.cancel();
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
            // Header with video info
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
                    Icons.play_circle_filled,
                    color: Color(0xFF006833),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Watch this video to claim your reward',
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
                              Navigator.of(context).pop(true); // Video completed
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
