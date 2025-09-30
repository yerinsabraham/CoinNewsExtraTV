import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/reward_service.dart';

class CMEWalletPage extends StatefulWidget {
  const CMEWalletPage({Key? key}) : super(key: key);

  @override
  State<CMEWalletPage> createState() => _CMEWalletPageState();
}

class _CMEWalletPageState extends State<CMEWalletPage> {
  CMEBalance? balance;
  bool isLoading = true;
  String? error;
  final TextEditingController _redeemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final fetchedBalance = await RewardService.getUserBalance();
      setState(() {
        balance = fetchedBalance;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _unlockTokens() async {
    try {
      final result = await RewardService.unlockExpiredTokens();
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlocked ${result['unlockedAmount']} CME tokens!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBalance(); // Refresh balance
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unlocking tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _redeemTokens() async {
    final amountText = _redeemController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (balance != null && amount > balance!.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient available balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await RewardService.redeemTokens(amount);
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redemption queued: ${result['redemptionId']}'),
            backgroundColor: Colors.green,
          ),
        );
        _redeemController.clear();
        _loadBalance(); // Refresh balance
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error redeeming tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CME Wallet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBalance,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading wallet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBalance,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBalance,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Overview Card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: Theme.of(context).primaryColor,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'CME Token Balance',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildBalanceRow('Available', balance?.available ?? 0, Colors.green),
                                const SizedBox(height: 12),
                                _buildBalanceRow('Locked', balance?.locked ?? 0, Colors.orange),
                                const SizedBox(height: 12),
                                _buildBalanceRow('Unlockable', balance?.unlockable ?? 0, Colors.blue),
                                const Divider(height: 32),
                                _buildBalanceRow('Total', balance?.total ?? 0, Theme.of(context).primaryColor, isTotal: true),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Wallet Info Card
                        if (balance?.walletAddress != null) ...[
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wallet Information',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Hedera Account', balance!.walletAddress!),
                                  if (balance!.did != null) ...[
                                    const SizedBox(height: 8),
                                    _buildInfoRow('DID', balance!.did!),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Token Locks Card
                        if (balance?.activeLocks.isNotEmpty == true) ...[
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Token Locks',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...balance!.activeLocks.map((lock) => _buildLockItem(lock)).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Actions Card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Actions',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Unlock Tokens Button
                                if (balance?.unlockable != null && balance!.unlockable > 0) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _unlockTokens,
                                      icon: const Icon(Icons.lock_open),
                                      label: Text('Unlock ${balance!.unlockable.toStringAsFixed(2)} CME'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Redeem Tokens Section
                                Text(
                                  'Redeem to On-Chain Tokens',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Convert your available CME points to real blockchain tokens',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _redeemController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Amount to Redeem',
                                    suffixText: 'CME',
                                    border: const OutlineInputBorder(),
                                    helperText: 'Available: ${balance?.available.toStringAsFixed(2) ?? '0.00'} CME',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: balance?.available != null && balance!.available > 0 
                                        ? _redeemTokens 
                                        : null,
                                    icon: const Icon(Icons.swap_horiz),
                                    label: const Text('Redeem Tokens'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Information Card
                        Card(
                          elevation: 2,
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How It Works',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '• Available tokens can be redeemed to on-chain CME tokens\n'
                                  '• Locked tokens are released after 2 years from earning\n'
                                  '• Your custodial Hedera wallet is managed securely\n'
                                  '• All transactions are recorded on Hedera blockchain',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceRow(String label, double value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? color : Colors.grey[700],
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} CME',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        Icon(Icons.copy, size: 16, color: Colors.grey[500]),
      ],
    );
  }

  Widget _buildLockItem(TokenLock lock) {
    final now = DateTime.now();
    final timeRemaining = lock.unlockDate.difference(now);
    final isExpired = timeRemaining.isNegative;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isExpired ? Colors.green[300]! : Colors.grey[300]!,
          width: isExpired ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isExpired ? Colors.green[50] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${lock.amount.toStringAsFixed(2)} CME',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isExpired ? Colors.green[700] : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isExpired ? 'UNLOCKABLE' : lock.source.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (!isExpired) ...[
            // Countdown timer
            Text(
              'Unlocks: ${lock.unlockDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRemaining(timeRemaining),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  'Ready to unlock!',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          
          // Progress bar for vesting
          if (!isExpired) ...[
            const SizedBox(height: 8),
            _buildVestingProgressBar(lock.unlockDate),
          ],
        ],
      ),
    );
  }

  Widget _buildVestingProgressBar(DateTime unlockDate) {
    final vestingPeriod = Duration(days: 2 * 365); // 2 years
    final startDate = unlockDate.subtract(vestingPeriod);
    final now = DateTime.now();
    
    final totalDuration = unlockDate.difference(startDate);
    final elapsed = now.difference(startDate);
    final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vesting Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 0.8 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 365) {
      final years = (duration.inDays / 365).floor();
      final months = ((duration.inDays % 365) / 30).floor();
      return '${years}y ${months}m';
    } else if (duration.inDays > 30) {
      final months = (duration.inDays / 30).floor();
      final days = duration.inDays % 30;
      return '${months}m ${days}d';
    } else if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }
}
