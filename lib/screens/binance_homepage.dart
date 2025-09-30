import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/quick_feature_row.dart';
import '../widgets/middle_feature_grid.dart';
import '../widgets/ads_carousel.dart';
import '../widgets/search_overlay.dart';
import '../provider/admin_provider.dart';

class BinanceHomePage extends StatefulWidget {
  const BinanceHomePage({super.key});

  @override
  State<BinanceHomePage> createState() => _BinanceHomePageState();
}

class _BinanceHomePageState extends State<BinanceHomePage> {
  bool _isSearchVisible = false;
  
  // Video data for search (combining featured videos and sample videos)
  final List<Map<String, dynamic>> _allVideos = [
    {
      'id': 'M7lc1UVf-VE',
      'title': 'Bitcoin Breaking \$100K? Market Analysis',
      'channel': 'CoinNewsExtra',
      'channelName': 'CoinNewsExtra',
    },
    {
      'id': '3jDhvKczYdQ', 
      'title': 'Ethereum 2.0 Complete Guide',
      'channel': 'Crypto Education',
      'channelName': 'Crypto Education',
    },
    {
      'id': 'kRuZKg3j4Ks',
      'title': 'Top 10 Altcoins for 2025', 
      'channel': 'CoinNewsExtra',
      'channelName': 'CoinNewsExtra',
    },
    {
      'id': '3Kf8Od6nIQM',
      'title': 'DeFi Explained: Complete Beginner Guide',
      'channel': 'DeFi Academy',
      'channelName': 'DeFi Academy',
    },
    {
      'id': '5-year-old-earns-6-figures-trading-stocks',
      'title': 'NFT Market Trends & Analysis',
      'channel': 'NFT Insights',
      'channelName': 'NFT Insights',
    },
    {
      'title': 'Cardano ADA Price Prediction 2025',
      'channelName': 'CoinNewsExtra',
      'views': '15K views',
      'uploadTime': '1 day ago',
    },
    {
      'title': 'Solana SOL: The Ethereum Killer?',
      'channelName': 'Blockchain Today',
      'views': '8.2K views',
      'uploadTime': '3 days ago',
    },
    {
      'title': 'Binance vs Coinbase: Which is Better?',
      'channelName': 'Crypto Compare',
      'views': '12K views',
      'uploadTime': '1 week ago',
    },
  ];

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

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Admin Content Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAdminMenuItem(
                  icon: FeatherIcons.image,
                  title: 'Manage Banners',
                  subtitle: 'Add, edit, or remove home banners',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Banner Management');
                  },
                ),
                _buildAdminMenuItem(
                  icon: FeatherIcons.tag,
                  title: 'Manage Ads',
                  subtitle: 'Control advertisement content',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Ad Management');
                  },
                ),
                _buildAdminMenuItem(
                  icon: FeatherIcons.calendar,
                  title: 'Manage Events',
                  subtitle: 'Create and manage events',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Event Management');
                  },
                ),
                _buildAdminMenuItem(
                  icon: FeatherIcons.fileText,
                  title: 'Manage News',
                  subtitle: 'Add and edit news articles',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'News Management');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF006833),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: const Color(0xFF006833).withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF006833),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
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
      floatingActionButton: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (!adminProvider.isAdmin || adminProvider.isLoading) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => _showAdminMenu(context),
            backgroundColor: const Color(0xFF006833),
            foregroundColor: Colors.white,
            child: const Icon(FeatherIcons.plus),
          );
        },
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