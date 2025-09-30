import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:feather_icons/feather_icons.dart';
import '../services/reward_service.dart';
import '../services/user_balance_service.dart';
import '../provider/admin_provider.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  final String title;
  final String channelName;
  final String views;
  final String uploadTime;
  final double reward;

  const VideoPlayerPage({
    super.key,
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.views,
    required this.uploadTime,
    required this.reward,
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
  int _watchedSeconds = 0;
  bool _rewardClaimed = false;
  bool _isClaimingReward = false;
  double _currentRewardAmount = 0.0;
  
  // Watch progress tracking
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  // Sample recommended videos
  final List<Map<String, dynamic>> _recommendedVideos = [
    {
      'title': 'Cryptocurrency Market Update',
      'channelName': 'Crypto News',
      'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      'views': '15K views',
      'uploadTime': '4 hours ago',
      'duration': '10:30',
    },
    {
      'title': 'Blockchain Technology Explained',
      'channelName': 'Tech Edu',
      'thumbnail': 'https://img.youtube.com/vi/oHg5SJYRHA0/maxresdefault.jpg',
      'views': '32K views',
      'uploadTime': '1 day ago',
      'duration': '15:45',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _loadCurrentRewardAmount();
    _startWatchTracking();
  }

  void _initializeVideoPlayer() {
    // Use a default YouTube video ID for demo
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId.isNotEmpty ? widget.videoId : 'M7lc1UVf-VE',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    // Listen to player events
    _controller.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      final duration = _controller.metadata.duration;
      final position = _controller.value.position;
      
      setState(() {
        _videoDuration = duration;
        _currentPosition = position;
      });
      
      // Check if reward should be enabled (watched at least 70%)
      if (!_rewardClaimed && _videoDuration.inSeconds > 0) {
        final watchPercentage = _currentPosition.inSeconds / _videoDuration.inSeconds;
        if (watchPercentage >= 0.7) {
          setState(() {
            // Reward is now claimable
          });
        }
      }
    }
  }

  void _startWatchTracking() {
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        _watchedSeconds++;
      }
    });
  }

  Future<void> _loadCurrentRewardAmount() async {
    final balanceService = Provider.of<UserBalanceService>(context, listen: false);
    setState(() {
      _currentRewardAmount = balanceService.rewardAmounts.videoReward;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    _watchTimer?.cancel();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_rewardClaimed || _isClaimingReward) return;

    // Check if watched enough (at least 30 seconds OR 70% of video)
    final minWatchTime = 30;
    final requiredWatchPercentage = 0.7;
    final actualWatchPercentage = _videoDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _videoDuration.inSeconds 
        : 0.0;

    // Must meet 30 second minimum OR 70% watch requirement
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
      final result = await RewardService.claimVideoReward(
        videoId: widget.videoId,
        watchDurationSeconds: _watchedSeconds,
        totalDurationSeconds: _videoDuration.inSeconds,
      );

      if (result.success) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim({
          'success': result.success,
          'reward': result.reward,
          'message': result.message,
        });

        setState(() {
          _rewardClaimed = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video reward claimed! +${result.reward?.toStringAsFixed(2) ?? '0.00'} CNE'),
            backgroundColor: const Color(0xFF006833),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cast feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon!')),
              );
            },
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
            bottomActions: [
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              const PlaybackSpeedButton(),
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
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.views} • ${widget.uploadTime}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              label: '2.5K',
                              onTap: () => setState(() => {
                                _isLiked = !_isLiked,
                                if (_isLiked) _isDisliked = false,
                              }),
                              isActive: _isLiked,
                            ),
                            _buildActionButton(
                              icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              label: 'Dislike',
                              onTap: () => setState(() => {
                                _isDisliked = !_isDisliked,
                                if (_isDisliked) _isLiked = false,
                              }),
                              isActive: _isDisliked,
                            ),
                            _buildActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Share feature coming soon!')),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.download_outlined,
                              label: 'Download',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Download feature coming soon!')),
                                );
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
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _rewardClaimed 
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFF006833).withOpacity(0.1),
                      border: Border.all(
                        color: _rewardClaimed 
                            ? Colors.green 
                            : const Color(0xFF006833)
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
                                ),
                              ),
                              if (_rewardClaimed)
                                Text(
                                  'You earned ${_currentRewardAmount.toStringAsFixed(1)} CNE tokens!',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontSize: 14,
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Earn ${_currentRewardAmount.toStringAsFixed(1)} CNE tokens',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildWatchProgress(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (_rewardClaimed)
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
                          )
                        else
                          ElevatedButton(
                            onPressed: _canClaimReward() ? _claimReward : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canClaimReward() 
                                  ? const Color(0xFF006833) 
                                  : Colors.grey[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                                : const Text('Claim'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description section
                  GestureDetector(
                    onTap: () => setState(() => _showDescription = !_showDescription),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                _showDescription ? Icons.expand_less : Icons.expand_more,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          if (_showDescription) ...[
                            const SizedBox(height: 8),
                            Text(
                              'This is a sample description for the video. In a real app, this would contain the actual video description with details about the content, links, and other relevant information.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Recommended videos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Recommended',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Recommended video list
                  ...(_recommendedVideos.map((video) => _buildRecommendedVideoCard(video)).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (!adminProvider.isAdmin) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () => _showAdminMenu(context),
            backgroundColor: const Color(0xFF006833),
            child: const Icon(FeatherIcons.settings, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Video Admin Panel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006833),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildAdminOption(
                      icon: FeatherIcons.edit3,
                      title: 'Edit Video URL',
                      subtitle: 'Update the current video link',
                      onTap: () => _showEditVideoDialog(context),
                    ),
                    _buildAdminOption(
                      icon: FeatherIcons.plus,
                      title: 'Add New Video',
                      subtitle: 'Add a new video to recommendations',
                      onTap: () => _showAddVideoDialog(context),
                    ),
                    _buildAdminOption(
                      icon: FeatherIcons.barChart2,
                      title: 'View Analytics',
                      subtitle: 'Check video watch statistics',
                      onTap: () => _showVideoAnalytics(context),
                    ),
                    _buildAdminOption(
                      icon: FeatherIcons.settings,
                      title: 'Video Settings',
                      subtitle: 'Configure video parameters',
                      onTap: () => _showVideoSettings(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF006833)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showEditVideoDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController(text: widget.videoId);
    final TextEditingController titleController = TextEditingController(text: widget.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Video', style: TextStyle(color: Color(0xFF006833))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Video Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement video update logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video updated successfully!')),
              );
              Navigator.pop(context);
              Navigator.pop(context); // Close admin menu too
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006833)),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddVideoDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController channelController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Video', style: TextStyle(color: Color(0xFF006833))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Video Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: channelController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                // TODO: Implement add video logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Video "${titleController.text}" added successfully!')),
                );
                Navigator.pop(context);
                Navigator.pop(context); // Close admin menu too
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006833)),
            child: const Text('Add Video', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVideoAnalytics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Analytics', style: TextStyle(color: Color(0xFF006833))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticRow('Total Views', '1,234'),
            _buildAnalyticRow('Average Watch Time', '3:45'),
            _buildAnalyticRow('Completion Rate', '68%'),
            _buildAnalyticRow('Rewards Claimed', '45'),
            _buildAnalyticRow('Today\'s Views', '89'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Color(0xFF006833))),
        ],
      ),
    );
  }

  void _showVideoSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Settings', style: TextStyle(color: Color(0xFF006833))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-play Next Video'),
              value: true,
              onChanged: (value) {
                // TODO: Implement setting logic
              },
              activeColor: const Color(0xFF006833),
            ),
            SwitchListTile(
              title: const Text('Track Watch Time'),
              value: true,
              onChanged: (value) {
                // TODO: Implement setting logic
              },
              activeColor: const Color(0xFF006833),
            ),
            SwitchListTile(
              title: const Text('Allow Comments'),
              value: false,
              onChanged: (value) {
                // TODO: Implement setting logic
              },
              activeColor: const Color(0xFF006833),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved!')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006833)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedVideoCard(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 120,
              height: 68,
              child: Stack(
                children: [
                  Image.network(
                    video['thumbnail'],
                    fit: BoxFit.cover,
                    width: 120,
                    height: 68,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        video['duration'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Video info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video['channelName'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${video['views']} • ${video['uploadTime']}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Check if reward can be claimed
  bool _canClaimReward() {
    if (_rewardClaimed) return false;
    
    final minWatchTime = 30; // seconds
    final requiredWatchPercentage = 0.7;
    final actualWatchPercentage = _videoDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _videoDuration.inSeconds 
        : 0.0;

    return _watchedSeconds >= minWatchTime || actualWatchPercentage >= requiredWatchPercentage;
  }

  // Build watch progress indicator
  Widget _buildWatchProgress() {
    final minWatchTime = 30;
    final requiredWatchPercentage = 0.7;
    final actualWatchPercentage = _videoDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _videoDuration.inSeconds 
        : 0.0;

    // Use the higher of time-based or percentage-based progress
    final timeProgress = (_watchedSeconds / minWatchTime).clamp(0.0, 1.0);
    final percentageProgress = actualWatchPercentage / requiredWatchPercentage;
    final progress = timeProgress > percentageProgress ? timeProgress : percentageProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[600],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? const Color(0xFF006833) : Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: progress >= 1.0 ? const Color(0xFF006833) : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0 
              ? 'Ready to claim!' 
              : 'Watch ${(minWatchTime - _watchedSeconds).clamp(0, minWatchTime)}s more or ${((requiredWatchPercentage - actualWatchPercentage) * 100).toInt()}% more',
          style: TextStyle(
            color: progress >= 1.0 ? const Color(0xFF006833) : Colors.grey[400],
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
