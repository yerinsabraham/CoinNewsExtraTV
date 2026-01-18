import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoPriceService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  // Cache for prices to avoid excessive API calls
  static Map<String, CryptoPrice> _priceCache = {};
  static DateTime? _lastUpdate;
  static const Duration _cacheDuration = Duration(minutes: 1);

  /// Fetch current prices for BTC, ETH, and BNB
  static Future<Map<String, CryptoPrice>> getCurrentPrices() async {
    // Return cached data if still valid
    if (_priceCache.isNotEmpty &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _cacheDuration) {
      return _priceCache;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/simple/price?ids=bitcoin,ethereum,binancecoin&vs_currencies=usd&include_24hr_change=true'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        _priceCache = {
          'BTC': CryptoPrice(
            symbol: 'BTC',
            price: data['bitcoin']?['usd']?.toDouble() ?? 0.0,
            change24h: data['bitcoin']?['usd_24h_change']?.toDouble() ?? 0.0,
          ),
          'ETH': CryptoPrice(
            symbol: 'ETH',
            price: data['ethereum']?['usd']?.toDouble() ?? 0.0,
            change24h: data['ethereum']?['usd_24h_change']?.toDouble() ?? 0.0,
          ),
          'BNB': CryptoPrice(
            symbol: 'BNB',
            price: data['binancecoin']?['usd']?.toDouble() ?? 0.0,
            change24h:
                data['binancecoin']?['usd_24h_change']?.toDouble() ?? 0.0,
          ),
        };

        _lastUpdate = DateTime.now();
        return _priceCache;
      } else {
        // API error, return fallback data
        return _getFallbackPrices();
      }
    } catch (e) {
      print('Error fetching crypto prices: $e');
      return _getFallbackPrices();
    }
  }

  /// Get fallback prices when API is unavailable
  static Map<String, CryptoPrice> _getFallbackPrices() {
    // Return cached data if available
    if (_priceCache.isNotEmpty) {
      return _priceCache;
    }

    // Return reasonable default values
    return {
      'BTC': CryptoPrice(symbol: 'BTC', price: 67450, change24h: 2.5),
      'ETH': CryptoPrice(symbol: 'ETH', price: 3245, change24h: 1.8),
      'BNB': CryptoPrice(symbol: 'BNB', price: 445, change24h: -0.7),
    };
  }

  /// Format price for display
  static String formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(4);
    }
  }

  /// Format percentage change
  static String formatChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }
}

class CryptoPrice {
  final String symbol;
  final double price;
  final double change24h;

  CryptoPrice({
    required this.symbol,
    required this.price,
    required this.change24h,
  });

  bool get isPositive => change24h >= 0;
}
