import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RewardService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get _userId => _auth.currentUser?.uid;

  // Claim video watching reward
  static Future<Map<String, dynamic>?> claimVideoReward({
    required String videoId,
    required int watchDurationSeconds,
    required int totalDurationSeconds,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimVideoReward').call({
        'userId': _userId,
        'videoId': videoId,
        'watchDurationSeconds': watchDurationSeconds,
        'totalDurationSeconds': totalDurationSeconds,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming video reward: $e');
      return null;
    }
  }

  // Claim quiz completion reward
  static Future<Map<String, dynamic>?> claimQuizReward({
    required String quizId,
    required int score,
    required int totalQuestions,
    required int timeTakenSeconds,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimQuizReward').call({
        'userId': _userId,
        'quizId': quizId,
        'score': score,
        'totalQuestions': totalQuestions,
        'timeTakenSeconds': timeTakenSeconds,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming quiz reward: $e');
      return null;
    }
  }

  // Claim daily check-in reward
  static Future<Map<String, dynamic>?> claimDailyReward() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimDailyReward').call({
        'userId': _userId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming daily reward: $e');
      return null;
    }
  }

  // Claim signup bonus (called once during registration)
  static Future<Map<String, dynamic>?> claimSignupBonus() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimSignupBonus').call({
        'userId': _userId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming signup bonus: $e');
      return null;
    }
  }

  // Claim referral reward (when someone uses your referral code)
  static Future<Map<String, dynamic>?> claimReferralReward({
    required String referredUserId,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimReferralReward').call({
        'referrerId': _userId,
        'referredUserId': referredUserId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming referral reward: $e');
      return null;
    }
  }

  // Use referral code (when you sign up with someone's code)
  static Future<Map<String, dynamic>?> useReferralCode({
    required String referralCode,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('useReferralCode').call({
        'userId': _userId,
        'referralCode': referralCode,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error using referral code: $e');
      return null;
    }
  }

  // Claim social media follow reward
  static Future<Map<String, dynamic>?> claimSocialReward({
    required String platform,
    required String socialMediaUrl,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimSocialReward').call({
        'userId': _userId,
        'platform': platform,
        'socialMediaUrl': socialMediaUrl,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming social reward: $e');
      return null;
    }
  }

  // Get current reward amounts (with halving logic)
  static Future<Map<String, dynamic>?> getCurrentRewardAmounts() async {
    try {
      final result = await _functions.httpsCallable('getCurrentRewardAmounts').call();
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error getting current reward amounts: $e');
      return null;
    }
  }

  // Get user balance and statistics
  static Future<Map<String, dynamic>?> getUserBalance() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('getUserBalance').call({
        'userId': _userId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error getting user balance: $e');
      return null;
    }
  }

  // Get user transaction history
  static Future<List<Map<String, dynamic>>?> getTransactionHistory({
    int limit = 50,
    String? lastTransactionId,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('getUserTransactions').call({
        'userId': _userId,
        'limit': limit,
        'lastTransactionId': lastTransactionId,
      });

      return List<Map<String, dynamic>>.from(result.data['transactions'] ?? []);
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      return null;
    }
  }

  // Get user referral code
  static Future<String?> getUserReferralCode() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('getUserReferralCode').call({
        'userId': _userId,
      });

      return result.data['referralCode'];
    } catch (e) {
      debugPrint('Error getting referral code: $e');
      return null;
    }
  }

  // Check daily reward status
  static Future<Map<String, dynamic>?> getDailyRewardStatus() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('getDailyRewardStatus').call({
        'userId': _userId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error getting daily reward status: $e');
      return null;
    }
  }

  // Claim live stream reward
  static Future<Map<String, dynamic>?> claimLiveStreamReward({
    required String streamId,
    required int watchDurationSeconds,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimLiveStreamReward').call({
        'userId': _userId,
        'streamId': streamId,
        'watchDurationSeconds': watchDurationSeconds,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming live stream reward: $e');
      return null;
    }
  }

  // Claim ad watching reward
  static Future<Map<String, dynamic>?> claimAdReward({
    required String adId,
    required String adProvider,
    required bool completedFully,
  }) async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('claimAdReward').call({
        'userId': _userId,
        'adId': adId,
        'adProvider': adProvider,
        'completedFully': completedFully,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error claiming ad reward: $e');
      return null;
    }
  }

  // Get user earning statistics
  static Future<Map<String, dynamic>?> getUserEarningStats() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('getUserEarningStats').call({
        'userId': _userId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error getting earning stats: $e');
      return null;
    }
  }

  // Initialize new user rewards (create user document)
  static Future<Map<String, dynamic>?> initializeUserRewards() async {
    if (_userId == null) return null;

    try {
      final result = await _functions.httpsCallable('initializeUserRewards').call({
        'userId': _userId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error initializing user rewards: $e');
      return null;
    }
  }

  // Check if user can claim specific reward type
  static Future<bool> canClaimReward({
    required String rewardType,
    String? identifier, // videoId, quizId, etc.
  }) async {
    if (_userId == null) return false;

    try {
      final result = await _functions.httpsCallable('canClaimReward').call({
        'userId': _userId,
        'rewardType': rewardType,
        'identifier': identifier,
      });

      return result.data['canClaim'] ?? false;
    } catch (e) {
      debugPrint('Error checking reward eligibility: $e');
      return false;
    }
  }
}
