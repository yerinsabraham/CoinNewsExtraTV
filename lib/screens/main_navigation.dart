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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const BinanceHomePage(),
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
      bottomNavigationBar: Container(
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
                  child: Icon(Icons.account_balance_wallet_outlined, size: 24),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.account_balance_wallet_rounded, size: 26),
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
  const BinanceHomePage({super.key});

  @override
  State<BinanceHomePage> createState() => _BinanceHomePageState();
}

class _BinanceHomePageState extends State<BinanceHomePage> {
  bool _isSearchVisible = false;
  
  // Use centralized video data for search - convert to Map format for SearchOverlay
  List<Map<String, dynamic>> get _allVideos {
    try {
      return VideoData.getAllVideos().map((video) => {
        'id': video.youtubeId,
        'title': video.title,
        'channel': video.channelName ?? 'CoinNews Extra',
        'channelName': video.channelName ?? 'CoinNews Extra',
      }).toList();
    } catch (e) {
      // Return mock data if VideoData is not available
      return [
        {
          'id': 'mock1',
          'title': 'Bitcoin News Update',
          'channel': 'CoinNews Extra',
          'channelName': 'CoinNews Extra',
        },
        {
          'id': 'mock2', 
          'title': 'Ethereum Analysis',
          'channel': 'CoinNews Extra',
          'channelName': 'CoinNews Extra',
        },
      ];
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
            child: const Icon(Icons.notifications_outlined, color: Colors.white),
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
                const QuickFeatureRow(),
                
                const SizedBox(height: 24),
                
                // Middle feature grid
                const MiddleFeatureGrid(),
                
                const SizedBox(height: 24),
                
                // Ad carousel
                const AdsCarousel(),
                
                const SizedBox(height: 24),
                
                // Cryptocurrency ticker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMarketTicker('BTC', '\$67,450', '+2.5%', true),
                          _buildMarketTicker('ETH', '\$3,245', '+1.8%', true),
                          _buildMarketTicker('BNB', '\$445', '-0.7%', false),
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

  Widget _buildMarketTicker(String symbol, String price, String change, bool isPositive) {
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
          price,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          change,
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }
}
