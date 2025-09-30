import 'package:flutter/material.dart';
import '../widgets/video_card.dart';
import 'video_player_page.dart';
import '../data/video_data.dart';
import '../models/video_model.dart';

class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({super.key});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  // Use centralized video data source
  List<VideoModel> get _sampleVideos => VideoData.getAllVideos();

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
              title: video.title,
              channelName: video.channelName ?? 'CoinNews Extra',
              thumbnail: video.youtubeThumbnailUrl,
              views: video.views,
              uploadTime: video.uploadTime,
              duration: video.duration,
              reward: video.reward,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      videoId: video.youtubeId,
                      title: video.title,
                      channelName: video.channelName ?? 'CoinNews Extra',
                      views: video.views,
                      uploadTime: video.uploadTime,
                      reward: video.reward,
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