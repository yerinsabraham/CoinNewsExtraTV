import 'package:flutter/material.dart';

class TrendingCoinsSection extends StatelessWidget {
  const TrendingCoinsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full market page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Market page coming soon!'),
                      backgroundColor: Color(0xFF006833),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: const Color(0xFF006833),
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Fiat/ USD prefix removed — show numeric price only per product requirement
                _buildCoinCard('BTC', 'Bitcoin', '67,450', '+2.5%', true),
                _buildCoinCard('ETH', 'Ethereum', '3,245', '+1.8%', true),
                _buildCoinCard('BNB', 'BNB', '445', '-0.7%', false),
                _buildCoinCard('SOL', 'Solana', '168', '+4.2%', true),
                _buildCoinCard('ADA', 'Cardano', '0.52', '-1.1%', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinCard(
    String symbol,
    String name,
    String price,
    String change,
    bool isPositive,
  ) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0F0F0F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF006833),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    symbol.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change,
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
