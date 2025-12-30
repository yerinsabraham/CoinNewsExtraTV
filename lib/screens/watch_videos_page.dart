import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:feather_icons/feather_icons.dart';
import '../services/user_balance_service.dart';
import '../data/video_data.dart';
import '../models/video_model.dart';
import '../widgets/ads_carousel.dart';

class WatchVideosPage extends StatefulWidget {
  const WatchVideosPage({super.key});

  @override
  State<WatchVideosPage> createState() => _WatchVideosPageState();
}

class _WatchVideosPageState extends State<WatchVideosPage> {
  final List<VideoModel> videos = VideoData.getAllVideos();
  final Set<String> watchedVideos = <String>{};
  bool _loadingWatchedFlags = true;

  @override
  void initState() {
    super.initState();
    _loadWatchedFlags();
  }

  Future<void> _loadWatchedFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final v in videos) {
        final claimed = prefs.getBool('video_reward_claimed_${v.id}') ?? false;
        if (claimed) watchedVideos.add(v.id);
      }
    } catch (e) {
      debugPrint('❌ Error loading watched flags: $e');
    } finally {
      if (mounted) setState(() => _loadingWatchedFlags = false);
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
          'Watch & Earn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF006833),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Consumer<UserBalanceService>(
              builder: (context, balanceService, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      balanceService.balance.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Earnings Info Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006833), Color(0xFF005029)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(FeatherIcons.play, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Watch Videos & Earn CNE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                          Text(
                            'Watch at least 25% of a video to unlock the claim button',
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
                  children: [
                    _buildStatItem('Videos Watched', '${watchedVideos.length}', FeatherIcons.checkCircle),
                    const SizedBox(width: 32),
                    _buildStatItem('Reward Per Video', '5 CNE', FeatherIcons.award),
                  ],
                ),
              ],
            ),
          ),
          
          // Video List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                final isWatched = watchedVideos.contains(video.id);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: isWatched 
                      ? Border.all(color: const Color(0xFF006833), width: 2)
                      : Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Video thumbnail and info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 120,
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(video.youtubeThumbnailUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  if (isWatched)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF006833),
                                          size: 32,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  // Duration badge
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (video.duration as String?) ?? '10:00',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Video details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lato',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    video.channelName ?? 'CoinNews Extra',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${video.views ?? '1K views'} • ${video.uploadTime ?? '1 hour ago'}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Reward status
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isWatched 
                                          ? const Color(0xFF006833).withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isWatched ? Icons.check_circle : Icons.monetization_on,
                                          color: isWatched ? const Color(0xFF006833) : Colors.orange,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isWatched ? 'Reward Claimed' : '5 CNE Reward',
                                          style: TextStyle(
                                            color: isWatched ? const Color(0xFF006833) : Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Lato',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // List-level actions (Share)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final url = video.url ?? 'https://www.youtube.com/watch?v=${video.youtubeId}';
                                          Share.share('Watch "${video.title}" on CoinNewsExtra: $url');
                                        },
                                        child: const Row(
                                          children: [
                                            Icon(Icons.share_outlined, color: Colors.white, size: 18),
                                            SizedBox(width: 6),
                                            Text(
                                              'Share',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontFamily: 'Lato',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action button
                      if (!isWatched)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: ElevatedButton(
                            onPressed: () => _watchVideo(video),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006833),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Watch & Earn',
                                  style: TextStyle(
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
                );
              },
            ),
          ),
          
          // Footer
          const Padding(
            padding: EdgeInsets.all(20),
            child: AdsCarousel(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  Future<void> _watchVideo(VideoModel video) async {
    // Navigate to video player page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          video: video,
          onRewardClaimed: () {
            setState(() {
              watchedVideos.add(video.id);
            });
          },
        ),
      ),
    );
    
    // If reward was claimed, update the UI
    if (result == true) {
      setState(() {
        watchedVideos.add(video.id);
      });
    }
  }
}

