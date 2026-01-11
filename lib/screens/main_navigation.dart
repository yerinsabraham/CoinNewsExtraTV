import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import 'program_page.dart';
import 'earning_page.dart';
import 'wallet_page.dart';
import 'profile_screen.dart';
import 'cne_token_test_page.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/quick_feature_row.dart';
import '../widgets/middle_feature_grid.dart';
import '../widgets/ads_carousel.dart';
import '../widgets/search_overlay.dart';
import '../widgets/notification_badge.dart';
import '../provider/admin_provider.dart';
import '../data/video_data.dart';
import '../models/video_model.dart';
import 'notifications_screen.dart';
import '../services/first_launch_service.dart';
import '../services/tour_service.dart';
import '../services/crypto_price_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _tourRunning = false;

  List<Widget> get _pages => [
        BinanceHomePage(onTourRunningChanged: (running) {
          // update parent bottom nav visibility when tour starts/stops
          if (mounted) {
            setState(() {
              _tourRunning = running;
            });
          }
        }),
        const ProgramPage(),
        const EarningPage(),
        const WalletPage(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _tourRunning
          ? null
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFF00B359),
                  unselectedItemColor: Colors.grey[500],
                  selectedFontSize: 13,
                  unselectedFontSize: 12,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.home_outlined, size: 24),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.home_rounded, size: 26),
                      ),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.tv_outlined, size: 24),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.tv_rounded, size: 26),
                      ),
                      label: 'Program',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.monetization_on_outlined, size: 24),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.monetization_on_rounded, size: 26),
                      ),
                      label: 'Earn',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.account_balance_wallet_outlined,
                            size: 24),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.account_balance_wallet_rounded,
                            size: 26),
                      ),
                      label: 'Wallet',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person_outline_rounded, size: 24),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person_rounded, size: 26),
                      ),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class BinanceHomePage extends StatefulWidget {
  final void Function(bool running)? onTourRunningChanged;

  const BinanceHomePage({super.key, this.onTourRunningChanged});

  @override
  State<BinanceHomePage> createState() => _BinanceHomePageState();
}

class _BinanceHomePageState extends State<BinanceHomePage> {
  bool _isSearchVisible = false;
  // GlobalKeys for tutorial highlights
  final GlobalKey _liveTvKey = GlobalKey();
  final GlobalKey _chatKey = GlobalKey();
  final GlobalKey _extraAiKey = GlobalKey();
  final GlobalKey _spotlightKey = GlobalKey();

  final GlobalKey _marketKey = GlobalKey();
  final GlobalKey _newsKey = GlobalKey();
  final GlobalKey _spinKey = GlobalKey();
  final GlobalKey _summitKey = GlobalKey();
  final GlobalKey _playExtraKey = GlobalKey();
  final GlobalKey _quizKey = GlobalKey();

  bool _tourShown = false;
  bool _tourRunning = false;
  // cache of all videos for search overlay (kept simple for now)
  final List<Map<String, dynamic>> _allVideos = [];

  // Crypto prices state
  Map<String, CryptoPrice> _cryptoPrices = {};
  bool _loadingPrices = true;

