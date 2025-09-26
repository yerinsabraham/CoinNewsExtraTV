import 'package:flutter/material.dart';
import 'dart:async';

class ChatAdCarousel extends StatefulWidget {
  const ChatAdCarousel({super.key});

  @override
  State<ChatAdCarousel> createState() => _ChatAdCarouselState();
}

class _ChatAdCarouselState extends State<ChatAdCarousel> {
  int _currentIndex = 0;
  final PageController _controller = PageController();
  Timer? _timer;

  // Using same ad images as home banner carousel (as requested)
  final List<Map<String, String>> _chatAds = [
    {
      'image': 'assets/images/ad1.png',
      'title': 'Exclusive Crypto Trading Course',
      'description': 'Learn advanced trading strategies',
    },
    {
      'image': 'assets/images/ad2.png',
      'title': 'Join Our Premium Community',
      'description': 'Access exclusive content and signals',
    },
    {
      'image': 'assets/images/ad3.png',
      'title': 'Earn 50% More Rewards',
      'description': 'Limited time bonus rewards',
    },
    {
      'image': 'assets/images/ad4.png',
      'title': 'Limited Time: Double Coins',
      'description': 'Double your earnings this week',
    },
  ];

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
      if (_currentIndex < _chatAds.length - 1) {
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

  void _onAdTapped(Map<String, String> ad) {
    // Navigate to ad popup page with countdown timer and token reward
    _showAdRewardPopup(ad);
  }

  void _showAdRewardPopup(Map<String, String> ad) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AdRewardDialog(ad: ad);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            height: 100, // 32:9 aspect ratio for rectangular banner
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PageView.builder(
              controller: _controller,
              itemCount: _chatAds.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final ad = _chatAds[index];
                return GestureDetector(
                  onTap: () => _onAdTapped(ad),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          // Ad image or fallback gradient
                          Image.asset(
                            ad['image']!,
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
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ad['title']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          fontFamily: 'Lato',
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Gradient overlay for text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                          
                          // Ad content overlay
                          Positioned(
                            bottom: 8,
                            left: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ad['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ad['description']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontFamily: 'Lato',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Tap indicator
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lato',
                                ),
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
          
          const SizedBox(height: 8),
          
          // Carousel indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _chatAds.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(
                  entry.key,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
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
      ),
    );
  }
}

class AdRewardDialog extends StatefulWidget {
  final Map<String, String> ad;

  const AdRewardDialog({super.key, required this.ad});

  @override
  State<AdRewardDialog> createState() => _AdRewardDialogState();
}

class _AdRewardDialogState extends State<AdRewardDialog> {
  int _countdown = 15; // 15-second countdown
  Timer? _countdownTimer;
  bool _canClaim = false;
  bool _isClaimed = false;
  final double _rewardAmount = 5.0; // CNE tokens

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canClaim = true;
          timer.cancel();
        }
      });
    });
  }

  void _claimReward() {
    setState(() {
      _isClaimed = true;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+$_rewardAmount CNE tokens earned!'),
        backgroundColor: const Color(0xFF006833),
      ),
    );
    
    // Close dialog after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF006833), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _canClaim || _isClaimed 
                    ? () => Navigator.of(context).pop()
                    : null,
              ),
            ),
            
            // Ad content
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.ad['image']!,
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
                              widget.ad['title']!,
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
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              widget.ad['title']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.ad['description']!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Countdown or claim section
            if (!_isClaimed) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (!_canClaim) ...[
                      Text(
                        'Watch ad to earn $_rewardAmount CNE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time remaining: $_countdown seconds',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: (15 - _countdown) / 15,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey[600],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF006833),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ad completed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006833),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Claim $_rewardAmount CNE Tokens',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF006833)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF006833),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+$_rewardAmount CNE Earned!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tokens have been added to your wallet',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}