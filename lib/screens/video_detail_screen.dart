import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../data/video_data.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String channelName;
  
  const VideoDetailScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.channelName,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late YoutubePlayerController _controller;
  bool _isLiked = false;
  bool _isDisliked = false;
  List<VideoModel> _recommendedVideos = [];
  bool _loadingRecommended = true;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        showLiveFullscreenButton: false,
      ),
    );
    _loadRecommendedVideos();
  }

  Future<void> _loadRecommendedVideos() async {
    try {
      setState(() => _loadingRecommended = true);
      
      // Get all videos from database
      final allVideos = await VideoData.getVideosFromDatabase();
      
      // Filter out current video and take first 4 as recommended
      final recommended = allVideos
          .where((video) => video.youtubeId != widget.videoId)
          .take(4)
          .toList();
      
      setState(() {
        _recommendedVideos = recommended;
        _loadingRecommended = false;
      });
    } catch (e) {
      print('❌ Error loading recommended videos: $e');
      setState(() => _loadingRecommended = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF006833),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'CoinNewsExtra TV',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video player
                player,
                
                // Video details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video title
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
                      
                      // Channel info and stats
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF006833),
                            child: Text(
                              widget.channelName[0].toUpperCase(),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                                Text(
                                  '125K subscribers',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Subscribed!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006833),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Subscribe',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            label: '1.2K',
                            isActive: _isLiked,
                            onTap: () {
                              setState(() {
                                _isLiked = !_isLiked;
                                if (_isLiked && _isDisliked) {
                                  _isDisliked = false;
                                }
                              });
                            },
                          ),
                          _buildActionButton(
                            icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                            label: 'Dislike',
                            isActive: _isDisliked,
                            onTap: () {
                              setState(() {
                                _isDisliked = !_isDisliked;
                                if (_isDisliked && _isLiked) {
                                  _isLiked = false;
                                }
                              });
                            },
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
                            label: 'Save',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Video saved!')),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Video description
                      Container(
                        width: double.infinity,
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
                                  '15K views',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '2 hours ago',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Watch and earn crypto rewards! This video covers the latest market analysis and trading strategies. Don\'t forget to like and subscribe for more crypto content.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 13,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Comments section
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Comment input
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF006833),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[600]!),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF006833)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sample comments
                      _buildComment(
                        'CryptoExpert',
                        'Great analysis! Bitcoin to the moon 🚀',
                        '2 hours ago',
                      ),
                      _buildComment(
                        'TraderJoe',
                        'Thanks for the insights. Very helpful content.',
                        '1 hour ago',
                      ),
                      _buildComment(
                        'Blockchain_Fan',
                        'Can you make a video about DeFi next?',
                        '45 minutes ago',
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Recommended videos section
                      const Text(
                        'Recommended Videos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recommended videos list
                      _buildRecommendedVideos(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF006833).withOpacity(0.2) : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF006833) : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF006833) : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF006833) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(String username, String comment, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF006833),
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
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

  Widget _buildRecommendedVideos() {
    if (_loadingRecommended) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: Color(0xFF006833),
          ),
        ),
      );
    }

    if (_recommendedVideos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No recommended videos available',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontFamily: 'Lato',
          ),
        ),
      );
    }

    return Column(
      children: _recommendedVideos.map((video) => _buildRecommendedVideoItem(video)).toList(),
    );
  }

  Widget _buildRecommendedVideoItem(VideoModel video) {
    return GestureDetector(
      onTap: () {
        // Navigate to the new video
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailScreen(
              videoId: video.youtubeId,
              title: video.title,
              channelName: video.channelName ?? 'CoinNews Extra',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 120,
                height: 68,
                color: Colors.grey[800],
                child: Image.network(
                  video.youtubeThumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                        size: 30,
                      ),
                    );
                  },
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
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                      fontSize: 12,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        video.views ?? '0 views',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        video.uploadTime ?? '',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Duration badge
            if (video.duration != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.duration!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