  @override
  void initState() {
    super.initState();
    _loadCryptoPrices();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _loadCryptoPrices() async {
    setState(() => _loadingPrices = true);
    final prices = await CryptoPriceService.getCurrentPrices();
    if (mounted) {
      setState(() {
        _cryptoPrices = prices;
        _loadingPrices = false;
      });
    }
  }

  Future<void> _maybeShowTour() async {
    if (_tourShown) return;
    _tourShown = true;
    final firstLaunch = FirstLaunchService();
    final seen = await firstLaunch.hasSeenIntro();
    final requested = await firstLaunch.consumeTourRequest();
    if (!seen || requested) {
      // Build ordered list of (key,title,desc)
      final items = [
        [
          _liveTvKey,
          'Live TV',
          'Watch live broadcasts, events, and streams directly from our network.'
        ],
        [
          _extraAiKey,
          'ExtraAI',
          'Ask questions, explore ideas, or get instant answers with our built-in AI assistant.'
        ],
        [
          _marketKey,
          'Market Cap',
          'Check the real-time cryptocurrency market stats and token data.'
        ],
        [
          _newsKey,
          'News',
          'Stay updated with the latest blockchain and tech headlines.'
        ],
        [
          _spinKey,
          'Spin to Earn',
          'Earn rewards daily by spinning the reward wheel.'
        ],
        [
          _summitKey,
          'Summit',
          'Discover and join live virtual events and discussions.'
        ],
        [
          _playExtraKey,
          'Play Extra',
          'Play interactive games and compete for token prizes.'
        ],
        [
          _quizKey,
          'Quiz',
          'Test your knowledge of blockchain, crypto, and AI topics.'
        ],
      ];

      final targets = <TargetFocus>[];

      // Ensure first visible: if first target is off-screen, scroll it into view before showing tour
      try {
        final firstKey = items.first[0] as GlobalKey;
        final fc = firstKey.currentContext;
        if (fc != null) {
          await Scrollable.ensureVisible(fc,
              duration: const Duration(milliseconds: 300), alignment: 0.2);
        }
      } catch (_) {}

      for (int idx = 0; idx < items.length; idx++) {
        final item = items[idx];
        final key = item[0] as GlobalKey;
        final title = item[1] as String;
        final desc = item[2] as String;

        // Decide whether to place content above or below the target based on its vertical position
        ContentAlign align = ContentAlign.bottom;
        double bottomPadding = MediaQuery.of(context).padding.bottom +
            70.0; // leave room for bottom nav

        final ctx = key.currentContext;
        if (ctx != null) {
          final box = ctx.findRenderObject() as RenderBox?;
          if (box != null) {
            final topLeft = box.localToGlobal(Offset.zero);
            final y = topLeft.dy;
            final screenHeight = MediaQuery.of(context).size.height;
            // If target is in lower third of the screen, show content above it
            if (y > screenHeight * 0.6) {
              align = ContentAlign.top;
            }
          }
        }

        targets.add(TargetFocus(
          identify: title,
          keyTarget: key,
          shape: ShapeLightFocus.RRect,
          radius: 8,
          contents: [
            TargetContent(
              align: align,
              child: Builder(builder: (ctx) {
                return Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(desc, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              TourService().skip();
                            },
                            child: const Text('Skip',
                                style: TextStyle(color: Colors.white70)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // try to bring next target into view before proceeding
                              // Find next key and ensure it's visible, then advance the coach mark
                              try {
                                final nextIndex = idx + 1;
                                if (nextIndex < items.length) {
                                  final nextKey =
                                      items[nextIndex][0] as GlobalKey;
                                  final nextCtx = nextKey.currentContext;
                                  if (nextCtx != null) {
                                    Scrollable.ensureVisible(nextCtx,
                                            duration: const Duration(
                                                milliseconds: 400),
                                            alignment: 0.2)
                                        .then((_) {
                                      TourService().next();
                                    });
                                    return;
                                  }
                                }
                              } catch (_) {}
                              TourService().next();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B359)),
                            child: const Text('Next',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ),
          ],
        ));
      }

      // When showing the tour, hide the bottom nav by setting _tourRunning flag and refreshing.
      setState(() {
        _tourRunning = true;
      });
      // notify parent that tour is running (so it can hide bottom nav)
      try {
        widget.onTourRunningChanged?.call(true);
      } catch (_) {}

      await TourService().showTour(
          context: context,
          targets: targets,
          onFinishCallback: () {
            setState(() {
              _tourRunning = false;
            });
            try {
              widget.onTourRunningChanged?.call(false);
            } catch (_) {}
          },
          onSkipCallback: () {
            setState(() {
              _tourRunning = false;
            });
            try {
              widget.onTourRunningChanged?.call(false);
            } catch (_) {}
          });
    }
  }

  void _showSearch() {
    setState(() {
      _isSearchVisible = true;
    });
  }

  void _hideSearch() {
    setState(() {
      _isSearchVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/logo48_dark.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.currency_bitcoin,
                  color: Color(0xFF006833),
                  size: 28,
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'CoinNewsExtra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        actions: [
          NotificationBadge(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            child:
                const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Video carousel section
                const HomeBannerCarousel(),

                const SizedBox(height: 24),

                // Quick features row
                QuickFeatureRow(
                  liveTvKey: _liveTvKey,
                  chatKey: _chatKey,
                  extraAiKey: _extraAiKey,
                  spotlightKey: _spotlightKey,
                ),

                const SizedBox(height: 24),

                // Middle feature grid
                MiddleFeatureGrid(
                  marketKey: _marketKey,
                  newsKey: _newsKey,
                  spinKey: _spinKey,
                  summitKey: _summitKey,
                  playExtraKey: _playExtraKey,
                  quizKey: _quizKey,
                ),

                const SizedBox(height: 24),

                // Ad carousel
                const AdsCarousel(),

                const SizedBox(height: 24),

                // Cryptocurrency ticker
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Market Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                          if (_loadingPrices)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF00B359)),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.grey, size: 20),
                              onPressed: _loadCryptoPrices,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMarketTicker('BTC', _cryptoPrices['BTC']),
                          _buildMarketTicker('ETH', _cryptoPrices['ETH']),
                          _buildMarketTicker('BNB', _cryptoPrices['BNB']),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Search overlay
          if (_isSearchVisible)
            SearchOverlay(
              videos: _allVideos,
              onClose: _hideSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildMarketTicker(String symbol, CryptoPrice? price) {
    if (price == null) {
      return Column(
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '---',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          symbol,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CryptoPriceService.formatPrice(price.price),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CryptoPriceService.formatChange(price.change24h),
          style: TextStyle(
            color: price.isPositive ? Colors.green : Colors.red,
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }
}
