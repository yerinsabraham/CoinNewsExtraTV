import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerAdWidget extends StatelessWidget {
  final String position; // 'top', 'mid', 'footer', 'inline'
  final double? height;
  final EdgeInsets? margin;

  const BannerAdWidget({
    super.key,
    required this.position,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? _getDefaultHeight(),
      margin: margin ?? _getDefaultMargin(),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Banner Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF006833).withOpacity(0.1),
                    Colors.grey[900]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Banner Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Ad Icon/Logo placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006833).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: Color(0xFF006833),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Ad Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getBannerTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getBannerDescription(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontFamily: 'Lato',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // CTA Button
                  GestureDetector(
                    onTap: _handleBannerTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006833),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Learn More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getDefaultHeight() {
    switch (position) {
      case 'top':
      case 'mid':
        return 70;
      case 'footer':
        return 40;
      case 'inline':
        return 80;
      default:
        return 70;
    }
  }

  EdgeInsets _getDefaultMargin() {
    // If custom margin is provided, use it
    if (margin != null) return margin!;
    
    switch (position) {
      case 'top':
        return const EdgeInsets.only(left: 16, right: 16, bottom: 12);
      case 'mid':
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case 'footer':
        return const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0); // Removed bottom margin to prevent overflow
      case 'inline':
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
      default:
        return const EdgeInsets.all(16);
    }
  }

  String _getBannerTitle() {
    switch (position) {
      case 'top':
        return 'Earn Crypto Rewards Daily';
      case 'mid':
        return 'Premium Trading Signals';
      case 'footer':
        return 'Join Our VIP Community';
      case 'inline':
        return 'Exclusive Trading Course';
      default:
        return 'Special Crypto Offer';
    }
  }

  String _getBannerDescription() {
    switch (position) {
      case 'top':
        return 'Watch videos & earn tokens. Start your journey now!';
      case 'mid':
        return 'Get 95% accurate trading signals from experts';
      case 'footer':
        return 'Connect with 10K+ crypto enthusiasts';
      case 'inline':
        return 'Master crypto trading with our comprehensive course';
      default:
        return 'Limited time offer - Don\'t miss out!';
    }
  }

  void _handleBannerTap() async {
    // Sample URLs for different banner types
    const urls = {
      'top': 'https://www.youtube.com/watch?v=p4kmPtTU4lw',
      'mid': 'https://coinmarketcap.com',
      'footer': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'inline': 'https://www.youtube.com/watch?v=L_jWHffIx5E',
    };

    final url = urls[position] ?? 'https://coinmarketcap.com';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
