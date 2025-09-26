import 'package:flutter/material.dart';
import '../widgets/video_card.dart';
import 'video_player_page.dart';

class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({super.key});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  // Sample data for video cards
  final List<Map<String, dynamic>> _sampleVideos = [
    {
      'id': '1',
      'title': 'Bitcoin Price Analysis: What\'s Next for BTC?',
      'channelName': 'CoinNewsExtra',
      'thumbnail': 'https://img.youtube.com/vi/p4kmPtTU4lw/maxresdefault.jpg',
      'views': '25K views',
      'uploadTime': '2 hours ago',
      'duration': '12:30',
      'reward': 2.5,
    },
    {
      'id': '2',
      'title': 'Ethereum 2.0 Update: Complete Guide',
      'channelName': 'Crypto Education',
      'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      'views': '45K views',
      'uploadTime': '5 hours ago',
      'duration': '18:45',
      'reward': 3.0,
    },
    {
      'id': '3',
      'title': 'Top 5 Altcoins to Watch This Month',
      'channelName': 'Altcoin Daily',
      'thumbnail': 'https://img.youtube.com/vi/oHg5SJYRHA0/maxresdefault.jpg',
      'views': '12K views',
      'uploadTime': '1 day ago',
      'duration': '8:20',
      'reward': 1.5,
    },
    {
      'id': '4',
      'title': 'DeFi Explained: Beginner\'s Guide to Decentralized Finance',
      'channelName': 'DeFi University',
      'thumbnail': 'https://img.youtube.com/vi/RDxaVw3X74s/maxresdefault.jpg',
      'views': '78K views',
      'uploadTime': '3 days ago',
      'duration': '22:15',
      'reward': 4.0,
    },
    {
      'id': '5',
      'title': 'NFT Market Trends: What You Need to Know',
      'channelName': 'NFT Insider',
      'thumbnail': 'https://img.youtube.com/vi/kJQP7kiw5Fk/maxresdefault.jpg',
      'views': '33K views',
      'uploadTime': '1 week ago',
      'duration': '15:30',
      'reward': 2.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/logo48_dark.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'CoinNewsExtra TV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh functionality
          await Future.delayed(const Duration(seconds: 1));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feed refreshed!')),
          );
        },
        child: ListView.builder(
          itemCount: _sampleVideos.length,
          itemBuilder: (context, index) {
            final video = _sampleVideos[index];
            return VideoCard(
              title: video['title'],
              channelName: video['channelName'],
              thumbnail: video['thumbnail'],
              views: video['views'],
              uploadTime: video['uploadTime'],
              duration: video['duration'],
              reward: video['reward'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      videoId: video['id'],
                      title: video['title'],
                      channelName: video['channelName'],
                      views: video['views'],
                      uploadTime: video['uploadTime'],
                      reward: video['reward'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}