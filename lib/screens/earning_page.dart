import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/ads_carousel.dart';
import '../services/user_balance_service.dart';
import '../services/reward_service.dart';
import '../services/social_media_verification_service.dart';
import '../widgets/social_media_verification_dialog.dart';
import 'video_player_page.dart';
import 'quiz_page.dart';
import 'daily_checkin_page.dart';
import 'live_stream_page.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {
  bool _isClaimingDailyReward = false;
  int _socialClaimRefreshKey = 0;
  
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
    return Consumer<UserBalanceService>(
      builder: (context, balanceService, child) {
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => balanceService.refreshAll(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => balanceService.refreshAll(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Earning summary card with real data
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Earnings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Lato',
                              ),
                            ),
                            if (balanceService.isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          balanceService.getFormattedUsdValue(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${balanceService.getFormattedBalance()} CNE Tokens',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Balance: ${balanceService.balance.totalBalance.toStringAsFixed(2)} CNE',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Epoch ${balanceService.rewardAmounts.currentEpoch}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ),
                          ],
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
            
                  // Earning methods grid with dynamic rewards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildEarningMethod(
                        icon: Icons.play_circle,
                        title: 'Watch Videos',
                        subtitle: 'Earn tokens by watching',
                        reward: '+${balanceService.rewardAmounts.videoReward.toInt()} CNE per video',
                        onTap: () {
                          _navigateToVideos(context);
                        },
                      ),
                      _buildEarningMethod(
                        icon: Icons.quiz,
                        title: 'Take Quiz',
                        subtitle: 'Test your knowledge',
                        reward: '+${balanceService.rewardAmounts.quizReward.toInt()} CNE per quiz',
                        onTap: () {
                          _navigateToQuiz(context);
                        },
                      ),
                      _buildEarningMethod(
                        icon: Icons.share,
                        title: 'Refer Friends',
                        subtitle: 'Invite and earn more',
                        reward: '+${balanceService.rewardAmounts.referralReward.toInt()} CNE per referral',
                        onTap: () {
                          _showReferralDialog(context);
                        },
                      ),
                      _buildDailyCheckInMethod(context, balanceService),
                      _buildSocialMediaEarningMethod(context, balanceService),
                      _buildEarningMethod(
                        icon: Icons.casino,
                        title: 'Spin2Earn',
                        subtitle: 'Spin the wheel to win',
                        reward: '+10-1000 CNE per spin',
                        onTap: () {
                          _navigateToSpin2Earn(context);
                        },
                      ),
                      _buildEarningMethod(
                        icon: Icons.video_camera_front,
                        title: 'Watch Live',
                        subtitle: 'Join live streams',
                        reward: '+${balanceService.rewardAmounts.liveStreamReward.toInt()} CNE per stream',
                        onTap: () {
                          _navigateToLiveStreams(context);
                        },
                      ),
                    ],
                  ),
            
            const SizedBox(height: 24),
            
            // Ad Carousel Section
            const AdsCarousel(),
            
            const SizedBox(height: 24),
            


                  const SizedBox(height: 24),

                  // Recent earnings with real data
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
                  
                  _buildRecentActivity(balanceService),
                ],
              ),
            ),
          ),
        );
      },
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
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  Widget _buildSocialMediaEarningMethod(BuildContext context, UserBalanceService balanceService) {
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
            Text(
              '+10-20 CNE per follow',
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
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Increased height
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
                          'Social Media Verification',
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
                    'Follow our accounts and get verified to earn CNE tokens!',
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
                          Icons.security,
                          color: Color(0xFF006833),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'We verify all follows to prevent abuse. Each platform can only be claimed once.',
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
                  
                  const SizedBox(height: 16),
                  
                  // Social Media Platforms List with new verification system
                  ..._buildVerificationPlatformsList(),
                  
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
    return FutureBuilder<bool>(
      key: ValueKey('social_${social['name']}_$_socialClaimRefreshKey'),
      future: _isFollowedPlatform(social['name']),
      builder: (context, snapshot) {
        final isFollowed = snapshot.data ?? false;
        
        return GestureDetector(
          onTap: () => _launchSocialMediaUrl(social['url']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFollowed 
                    ? const Color(0xFF006833).withOpacity(0.6)
                    : const Color(0xFF006833).withOpacity(0.3),
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
                // Checkbox instead of open icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFollowed ? const Color(0xFF006833) : Colors.grey,
                      width: 2,
                    ),
                    color: isFollowed ? const Color(0xFF006833) : Colors.transparent,
                  ),
                  child: isFollowed
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _isFollowedPlatform(String platform) async {
    try {
      // Convert platform name to lowercase to match the format used when claiming rewards
      String platformKey = platform.toLowerCase();
      print('🔍 DEBUG: Checking if platform $platform ($platformKey) is followed');
      final isFollowed = await RewardService.isFollowedPlatform(platformKey);
      print('🔍 DEBUG: Platform $platformKey followed status: $isFollowed');
      return isFollowed;
    } catch (e) {
      print('❌ DEBUG: Error checking platform follow status: $e');
      return false;
    }
  }

  Future<void> _launchSocialMediaUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        
        // After launching, show verification dialog after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          _showVerificationForUrl(url);
        });
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

  // Build daily check-in method with status
  Widget _buildDailyCheckInMethod(BuildContext context, UserBalanceService balanceService) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: RewardService.getDailyRewardStatus(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final canClaim = data?['canClaim'] ?? false;
        final streak = data?['currentStreak'] ?? 0;
        
        return _buildEarningMethod(
          icon: canClaim ? Icons.calendar_today : Icons.check_circle,
          title: 'Daily Check-in',
          subtitle: canClaim ? 'Claim your daily bonus!' : 'Streak: $streak days',
          reward: '+${balanceService.rewardAmounts.dailyReward.toInt()} CNE per day',
          onTap: () => _navigateToDailyCheckin(context),
        );
      },
    );
  }

  // Navigation methods
  void _navigateToVideos(BuildContext context) {
    // Navigate to actual YouTube video with CNE rewards
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoPlayerPage(
          videoId: 'M7lc1UVf-VE',
          title: 'Bitcoin Breaking \$100K? Market Analysis',
          channelName: 'CoinNewsExtra',
          views: '25K views',
          uploadTime: '2 hours ago',
          reward: 3.0, // CNE reward amount for watching 30+ seconds
        ),
      ),
    );
  }

  void _navigateToQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizPage(),
      ),
    );
  }

  void _navigateToLiveStreams(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveStreamPage(
          streamId: 'live_stream_001',
          title: 'CoinNewsExtra Live',
          description: 'Watch our live crypto news and analysis stream',
        ),
      ),
    );
  }

  void _navigateToDailyCheckin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DailyCheckinPage(),
      ),
    );
  }

  void _navigateToSpin2Earn(BuildContext context) {
    Navigator.pushNamed(context, '/spin2earn');
  }

  // Daily reward claim
  Future<void> _claimDailyReward(BuildContext context) async {
    if (_isClaimingDailyReward) return;

    setState(() {
      _isClaimingDailyReward = true;
    });

    try {
      final result = await RewardService.claimDailyReward();
      if (result.success) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim({
          'success': result.success,
          'reward': result.reward,
          'message': result.message,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily reward claimed! +${result.reward?.toStringAsFixed(2) ?? '0.00'} CNE'),
              backgroundColor: const Color(0xFF006833),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error claiming daily reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isClaimingDailyReward = false;
      });
    }
  }

  // Show referral dialog
  void _showReferralDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Refer Friends & Earn',
            style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Invite friends using your referral code and earn CNE tokens when they sign up!',
                style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
              ),
              const SizedBox(height: 16),
              FutureBuilder<String?>(
                future: RewardService.getUserReferralCode(),
                builder: (context, snapshot) {
                  final code = snapshot.data ?? 'Loading...';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Code: $code',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF006833)),
                          onPressed: () {
                            // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Referral code copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF006833))),
            ),
          ],
        );
      },
    );
  }

  // Show verification for specific URL
  void _showVerificationForUrl(String url) {
    // Extract platform from URL
    String platformId = 'twitter'; // default
    if (url.contains('tiktok.com')) platformId = 'twitter'; // TikTok not in verification service yet
    else if (url.contains('t.me') || url.contains('telegram')) platformId = 'telegram';
    else if (url.contains('youtube.com')) platformId = 'youtube';
    else if (url.contains('linkedin.com')) platformId = 'linkedin';
    else if (url.contains('facebook.com')) platformId = 'facebook';
    else if (url.contains('twitter.com') || url.contains('x.com')) platformId = 'twitter';
    else if (url.contains('instagram.com')) platformId = 'instagram';

    // Find the platform in verification service
    final platforms = SocialMediaVerificationService.getSupportedPlatforms();
    final platform = platforms.firstWhere(
      (p) => p['id'] == platformId,
      orElse: () => platforms.first, // fallback to first platform
    );

    _showVerificationDialog(platform);
  }

  // Show social reward claim dialog (legacy - keeping for compatibility)
  void _showSocialRewardClaimDialog(String url) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Claim Your Reward',
            style: TextStyle(
              color: Colors.white, 
              fontFamily: 'Lato',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFF006833),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Did you follow our social media account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70, 
                  fontFamily: 'Lato',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Claim your 2 CNE reward now!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF006833), 
                  fontFamily: 'Lato',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel', 
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _claimSocialReward(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006833),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Claim Reward',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Claim social media reward
  Future<void> _claimSocialReward(String url) async {
    try {
      // Extract platform from URL
      String platform = 'unknown';
      if (url.contains('tiktok.com')) platform = 'tiktok';
      else if (url.contains('t.me') || url.contains('telegram')) platform = 'telegram';
      else if (url.contains('youtube.com')) platform = 'youtube';
      else if (url.contains('linkedin.com')) platform = 'linkedin';
      else if (url.contains('facebook.com')) platform = 'facebook';
      else if (url.contains('twitter.com') || url.contains('x.com')) platform = 'twitter';
      else if (url.contains('instagram.com')) platform = 'instagram';

      final result = await RewardService.claimSocialReward(
        platform: platform,
      );

      if (result.success) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim({
          'success': result.success,
          'reward': result.reward,
          'message': result.message,
        });

        if (mounted) {
          setState(() {
            _socialClaimRefreshKey++;
          });
          
          // Force a page rebuild to refresh all social media tiles
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _socialClaimRefreshKey++;
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Social media reward claimed! +${result.reward?.toStringAsFixed(2) ?? '0.00'} CNE'),
              backgroundColor: const Color(0xFF006833),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error claiming social reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build verification platforms list using new system
  List<Widget> _buildVerificationPlatformsList() {
    final platforms = SocialMediaVerificationService.getSupportedPlatforms();
    
    return platforms.map((platform) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FutureBuilder<VerificationStatus>(
          future: SocialMediaVerificationService.getVerificationStatus(platform['id']),
          builder: (context, snapshot) {
            final status = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            
            return GestureDetector(
              onTap: () => _showVerificationDialog(platform),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusBorderColor(status),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPlatformIcon(platform['id']),
                      color: const Color(0xFF006833),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            platform['displayName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lato',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoading 
                                ? 'Loading status...'
                                : (status?.message ?? 'Click to start verification'),
                            style: TextStyle(
                              color: _getStatusTextColor(status),
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${platform['reward']} CNE',
                          style: const TextStyle(
                            color: Color(0xFF006833),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 4),
                        _getStatusIcon(status, isLoading),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  void _showVerificationDialog(Map<String, dynamic> platform) {
    showDialog(
      context: context,
      builder: (context) => SocialMediaVerificationDialog(
        platform: platform,
        onVerificationComplete: () {
          setState(() {
            _socialClaimRefreshKey++;
          });
        },
      ),
    );
  }

  Color _getStatusBorderColor(VerificationStatus? status) {
    if (status == null) return const Color(0xFF006833).withOpacity(0.3);
    
    switch (status.status) {
      case 'completed':
        return const Color(0xFF006833);
      case 'approved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFF006833).withOpacity(0.3);
    }
  }

  Color _getStatusTextColor(VerificationStatus? status) {
    if (status == null) return Colors.grey[400]!;
    
    switch (status.status) {
      case 'completed':
        return const Color(0xFF006833);
      case 'approved':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _getStatusIcon(VerificationStatus? status, bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF006833),
        ),
      );
    }
    
    if (status == null) {
      return const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      );
    }
    
    switch (status.status) {
      case 'completed':
        return const Icon(
          Icons.check_circle,
          color: Color(0xFF006833),
          size: 20,
        );
      case 'approved':
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.blue,
          size: 20,
        );
      case 'pending':
        return const Icon(
          Icons.hourglass_empty,
          color: Colors.orange,
          size: 20,
        );
      case 'rejected':
        return const Icon(
          Icons.cancel_outlined,
          color: Colors.red,
          size: 20,
        );
      default:
        return const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        );
    }
  }

  IconData _getPlatformIcon(String platformId) {
    switch (platformId.toLowerCase()) {
      case 'twitter':
        return Icons.alternate_email;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'linkedin':
        return Icons.business;
      case 'telegram':
        return Icons.send;
      default:
        return Icons.link;
    }
  }

  // Build recent activity widget
  Widget _buildRecentActivity(UserBalanceService balanceService) {
    if (balanceService.recentTransactions.isEmpty) {
      return Container(
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
      );
    }

    return Column(
      children: balanceService.recentTransactions.take(3).map((transaction) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTransactionIcon(transaction['type']),
                  color: const Color(0xFF006833),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionTitle(transaction['type']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lato',
                      ),
                    ),
                    Text(
                      _formatTransactionDate(transaction['timestamp']),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${transaction['amount']} CNE',
                style: const TextStyle(
                  color: Color(0xFF006833),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods for transactions
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_circle;
      case 'quiz': return Icons.quiz;
      case 'daily': return Icons.calendar_today;
      case 'referral': return Icons.share;
      case 'social': return Icons.thumb_up;
      case 'signup': return Icons.person_add;
      case 'ad': return Icons.ads_click;
      case 'live': return Icons.video_camera_front;
      default: return Icons.monetization_on;
    }
  }

  String _getTransactionTitle(String type) {
    switch (type) {
      case 'video': return 'Video Watched';
      case 'quiz': return 'Quiz Completed';
      case 'daily': return 'Daily Check-in';
      case 'referral': return 'Referral Bonus';
      case 'social': return 'Social Follow';
      case 'signup': return 'Signup Bonus';
      case 'ad': return 'Ad Watched';
      case 'live': return 'Live Stream';
      default: return 'Reward Earned';
    }
  }

  String _formatTransactionDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
