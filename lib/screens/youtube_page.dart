import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/external_link_helper.dart';
import '../services/user_balance_service.dart';
import '../data/video_data.dart';
import '../models/video_model.dart';

class YoutubePage extends StatefulWidget {
  const YoutubePage({super.key});

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  final List<VideoModel> videos = VideoData.getCarouselVideos();
  final Set<String> watchedVideos = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Earnings Info
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF006833),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Earn 5 CNE per video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  'Watched: ${watchedVideos.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
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
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: isWatched 
                      ? Border.all(color: const Color(0xFF006833), width: 2)
                      : Border.all(color: Colors.grey[800]!),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(video.youtubeThumbnailUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isWatched
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Color(0xFF006833),
                              size: 30,
                            ),
                          )
                        : null,
                    ),
                    title: Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          video.description ?? 'CoinNews Extra Content',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: 'Lato',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: isWatched ? Colors.grey : const Color(0xFF006833),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isWatched ? 'Earned' : '5 CNE',
                              style: TextStyle(
                                color: isWatched ? Colors.grey : const Color(0xFF006833),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      isWatched ? Icons.check_circle : Icons.play_arrow,
                      color: isWatched ? const Color(0xFF006833) : Colors.white,
                      size: 30,
                    ),
                    onTap: isWatched ? null : () => _watchVideo(video),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _watchVideo(VideoModel video) async {
    try {
      // Use the exact YouTube URL from the video data
      final String videoUrl = video.url ?? video.youtubeWatchUrl;
      final Uri youtubeUrl = Uri.parse(videoUrl);
      
      final launched = await launchUrlWithDisclaimer(context, videoUrl);
      if (launched) {
        
        // Mark as watched and give reward
        setState(() {
          watchedVideos.add(video.id);
        });
        
        // Add CNE reward
        if (mounted) {
          final balanceService = Provider.of<UserBalanceService>(context, listen: false);
          await balanceService.addBalance(5.0, 'Watched: ${video.title}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Earned 5 CNE for watching: ${video.title}'),
              backgroundColor: const Color(0xFF006833),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw 'Could not launch YouTube';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
