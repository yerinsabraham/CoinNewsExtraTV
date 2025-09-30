import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cme_config_service.dart';
import '../config/environment_config.dart';
import 'did_auth_service.dart';
import 'smart_contract_service.dart';

// CME Token Constants (must match Firebase Functions)
const int CME_TOKEN_DECIMALS = 8;
const int CME_MULTIPLIER = 100000000; // Math.pow(10, 8)

// CME Token Price (USD) - This should be fetched from a price API in production
const double CME_PRICE_USD = 0.01; // $0.01 per CME token

// CME Unit Conversion Functions
double fromCMEUnits(dynamic rawUnits) {
  if (rawUnits == null) return 0.0;
  final units = rawUnits is int ? rawUnits : (rawUnits as num).toInt();
  return units / CME_MULTIPLIER;
}

int toCMEUnits(double humanAmount) {
  return (humanAmount * CME_MULTIPLIER).floor();
}

// USD Value Calculation
double calculateUSDValue(double cmeAmount) {
  return cmeAmount * CME_PRICE_USD;
}

// CME Token Balance Model
class CMEBalance {
  final double total;      // Total lifetime earnings
  final double available;  // Available balance to spend/redeem
  final double locked;     // Locked (vesting) balance
  final List<TokenLock> vestingSchedule;
  
  CMEBalance({
    required this.total,
    required this.available,
    required this.locked,
    this.vestingSchedule = const [],
  });
  
  factory CMEBalance.fromMap(Map<String, dynamic> map) {
    print('CMEBalance.fromMap - Raw map data: $map');
    
    final vestingList = (map['vestingSchedule'] as List<dynamic>?)?.map((v) => 
      TokenLock.fromMap(v as Map<String, dynamic>)).toList() ?? <TokenLock>[];
    
    // Firebase stores balances with different field names and in raw CME units
    final totalRaw = map['total_earned'] ?? map['total'] ?? 0;
    final availableRaw = map['available_balance'] ?? map['available'] ?? 0;  
    final lockedRaw = map['locked_balance'] ?? map['locked'] ?? 0;
    
    print('CMEBalance.fromMap - Raw units: total=$totalRaw, available=$availableRaw, locked=$lockedRaw');
    
    // Convert to human-readable amounts
    final availableAmount = fromCMEUnits(availableRaw);
    final lockedAmount = fromCMEUnits(lockedRaw);
    final totalAmount = fromCMEUnits(totalRaw);
    
    // If total_earned is 0 but we have balances, calculate total from available + locked
    final calculatedTotal = totalAmount > 0 ? totalAmount : (availableAmount + lockedAmount);
    
    print('CMEBalance.fromMap - Calculated total: $calculatedTotal (totalAmount=$totalAmount, fallback=${availableAmount + lockedAmount})');
    
    final result = CMEBalance(
      total: calculatedTotal,
      available: availableAmount,
      locked: lockedAmount,
      vestingSchedule: vestingList,
    );
    
    print('CMEBalance.fromMap - Converted result: total=${result.total}, available=${result.available}, locked=${result.locked}');
    return result;
  }
  
  Map<String, dynamic> toMap() {
    return {
      // Legacy field names for UserBalance compatibility
      'totalBalance': total,
      'unlockedBalance': available, 
      'lockedBalance': locked,
      'totalEarnings': total.toInt(),
      'pendingBalance': 0.0,
      'totalUsdValue': calculateUSDValue(total),
      'lastUpdated': DateTime.now().toIso8601String(),
      
      // New CME field names for future use
      'total': total,
      'available': available,
      'locked': locked,
      'vestingSchedule': vestingSchedule.map((v) => v.toMap()).toList(),
    };
  }
}

// Token Lock/Vesting Model
class TokenLock {
  final double amount;
  final DateTime unlockDate;
  final String reason;
  
  TokenLock({
    required this.amount,
    required this.unlockDate,
    required this.reason,
  });
  
  factory TokenLock.fromMap(Map<String, dynamic> map) {
    return TokenLock(
      amount: (map['amount'] ?? 0.0).toDouble(),
      unlockDate: DateTime.fromMillisecondsSinceEpoch(map['unlockDate'] ?? 0),
      reason: map['reason'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'unlockDate': unlockDate.millisecondsSinceEpoch,
      'reason': reason,
    };
  }
  
  bool get isUnlocked => DateTime.now().isAfter(unlockDate);
}

// Reward Result Model
class RewardResult {
  final bool success;
  final String message;
  final double? reward;
  final Map<String, dynamic>? data;
  
  RewardResult({
    required this.success,
    required this.message,
    this.reward,
    this.data,
  });
  
