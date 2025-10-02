/// Simple Referral Test Function
/// Quick test to verify referral code functionality works end-to-end
import 'package:firebase_auth/firebase_auth.dart';
// Removed import during nuclear cleanup
import '../services/referral_testing_service.dart';

/// Quick test function to verify referral functionality
Future<void> testReferralSystemQuick() async {
  print('🧪 Starting quick referral system test...');
  
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No user logged in - please sign in first');
      return;
    }
    
    print('✅ User logged in: ${currentUser.email}');
    
    // Test 1: Generate referral code
    print('\n📋 Test 1: Generating referral code...');
    final referralCode = await RewardService.getUserReferralCode();
    
    if (referralCode != null && referralCode.isNotEmpty) {
      print('✅ Referral code generated: $referralCode');
    } else {
      print('❌ Failed to generate referral code');
      return;
    }
    
    // Test 2: Test code format
    print('\n🔍 Test 2: Validating code format...');
    if (referralCode.startsWith('REF') && referralCode.length >= 8) {
      print('✅ Referral code format is valid');
    } else {
      print('❌ Invalid referral code format: $referralCode');
    }
    
    // Test 3: Test code usage (self-referral should fail)
    print('\n🚫 Test 3: Testing self-referral prevention...');
    final selfReferralResult = await RewardService.useReferralCode(referralCode: referralCode);
    
    if (!selfReferralResult.success) {
      print('✅ Self-referral correctly prevented: ${selfReferralResult.message}');
    } else {
      print('⚠️ Self-referral was allowed (this might be a security issue)');
    }
    
    // Test 4: Get current reward amounts
    print('\n💰 Test 4: Checking reward amounts...');
    final rewardAmounts = await RewardService.getCurrentRewardAmounts();
    
    if (rewardAmounts != null) {
      final referralReward = rewardAmounts['referral_reward'] ?? rewardAmounts['referralReward'] ?? 0;
      print('✅ Referral reward amount: $referralReward CNE');
      
      if (referralReward > 0) {
        print('✅ Referral rewards are configured');
      } else {
        print('⚠️ Referral reward amount is 0 or not configured');
      }
    } else {
      print('❌ Failed to get reward amounts');
    }
    
    // Test 5: Get referral stats
    print('\n📊 Test 5: Getting referral statistics...');
    final stats = await ReferralTestingService.instance.getReferralStats();
    
    print('✅ Referral stats:');
    print('   - Successful referrals: ${stats.successfulReferrals}');
    print('   - Total earnings: ${stats.totalEarnings.toStringAsFixed(2)} CNE');
    print('   - Used referral code: ${stats.usedReferralCode ? "Yes" : "No"}');
    
    print('\n🎉 Quick referral system test completed!');
    print('═' * 50);
    print('SUMMARY:');
    print('• Referral code: $referralCode');
    print('• Format: ${referralCode.startsWith('REF') ? "Valid" : "Invalid"}');
    print('• Self-referral prevention: ${!selfReferralResult.success ? "Working" : "Issue"}');
    print('• Reward amount: ${rewardAmounts?['referral_reward'] ?? rewardAmounts?['referralReward'] ?? 0} CNE');
    print('• User referrals: ${stats.successfulReferrals}');
    print('• User earnings: ${stats.totalEarnings.toStringAsFixed(2)} CNE');
    
  } catch (e, stackTrace) {
    print('❌ Error during referral system test: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Test with a specific referral code
Future<void> testReferralCode(String testCode) async {
  print('🧪 Testing specific referral code: $testCode');
  
  try {
    final result = await RewardService.useReferralCode(referralCode: testCode);
    
    if (result.success) {
      print('✅ Referral code used successfully!');
      print('   - Reward: ${result.reward ?? 0} CNE');
      print('   - Message: ${result.message}');
    } else {
      print('❌ Referral code usage failed:');
      print('   - Message: ${result.message}');
    }
    
  } catch (e) {
    print('❌ Error testing referral code: $e');
  }
}
