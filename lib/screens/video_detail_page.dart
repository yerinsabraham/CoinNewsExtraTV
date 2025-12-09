import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:feather_icons/feather_icons.dart';
import '../models/video_model.dart';
import '../services/user_balance_service.dart';

class VideoDetailPage extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onRewardClaimed;

  const VideoDetailPage({
    super.key,
    required this.video,
    this.onRewardClaimed,
  });

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late YoutubePlayerController _controller;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _showDescription = false;
  int _likeCount = 2534;
  int _dislikeCount = 89;
  
  // Reward tracking
  Timer? _watchTimer;
  int _watchedSeconds = 0;
  bool _rewardClaimed = false;
  bool _isClaimingReward = false;
  
  // Watch progress tracking
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  // Comments data
  final List<VideoComment> _comments = [
    VideoComment(
      username: 'CryptoKing',
      message: 'Great analysis! Really helpful for understanding market trends.',
      timestamp: '2 hours ago',
      likes: 45,
      isLiked: false,
      avatar: 'C',
    ),
    VideoComment(
      username: 'BlockchainBella',
      message: 'This channel always provides quality content 🚀',
      timestamp: '3 hours ago',
      likes: 32,
      isLiked: true,
      avatar: 'B',
    ),
    VideoComment(
      username: 'TechTrader99',
      message: 'Can you do more videos on DeFi protocols? Love your explanations!',
      timestamp: '4 hours ago',
      likes: 28,
      isLiked: false,
      avatar: 'T',
    ),
    VideoComment(
      username: 'HODLmaster',
      message: 'Perfect timing with this video! Market is so volatile right now.',
      timestamp: '5 hours ago',
      likes: 19,
      isLiked: false,
      avatar: 'H',
    ),
  ];

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _startWatchTracking();
  }

  void _initializeVideoPlayer() {
    String videoId = widget.video.youtubeId.trim();
    
    // Validate and extract video ID
    if (videoId.isEmpty && widget.video.url != null && widget.video.url!.isNotEmpty) {
      final extractedId = YoutubePlayer.convertUrlToId(widget.video.url!);
      if (extractedId != null && extractedId.isNotEmpty) {
        videoId = extractedId;
      }
    }
    
    // Use fallback if still empty
    if (videoId.isEmpty) {
      videoId = 'dQw4w9WgXcQ'; // Fallback: popular video
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading video (Error ${_controller.value.errorCode}). Please check your internet connection.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
      
      // Debug logging
      if (_controller.value.isPlaying) {
        debugPrint('▶️ Video playing - Position: ${position.inSeconds}s / ${duration.inSeconds}s');
      }
    }
  }

  void _startWatchTracking() {
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        setState(() {
          _watchedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    _watchTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_rewardClaimed || _isClaimingReward) return;

    // Check if watched enough (at least 30 seconds OR 70% of video)
    const minWatchTime = 30;
    const requiredWatchPercentage = 0.7;
    final actualWatchPercentage = _videoDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _videoDuration.inSeconds 
        : 0.0;

    if (_watchedSeconds < minWatchTime && actualWatchPercentage < requiredWatchPercentage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watch at least 30 seconds or 70% of the video to claim your reward!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isClaimingReward = true;
    });

    try {
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(widget.video.reward, 'Video watched: ${widget.video.title}');

      setState(() {
        _rewardClaimed = true;
        _isClaimingReward = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Earned ${widget.video.reward} CNE for watching video!'),
            backgroundColor: const Color(0xFF006833),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      widget.onRewardClaimed?.call();
    } catch (e) {
      setState(() {
        _isClaimingReward = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _canClaimReward() {
    if (_rewardClaimed) return false;
    
    const minWatchTime = 30; // seconds
    const requiredWatchPercentage = 0.7;
    final actualWatchPercentage = _videoDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _videoDuration.inSeconds 
        : 0.0;

    return _watchedSeconds >= minWatchTime || actualWatchPercentage >= requiredWatchPercentage;
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
          'Video Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showMoreOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player
          Stack(
            children: [
              YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF006833),
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFF006833),
                  handleColor: Color(0xFF006833),
                ),
                bottomActions: [
                  CurrentPosition(),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  const PlaybackSpeedButton(),
                ],
              ),
              // Loading indicator overlay
              if (!_controller.value.isReady && !_controller.value.hasError)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                    ),
                  ),
                ),
              // Error state display
              if (_controller.value.hasError)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading video\nError Code: ${_controller.value.errorCode}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _controller.load(_controller.initialVideoId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006833),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Video Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Views and upload time
                        Text(
                          '${widget.video.views ?? '${widget.video.viewCount ?? 0} views'} • ${widget.video.uploadTime ?? 'Recently uploaded'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Action Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              label: _likeCount.toString(),
                              onTap: () {
                                setState(() {
                                  if (_isLiked) {
                                    _likeCount--;
                                    _isLiked = false;
                                  } else {
                                    _likeCount++;
                                    _isLiked = true;
                                    if (_isDisliked) {
                                      _dislikeCount--;
                                      _isDisliked = false;
                                    }
                                  }
                                });
                              },
                              isActive: _isLiked,
                            ),
                            _buildActionButton(
                              icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              label: _dislikeCount.toString(),
                              onTap: () {
                                setState(() {
                                  if (_isDisliked) {
                                    _dislikeCount--;
                                    _isDisliked = false;
                                  } else {
                                    _dislikeCount++;
                                    _isDisliked = true;
                                    if (_isLiked) {
                                      _likeCount--;
                                      _isLiked = false;
                                    }
                                  }
                                });
                              },
                              isActive: _isDisliked,
                            ),
                            _buildActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Share link copied to clipboard!')),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.download_outlined,
                              label: 'Save',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Video saved to watch later!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(color: Colors.grey, height: 1),
                  
                  // Earn Reward Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _rewardClaimed 
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFF006833).withOpacity(0.1),
                      border: Border.all(
                        color: _rewardClaimed 
                            ? Colors.green 
                            : const Color(0xFF006833),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _rewardClaimed ? Icons.check_circle : Icons.monetization_on,
                          color: _rewardClaimed ? Colors.green : const Color(0xFF006833),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _rewardClaimed ? 'Reward Claimed!' : 'Watch & Earn',
                                style: TextStyle(
                                  color: _rewardClaimed ? Colors.green : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              if (_rewardClaimed)
                                Text(
                                  'You earned ${widget.video.reward} CNE tokens!',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontSize: 14,
                                    fontFamily: 'Lato',
                                  ),
                                )
                              else
                                Text(
                                  'Earn ${widget.video.reward} CNE tokens by watching',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!_rewardClaimed)
                          ElevatedButton(
                            onPressed: _canClaimReward() ? _claimReward : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canClaimReward() ? const Color(0xFF006833) : Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: _isClaimingReward
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _canClaimReward() ? 'Claim' : 'Keep Watching',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Claimed',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Channel Info (expandable description)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF006833),
                              child: Text(
                                widget.video.channelName?.isNotEmpty == true 
                                    ? widget.video.channelName![0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.video.channelName ?? 'CoinNews Extra',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  Text(
                                    '1.2K subscribers',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Subscribed!')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF006833)),
                              ),
                              child: const Text(
                                'Subscribe',
                                style: TextStyle(
                                  color: Color(0xFF006833),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.video.description != null) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showDescription = !_showDescription;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.video.description!,
                                    maxLines: _showDescription ? null : 2,
                                    overflow: _showDescription ? null : TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _showDescription ? 'Show less' : 'Show more',
                                    style: const TextStyle(
                                      color: Color(0xFF006833),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Comments Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Comments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_comments.length})',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Add Comment Input
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF006833),
                              child: Text(
                                'Y',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(color: Colors.grey[600]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(color: Colors.grey[600]!),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(20)),
                                    borderSide: BorderSide(color: Color(0xFF006833)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.send, color: Color(0xFF006833)),
                                    onPressed: _addComment,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Comments List
                        ..._comments.map((comment) => _buildCommentItem(comment)).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80), // Bottom padding
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

  Widget _buildCommentItem(VideoComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF006833),
            child: Text(
              comment.avatar,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timestamp,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.message,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          comment.isLiked = !comment.isLiked;
                          if (comment.isLiked) {
                            comment.likes++;
                          } else {
                            comment.likes--;
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: comment.isLiked ? const Color(0xFF006833) : Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likes.toString(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reply feature coming soon!')),
                        );
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.insert(0, VideoComment(
          username: 'You',
          message: _commentController.text.trim(),
          timestamp: 'Just now',
          likes: 0,
          isLiked: false,
          avatar: 'Y',
        ));
      });
      _commentController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added!'),
          backgroundColor: Color(0xFF006833),
        ),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video reported')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text('Block Channel', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Channel blocked')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('Video Info', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showVideoInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Video Information', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Video ID', widget.video.youtubeId),
            _buildInfoRow('Duration', '${(widget.video.durationSeconds / 60).floor()}:${(widget.video.durationSeconds % 60).toString().padLeft(2, '0')}'),
            _buildInfoRow('Reward', '${widget.video.reward} CNE'),
            _buildInfoRow('Channel', widget.video.channelName ?? 'Unknown'),
            if (widget.video.publishedAt != null)
              _buildInfoRow('Published', widget.video.publishedAt!.toLocal().toString().split(' ')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF006833))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoComment {
  final String username;
  final String message;
  final String timestamp;
  int likes;
  bool isLiked;
  final String avatar;

  VideoComment({
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likes,
    required this.isLiked,
    required this.avatar,
  });
}