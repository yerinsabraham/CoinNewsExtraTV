import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../utils/external_link_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/spotlight_model.dart';
import '../services/user_balance_service.dart';

class SpotlightDetailsScreen extends StatefulWidget {
  final SpotlightItem item;

  const SpotlightDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  State<SpotlightDetailsScreen> createState() => _SpotlightDetailsScreenState();
}

class _SpotlightDetailsScreenState extends State<SpotlightDetailsScreen> {
  int _currentImageIndex = 0;
  late PageController _pageController;
  
  // Reward timer variables
  Timer? _rewardTimer;
  int _remainingSeconds = 60;
  bool _timerStarted = false;
  bool _rewardClaimed = false;
  bool _claimingReward = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startRewardTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rewardTimer?.cancel();
    super.dispose();
  }

  void _startRewardTimer() {
    if (_timerStarted) return;
    
    setState(() {
      _timerStarted = true;
    });

    _rewardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _claimReward();
      }
    });
  }

  Future<void> _claimReward() async {
    if (_rewardClaimed || _claimingReward) return;

    setState(() {
      _claimingReward = true;
    });

    try {
      print('🎯 Starting reward claim for spotlight view...');
      
      // Use the SAME method as all other games (Spin2Earn, Quiz, etc.)
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.addBalance(2.8, 'Spotlight View'); // Updated CNE reward for 1-10K tier
      
      if (mounted) {
        setState(() {
          _rewardClaimed = true;
          _claimingReward = false;
        });

        print('✅ Spotlight reward claimed successfully: 2.8 CNE (using UserBalanceService)');
        
        // Show success animation/notification
        _showRewardClaimedDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _claimingReward = false;
        });
        
        print('❌ Failed to claim spotlight reward: $e');
        
        // Show user-friendly error message
        String errorMessage = 'Failed to claim reward';
        if (e.toString().contains('unauthenticated') || e.toString().contains('authentication')) {
          errorMessage = 'Please sign in again to claim your reward';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again';
        } else if (e.toString().contains('HTTP 500')) {
          errorMessage = 'Server error. Please try again in a moment';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry claiming the reward
                _claimReward();
              },
            ),
          ),
        );
      }
    }
  }

  void _showRewardClaimedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FeatherIcons.award,
                color: Colors.amber,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reward Earned!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ve earned 2.8 CNE tokens for viewing this spotlight!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(FeatherIcons.award, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Text(
                  '+2.8 CNE',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Awesome!',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTimer() {
    if (_rewardClaimed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(FeatherIcons.checkCircle, color: Colors.amber, size: 16),
            SizedBox(width: 8),
            Text(
              'Reward earned! +2.8 CNE tokens',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      );
    }

    if (_claimingReward) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.amber,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Claiming reward...',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$_remainingSeconds',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Stay on this page for 1 minute to earn 2.8 CNE tokens',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
            ),
          ),
          const Icon(FeatherIcons.award, color: Colors.amber, size: 16),
        ],
      ),
    );
  }

  Color _getCategoryColor(SpotlightCategory category) {
    switch (category) {
      case SpotlightCategory.airdrops:
        return Colors.purple;
      case SpotlightCategory.crypto:
        return Colors.orange;
      case SpotlightCategory.ai:
        return Colors.blue;
      case SpotlightCategory.fintech:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(SpotlightCategory category) {
    switch (category) {
      case SpotlightCategory.airdrops:
        return FeatherIcons.gift;
      case SpotlightCategory.crypto:
        return FeatherIcons.trendingUp;
      case SpotlightCategory.ai:
        return FeatherIcons.cpu;
      case SpotlightCategory.fintech:
        return FeatherIcons.creditCard;
    }
  }

  Future<void> _launchUrl() async {
    try {
      await launchUrlWithDisclaimer(context, widget.item.ctaLink);
    } catch (e) {
      _showErrorSnackBar('Invalid URL format');
    }
  }

  void _shareItem() {
    Share.share(
      'Check out ${widget.item.title} on CoinNewsExtra!\n\n${widget.item.shortDescription}\n\n${widget.item.ctaLink}',
      subject: widget.item.title,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = [
      widget.item.bannerUrl ?? widget.item.imageUrl,
      ...widget.item.galleryImages,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(FeatherIcons.share2, color: Colors.white),
                  onPressed: _shareItem,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Main image carousel
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return images[index].startsWith('assets/')
                          ? Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    FeatherIcons.image,
                                    color: Colors.grey[500],
                                    size: 64,
                                  ),
                                );
                              },
                            )
                          : Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    FeatherIcons.image,
                                    color: Colors.grey[500],
                                    size: 64,
                                  ),
                                );
                              },
                            );
                    },
                  ),
                  
                  // Gradient overlay
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
                  
                  // Image indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  // Featured badge
                  if (widget.item.isFeatured)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FeatherIcons.star,
                              color: Colors.black,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(widget.item.category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(widget.item.category),
                              color: _getCategoryColor(widget.item.category),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.item.category.displayName,
                              style: TextStyle(
                                color: _getCategoryColor(widget.item.category),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Reward Timer
                  _buildRewardTimer(),
                  
                  // Title
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Short description
                  Text(
                    widget.item.shortDescription,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontFamily: 'Lato',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Full description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.description,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.5,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // CTA Buttons
                  Row(
                    children: [
                      // Main CTA button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _launchUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getCategoryColor(widget.item.category),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCtaIcon(widget.item.ctaText),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.item.ctaText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Share button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _shareItem,
                          icon: const Icon(
                            FeatherIcons.share2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Additional info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FeatherIcons.info,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is a third-party service. Please review their terms and conditions before proceeding.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCtaIcon(String ctaText) {
    final lowerText = ctaText.toLowerCase();
    if (lowerText.contains('download') || lowerText.contains('app')) {
      return FeatherIcons.download;
    } else if (lowerText.contains('website') || lowerText.contains('visit')) {
      return FeatherIcons.externalLink;
    } else if (lowerText.contains('join') || lowerText.contains('airdrop')) {
      return FeatherIcons.gift;
    } else if (lowerText.contains('learn') || lowerText.contains('more')) {
      return FeatherIcons.bookOpen;
    }
    return FeatherIcons.arrowRight;
  }
}