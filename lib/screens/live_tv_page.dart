import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:feather_icons/feather_icons.dart';

class LiveTvPage extends StatefulWidget {
  const LiveTvPage({super.key});

  @override
  State<LiveTvPage> createState() => _LiveTvPageState();
}

class _LiveTvPageState extends State<LiveTvPage> with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late TabController _tabController;
  
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
    
    // Initialize YouTube player with the livestream URL
    final videoId = YoutubePlayer.convertUrlToId('https://www.youtube.com/live/HwHP5WojgBg?si=Eaoja0H3P0veWfOt');
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? 'HwHP5WojgBg', // Specific livestream ID
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        isLive: true,
        forceHD: false,
        enableCaption: true,
      ),
    );
    
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
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
        title: Row(
          children: [
            Container(
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
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CNETV Live',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.white,
            ),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: Column(
        children: [
          // YouTube Player
          YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF006833),
              bottomActions: [
                CurrentPosition(),
                ProgressBar(
                  isExpanded: true,
                  colors: const ProgressBarColors(
                    playedColor: Color(0xFF006833),
                    handleColor: Color(0xFF006833),
                  ),
                ),
                PlaybackSpeedButton(),
              ],
            ),
            builder: (context, player) => player,
          ),
          
          // Live stream info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crypto Market Analysis & News',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            FeatherIcons.eye,
                            color: Colors.grey[400],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$viewerCount viewers',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likeCount likes',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'Lato',
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
          
          // Tabs for Comments and Polls
          Container(
            color: Colors.grey[900],
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF006833),
              labelColor: const Color(0xFF006833),
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(fontSize: 12, fontFamily: 'Lato'),
              tabs: const [
                Tab(
                  icon: Icon(FeatherIcons.messageSquare, size: 16),
                  text: 'Chat',
                ),
                Tab(
                  icon: Icon(FeatherIcons.barChart, size: 16),
                  text: 'Polls',
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommentsSection(),
                _buildPollsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[comments.length - 1 - index];
                return _buildCommentItem(comment);
              },
            ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF006833),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      // Handle send comment
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comment sent!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(LiveComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.username,
                style: const TextStyle(
                  color: Color(0xFF006833),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              const Spacer(),
              Text(
                comment.timestamp,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsSection() {
    final totalVotes = pollResults.values.fold(0, (sum, votes) => sum + votes);
    
    return Container(
      color: Colors.black,
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
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Do you think Bitcoin will cross \$100K this year?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Poll Options
                ...pollResults.entries.map((entry) {
                  final option = entry.key;
                  final votes = entry.value;
                  final percentage = totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
                  final isSelected = selectedPollOption == option;
                  
                  return GestureDetector(
                    onTap: () => _votePoll(option),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? const Color(0xFF006833).withOpacity(0.2)
                          : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                          ? Border.all(color: const Color(0xFF006833))
                          : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF006833) : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[700],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected ? const Color(0xFF006833) : Colors.grey[500]!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 12),
                Text(
                  '$totalVotes total votes',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      if (isLiked) {
        likeCount--;
        isLiked = false;
      } else {
        likeCount++;
        isLiked = true;
      }
    });
  }

  void _votePoll(String option) {
    setState(() {
      if (selectedPollOption != null) {
        pollResults[selectedPollOption!] = pollResults[selectedPollOption]! - 1;
      }
      
      selectedPollOption = option;
      pollResults[option] = pollResults[option]! + 1;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voted for: $option'),
        duration: const Duration(seconds: 2),
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
    this.isLiked = false,
  });
}
