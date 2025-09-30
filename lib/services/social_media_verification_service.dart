import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SocialMediaVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<Map<String, dynamic>> supportedPlatforms = [
    {
      'id': 'twitter',
      'name': 'X (Twitter)',
      'url': 'https://x.com/CoinNewsExtraTv',
      'displayName': 'X (Twitter)',
      'reward': 15.0,
      'verificationRequired': true,
      'proofInstructions': 'Follow @CoinNewsExtraTv and like our latest post, then provide your Twitter username for verification.',
    },
    {
      'id': 'instagram',
      'name': 'Instagram',
      'url': 'https://www.instagram.com/coinnewsextratv',
      'displayName': 'Instagram',
      'reward': 15.0,
      'verificationRequired': true,
      'proofInstructions': 'Follow @coinnewsextratv and like our latest post, then provide your Instagram username for verification.',
    },
    {
      'id': 'facebook',
      'name': 'Facebook',
      'url': 'https://www.facebook.com/CoinNewsExtraTv',
      'displayName': 'Facebook',
      'reward': 15.0,
      'verificationRequired': true,
      'proofInstructions': 'Like our Facebook page and interact with our latest post, then provide your Facebook profile name for verification.',
    },
    {
      'id': 'youtube',
      'name': 'YouTube',
      'url': 'https://youtube.com/@coinnewsextratv',
      'displayName': 'YouTube',
      'reward': 20.0,
      'verificationRequired': true,
      'proofInstructions': 'Subscribe to our YouTube channel and like our latest video, then provide your YouTube channel name for verification.',
    },
    {
      'id': 'linkedin',
      'name': 'LinkedIn',
      'url': 'https://www.linkedin.com/company/coin-news-extra/',
      'displayName': 'LinkedIn',
      'reward': 15.0,
      'verificationRequired': true,
      'proofInstructions': 'Follow our LinkedIn company page and engage with our latest post, then provide your LinkedIn profile URL for verification.',
    },
    {
      'id': 'telegram',
      'name': 'Telegram',
      'url': 'https://t.me/coinnewsextra',
      'displayName': 'Telegram',
      'reward': 10.0,
      'verificationRequired': false,
      'proofInstructions': 'Join our Telegram channel and send a message with "Joined from CoinNewsExtra TV app" to receive your reward automatically.',
    },
  ];

  /// Get all supported social media platforms
  static List<Map<String, dynamic>> getSupportedPlatforms() {
    return supportedPlatforms;
  }

  /// Get platform details by ID
  static Map<String, dynamic>? getPlatformById(String platformId) {
    try {
      return supportedPlatforms.firstWhere(
        (platform) => platform['id'] == platformId.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user has already claimed reward for a platform
  static Future<bool> hasClaimedPlatformReward(String platformId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('social_verifications')
          .doc(platformId.toLowerCase())
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return data['rewardClaimed'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking platform reward status: $e');
      return false;
    }
  }

  /// Submit verification proof for a platform
  static Future<VerificationResult> submitVerificationProof({
    required String platformId,
    required String proofText,
    String? screenshotUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return VerificationResult(
          success: false,
          message: 'User not authenticated',
        );
      }

      // Ensure user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _createBasicUserDocument(user);
      }

      final platform = getPlatformById(platformId);
      if (platform == null) {
        return VerificationResult(
          success: false,
          message: 'Invalid platform',
        );
      }

      // Check if already claimed
      if (await hasClaimedPlatformReward(platformId)) {
        return VerificationResult(
          success: false,
          message: 'Reward already claimed for this platform',
        );
      }

      // Store verification submission
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('social_verifications')
          .doc(platformId.toLowerCase())
          .set({
        'platformId': platformId.toLowerCase(),
        'platformName': platform['displayName'],
        'proofText': proofText.trim(),
        'screenshotUrl': screenshotUrl,
        'submittedAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'pending',
        'rewardClaimed': false,
        'userEmail': user.email,
        'userId': user.uid,
      });

      debugPrint('✅ Verification proof submitted for $platformId');

      // For platforms that don't require manual verification (like Telegram),
      // auto-approve after a short delay to simulate processing
      if (platform['verificationRequired'] == false) {
        await Future.delayed(const Duration(seconds: 2));
        return await _autoApproveVerification(platformId);
      }

      return VerificationResult(
        success: true,
        message: 'Verification proof submitted successfully! It will be reviewed within 24 hours.',
        status: 'pending',
      );
    } catch (e) {
      debugPrint('❌ Error submitting verification proof: $e');
      return VerificationResult(
        success: false,
        message: 'Failed to submit verification proof. Please try again.',
      );
    }
  }

  /// Auto-approve verification for platforms that don't require manual review
  static Future<VerificationResult> _autoApproveVerification(String platformId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return VerificationResult(
          success: false,
          message: 'User not authenticated',
        );
      }

      final platform = getPlatformById(platformId);
      if (platform == null) {
        return VerificationResult(
          success: false,
          message: 'Invalid platform',
        );
      }

      // Update verification status to approved
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('social_verifications')
          .doc(platformId.toLowerCase())
          .update({
        'verificationStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'rewardClaimed': true,
        'rewardAmount': platform['reward'],
        'claimedAt': FieldValue.serverTimestamp(),
      });

      // Update user's balance (this would typically be done through the reward service)
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'balance': FieldValue.increment(platform['reward']),
        'totalEarned': FieldValue.increment(platform['reward']),
      });

      // Log the transaction
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
        'type': 'social_follow',
        'amount': platform['reward'],
        'platform': platformId.toLowerCase(),
        'platformName': platform['displayName'],
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Social media follow reward for ${platform['displayName']}',
      });

      return VerificationResult(
        success: true,
        message: 'Social media reward approved! +${platform['reward']} CNE added to your account.',
        status: 'approved',
        rewardAmount: platform['reward'],
      );
    } catch (e) {
      debugPrint('❌ Error auto-approving verification: $e');
      return VerificationResult(
        success: false,
        message: 'Failed to process reward. Please try again.',
      );
    }
  }

  /// Get verification status for a platform
  static Future<VerificationStatus> getVerificationStatus(String platformId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for getVerificationStatus');
        return VerificationStatus(
          status: 'not_started',
          message: 'Please sign in to verify social media follows',
        );
      }

      debugPrint('🔍 Getting verification status for platform: $platformId, user: ${user.uid}');
      
      // Check if user document exists first
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document does not exist, creating basic user document');
        // Create basic user document if it doesn't exist
        await _createBasicUserDocument(user);
      }
      
      // Add a small delay to ensure auth token is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('social_verifications')
          .doc(platformId.toLowerCase())
          .get();

      if (!docSnapshot.exists) {
        return VerificationStatus(
          status: 'not_started',
          message: 'Click to start verification process',
        );
      }

      final data = docSnapshot.data()!;
      final status = data['verificationStatus'] as String;
      final rewardClaimed = data['rewardClaimed'] as bool? ?? false;

      switch (status) {
        case 'pending':
          return VerificationStatus(
            status: 'pending',
            message: 'Verification pending review',
            submittedAt: data['submittedAt'] as Timestamp?,
          );
        case 'approved':
          return VerificationStatus(
            status: rewardClaimed ? 'completed' : 'approved',
            message: rewardClaimed 
                ? 'Reward claimed ✅' 
                : 'Approved - Click to claim reward',
            approvedAt: data['approvedAt'] as Timestamp?,
            rewardAmount: data['rewardAmount'] as double?,
          );
        case 'rejected':
          return VerificationStatus(
            status: 'rejected',
            message: 'Verification rejected - Please resubmit',
            rejectedAt: data['rejectedAt'] as Timestamp?,
            rejectionReason: data['rejectionReason'] as String?,
          );
        default:
          return VerificationStatus(
            status: 'not_started',
            message: 'Click to start verification process',
          );
      }
    } catch (e) {
      debugPrint('❌ Error getting verification status: $e');
      
      // Check if it's a permission error
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('🔍 Permission denied - checking auth state...');
        final user = _auth.currentUser;
        if (user == null) {
          debugPrint('❌ User is null during permission error');
          return VerificationStatus(
            status: 'error',
            message: 'Authentication required',
          );
        } else {
          debugPrint('🔍 User exists: ${user.uid}, email verified: ${user.emailVerified}');
          // Try to refresh the auth token
          try {
            await user.getIdToken(true); // Force refresh
            debugPrint('✅ Auth token refreshed');
          } catch (tokenError) {
            debugPrint('❌ Error refreshing token: $tokenError');
          }
        }
      }
      
      return VerificationStatus(
        status: 'error',
        message: 'Authentication error - please sign in again',
      );
    }
  }

  /// Get all user's social media verifications
  static Future<List<Map<String, dynamic>>> getUserVerifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('social_verifications')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting user verifications: $e');
      return [];
    }
  }

  /// Create basic user document if it doesn't exist
  static Future<void> _createBasicUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'tokenBalance': 0.0,
        'totalEarned': 0.0,
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
      
      debugPrint('✅ Basic user document created for: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error creating basic user document: $e');
    }
  }
}

/// Result class for verification operations
class VerificationResult {
  final bool success;
  final String message;
  final String? status;
  final double? rewardAmount;

  VerificationResult({
    required this.success,
    required this.message,
    this.status,
    this.rewardAmount,
  });
}

/// Status class for verification tracking
class VerificationStatus {
  final String status; // not_started, pending, approved, rejected, completed, error
  final String message;
  final Timestamp? submittedAt;
  final Timestamp? approvedAt;
  final Timestamp? rejectedAt;
  final String? rejectionReason;
  final double? rewardAmount;

  VerificationStatus({
    required this.status,
    required this.message,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.rewardAmount,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get canClaim => status == 'approved';
}