class VideoPlayerPage extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onRewardClaimed;

  const VideoPlayerPage({
    super.key,
    required this.video,
    this.onRewardClaimed,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _showDescription = false;
  
  // Reward tracking
  Timer? _watchTimer;
  bool _rewardClaimed = false;
  bool _isClaimingReward = false;
  
  // Watch progress tracking
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  int _lastPersistedSecond = -1;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _startWatchTracking();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = widget.video.id;
      final posMs = prefs.getInt('video_last_position_$id') ?? 0;
      final claimed = prefs.getBool('video_reward_claimed_$id') ?? false;
      setState(() {
        _rewardClaimed = claimed;
      });

      if (posMs > 0) {
        final pos = Duration(milliseconds: posMs);
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            _controller.seekTo(pos);
          } catch (e) {
            debugPrint('❌ Error seeking to last position: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading saved video state: $e');
    }
  }

  void _initializeVideoPlayer() {
    // Extract YouTube video ID from URL
    String videoId = widget.video.youtubeId.trim();
    
    if (videoId.isEmpty && widget.video.url != null && widget.video.url!.isNotEmpty) {
      final extractedId = YoutubePlayer.convertUrlToId(widget.video.url!);
      if (extractedId != null && extractedId.isNotEmpty) {
        videoId = extractedId;
      }
    }
    
    if (videoId.isEmpty) {
      videoId = 'dQw4w9WgXcQ'; // Fallback video
      debugPrint('⚠️ No video ID found, using fallback: $videoId');
    }
    
    debugPrint('📺 Initializing player with video ID: $videoId');

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        useHybridComposition: false,  // Disabled - causes play() to fail
        enableCaption: true,
        controlsVisibleAtStart: true,
        hideControls: false,
        isLive: false,
      ),
    );

    // Listen to player events
    _controller.addListener(_onPlayerStateChanged);
    
    // Add error handling and diagnostic logging
    _controller.addListener(() {
      debugPrint('🎯 Player state: Ready=${_controller.value.isReady}, Playing=${_controller.value.isPlaying}, Error=${_controller.value.hasError}');
      
      if (_controller.value.hasError) {
        debugPrint('❌ YouTube Player Error: ${_controller.value.errorCode}');
      } else if (_controller.value.isReady && !_controller.value.isPlaying) {
        debugPrint('✅ Player ready, attempting autoplay...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_controller.value.isPlaying) {
            debugPrint('⏯️ Calling play() method...');
            _controller.play();
            // Double-check that play was triggered
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_controller.value.isPlaying) {
                debugPrint('🔄 Play attempt failed, retrying...');
                _controller.play();
              }
            });
          }
        });
      } else if (_controller.value.isPlaying) {
        debugPrint('▶️ Video is now playing');
      }
    });
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      final duration = _controller.metadata.duration;
      final position = _controller.value.position;
      
      setState(() {
        _videoDuration = duration;
        _currentPosition = position;
      });
    }
  }

  void _startWatchTracking() {
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        setState(() {
          _currentPosition = _controller.value.position;
        });
        // Persist position every 5 seconds (avoid repeated writes)
        final sec = _currentPosition.inSeconds;
        if (sec % 5 == 0 && sec != _lastPersistedSecond) {
          _lastPersistedSecond = sec;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt('video_last_position_${widget.video.id}', _controller.value.position.inMilliseconds);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    // Save current position on dispose
    try {
      final id = widget.video.id;
      SharedPreferences.getInstance().then((prefs) {
        // If reward has been claimed, save full duration as last position to mark completed
        final saveMs = _rewardClaimed ? _videoDuration.inMilliseconds : _controller.value.position.inMilliseconds;
        prefs.setInt('video_last_position_$id', saveMs);
      });
    } catch (e) {
      debugPrint('❌ Error saving position on dispose: $e');
    }
    _controller.dispose();
    _watchTimer?.cancel();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_rewardClaimed || _isClaimingReward) return;

    // Check if watched enough (25% of video)
    const requiredWatchPercentage = 0.25;
    final actualWatchPercentage = _videoDuration.inSeconds > 0
        ? _currentPosition.inSeconds / _videoDuration.inSeconds
        : 0.0;
    if (actualWatchPercentage < requiredWatchPercentage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watch at least 25% of the video to claim your reward!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isClaimingReward = true;
    });

    try {
      // Award reward using current token system
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(5.0, 'Video watch reward: ${widget.video.title}');

      setState(() {
        _rewardClaimed = true;
      });

        // Persist reward claimed flag
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('video_reward_claimed_${widget.video.id}', true);
            // Also persist final watched position as full duration so it's not claimable again
            await prefs.setInt('video_last_position_${widget.video.id}', _videoDuration.inMilliseconds);
        } catch (e) {
          debugPrint('❌ Error saving reward claimed flag: $e');
        }
      // Notify parent widget
      widget.onRewardClaimed?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video reward claimed! +5.0 CNE'),
          backgroundColor: Color(0xFF006833),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error claiming reward'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isClaimingReward = false;
    });
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
          onPressed: () => Navigator.pop(context, _rewardClaimed),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF006833),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Consumer<UserBalanceService>(
              builder: (context, balanceService, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      balanceService.balance.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF006833),
            bottomActions: const [
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              PlaybackSpeedButton(),
            ],
          ),
          
          // Video Info and Controls
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and basic info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.video.channelName ?? 'CoinNews Extra'} • ${widget.video.views ?? '1K views'} • ${widget.video.uploadTime ?? '1 hour ago'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              label: 'Like',
                              onTap: () => setState(() {
                                _isLiked = !_isLiked;
                                if (_isLiked) _isDisliked = false;
                              }),
                              isActive: _isLiked,
                            ),
                            _buildActionButton(
                              icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              label: 'Dislike',
                              onTap: () => setState(() {
                                _isDisliked = !_isDisliked;
                                if (_isDisliked) _isLiked = false;
                              }),
                              isActive: _isDisliked,
                            ),
                            _buildActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                final url = widget.video.url ?? 'https://www.youtube.com/watch?v=${widget.video.youtubeId}';
                                Share.share('Watch "${widget.video.title}" on CoinNewsExtra: $url');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(color: Colors.grey, height: 1),
                  
                  // Enhanced earn reward section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _rewardClaimed 
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFF006833).withOpacity(0.1),
                      border: Border.all(
                        color: _rewardClaimed 
                            ? Colors.green 
                            : const Color(0xFF006833),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _rewardClaimed ? Icons.check_circle : Icons.monetization_on,
                              color: _rewardClaimed ? Colors.green : const Color(0xFF006833),
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _rewardClaimed ? 'Reward Claimed!' : 'Watch & Earn',
                                    style: TextStyle(
                                      color: _rewardClaimed ? Colors.green : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_rewardClaimed)
                                    Text(
                                      'You earned 5.0 CNE tokens!',
                                      style: TextStyle(
                                        color: Colors.green[300],
                                        fontSize: 14,
                                        fontFamily: 'Lato',
                                      ),
                                    )
                                  else
                                    Text(
                                      'Earn 5.0 CNE tokens for watching this video',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_rewardClaimed) ...[
                          const SizedBox(height: 16),
                          _buildWatchProgress(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _canClaimReward() ? _claimReward : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canClaimReward() 
                                    ? const Color(0xFF006833) 
                                    : Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isClaimingReward
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Claim Reward',
                                      style: TextStyle(
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
                  
                  // Description section
                  GestureDetector(
                    onTap: () => setState(() => _showDescription = !_showDescription),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              Icon(
                                _showDescription ? Icons.expand_less : Icons.expand_more,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          if (_showDescription) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.video.description ?? 'Watch this educational cryptocurrency and blockchain content to learn about the latest trends, market analysis, and technology insights. Earn CNE tokens for watching and engaging with quality content.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.4,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Ads section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Sponsored Content',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: AdsCarousel(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF006833) : Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF006833) : Colors.white,
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  // Check if reward can be claimed
  bool _canClaimReward() {
    if (_rewardClaimed) return false;
    const requiredWatchPercentage = 0.25;
    final actualWatchPercentage = _videoDuration.inSeconds > 0
        ? _currentPosition.inSeconds / _videoDuration.inSeconds
        : 0.0;
    return actualWatchPercentage >= requiredWatchPercentage;
  }

  // Build watch progress indicator
  Widget _buildWatchProgress() {
    const requiredWatchPercentage = 0.25;
    final actualWatchPercentage = _videoDuration.inSeconds > 0
        ? _currentPosition.inSeconds / _videoDuration.inSeconds
        : 0.0;
    final percentageProgress = actualWatchPercentage / requiredWatchPercentage;
    final progress = percentageProgress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? const Color(0xFF006833) : Colors.orange,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: progress >= 1.0 ? const Color(0xFF006833) : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(progress * 100).toInt()}%',
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
        const SizedBox(height: 8),
        Text(
          progress >= 1.0 
              ? 'Ready to claim your reward!' 
              : 'Watch ${((requiredWatchPercentage - actualWatchPercentage) * 100).toInt()}% more',
          style: TextStyle(
            color: progress >= 1.0 ? const Color(0xFF006833) : Colors.grey[400],
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }
}