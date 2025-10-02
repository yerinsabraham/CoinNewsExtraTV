import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_balance_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
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
              'Wallet',
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
                onPressed: () => balanceService.loadUserBalance(),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () => _showTransactionHistory(context, balanceService),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => balanceService.loadUserBalance(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet balance card with green theme
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF006833),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Balance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              Row(
                                children: [
                                  if (balanceService.isLoading)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006833).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'CNE',
                                      style: TextStyle(
                                        color: Color(0xFF006833),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Lato',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            balanceService.getFormattedBalance(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '≈ \$0.10',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Lato',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Balance breakdown with green theme
                          Row(
                            children: [
                              Expanded(
                                child: _buildBalanceDetail(
                                  'Available Balance',
                                  balanceService.balance.toStringAsFixed(2),
                                  Icons.account_balance_wallet,
                                  const Color(0xFF006833),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons with green theme
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.send,
                            label: 'Send',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Send feature coming soon!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.qr_code,
                            label: 'Receive',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receive feature coming soon!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.swap_horiz,
                            label: 'Swap',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Swap feature coming soon!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Assets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Assets list with green theme
                    _buildAssetItem(
                      symbol: 'CNE',
                      name: 'CoinNewsExtra Token',
                      balance: balanceService.getFormattedBalance(),
                      value: balanceService.getFormattedUsdValue(),
                      change: '+0.00%',
                      isPositive: true,
                    ),

                    const SizedBox(height: 24),

                    // Recent transactions
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildRecentTransactions(balanceService),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF006833),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem({
    required String symbol,
    required String name,
    required String balance,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
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
            child: const Icon(
              Icons.currency_bitcoin,
              color: Color(0xFF006833),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDetail(String label, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\ CNE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(UserBalanceService balanceService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lato',
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Start earning to see your transaction history',
            textAlign: TextAlign.center,
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

  void _showTransactionHistory(BuildContext context, UserBalanceService balanceService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: Center(
                  child: Text(
                    'No transaction history available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
