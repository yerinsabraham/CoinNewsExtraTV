import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/external_link_helper.dart';
import 'dart:async';
import '../data/video_data.dart';

class AdsCarousel extends StatefulWidget {
  final List<Map<String, String>>? extraBanners;

  const AdsCarousel({super.key, this.extraBanners});

  @override
  State<AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<AdsCarousel> {
  int _currentIndex = 0;
  final PageController _controller = PageController();
  Timer? _timer;

  // Use real ad data with video URLs
  List<Map<String, String>> get _bannerAds {
    final videos = VideoData.getAllVideos();
    return [
      // Extra banners injected by parent (e.g., special offers)
      if (widget.extraBanners != null) ...widget.extraBanners!,
      {
        'image': 'assets/images/ad1.png',
        'title': 'Exclusive Crypto Trading Course',
        'url': videos.isNotEmpty ? (videos[0].url ?? '') : '',
      },
      {
        'image': 'assets/images/ad2.png', 
        'title': 'Join Our Premium Community',
        'url': videos.length > 1 ? (videos[1].url ?? '') : '',
      },
      {
        'image': 'assets/images/ad3.png',
        'title': 'Earn 50% More Rewards',
        'url': videos.length > 2 ? (videos[2].url ?? '') : '',
      },
      {
        'image': 'assets/images/ad4.png',
        'title': 'Limited Time: Double Coins',
        'url': videos.length > 3 ? (videos[3].url ?? '') : '',
      },
      {
        'image': 'assets/images/ad5.png',
        'title': 'New Features Available',
        'url': videos.length > 4 ? (videos[4].url ?? '') : '',
      },
    ];
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feature coming soon!')),
      );
      return;
    }

    await launchUrlWithDisclaimer(context, urlString);
  }

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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < _bannerAds.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (mounted) {
        _controller.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Special Offers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ),
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: PageView.builder(
            controller: _controller,
            itemCount: _bannerAds.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _bannerAds[index];
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Banner image
                      Image.asset(
                        banner['image']!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF006833),
                                  const Color(0xFF006833).withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.campaign,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Lato',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Subtle gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tap detector
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _launchUrl(banner['url']!),
                            child: Container(),
                          ),
                        ),
                      ),
                    ],
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
          children: _bannerAds.asMap().entries.map((entry) {
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
