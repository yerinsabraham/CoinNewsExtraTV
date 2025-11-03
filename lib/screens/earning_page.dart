import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_balance_service.dart';
import '../widgets/ads_carousel.dart';
import 'live_stream_page.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {
  bool _isClaimingReward = false;
  final Set<String> _followedPlatforms = {};

  // Social Media Links Configuration - Updated CNE rewards (100 CNE per follow for 1-10K tier)
  final List<Map<String, dynamic>> _socialMediaLinks = [
    {
      'name': 'TikTok',
      'url': 'https://www.tiktok.com/@coinnewsextratv',
      'icon': FeatherIcons.music,
      'reward': 100,
      'description': 'Follow us on TikTok for crypto news',
    },
    {
      'name': 'Telegram',
      'url': 'https://t.me/coinnewsextra',
      'icon': FeatherIcons.send,
      'reward': 100,
      'description': 'Join our Telegram community',
    },
    {
      'name': 'YouTube',
      'url': 'https://youtube.com/@coinnewsextratv',
      'icon': FeatherIcons.youtube,
      'reward': 100,
      'description': 'Subscribe to our YouTube channel',
    },
    {
      'name': 'LinkedIn',
      'url': 'https://www.linkedin.com/company/coin-news-extra/',
      'icon': FeatherIcons.linkedin,
      'reward': 100,
      'description': 'Connect with us on LinkedIn',
    },
    {
      'name': 'Facebook',
      'url': 'https://www.facebook.com/CoinNewsExtraTv',
      'icon': FeatherIcons.facebook,
      'reward': 100,
      'description': 'Like our Facebook page',
    },
    {
      'name': 'X (Twitter)',
      'url': 'https://x.com/CoinNewsExtraTv',
      'icon': FeatherIcons.twitter,
      'reward': 100,
      'description': 'Follow us on X (Twitter)',
    },
    {
      'name': 'Instagram',
      'url': 'https://www.instagram.com/coinnewsextratv',
      'icon': FeatherIcons.instagram,
      'reward': 100,
      'description': 'Follow us on Instagram',
    },
  ];

  Future<void> _claimReward(int amount, String source) async {
    if (_isClaimingReward) return;

    setState(() => _isClaimingReward = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(amount.toDouble(), 'Earning reward: $source');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward claimed! +$amount CNE'),
            backgroundColor: const Color(0xFF006833),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaimingReward = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Earn CNE',
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
            // Balance card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<UserBalanceService>(
                    builder: (context, balanceService, child) {
                      return Text(
                        '${balanceService.balance.toStringAsFixed(2)} CNE',       
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      );
                    },
                  ),
                  // Fiat / USD display removed — showing token-only balance
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

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildEarningMethod(
                  icon: Icons.play_circle,
                  title: 'Watch Videos',
                  subtitle: 'Earn tokens by watching',
                  reward: '+7 CNE per video',
                  onTap: () => Navigator.pushNamed(context, '/watch-videos'),
                ),
                _buildEarningMethod(
                  icon: Icons.quiz,
                  title: 'Quiz Game',
                  subtitle: 'Test your knowledge',
                  reward: '+2 CNE per question',
                  onTap: () => Navigator.pushNamed(context, '/quiz'),
                ),
                _buildEarningMethod(
                  icon: Icons.share,
                  title: 'Refer Friends',
                  subtitle: 'Invite and earn more',
                  reward: '+700 CNE per referral',
                  onTap: () => Navigator.pushNamed(context, '/referral'),
                ),
                _buildEarningMethod(
                  icon: Icons.calendar_today,
                  title: 'Daily Check-in',
                  subtitle: 'Login daily bonus',
                  reward: '+28 CNE per day',
                  onTap: () => Navigator.pushNamed(context, '/daily-checkin'),
                ),
                _buildEarningMethod(
                  icon: Icons.casino,
                  title: 'Spin to Earn',
                  subtitle: 'Spin the wheel to win',
                  reward: 'Up to 1000 CNE',
                  onTap: () => Navigator.pushNamed(context, '/spin-game'),
                ),
                _buildEarningMethod(
                  icon: Icons.live_tv,
                  title: 'Live TV Watching',
                  subtitle: 'Watch live content & earn',
                  reward: '+7 CNE per video',
                  onTap: () => _navigateToLiveStream(),
                ),
                _buildSocialMediaEarningMethod(),
              ],
            ),

            const SizedBox(height: 24),

            const AdsCarousel(),
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: _isClaimingReward ? null : onTap,
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
            Icon(
              icon,
              color: const Color(0xFF006833),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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
                fontSize: 10,
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

  void _navigateToLiveStream() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveStreamPage(
          streamId: 'live_stream_001',
          title: 'CoinNewsExtra Live',
          description: 'Watch our live crypto news and analysis stream to earn rewards!',
        ),
      ),
    );
  }

  Widget _buildSocialMediaEarningMethod() {
    return GestureDetector(
      onTap: () => _showSocialMediaBottomSheet(),
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
              '+100 CNE per follow',
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

  void _showSocialMediaBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Follow Us & Earn Rewards',
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
                    'Follow our social media accounts and earn CNE tokens! Each platform can only be claimed once.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Verification Process Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006833).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF006833).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info,
                          color: Color(0xFF006833),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap any platform to open it in your browser, then come back and claim your reward!',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Social Media Platforms List
                  ..._socialMediaLinks.map((social) => _buildSocialMediaTile(social)).toList(),
                  
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
    final isFollowed = _followedPlatforms.contains(social['name']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _launchSocialMediaUrl(social),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFollowed 
                  ? const Color(0xFF006833)
                  : Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  social['icon'],
                  color: const Color(0xFF006833),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      social['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      social['description'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006833).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${social['reward']} CNE',
                      style: const TextStyle(
                        color: Color(0xFF006833),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isFollowed)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF006833),
                      size: 24,
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchSocialMediaUrl(Map<String, dynamic> social) async {
    try {
      final uri = Uri.parse(social['url']);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        // Show reward claim dialog after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showRewardClaimDialog(social);
          }
        });
      }
    } catch (e) {
      debugPrint('Could not launch ${social['url']}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${social['name']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRewardClaimDialog(Map<String, dynamic> social) {
    if (_followedPlatforms.contains(social['name'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have already claimed the reward for ${social['name']}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                social['icon'],
                color: const Color(0xFF006833),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Claim Your Reward',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontFamily: 'Lato',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFF006833),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Did you follow us on ${social['name']}?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontFamily: 'Lato',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Claim your ${social['reward']} CNE reward now!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF006833), 
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We trust our community! Please only claim if you actually followed us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Not Yet', 
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pop(context); // Close bottom sheet too
                await _claimSocialReward(social);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B359),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 8,
                shadowColor: const Color(0xFF00B359).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes, Claim Reward!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _claimSocialReward(Map<String, dynamic> social) async {
    if (_isClaimingReward) return;
    
    setState(() {
      _isClaimingReward = true;
      _followedPlatforms.add(social['name']);
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(social['reward'].toDouble(), 'Social Media Follow: ${social['name']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Reward claimed! +${social['reward']} CNE from ${social['name']}'),
            backgroundColor: const Color(0xFF006833),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClaimingReward = false);
      }
    }
  }
}
