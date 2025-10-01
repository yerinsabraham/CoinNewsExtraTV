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
  final int adsWatched;
  final int dailyRewardsClaimed;
  final int socialRewardsClaimed;
  final int referralRewardsClaimed;
  final double totalEarned;
  final String lastActivity;

  EarningStats({
    required this.videosWatched,
    required this.adsWatched,
    required this.dailyRewardsClaimed,
    required this.socialRewardsClaimed,
    required this.referralRewardsClaimed,
    required this.totalEarned,
    required this.lastActivity,
  });

  factory EarningStats.fromMap(Map<String, dynamic> data) {
    return EarningStats(
      videosWatched: data['videosWatched'] ?? 0,
      adsWatched: data['adsWatched'] ?? 0,
      dailyRewardsClaimed: data['dailyRewardsClaimed'] ?? 0,
      socialRewardsClaimed: data['socialRewardsClaimed'] ?? 0,
      referralRewardsClaimed: data['referralRewardsClaimed'] ?? 0,
      totalEarned: (data['totalEarned'] ?? 0.0).toDouble(),
      lastActivity: data['lastActivity'] ?? DateTime.now().toIso8601String(),
    );
  }

  factory EarningStats.empty() {
    return EarningStats(
      videosWatched: 0,
      adsWatched: 0,
      dailyRewardsClaimed: 0,
      socialRewardsClaimed: 0,
      referralRewardsClaimed: 0,
      totalEarned: 0.0,
      lastActivity: DateTime.now().toIso8601String(),
    );
  }
}

class RewardAmounts {
  final double videoReward;
  final double adReward;
  final double dailyReward;
  final double socialReward;
  final double referralReward;
  final double signupBonus;
  final double quizReward;
  final double liveStreamReward;
  final int currentEpoch;

  RewardAmounts({
    required this.videoReward,
    required this.adReward,
    required this.dailyReward,
    required this.socialReward,
    required this.referralReward,
    required this.signupBonus,
    required this.quizReward,
    required this.liveStreamReward,
    required this.currentEpoch,
  });

  factory RewardAmounts.fromMap(Map<String, dynamic> data) {
    return RewardAmounts(
      videoReward: (data['video_watch'] ?? 1.0).toDouble(),
      adReward: (data['ad_view'] ?? 0.5).toDouble(),
      dailyReward: (data['daily_airdrop'] ?? 5.0).toDouble(),
      socialReward: (data['social_follow'] ?? 2.0).toDouble(),
      referralReward: (data['referral_reward'] ?? 10.0).toDouble(),
      signupBonus: (data['signup'] ?? 50.0).toDouble(),
      quizReward: (data['quiz_completion'] ?? 3.0).toDouble(),
      liveStreamReward: (data['live_stream'] ?? 2.0).toDouble(),
      currentEpoch: (data['currentEpoch'] ?? 1).toInt(),
    );
  }

  factory RewardAmounts.defaultAmounts() {
    return RewardAmounts(
      videoReward: 1.0,
      adReward: 0.5,
      dailyReward: 5.0,
      socialReward: 2.0,
      referralReward: 10.0,
      signupBonus: 50.0,
      quizReward: 3.0,
      liveStreamReward: 2.0,
      currentEpoch: 1,
    );
  }
}

class UserBalanceService extends ChangeNotifier {
  UserBalance _balance = UserBalance.empty();
  EarningStats _earningStats = EarningStats.empty();
  RewardAmounts _rewardAmounts = RewardAmounts.defaultAmounts();
  List<Map<String, dynamic>> _transactionHistory = [];
  
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _authSubscription;
  
  // Getters
  UserBalance get balance => _balance;
  EarningStats get earningStats => _earningStats;
  RewardAmounts get rewardAmounts => _rewardAmounts;
  List<Map<String, dynamic>> get transactionHistory => _transactionHistory;
  List<Map<String, dynamic>> get recentTransactions => _transactionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserBalanceService() {
    _initializeService();
  }

