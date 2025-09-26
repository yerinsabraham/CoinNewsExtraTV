import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:feather_icons/feather_icons.dart';
import '../widgets/ads_carousel.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {
  
  // Social Media Links Configuration (Easily expandable by admin)
  final List<Map<String, dynamic>> _socialMediaLinks = [
    {
      'name': 'TikTok',
      'url': 'https://www.tiktok.com/@coinnewsextratv',
      'icon': FeatherIcons.music,
    },
    {
      'name': 'Telegram',
      'url': 'https://t.me/coinnewsextra',
      'icon': FeatherIcons.send,
    },
    {
      'name': 'YouTube',
      'url': 'https://youtube.com/@coinnewsextratv',
      'icon': FeatherIcons.youtube,
    },
    {
      'name': 'LinkedIn',
      'url': 'https://www.linkedin.com/company/coin-news-extra/',
      'icon': FeatherIcons.linkedin,
    },
    {
      'name': 'Facebook',
      'url': 'https://www.facebook.com/CoinNewsExtraTv',
      'icon': FeatherIcons.facebook,
    },
    {
      'name': 'X (Twitter)',
      'url': 'https://x.com/CoinNewsExtraTv',
      'icon': FeatherIcons.twitter,
    },
    {
      'name': 'Instagram',
      'url': 'https://www.instagram.com/coinnewsextratv',
      'icon': FeatherIcons.instagram,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Earn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earning summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006833), Color(0xFF005029)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$0.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '0 CNE Tokens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Earning Methods',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Earning methods grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3, // Increased to fix overflow
              children: [
                _buildEarningMethod(
                  icon: Icons.play_circle,
                  title: 'Watch Videos',
                  subtitle: 'Earn tokens by watching',
                  reward: '+5 CNE per video',
                ),
                _buildEarningMethod(
                  icon: Icons.quiz,
                  title: 'Take Quiz',
                  subtitle: 'Test your knowledge',
                  reward: '+10 CNE per quiz',
                ),
                _buildEarningMethod(
                  icon: Icons.share,
                  title: 'Refer Friends',
                  subtitle: 'Invite and earn more',
                  reward: '+50 CNE per referral',
                ),
                _buildEarningMethod(
                  icon: Icons.calendar_today,
                  title: 'Daily Check-in',
                  subtitle: 'Login daily bonus',
                  reward: '+20 CNE per day',
                ),
                _buildSocialMediaEarningMethod(context),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Ad Carousel Section
            const AdsCarousel(),
            
            const SizedBox(height: 24),
            
            // Recent earnings
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No earnings yet.\nStart watching videos to earn!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required String reward,
  }) {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced padding to fix overflow
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Icon(
            icon,
            color: const Color(0xFF006833),
            size: 22, // Slightly smaller icon
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13, // Slightly smaller font
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10, // Smaller subtitle
              fontFamily: 'Lato',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            reward,
            style: const TextStyle(
              color: Color(0xFF006833),
              fontSize: 11, // Smaller reward text
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaEarningMethod(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSocialMediaBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              FeatherIcons.share2,
              color: Color(0xFF006833),
              size: 22,
            ),
            const SizedBox(height: 6),
            const Text(
              'Follow Us',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Follow on social media',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
                fontFamily: 'Lato',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const Text(
              '+15 CNE per follow',
              style: TextStyle(
                color: Color(0xFF006833),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocialMediaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true, // Allow custom height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Limit height to 70% of screen
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Account for keyboard
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Follow Us on Social Media',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Earn tokens by following our social media accounts!',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Social Media Links List (Changed from Grid to List for better space management)
                  ..._socialMediaLinks.map((social) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSocialMediaTile(social),
                    ),
                  ).toList(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialMediaTile(Map<String, dynamic> social) {
    return GestureDetector(
      onTap: () => _launchSocialMediaUrl(social['url']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF006833).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              social['icon'],
              color: const Color(0xFF006833),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                social['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.grey[500],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSocialMediaUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Handle error - could show snackbar or try in-app browser
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.inAppWebView,
          );
        }
      }
    } catch (e) {
      // Show error message to user
      debugPrint('Could not launch $url: $e');
    }
  }
}
