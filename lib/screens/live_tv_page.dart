import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/live_video_config.dart';
import '../services/user_balance_service.dart';

class LiveTvPage extends StatefulWidget {
  const LiveTvPage({super.key});

  @override
  State<LiveTvPage> createState() => _LiveTvPageState();
}

class _LiveTvPageState extends State<LiveTvPage> with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late TabController _tabController;
  
  // Watch time tracking
  Timer? _watchTimer;
  int _watchTimeSeconds = 0;
  bool _isWatching = false;
  bool _hasClaimedReward = false;
  bool _isClaimingReward = false;
  bool _hasStartedPlaying = false;
  
  // Poll state management
  String? selectedPollOption;
  Map<String, int> pollResults = {
    'Yes': 245,
    'No': 89,
    'Maybe': 156,
  };
  
  // Comments data
  List<LiveComment> comments = [
    LiveComment(
      username: 'CryptoMaster99',
      message: 'Bitcoin to the moon! 🚀',
      timestamp: '2 min ago',
      isLiked: false,
    ),
    LiveComment(
      username: 'BlockchainExpert',
      message: 'Great analysis on the market trends',
      timestamp: '5 min ago',
      isLiked: true,
    ),
    LiveComment(
      username: 'HODLer2024',
      message: 'When altcoin season? 🤔',
      timestamp: '8 min ago',
      isLiked: false,
    ),
    LiveComment(
      username: 'DeFiWarrior',
      message: 'Love this live stream format!',
      timestamp: '12 min ago',
      isLiked: true,
    ),
    LiveComment(
      username: 'SatoshiFan',
      message: 'Can you discuss Ethereum updates?',
      timestamp: '15 min ago',
      isLiked: false,
    ),
  ];
  
  bool isLiked = false;
  int likeCount = 1247;
  int viewerCount = 3421;

  @override
  void initState() {
    super.initState();
    
    // Initialize YouTube player with unified configuration
    _controller = YoutubePlayerController(
      initialVideoId: LiveVideoConfig.getVideoId(),
      flags: YoutubePlayerFlags(
        autoPlay: LiveVideoConfig.autoPlayOnLaunch,
        mute: false,
        isLive: LiveVideoConfig.isLiveStream,
        forceHD: false,
        enableCaption: LiveVideoConfig.enableCaptions,
      ),
    );
    
    // Listen to player state changes
    _controller.addListener(_onPlayerStateChanged);
    
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _stopWatching();
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    _tabController.dispose();
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
        !LiveVideoConfig.hasMetWatchRequirement(_watchTimeSeconds)) return;

    setState(() {
      _isClaimingReward = true;
    });

    try {
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(LiveVideoConfig.watchReward, 'Live TV Watch Reward');

      setState(() {
        _hasClaimedReward = true;
        _isClaimingReward = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Earned ${LiveVideoConfig.watchReward} CNE for watching live TV!'),
            backgroundColor: const Color(0xFF006833),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Live TV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
          // YouTube Video Player
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF006833),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFF006833),
              handleColor: Color(0xFF006833),
            ),
          ),
          
          // Video Info and Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Live Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        LiveVideoConfig.liveStreamTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$viewerCount viewers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  LiveVideoConfig.liveStreamDescription,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            likeCount--;
                            isLiked = false;
                          } else {
                            likeCount++;
                            isLiked = true;
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: isLiked ? const Color(0xFF006833) : Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            likeCount.toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Share Button
                    GestureDetector(
                      onTap: () {
                        // Share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share link copied to clipboard!'),
                            backgroundColor: Color(0xFF006833),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Watch Progress and Reward Button
                    if (LiveVideoConfig.hasMetWatchRequirement(_watchTimeSeconds))
                      ElevatedButton(
                        onPressed: _hasClaimedReward ? null : _claimWatchReward,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasClaimedReward ? Colors.grey : const Color(0xFF006833),
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
                                _hasClaimedReward ? 'Claimed!' : 'Claim ${LiveVideoConfig.watchReward} CNE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Watch ${LiveVideoConfig.formatWatchTime(LiveVideoConfig.getRemainingWatchTime(_watchTimeSeconds))} more',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            color: Colors.grey[900],
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF006833),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Chat'),
                Tab(text: 'Poll'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildPollTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF006833),
                        child: Text(
                          comment.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.username,
                                  style: const TextStyle(
                                    color: Color(0xFF006833),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comment.timestamp,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              comment.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            comment.isLiked = !comment.isLiked;
                          });
                        },
                        child: Icon(
                          comment.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: comment.isLiked ? Colors.red : Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Chat Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: Color(0xFF006833)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006833),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollTab() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Poll',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Will Bitcoin reach \$100K this month?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 20),
          
          // Poll Options
          ...pollResults.entries.map((entry) {
            final option = entry.key;
            final votes = entry.value;
            final totalVotes = pollResults.values.reduce((a, b) => a + b);
            final percentage = (votes / totalVotes * 100).round();
            final isSelected = selectedPollOption == option;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPollOption = option;
                    pollResults[option] = votes + 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF006833).withOpacity(0.3) : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF006833) : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                      Text(
                        '$percentage% ($votes)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class LiveComment {
  final String username;
  final String message;
  final String timestamp;
  bool isLiked;

  LiveComment({
    required this.username,
    required this.message,
    required this.timestamp,
    required this.isLiked,
  });
}