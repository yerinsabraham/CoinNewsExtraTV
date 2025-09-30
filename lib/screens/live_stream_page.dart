import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';
import '../services/reward_service.dart';
import '../services/user_balance_service.dart';
import '../services/live_video_config.dart';

class LiveStreamPage extends StatefulWidget {
  final String streamId;
  final String title;
  final String description;

  const LiveStreamPage({
    super.key,
    required this.streamId,
    required this.title,
    required this.description,
  });

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  Timer? _watchTimer;
  int _watchTimeSeconds = 0;
  bool _isWatching = false;
  bool _hasClaimedReward = false;
  bool _isClaimingReward = false;
  bool _hasStartedPlaying = false;
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    
    // Use unified live video configuration
    _controller = YoutubePlayerController(
      initialVideoId: LiveVideoConfig.getVideoId(),
      flags: const YoutubePlayerFlags(
        autoPlay: LiveVideoConfig.autoPlayOnLaunch,
        mute: false,
        controlsVisibleAtStart: true,
        loop: false,
        isLive: LiveVideoConfig.isLiveStream,
        enableCaption: LiveVideoConfig.enableCaptions,
      ),
    );
    
    // Listen to player state changes
    _controller.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    _stopWatching();
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (_controller.value.isPlaying && !_hasStartedPlaying) {
      _hasStartedPlaying = true;
      _startWatching();
    } else if (!_controller.value.isPlaying && _isWatching) {
      _pauseWatching();
    }
  }

  void _startWatching() {
    if (_isWatching) return;
    
    setState(() {
      _isWatching = true;
    });

    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        setState(() {
          _watchTimeSeconds++;
        });
        LiveVideoConfig.logWatchTime(_watchTimeSeconds);
      }
    });
  }

  void _pauseWatching() {
    setState(() {
      _isWatching = false;
    });
  }

  void _stopWatching() {
    _watchTimer?.cancel();
    setState(() {
      _isWatching = false;
    });
  }

  Future<void> _claimWatchReward() async {
    if (_isClaimingReward || _hasClaimedReward || 
        !LiveVideoConfig.hasMetWatchRequirement(_watchTimeSeconds)) {
      return;
    }

    setState(() {
      _isClaimingReward = true;
    });

    try {
      final result = await RewardService.claimLiveStreamReward(
        streamId: LiveVideoConfig.getVideoId(),
        watchDurationSeconds: _watchTimeSeconds,
      );

      if (result.success) {
        if (mounted) {
          final balanceService = Provider.of<UserBalanceService>(context, listen: false);
          await balanceService.processRewardClaim({
            'success': result.success,
            'reward': result.reward,
            'message': result.message,
          });

          setState(() {
            _hasClaimedReward = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Live stream reward claimed! +${result.reward?.toStringAsFixed(2) ?? '0.00'} CNE'),
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
            content: Text('Error claiming reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isClaimingReward = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = LiveVideoConfig.getWatchProgress(_watchTimeSeconds);
    final canClaim = LiveVideoConfig.hasMetWatchRequirement(_watchTimeSeconds) && !_hasClaimedReward;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // YouTube video player
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF006833),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFF006833),
                    handleColor: Color(0xFF006833),
                  ),
                ),
                
                // Watch time overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          FeatherIcons.clock,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          LiveVideoConfig.formatWatchTime(_watchTimeSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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

          // Reward tracking section
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reward progress
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: canClaim 
                            ? [const Color(0xFF006833), const Color(0xFF005029)]
                            : [Colors.grey[800]!, Colors.grey[900]!],
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
                            Icon(
                              canClaim ? FeatherIcons.gift : FeatherIcons.clock,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    canClaim ? 'Reward Ready!' : 'Watch for 1+ minute',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  Text(
                                    canClaim 
                                        ? 'Claim your ${LiveVideoConfig.watchReward.toInt()} CNE tokens now!'
                                        : LiveVideoConfig.getTimeRemainingMessage(_watchTimeSeconds),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
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
                        
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress to reward',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (canClaim) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isClaimingReward ? null : _claimWatchReward,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF006833),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isClaimingReward
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF006833),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Claim ${LiveVideoConfig.watchReward.toInt()} CNE Reward',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Live stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Watch Time', LiveVideoConfig.formatWatchTime(_watchTimeSeconds)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Reward Status', _hasClaimedReward ? 'Claimed' : 'Pending'),
                      ),
                    ],
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

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }
}
