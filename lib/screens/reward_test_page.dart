import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../services/user_balance_service.dart';

class RewardSystemTestPage extends StatefulWidget {
  const RewardSystemTestPage({super.key});

  @override
  State<RewardSystemTestPage> createState() => _RewardSystemTestPageState();
}

class _RewardSystemTestPageState extends State<RewardSystemTestPage> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _testResults = [];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Reward System Test',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _runAllTests,
          ),
        ],
      ),
      body: Consumer<UserBalanceService>(
        builder: (context, balanceService, child) {
          return Column(
            children: [
              // Current Balance Display
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF006833)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${balanceService.getFormattedBalance()} CNE',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Locked: ${balanceService.balance.lockedBalance.toStringAsFixed(2)} CNE',
                      style: const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                    Text(
                      'Available: ${balanceService.balance.unlockedBalance.toStringAsFixed(2)} CNE',
                      style: const TextStyle(color: Color(0xFF006833), fontSize: 14),
                    ),
                    Text(
                      'USD Value: ${balanceService.getFormattedUsdValue()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Test Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton('Video Reward', _testVideoReward),
                    _buildTestButton('Quiz Reward', _testQuizReward),
                    _buildTestButton('Daily Reward', _testDailyReward),
                    _buildTestButton('Social Reward', _testSocialReward),
                    _buildTestButton('Ad Reward', _testAdReward),
                    _buildTestButton('Live Stream', _testLiveStreamReward),
                    _buildTestButton('Referral Code', _testReferralCode),
                    _buildTestButton('Get Balance', _testGetBalance),
                    _buildTestButton('Reward Amounts', _testRewardAmounts),
                    _buildTestButton('Transaction History', _testTransactionHistory),
                    _buildTestButton('Clear Results', _clearResults),
                    _buildTestButton('Run All Tests', _runAllTests),
                  ],
                ),
              ),

              // Test Results
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Test Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isTesting)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _testResults.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _testResults[index],
                                style: TextStyle(
                                  color: _testResults[index].contains('✅') 
                                      ? Colors.green 
                                      : _testResults[index].contains('❌')
                                          ? Colors.red
                                          : Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isTesting ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006833),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toIso8601String().substring(11, 19)}: $result');
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _testVideoReward() async {
    _addResult('Testing video reward...');
    try {
      final result = await RewardService.claimVideoReward(
        videoId: 'test_video_${DateTime.now().millisecondsSinceEpoch}',
        watchDurationSeconds: 45,
        totalDurationSeconds: 60,
      );
      
      if (result != null && result.success == true) {
        _addResult('✅ Video reward: +${result.reward ?? 0} CNE');
        await _refreshBalance();
      } else {
        _addResult('❌ Video reward failed: ${result?.message ?? 'Unknown error'}');
      }
    } catch (e) {
      _addResult('❌ Video reward error: $e');
    }
  }

  Future<void> _testQuizReward() async {
    _addResult('Testing quiz reward...');
    try {
      final result = await RewardService.claimQuizReward(
        quizId: 'test_quiz_${DateTime.now().millisecondsSinceEpoch}',
        score: 8,
        totalQuestions: 10,
      );
      
      if (result != null && result.success == true) {
        _addResult('✅ Quiz reward: +${result.reward ?? 0} CNE');
        await _refreshBalance();
      } else {
        _addResult('❌ Quiz reward failed: ${result?.message ?? 'Unknown error'}');
      }
    } catch (e) {
      _addResult('❌ Quiz reward error: $e');
    }
  }

  Future<void> _testDailyReward() async {
    _addResult('Testing daily reward...');
    try {
      final result = await RewardService.claimDailyReward();
      
      if (result != null && result.success == true) {
        _addResult('✅ Daily reward: +${result.reward ?? 0} CNE');
        await _refreshBalance();
      } else {
        _addResult('❌ Daily reward failed: ${result?.message ?? 'Unknown error'}');
      }
    } catch (e) {
      _addResult('❌ Daily reward error: $e');
    }
  }

  Future<void> _testSocialReward() async {
    _addResult('Testing social media reward...');
    try {
      final result = await RewardService.claimSocialReward(
        platform: 'twitter',
      );
      
      if (result != null && result.success == true) {
        _addResult('✅ Social reward: +${result.reward ?? 0} CNE');
        await _refreshBalance();
      } else {
        _addResult('❌ Social reward failed: ${result?.message ?? 'Unknown error'}');
      }
    } catch (e) {
      _addResult('❌ Social reward error: $e');
    }
  }

  Future<void> _testAdReward() async {
    _addResult('Testing ad reward...');
    try {
      final result = await RewardService.claimAdReward(
        adId: 'test_ad_${DateTime.now().millisecondsSinceEpoch}',
        adDurationSeconds: 30,
      );
      
      if (result != null && result.success == true) {
        _addResult('✅ Ad reward: +${result.reward ?? 0} CNE');
        await _refreshBalance();
      } else {
        _addResult('❌ Ad reward failed: ${result?.message ?? 'Unknown error'}');
      }
    } catch (e) {
      _addResult('❌ Ad reward error: $e');
    }
  }

  Future<void> _testLiveStreamReward() async {
    _addResult('Testing live stream reward...');
    try {
      final result = await RewardService.claimLiveStreamReward(
        streamId: 'test_stream_${DateTime.now().millisecondsSinceEpoch}',
        watchDurationSeconds: 300,
      );
      
      if (result != null && result.success == true) {
        _addResult('✅ Live stream reward: +${result.reward ?? 0} CNE');
        await _refreshBalance();
      } else {
        _addResult('❌ Live stream reward failed: ${result?.message ?? 'Unknown error'}');
      }
    } catch (e) {
      _addResult('❌ Live stream reward error: $e');
    }
  }

  Future<void> _testReferralCode() async {
    _addResult('Testing referral code generation...');
    try {
      final code = await RewardService.getUserReferralCode();
      if (code != null) {
        _addResult('✅ Referral code: $code');
      } else {
        _addResult('❌ Failed to get referral code');
      }
    } catch (e) {
      _addResult('❌ Referral code error: $e');
    }
  }

  Future<void> _testGetBalance() async {
    _addResult('Testing balance retrieval...');
    try {
      final balance = await RewardService.getUserBalance();
      if (balance != null) {
        _addResult('✅ Balance: ${balance['totalBalance']} CNE (${balance['lockedBalance']} locked)');
      } else {
        _addResult('❌ Failed to get balance');
      }
    } catch (e) {
      _addResult('❌ Balance error: $e');
    }
  }

  Future<void> _testRewardAmounts() async {
    _addResult('Testing current reward amounts...');
    try {
      final amounts = await RewardService.getCurrentRewardAmounts();
      if (amounts != null) {
        _addResult('✅ Current rewards: Video=${amounts['videoReward']}, Quiz=${amounts['quizReward']}, Daily=${amounts['dailyReward']}');
        _addResult('   Epoch: ${amounts['currentEpoch']}, Next halving: ${amounts['nextHalvingDate']}');
      } else {
        _addResult('❌ Failed to get reward amounts');
      }
    } catch (e) {
      _addResult('❌ Reward amounts error: $e');
    }
  }

  Future<void> _testTransactionHistory() async {
    _addResult('Testing transaction history...');
    try {
      final transactions = await RewardService.getTransactionHistory(limit: 5);
      if (transactions != null) {
        _addResult('✅ Transaction history: ${transactions.length} transactions');
        for (final tx in transactions.take(3)) {
          _addResult('   ${tx['type']}: +${tx['amount']} CNE');
        }
      } else {
        _addResult('❌ Failed to get transaction history');
      }
    } catch (e) {
      _addResult('❌ Transaction history error: $e');
    }
  }

  Future<void> _refreshBalance() async {
    final balanceService = Provider.of<UserBalanceService>(context, listen: false);
    await balanceService.loadUserBalance();
  }

  Future<void> _runAllTests() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    _addResult('🚀 Starting comprehensive reward system test...');
    
    await _testRewardAmounts();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testGetBalance();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testVideoReward();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testQuizReward();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testDailyReward();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testSocialReward();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testAdReward();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testLiveStreamReward();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testReferralCode();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testTransactionHistory();
    
    _addResult('🎉 All tests completed!');
    
    setState(() {
      _isTesting = false;
    });
  }
}