  void _initializeService() {
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, load their balance
        loadUserBalance();
      } else {
        // User signed out, reset to empty state
        _resetToEmpty();
      }
    });
  }

  void _resetToEmpty() {
    _balance = UserBalance.empty();
    _earningStats = EarningStats.empty();
    _rewardAmounts = RewardAmounts.defaultAmounts();
    _transactionHistory = [];
    _error = null;
    notifyListeners();
  }

  Future<void> loadUserBalance() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _error = null;

    try {
      // Load balance
      final data = await RewardService.getUserBalance();
      if (data != null && data['success'] == true) {
        _balance = UserBalance.fromMap(data['balance'] ?? {});
      } else {
        _balance = UserBalance.empty();
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load balance: $e';
      debugPrint('Error loading user balance: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEarningStats() async {
    try {
      final data = await RewardService.getUserEarningStats();
      if (data != null && data['success'] == true) {
        _earningStats = EarningStats.fromMap(data['stats'] ?? {});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading earning stats: $e');
    }
  }

  Future<void> loadRewardAmounts() async {
    try {
      final data = await RewardService.getCurrentRewardAmounts();
      if (data != null && data['success'] == true) {
        _rewardAmounts = RewardAmounts.fromMap(data['data'] ?? {});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading reward amounts: $e');
    }
  }

  Future<void> loadTransactionHistory({String? lastTransactionId}) async {
    try {
      final transactions = await RewardService.getTransactionHistory(
        limit: 50,
      );
      
      if (transactions != null) {
        if (lastTransactionId == null) {
          _transactionHistory = transactions;
        } else {
          _transactionHistory.addAll(transactions);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading transaction history: $e');
    }
  }

  Future<void> refreshAllData() async {
    await Future.wait([
      loadUserBalance(),
      loadEarningStats(),
      loadRewardAmounts(),
      loadTransactionHistory(),
    ]);
  }

  Map<String, dynamic> getBalanceDisplay() {
    return {
      'totalBalance': _balance.totalBalance,
      'lockedBalance': _balance.lockedBalance,
      'unlockedBalance': _balance.unlockedBalance,
      'pendingBalance': _balance.pendingBalance,
      'totalUsdValue': _balance.totalUsdValue,
    };
  }

  double get availableBalance => _balance.unlockedBalance;
  
  bool canAfford(double amount) {
    return _balance.unlockedBalance >= amount;
  }

  // Formatting methods
  String getFormattedBalance() {
    return _balance.totalBalance.toStringAsFixed(2);
  }

  String getFormattedUsdValue() {
    return '\$${_balance.totalUsdValue.toStringAsFixed(2)}';
  }

  // Refresh methods
  Future<void> refreshAll() async {
    await refreshAllData();
  }

  Future<void> initialize() async {
    await initializeUser();
  }

  void listenToAuthChanges() {
    // Already handled in constructor
  }

  Future<bool> spendBalance(double amount) async {
    if (!canAfford(amount)) {
      return false;
    }

    // This would typically make an API call to spend the balance
    // For now, we'll just refresh the balance
    await loadUserBalance();
    return true;
  }

  // Process a reward claim result
  Future<void> processRewardClaim(Map<String, dynamic> result) async {
    if (result['success'] == true) {
      // Refresh balance after successful claim
      await loadUserBalance();
      await loadEarningStats();
    }
  }

  // Initialize user in reward system
  Future<bool> initializeUser() async {
    try {
      final result = await RewardService.initializeUserRewards();
      if (result != null && result['success'] == true) {
        await loadUserBalance();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to initialize user: $e';
      debugPrint('Error initializing user: $e');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add transaction to recent transactions list for immediate UI feedback
  void addRecentTransaction(Map<String, dynamic> transaction) {
    _transactionHistory.insert(0, transaction);
    // Keep only the last 10 transactions
    if (_transactionHistory.length > 10) {
      _transactionHistory = _transactionHistory.take(10).toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