  factory RewardResult.fromMap(Map<String, dynamic> map) {
    final parsedReward = _parseRewardAmount(map['reward']);
    print('🔍 DEBUG: Parsing reward from map: ${map['reward']} -> $parsedReward');
    
    return RewardResult(
      success: map['success'] ?? false,
      message: map['message'] ?? '',
      reward: parsedReward,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data'] as Map) : null,
    );
  }
  
  static double? _parseRewardAmount(dynamic value) {
    if (value == null) return null;
    
    // If it's a nested reward object, extract the amount
    if (value is Map) {
      final amount = value['amount'];
      print('🔍 DEBUG: Extracting amount from reward map: $amount (type: ${amount.runtimeType})');
      if (amount is double) return amount;
      if (amount is int) return amount.toDouble();
      if (amount is String) return double.tryParse(amount);
      return 0.0;
    }
    
    // If it's a direct numeric value
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return 0.0;
  }
}

class RewardService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static User? get _currentUser => FirebaseAuth.instance.currentUser;
  static String? get _userId => _currentUser?.uid;

  // ===== CORE CME TOKEN METHODS =====

  /// Get user's CME token balance with vesting details
  static Future<CMEBalance?> getCMEBalance() async {
    if (_userId == null) return null;
    
    try {
      print('🔍 DEBUG: Fetching user balance for $_userId');
      final result = await _functions.httpsCallable('getUserRewardBalance').call({});
      
      print('🔍 DEBUG: Balance result: ${result.data}');
      
      if (result.data['success'] == true) {
        final balanceData = Map<String, dynamic>.from(result.data['balance'] as Map);
        return CMEBalance.fromMap(balanceData);
      }
      return null;
    } catch (e) {
      print('❌ DEBUG: Error fetching CME balance: $e');
      return null;
    }
  }

  /// Redeem CME tokens to Hedera wallet
  static Future<RewardResult> redeemCMETokens({
    required double amount,
    required String hederaAccountId,
  }) async {
    if (_userId == null) {
      return RewardResult(success: false, message: 'User not authenticated');
    }
    
    try {
      final result = await _functions.httpsCallable('redeemCMETokens').call({
        'userId': _userId,
        'amount': amount,
        'hederaAccountId': hederaAccountId,
      });
      
      return RewardResult.fromMap(result.data);
    } catch (e) {
      return RewardResult(success: false, message: 'Redemption failed: $e');
    }
  }

  /// Check pending token unlocks and claim if available
  static Future<RewardResult> claimVestedTokens() async {
    if (_userId == null) {
      return RewardResult(success: false, message: 'User not authenticated');
    }
    
    try {
      final result = await _functions.httpsCallable('claimVestedTokens').call({
        'userId': _userId,
      });
      
      return RewardResult.fromMap(result.data);
    } catch (e) {
      return RewardResult(success: false, message: 'Claim failed: $e');
    }
  }

  // ===== FRAUD PREVENTION METHODS =====

  /// Check if user can claim a specific reward type (rate limiting)
  static Future<bool> canClaimReward({
    required String rewardType,
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null) return false;
    
    try {
      return await _checkRateLimit(rewardType, metadata);
    } catch (e) {
      print('Error checking reward eligibility: $e');
      return false;
    }
  }

