import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  bool _isSubscribed = false;
  bool _showDescription = false;

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
    // Use a default YouTube video ID for demo
    _controller = YoutubePlayerController(
      initialVideoId: 'p4kmPtTU4lw', // Default video for demo
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _claimReward() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Congratulations! You earned \$${widget.reward.toStringAsFixed(1)}!'),
        backgroundColor: const Color(0xFF006833),
      ),
    );
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
                  // Channel info and subscribe
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF006833),
                          child: Text(
                            widget.channelName.isNotEmpty ? widget.channelName[0].toUpperCase() : 'C',
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
                                widget.channelName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '125K subscribers',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => _isSubscribed = !_isSubscribed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSubscribed ? Colors.grey[700] : const Color(0xFF006833),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(_isSubscribed ? 'Subscribed' : 'Subscribe'),
                        ),
                      ],
                    ),
                  ),
                  // Earn reward section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006833).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFF006833)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFF006833),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Watch & Earn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Complete this video to earn \$${widget.reward.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006833),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Claim'),
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
}
