import 'package:flutter/material.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/quick_feature_row.dart';
import '../widgets/middle_feature_grid.dart';
import '../widgets/ads_carousel.dart';
import '../widgets/search_overlay.dart';

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
      'id': 'p4kmPtTU4lw',
      'title': 'Bitcoin Breaking \$100K? Market Analysis',
      'channel': 'CoinNewsExtra',
      'channelName': 'CoinNewsExtra',
    },
    {
      'id': 'dQw4w9WgXcQ', 
      'title': 'Ethereum 2.0 Complete Guide',
      'channel': 'Crypto Education',
      'channelName': 'Crypto Education',
    },
    {
      'id': 'L_jWHffIx5E',
      'title': 'Top 10 Altcoins for 2025', 
      'channel': 'CoinNewsExtra',
      'channelName': 'CoinNewsExtra',
    },
    {
      'id': 'fJ9rUzIMcZQ',
      'title': 'DeFi Explained: Complete Beginner Guide',
      'channel': 'DeFi Academy',
      'channelName': 'DeFi Academy',
    },
    {
      'id': 'zbRSjy4CSzM',
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