  /// Internal rate limiting check
  static Future<bool> _checkRateLimit(String rewardType, [Map<String, dynamic>? metadata]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_${rewardType}_$_userId';
    final lastClaim = prefs.getInt(key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get rate limit from config
    final config = await CMEConfigService.getConfig();
    final rateLimits = config['rate_limits'] as Map<String, dynamic>? ?? {};
    final limit = rateLimits[rewardType] as int? ?? 3600000; // Default 1 hour
    
    return (now - lastClaim) >= limit;
  }

  /// Record rate limit after successful claim
  static Future<void> _recordRateLimit(String rewardType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_${rewardType}_$_userId';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Validate video watch duration - 30 second minimum OR 70% of video
  static bool _validateVideoWatch(int watchSeconds, int totalSeconds) {
    if (totalSeconds <= 0) return false;
    
    // Must watch at least 30 seconds OR 70% of video (whichever is more lenient)
    final minWatchTime = 30;
    final requiredPercent = 0.7;
    final percentageWatched = watchSeconds / totalSeconds;
    
    return watchSeconds >= minWatchTime || percentageWatched >= requiredPercent;
  }

  /// Validate ad view duration
  static bool _validateAdView(int watchSeconds) {
    return watchSeconds >= 30; // Must watch at least 30 seconds
  }

  // ===== REWARD CLAIMING METHODS =====

  /// Process reward earning event with fraud prevention
  static Future<RewardResult> _earnEvent({
    required String eventType,
    required String idempotencyKey,
    Map<String, dynamic>? metadata,
  }) async {
    print('🔍 DEBUG: _earnEvent called - eventType: $eventType, idempotencyKey: $idempotencyKey');
    
    if (_userId == null) {
      print('❌ DEBUG: User not authenticated in _earnEvent');
      return RewardResult(success: false, message: 'User not authenticated');
    }

    try {
      print('🔍 DEBUG: Calling Firebase function earnEvent');
      final HttpsCallable callable = _functions.httpsCallable('earnEvent');
      final HttpsCallableResult result = await callable.call({
        'uid': _userId,
        'eventType': eventType,
        'idempotencyKey': idempotencyKey,
        'meta': metadata ?? {},
      });

      print('🔍 DEBUG: Firebase function returned: ${result.data}');

      if (result.data['success'] == true) {
        await _recordRateLimit(eventType);
        print('✅ DEBUG: Rate limit recorded for $eventType');
      }

      return RewardResult.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      print('❌ DEBUG: FirebaseFunctionsException in _earnEvent: code=${e.code} message=${e.message} details=${e.details}');
      return RewardResult(
        success: false, 
        message: 'Function error: ${e.message ?? e.code}',
        data: {'code': e.code, 'details': e.details}
      );
    } catch (e, stackTrace) {
      print('❌ DEBUG: Unhandled error in _earnEvent: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      return RewardResult(success: false, message: 'Reward processing failed: $e');
    }
  }

  /// Initialize user in reward system
  static Future<Map<String, dynamic>?> onboardUser() async {
    if (_userId == null) return null;
    
    try {
      final result = await _functions.httpsCallable('onboardUser').call({
        'uid': _userId,
      });
      
      return result.data;
    } catch (e) {
      print('Onboarding error: $e');
      return null;
    }
  }

  /// Claim signup bonus
  static Future<RewardResult> claimSignupBonus() async {
    if (!await canClaimReward(rewardType: 'signup')) {
      return RewardResult(success: false, message: 'Signup bonus already claimed');
    }

    return await _earnEvent(
      eventType: 'signup',
      idempotencyKey: 'signup_$_userId',
    );
  }

  /// Use referral code during signup
  static Future<RewardResult> useReferralCode({required String referralCode}) async {
    if (!await canClaimReward(rewardType: 'referral_use')) {
      return RewardResult(success: false, message: 'Referral already used');
    }

    return await _earnEvent(
      eventType: 'referral_use',
      idempotencyKey: 'referral_${_userId}_$referralCode',
      metadata: {'referralCode': referralCode},
    );
  }

  /// Claim referral reward (for referrer)
  static Future<RewardResult> claimReferralReward({required String referredUserId}) async {
    return await _earnEvent(
      eventType: 'referral_reward',
      idempotencyKey: 'referrer_${_userId}_$referredUserId',
      metadata: {'referredUserId': referredUserId},
    );
  }

  /// Claim social media reward
  static Future<RewardResult> claimSocialReward({required String platform}) async {
    print('🔍 DEBUG: Attempting to claim social reward for platform: $platform');
    print('🔍 DEBUG: User ID: $_userId');
    
    if (_userId == null) {
      print('❌ DEBUG: User not authenticated');
      return RewardResult(success: false, message: 'User not authenticated');
    }
    
    if (!await canClaimReward(rewardType: 'social_$platform')) {
      print('❌ DEBUG: Social reward cooldown active for $platform');
      return RewardResult(success: false, message: 'Social reward already claimed today');
    }

    try {
      print('✅ DEBUG: Calling earnEvent function with social_follow event');
      final HttpsCallable callable = _functions.httpsCallable('earnEvent');
      final HttpsCallableResult result = await callable.call({
        'uid': _userId,
        'eventType': 'social_follow',
        'idempotencyKey': 'social_${platform}_${_userId}_${DateTime.now().millisecondsSinceEpoch}',
        'meta': {'platform': platform},
      });

      print('🔍 DEBUG: Firebase function returned: ${result.data}');

      if (result.data['success'] == true) {
        await _recordRateLimit('social_$platform');
        await _markPlatformAsFollowed(platform);
        print('✅ DEBUG: Rate limit recorded and platform marked as followed for social_$platform');
      }

      final data = Map<String, dynamic>.from(result.data as Map);
      return RewardResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      print('❌ DEBUG: FirebaseFunctionsException: code=${e.code} message=${e.message} details=${e.details}');
      return RewardResult(
        success: false, 
        message: 'Function error: ${e.message ?? e.code}',
        data: {'code': e.code, 'details': e.details}
      );
    } catch (e, stackTrace) {
      print('❌ DEBUG: Unhandled error calling earnEvent for social reward: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      return RewardResult(success: false, message: 'Social reward failed: $e');
    }
  }

  /// Claim video watch reward
  static Future<RewardResult> claimVideoReward({
    required String videoId,
    required int watchDurationSeconds,
    required int totalDurationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate watch duration
    if (!_validateVideoWatch(watchDurationSeconds, totalDurationSeconds)) {
      return RewardResult(success: false, message: 'Insufficient watch time');
    }

    if (!await canClaimReward(rewardType: 'video_watch')) {
      return RewardResult(success: false, message: 'Video reward cooldown active');
    }

    return await _earnEvent(
      eventType: 'video_watch',
      idempotencyKey: 'video_${videoId}_${_userId}_${DateTime.now().millisecondsSinceEpoch}',
      metadata: {
        'videoId': videoId,
        'watchDuration': watchDurationSeconds,
        'totalDuration': totalDurationSeconds,
        ...?metadata,
      },
    );
  }

  /// Claim ad view reward
  static Future<RewardResult> claimAdReward({
    required String adId,
    required int adDurationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate ad view duration
    if (!_validateAdView(adDurationSeconds)) {
      return RewardResult(success: false, message: 'Insufficient ad watch time');
    }

    if (!await canClaimReward(rewardType: 'ad_view')) {
      return RewardResult(success: false, message: 'Ad reward cooldown active');
    }

    return await _earnEvent(
      eventType: 'ad_view',
      idempotencyKey: 'ad_${adId}_${_userId}_${DateTime.now().millisecondsSinceEpoch}',
      metadata: {
        'adId': adId,
        'duration': adDurationSeconds,
        ...?metadata,
      },
    );
  }

  /// Claim quiz reward
  static Future<RewardResult> claimQuizReward({
    required String quizId,
    required int score,
    required int totalQuestions,
    Map<String, dynamic>? metadata,
  }) async {
    if (!await canClaimReward(rewardType: 'quiz_completion')) {
      return RewardResult(success: false, message: 'Quiz reward cooldown active');
    }

    return await _earnEvent(
      eventType: 'quiz_completion',
      idempotencyKey: 'quiz_${quizId}_${_userId}_${DateTime.now().millisecondsSinceEpoch}',
      metadata: {
        'quizId': quizId,
        'score': score,
        'totalQuestions': totalQuestions,
        ...?metadata,
      },
    );
  }

  /// Claim daily login reward
  static Future<RewardResult> claimDailyReward() async {
    if (_userId == null) {
      return RewardResult(success: false, message: 'User not authenticated');
    }
    
    if (!await canClaimReward(rewardType: 'daily_airdrop')) {
      return RewardResult(success: false, message: 'Daily reward already claimed');
    }

    try {
      print('🔍 DEBUG: Calling claimDailyAirdrop function');
      final result = await _functions.httpsCallable('claimDailyAirdrop').call({});

      print('🔍 DEBUG: Daily airdrop result: ${result.data}');

      if (result.data['success'] == true) {
        await _recordRateLimit('daily_airdrop');
      }

      return RewardResult.fromMap(result.data);
    } catch (e) {
      print('❌ DEBUG: Error claiming daily reward: $e');
      return RewardResult(success: false, message: 'Daily reward failed: $e');
    }
  }

  /// Claim live stream reward
  static Future<RewardResult> claimLiveStreamReward({
    required String streamId,
    required int watchDurationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    if (!await canClaimReward(rewardType: 'live_stream')) {
      return RewardResult(success: false, message: 'Live stream reward cooldown active');
    }

    return await _earnEvent(
      eventType: 'live_stream',
      idempotencyKey: 'stream_${streamId}_${_userId}',
      metadata: {
        'streamId': streamId,
        'watchDuration': watchDurationSeconds,
        ...?metadata,
      },
    );
  }

  /// Claim game reward (for games like spin wheel, scratch cards, etc.)
  static Future<RewardResult> claimGameReward({
    required String gameType,
    required String gameId,
    required double rewardAmount,
    Map<String, dynamic>? metadata,
  }) async {
    if (!await canClaimReward(rewardType: 'ad_view')) {
      return RewardResult(success: false, message: 'Game reward cooldown active');
    }

    return await _earnEvent(
      eventType: 'ad_view',
      idempotencyKey: 'game_${gameType}_${gameId}_${_userId}',
      metadata: {
        'gameType': gameType,
        'gameId': gameId,
        'rewardAmount': rewardAmount,
        ...?metadata,
      },
    );
  }

  // ===== LEGACY COMPATIBILITY METHODS =====

  /// Get current reward amounts (legacy)
  static Future<Map<String, dynamic>?> getCurrentRewardAmounts() async {
    try {
      final config = await CMEConfigService.getConfig();
      final rewardRates = config['reward_rates'] as Map<String, dynamic>? ?? {};
      
      final amounts = <String, double>{};
      for (final entry in rewardRates.entries) {
        final eventConfig = entry.value as Map<String, dynamic>;
        amounts[entry.key] = (eventConfig['base'] ?? 0.0).toDouble();
      }
      
      return {
        'success': true,
        'data': amounts,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get user earning statistics (legacy)
  static Future<Map<String, dynamic>?> getUserEarningStats() async {
    if (_userId == null) return null;
    
    try {
      final result = await _functions.httpsCallable('getUserStats').call({
        'userId': _userId,
      });
      
      return result.data;
    } catch (e) {
      return null;
    }
  }

  /// Get transaction history (legacy)
  static Future<List<Map<String, dynamic>>?> getTransactionHistory({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    if (_userId == null) return null;
    
    try {
      final result = await _functions.httpsCallable('getUserStats').call({
        'userId': _userId,
        'includeTransactions': true,
        'limit': limit,
      });
      
      if (result.data['success'] == true) {
        final transactions = result.data['transactions'] as List<dynamic>?;
        return transactions?.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get user referral code (legacy)
  static Future<String?> getUserReferralCode() async {
    if (_userId == null) return null;
    
    // Generate simple referral code from user ID
    return 'REF${_userId?.substring(0, 8).toUpperCase()}';
  }

  /// Get daily reward status (legacy)
  static Future<Map<String, dynamic>?> getDailyRewardStatus() async {
    if (_userId == null) return null;
    
    try {
      final result = await _functions.httpsCallable('getUserStats').call({
        'userId': _userId,
        'includeDailyStatus': true,
      });
      
      return result.data;
    } catch (e) {
      return null;
    }
  }

  /// Initialize user rewards (legacy)
  static Future<Map<String, dynamic>?> initializeUserRewards() async {
    if (_userId == null) return null;
    
    return await onboardUser();
  }

  /// Check if user follows platform (uses both Firestore and rate limit)
  static Future<bool> isFollowedPlatform(String platform) async {
    if (_userId == null) return false;
    
    try {
      // First check Firestore for explicit follow status
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('social_claims')
          .doc(platform.toLowerCase())
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        if (data['claimed'] == true) {
          return true;
        }
      }
      
      // If not found in Firestore, check rate limit (indicates previous claim)
      final canClaim = await canClaimReward(rewardType: 'social_$platform');
      return !canClaim; // If can't claim, means it was already claimed
      
    } catch (e) {
      print('🔍 DEBUG: Error checking followed platform $platform: $e');
      return false;
    }
  }

  /// Mark platform as followed in Firestore
  static Future<void> _markPlatformAsFollowed(String platform) async {
    if (_userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('social_claims')
          .doc(platform.toLowerCase())
          .set({
        'claimed': true,
        'claimedAt': FieldValue.serverTimestamp(),
        'platform': platform,
        'userId': _userId,
      }, SetOptions(merge: true));
      
      print('✅ DEBUG: Marked platform $platform as followed for user $_userId');
    } catch (e) {
      print('❌ DEBUG: Error marking platform as followed: $e');
    }
  }

  /// Get user balance (legacy)
  static Future<Map<String, dynamic>?> getUserBalance() async {
    final balance = await getCMEBalance();
    if (balance == null) return null;
    
    return {
      'success': true,
      'balance': balance.toMap(),
    };
  }

  /// Debug method to test Firebase Functions connectivity
  static Future<void> testFirebaseConnection() async {
    print('🔍 DEBUG: Testing Firebase Functions connection...');
    print('🔍 DEBUG: User authenticated: ${_userId != null}');
    print('🔍 DEBUG: User ID: $_userId');
    
    if (_userId == null) {
      print('❌ DEBUG: No user authenticated');
      return;
    }
    
    try {
      print('🔍 DEBUG: Attempting to call getUserStats function...');
      final result = await _functions.httpsCallable('getUserStats').call({
        'userId': _userId,
      });
      
      print('✅ DEBUG: Firebase Functions connection successful!');
      print('🔍 DEBUG: Response: ${result.data}');
    } catch (e) {
      print('❌ DEBUG: Firebase Functions connection failed: $e');
    }
  }
}
