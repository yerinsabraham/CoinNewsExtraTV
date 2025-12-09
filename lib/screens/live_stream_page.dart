import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';
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

  // Reward configuration (use central LiveVideoConfig)
  late final int _requiredWatchTimeSeconds = LiveVideoConfig.requiredWatchTimeSeconds;
  late final double _rewardAmount = LiveVideoConfig.watchReward;
  // Internal flag to avoid double-triggering claim
  bool _claimTriggered = false;

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
        disableDragSeek: true,
        useHybridComposition: true,
      ),
    );
    
    // Listen to player state changes
    _controller.addListener(_onPlayerStateChanged);
    
    // Add error handling and auto-play retry
    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('❌ Live Stream Error: ${_controller.value.errorCode}');
      } else if (_controller.value.isReady && !_controller.value.isPlaying) {
        debugPrint('✅ Live stream ready, attempting autoplay...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_controller.value.isPlaying) {
            _controller.play();
          }
        });
      }
    });
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
      }
        // Auto-claim when threshold met
        if (!_claimTriggered && _watchTimeSeconds >= _requiredWatchTimeSeconds) {
          _claimTriggered = true;
          if (!_isClaimingReward) {
            _claimWatchReward().then((_) {
              // After claiming, reset timer for next period
              setState(() {
                _watchTimeSeconds = 0;
                _hasClaimedReward = false;
                _claimTriggered = false;
              });
            });
          }
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

  bool _hasMetWatchRequirement() {
    return _watchTimeSeconds >= _requiredWatchTimeSeconds;
  }

  double _getWatchProgress() {
    return (_watchTimeSeconds / _requiredWatchTimeSeconds).clamp(0.0, 1.0);
  }

  String _getTimeRemainingMessage() {
    if (_hasMetWatchRequirement()) {
      return 'Reward ready to claim!';
    }
    final remaining = _requiredWatchTimeSeconds - _watchTimeSeconds;
    return 'Watch for ${remaining}s more to earn rewards';
  }

  String _formatWatchTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _claimWatchReward() async {
    if (_isClaimingReward || _hasClaimedReward || !_hasMetWatchRequirement()) {
      return;
    }

    setState(() {
      _isClaimingReward = true;
    });

    try {
      // Award the reward using our balance service
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
  await balanceService.addBalance(_rewardAmount, 'Live Stream Watch Reward');

      setState(() {
        _hasClaimedReward = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Live stream reward claimed! +${_rewardAmount.toInt()} CNE'),
            backgroundColor: const Color(0xFF006833),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error claiming reward'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
    final progress = _getWatchProgress();
    final canClaim = _hasMetWatchRequirement() && !_hasClaimedReward;

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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // YouTube video player
          Container(
            height: 240,
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
                      color: Colors.black.withOpacity(0.7),
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
                          _formatWatchTime(_watchTimeSeconds),
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
                
                // Live status indicator
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'STREAMING LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stream info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Thin in-house ad banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Special Offer: Join our Summit highlights on CNE — tap to view',
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/summit'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006833),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Reward progress
                  Container(
                    width: double.infinity,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                canClaim ? FeatherIcons.gift : FeatherIcons.clock,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    canClaim ? 'Reward Ready! 🎉' : 'Earn While Watching',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    canClaim 
                                        ? 'Claim your ${_rewardAmount.toInt()} CNE tokens now!'
                                        : _getTimeRemainingMessage(),
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
                        
                        const SizedBox(height: 20),
                        
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Watch Progress',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatWatchTime(_watchTimeSeconds)} / ${_formatWatchTime(_requiredWatchTimeSeconds)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                        
                        if (canClaim) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isClaimingReward ? null : _claimWatchReward,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF006833),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              icon: _isClaimingReward
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF006833),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(FeatherIcons.gift, size: 20),
                              label: Text(
                                _isClaimingReward 
                                    ? 'Claiming...' 
                                    : 'Claim ${_rewardAmount.toInt()} CNE Reward',
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
                        child: _buildStatCard(
                          'Watch Time', 
                          _formatWatchTime(_watchTimeSeconds),
                          FeatherIcons.clock,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Status',
                          _hasClaimedReward ? 'Claimed ✅' : (_hasMetWatchRequirement() ? 'Ready!' : 'Watching...'),
                          _hasClaimedReward ? FeatherIcons.checkCircle : FeatherIcons.eye,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Earned', 
                          _hasClaimedReward ? '${_rewardAmount.toInt()} CNE' : '0 CNE',
                          FeatherIcons.award,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Stream Status',
                          'Live 🔴',
                          FeatherIcons.radio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF006833),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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