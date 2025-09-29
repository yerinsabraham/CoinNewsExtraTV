import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'reward_service.dart';

class UserBalance {
  final double totalBalance;
  final double lockedBalance;
  final double unlockedBalance;
  final double pendingBalance;
  final int totalEarnings;
  final double totalUsdValue;
  final String lastUpdated;

  UserBalance({
    required this.totalBalance,
    required this.lockedBalance,
    required this.unlockedBalance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.totalUsdValue,
    required this.lastUpdated,
  });

  factory UserBalance.fromMap(Map<String, dynamic> data) {
    return UserBalance(
      totalBalance: (data['totalBalance'] ?? 0.0).toDouble(),
      lockedBalance: (data['lockedBalance'] ?? 0.0).toDouble(),
      unlockedBalance: (data['unlockedBalance'] ?? 0.0).toDouble(),
      pendingBalance: (data['pendingBalance'] ?? 0.0).toDouble(),
      totalEarnings: data['totalEarnings'] ?? 0,
      totalUsdValue: (data['totalUsdValue'] ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated'] ?? DateTime.now().toIso8601String(),
    );
  }

  factory UserBalance.empty() {
    return UserBalance(
      totalBalance: 0.0,
      lockedBalance: 0.0,
      unlockedBalance: 0.0,
      pendingBalance: 0.0,
      totalEarnings: 0,
      totalUsdValue: 0.0,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }
}

class EarningStats {
  final int videosWatched;
  final int quizzesCompleted;
  final int dailyCheckIns;
  final int referrals;
  final int socialFollows;
  final int adsWatched;
  final int liveStreamsWatched;
  final double totalVideoRewards;
  final double totalQuizRewards;
  final double totalDailyRewards;
  final double totalReferralRewards;
  final double totalSocialRewards;
  final double totalAdRewards;
  final double totalLiveStreamRewards;
  final int currentStreak;
  final int longestStreak;

  EarningStats({
    required this.videosWatched,
    required this.quizzesCompleted,
    required this.dailyCheckIns,
    required this.referrals,
    required this.socialFollows,
    required this.adsWatched,
    required this.liveStreamsWatched,
    required this.totalVideoRewards,
    required this.totalQuizRewards,
    required this.totalDailyRewards,
    required this.totalReferralRewards,
    required this.totalSocialRewards,
    required this.totalAdRewards,
    required this.totalLiveStreamRewards,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory EarningStats.fromMap(Map<String, dynamic> data) {
    return EarningStats(
      videosWatched: data['videosWatched'] ?? 0,
      quizzesCompleted: data['quizzesCompleted'] ?? 0,
      dailyCheckIns: data['dailyCheckIns'] ?? 0,
      referrals: data['referrals'] ?? 0,
      socialFollows: data['socialFollows'] ?? 0,
      adsWatched: data['adsWatched'] ?? 0,
      liveStreamsWatched: data['liveStreamsWatched'] ?? 0,
      totalVideoRewards: (data['totalVideoRewards'] ?? 0.0).toDouble(),
      totalQuizRewards: (data['totalQuizRewards'] ?? 0.0).toDouble(),
      totalDailyRewards: (data['totalDailyRewards'] ?? 0.0).toDouble(),
      totalReferralRewards: (data['totalReferralRewards'] ?? 0.0).toDouble(),
      totalSocialRewards: (data['totalSocialRewards'] ?? 0.0).toDouble(),
      totalAdRewards: (data['totalAdRewards'] ?? 0.0).toDouble(),
      totalLiveStreamRewards: (data['totalLiveStreamRewards'] ?? 0.0).toDouble(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
    );
  }

  factory EarningStats.empty() {
    return EarningStats(
      videosWatched: 0,
      quizzesCompleted: 0,
      dailyCheckIns: 0,
      referrals: 0,
      socialFollows: 0,
      adsWatched: 0,
      liveStreamsWatched: 0,
      totalVideoRewards: 0.0,
      totalQuizRewards: 0.0,
      totalDailyRewards: 0.0,
      totalReferralRewards: 0.0,
      totalSocialRewards: 0.0,
      totalAdRewards: 0.0,
      totalLiveStreamRewards: 0.0,
      currentStreak: 0,
      longestStreak: 0,
    );
  }
}

class RewardAmounts {
  final double videoReward;
  final double quizReward;
  final double dailyReward;
  final double signupBonus;
  final double referralReward;
  final double socialReward;
  final double adReward;
  final double liveStreamReward;
  final int currentEpoch;
  final DateTime nextHalvingDate;

  RewardAmounts({
    required this.videoReward,
    required this.quizReward,
    required this.dailyReward,
    required this.signupBonus,
    required this.referralReward,
    required this.socialReward,
    required this.adReward,
    required this.liveStreamReward,
    required this.currentEpoch,
    required this.nextHalvingDate,
  });

  factory RewardAmounts.fromMap(Map<String, dynamic> data) {
    return RewardAmounts(
      videoReward: (data['videoReward'] ?? 5.0).toDouble(),
      quizReward: (data['quizReward'] ?? 10.0).toDouble(),
      dailyReward: (data['dailyReward'] ?? 20.0).toDouble(),
      signupBonus: (data['signupBonus'] ?? 100.0).toDouble(),
      referralReward: (data['referralReward'] ?? 50.0).toDouble(),
      socialReward: (data['socialReward'] ?? 15.0).toDouble(),
      adReward: (data['adReward'] ?? 3.0).toDouble(),
      liveStreamReward: (data['liveStreamReward'] ?? 8.0).toDouble(),
      currentEpoch: data['currentEpoch'] ?? 1,
      nextHalvingDate: DateTime.parse(data['nextHalvingDate'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String()),
    );
  }

  factory RewardAmounts.defaults() {
    return RewardAmounts(
      videoReward: 5.0,
      quizReward: 10.0,
      dailyReward: 20.0,
      signupBonus: 100.0,
      referralReward: 50.0,
      socialReward: 15.0,
      adReward: 3.0,
      liveStreamReward: 8.0,
      currentEpoch: 1,
      nextHalvingDate: DateTime.now().add(const Duration(days: 365)),
    );
  }
}

class UserBalanceService extends ChangeNotifier {
  static final UserBalanceService _instance = UserBalanceService._internal();
  factory UserBalanceService() => _instance;
  UserBalanceService._internal();

  UserBalance _balance = UserBalance.empty();
  EarningStats _stats = EarningStats.empty();
  RewardAmounts _rewardAmounts = RewardAmounts.defaults();
  List<Map<String, dynamic>> _recentTransactions = [];
  
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  // Getters
  UserBalance get balance => _balance;
  EarningStats get stats => _stats;
  RewardAmounts get rewardAmounts => _rewardAmounts;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize service
  Future<void> initialize() async {
    await refreshAll();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshBalance();
    });
  }

  // Refresh all user data
  Future<void> refreshAll() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        refreshBalance(),
        refreshStats(),
        refreshRewardAmounts(),
        refreshTransactions(),
      ]);
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }

    _setLoading(false);
  }

