import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:feather_icons/feather_icons.dart';
import '../widgets/ads_carousel.dart';

class MarketCapPage extends StatefulWidget {
  const MarketCapPage({super.key});

  @override
  State<MarketCapPage> createState() => _MarketCapPageState();
}

class _MarketCapPageState extends State<MarketCapPage> {
  List<Cryptocurrency> cryptos = [];
  List<Cryptocurrency> _filteredCryptos = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCryptocurrencies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCryptocurrencies() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false'
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cryptos = data.map((crypto) => Cryptocurrency.fromJson(crypto)).toList();
          _filteredCryptos = List.from(cryptos);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load market data. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: Unable to fetch market data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Market Cap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw, color: Color(0xFF006833)),
            onPressed: _fetchCryptocurrencies,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCryptocurrencies,
        color: const Color(0xFF006833),
        backgroundColor: Colors.grey[900],
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search coins (name or symbol)...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredCryptos = List.from(cryptos));
    } else {
      setState(() {
        _filteredCryptos = cryptos.where((c) => c.name.toLowerCase().contains(q) || c.symbol.toLowerCase().contains(q)).toList();
      });
    }
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF006833),
            ),
            SizedBox(height: 16),
            Text(
              'Loading market data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Lato',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fetching live prices from CoinGecko',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FeatherIcons.alertCircle,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading market data',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchCryptocurrencies,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006833),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final list = _filteredCryptos;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FeatherIcons.alertCircle,
                color: Colors.grey[500],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No coins match your search',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Try a different name or clear the search to view the full list.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006833),
                ),
                child: const Text('Clear search'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: list.length + 1, // +1 for the ad carousel
      itemBuilder: (context, index) {
        // Show ad carousel after the first 3 cryptocurrency entries
        if (index == 3) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: AdsCarousel(),
          );
        }

        // Adjust index for crypto data after ad insertion
        final cryptoIndex = index > 3 ? index - 1 : index;

        // Guard in case filtered list is smaller
        if (cryptoIndex < 0 || cryptoIndex >= list.length) return const SizedBox.shrink();

        // Return crypto tile with proper padding
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCryptoTile(list[cryptoIndex], cryptoIndex + 1),
        );
      },
    );
  }

  Widget _buildCryptoTile(Cryptocurrency crypto, int rank) {
    final isPositive = crypto.priceChange24h >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Coin Icon (placeholder)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: crypto.image.isNotEmpty 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    crypto.image,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        FeatherIcons.circle,
                        color: Color(0xFF006833),
                        size: 16,
                      );
                    },
                  ),
                )
              : const Icon(
                  FeatherIcons.circle,
                  color: Color(0xFF006833),
                  size: 16,
                ),
          ),
          
          const SizedBox(width: 12),
          
          // Coin Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crypto.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  crypto.symbol.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          // Price & Market Cap
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price: ensure full display and reasonable font size. Use FittedBox
                // to scale down the text if the available width is small so the
                // full numeric price remains visible.
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_formatNumber(crypto.currentPrice)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_formatMarketCap(crypto.marketCap)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 24h Change
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? FeatherIcons.trendingUp : FeatherIcons.trendingDown,
                  size: 12,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${crypto.priceChange24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    // Use simple thousands separator formatting for readability
    if (number >= 1000) {
      return number.toStringAsFixed(2).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    } else if (number >= 1) {
      return number.toStringAsFixed(3).replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    } else {
      return number.toStringAsFixed(6);
    }
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1e12) {
      return '${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      return '${(marketCap / 1e6).toStringAsFixed(2)}M';
    } else {
      return marketCap.toStringAsFixed(0);
    }
  }
}

class Cryptocurrency {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double marketCap;
  final double priceChange24h;
  final double? volume24h;
  final double? circulatingSupply;

  Cryptocurrency({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.marketCap,
    required this.priceChange24h,
    this.volume24h,
    this.circulatingSupply,
  });

  factory Cryptocurrency.fromJson(Map<String, dynamic> json) {
    return Cryptocurrency(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      priceChange24h: (json['price_change_percentage_24h'] ?? 0).toDouble(),
      volume24h: json['total_volume']?.toDouble(),
      circulatingSupply: json['circulating_supply']?.toDouble(),
    );
  }
}