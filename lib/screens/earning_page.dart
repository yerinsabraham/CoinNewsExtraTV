import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/ads_carousel.dart';
import '../services/user_balance_service.dart';
import '../services/reward_service.dart';
import 'video_player_page.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {
  bool _isClaimingDailyReward = false;
  
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
                                    'Locked: ${balanceService.balance.lockedBalance.toStringAsFixed(2)} CNE',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                  Text(
                                    'Available: ${balanceService.balance.unlockedBalance.toStringAsFixed(2)} CNE',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'Lato',
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
            
                  // Next halving countdown
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Next Reward Halving',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              Text(
                                'In ${balanceService.getDaysUntilNextHalving()} days - Rewards will be reduced by 50%',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
              '+${balanceService.rewardAmounts.socialReward.toInt()} CNE per follow',
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
        
        // After launching, show option to claim reward
        Future.delayed(const Duration(seconds: 2), () {
          _showSocialRewardClaimDialog(url);
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
          onTap: canClaim ? () => _claimDailyReward(context) : null,
        );
      },
    );
  }

  // Navigation methods
  void _navigateToVideos(BuildContext context) {
    // Navigate to video list or specific video
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoPlayerPage(
          videoId: 'sample_video',
          title: 'Sample Video',
          channelName: 'CoinNewsExtra',
          views: '1K views',
          uploadTime: '1 hour ago',
          reward: 5.0,
        ),
      ),
    );
  }

  void _navigateToQuiz(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz feature coming soon!')),
    );
  }

  void _navigateToLiveStreams(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live streams coming soon!')),
    );
  }

  // Daily reward claim
  Future<void> _claimDailyReward(BuildContext context) async {
    if (_isClaimingDailyReward) return;

    setState(() {
      _isClaimingDailyReward = true;
    });

    try {
      final result = await RewardService.claimDailyReward();
      if (result != null && result['success'] == true) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily reward claimed! +${result['rewardAmount']} CNE'),
              backgroundColor: const Color(0xFF006833),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to claim daily reward'),
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

  // Show social reward claim dialog
  void _showSocialRewardClaimDialog(String url) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Claim Your Reward',
            style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
          ),
          content: const Text(
            'Did you follow our social media account? Claim your reward now!',
            style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _claimSocialReward(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006833),
              ),
              child: const Text('Claim Reward'),
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
        socialMediaUrl: url,
      );

      if (result != null && result['success'] == true) {
        final balanceService = Provider.of<UserBalanceService>(context, listen: false);
        await balanceService.processRewardClaim(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Social media reward claimed! +${result['rewardAmount']} CNE'),
              backgroundColor: const Color(0xFF006833),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to claim social reward'),
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