  // Refresh user balance
  Future<void> refreshBalance() async {
    try {
      final data = await RewardService.getUserBalance();
      if (data != null) {
        _balance = UserBalance.fromMap(data);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh balance: $e');
    }
  }

  // Refresh earning statistics
  Future<void> refreshStats() async {
    try {
      final data = await RewardService.getUserEarningStats();
      if (data != null) {
        _stats = EarningStats.fromMap(data);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh stats: $e');
    }
  }

  // Refresh current reward amounts
  Future<void> refreshRewardAmounts() async {
    try {
      final data = await RewardService.getCurrentRewardAmounts();
      if (data != null) {
        _rewardAmounts = RewardAmounts.fromMap(data);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh reward amounts: $e');
    }
  }

  // Refresh transaction history
  Future<void> refreshTransactions({bool loadMore = false}) async {
    try {
      final lastId = loadMore && _recentTransactions.isNotEmpty 
          ? _recentTransactions.last['id'] 
          : null;
      
      final transactions = await RewardService.getTransactionHistory(
        limit: 20,
        lastTransactionId: lastId,
      );
      
      if (transactions != null) {
        if (loadMore) {
          _recentTransactions.addAll(transactions);
        } else {
          _recentTransactions = transactions;
        }
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh transactions: $e');
    }
  }

  // Process a reward claim and update local data
  Future<bool> processRewardClaim(Map<String, dynamic> rewardResult) async {
    try {
      if (rewardResult['success'] == true) {
        // Update local balance immediately for better UX
        final rewardAmount = (rewardResult['rewardAmount'] ?? 0.0).toDouble();
        _balance = UserBalance(
          totalBalance: _balance.totalBalance + rewardAmount,
          lockedBalance: _balance.lockedBalance + rewardAmount,
          unlockedBalance: _balance.unlockedBalance,
          pendingBalance: _balance.pendingBalance,
          totalEarnings: _balance.totalEarnings + 1,
          totalUsdValue: _balance.totalUsdValue + (rewardResult['usdValue'] ?? 0.0),
          lastUpdated: DateTime.now().toIso8601String(),
        );

        notifyListeners();

        // Refresh full data in background
        Future.delayed(const Duration(milliseconds: 500), () {
          refreshAll();
        });

        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to process reward: $e');
      return false;
    }
  }

  // Get formatted balance string
  String getFormattedBalance({bool showDecimals = true}) {
    if (showDecimals) {
      return _balance.totalBalance.toStringAsFixed(2);
    } else {
      return _balance.totalBalance.toInt().toString();
    }
  }

  // Get formatted USD value
  String getFormattedUsdValue() {
    return '\$${_balance.totalUsdValue.toStringAsFixed(2)}';
  }

  // Check if user has sufficient balance for operations
  bool hasSufficientBalance(double amount) {
    return _balance.unlockedBalance >= amount;
  }

  // Get time until next halving
  Duration getTimeUntilNextHalving() {
    return _rewardAmounts.nextHalvingDate.difference(DateTime.now());
  }

  // Get days until next halving
  int getDaysUntilNextHalving() {
    final duration = getTimeUntilNextHalving();
    return duration.inDays;
  }

  // Format reward amount for display
  String formatRewardAmount(double amount) {
    return '${amount.toStringAsFixed(1)} CNE';
  }

  // Initialize user rewards (for new users)
  Future<bool> initializeUserRewards() async {
    try {
      final result = await RewardService.initializeUserRewards();
      if (result != null && result['success'] == true) {
        await refreshAll();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to initialize user rewards: $e');
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('UserBalanceService Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Reset service (for logout)
  void reset() {
    _refreshTimer?.cancel();
    _balance = UserBalance.empty();
    _stats = EarningStats.empty();
    _rewardAmounts = RewardAmounts.defaults();
    _recentTransactions = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Listen to auth state changes
  void listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        initialize();
      } else {
        reset();
      }
    });
  }
}
