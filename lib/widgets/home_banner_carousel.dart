import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/video_detail_screen.dart';
import '../services/youtube_thumbnail_service.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _currentIndex = 0;
  final PageController _controller = PageController();
  Timer? _timer;

  // Sample YouTube video IDs - replace with actual video data from backend
  final List<Map<String, String>> _featuredVideos = [
    {
      'id': 'M7lc1UVf-VE',
      'title': 'Bitcoin Breaking \$100K? Market Analysis',
      'channel': 'CoinNewsExtra'
    },
    {
      'id': '3jDhvKczYdQ', 
      'title': 'Ethereum 2.0 Complete Guide',
      'channel': 'Crypto Education'
    },
    {
      'id': 'kRuZKg3j4Ks',
      'title': 'Top 10 Altcoins for 2025', 
      'channel': 'CoinNewsExtra'
    },
    {
      'id': '3Kf8Od6nIQM',
      'title': 'DeFi Explained: Complete Beginner Guide',
      'channel': 'DeFi Academy'
    },
    {
      'id': '5-year-old-earns-6-figures-trading-stocks',
      'title': 'NFT Market Trends & Analysis',
      'channel': 'NFT Insights'
    },
  ];

  // Removed _getYoutubeThumbnail - now using YouTubeThumbnailService

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < _featuredVideos.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _controller.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: _featuredVideos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final video = _featuredVideos[index];
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: YouTubeThumbnailService.buildThumbnailWidget(
                    videoId: video['id']!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: video['title']!,
                    child: Stack(
                      children: [
                        // Dark gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        
                        // Play button overlay
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                        
                        // Video info at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Lato',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  video['channel']!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Tap detector
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoDetailScreen(
                                      videoId: video['id']!,
                                      title: video['title']!,
                                      channelName: video['channel']!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
                ),
              );
            },
          ),
        ),
        
        // Carousel indicators
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _featuredVideos.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(
                entry.key,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key 
                      ? const Color(0xFF006833)
                      : Colors.grey.withOpacity(0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
