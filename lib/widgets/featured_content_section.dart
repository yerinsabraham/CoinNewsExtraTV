import 'package:flutter/material.dart';
import '../data/video_data.dart';

class FeaturedContentSection extends StatelessWidget {
  const FeaturedContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/youtube');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF006833),
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeaturedContent(context),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent(BuildContext context) {
    // Get featured videos from data
    final videos = VideoData.getCarouselVideos();
    if (videos.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No featured content available',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Lato',
            ),
          ),
        ),
      );
    }

    final featuredVideo = videos.first;
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Image.network(
              featuredVideo.thumbnailUrl ?? '',
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 160,
                  height: 120,
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    featuredVideo.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006833),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFF006833),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '5 CNE',
                        style: TextStyle(
                          color: Color(0xFF006833),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.play_arrow,
              color: Color(0xFF006833),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}