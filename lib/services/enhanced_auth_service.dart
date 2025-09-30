/// Enhanced Authentication Service with Automatic Wallet Creation
/// Integrates Firebase Auth with Hedera wallet creation and DID management
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_creation_service.dart';
import 'did_auth_service.dart';

class EnhancedAuthService {
  static EnhancedAuthService? _instance;
  static EnhancedAuthService get instance => _instance ??= EnhancedAuthService._();
  
  EnhancedAuthService._();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Complete user onboarding with wallet and DID creation
  Future<OnboardingResult> onboardNewUser({
    required String email,
    required String password,
    required String displayName,
    String? username,
  }) async {
    try {
      _logDebug('🔐 Starting complete user onboarding for: $email');
      
      // Step 1: Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return OnboardingResult.error('Failed to create Firebase user');
      }
      
      // Update display name
      await firebaseUser.updateDisplayName(displayName);
      
      try {
        // Step 2: Create custodial Hedera wallet
        final walletResult = await WalletCreationService.instance.createCustodialWallet(
          userId: firebaseUser.uid,
          userEmail: email,
          displayName: displayName,
        );
        
        if (!walletResult.success) {
          // Rollback Firebase user
          await firebaseUser.delete();
          return OnboardingResult.error('Failed to create wallet: ${walletResult.error}');
        }
        
        final wallet = walletResult.wallet!;
        
        // Step 3: Create DID with wallet address
        final didResult = await DIDAuthService.instance.registerUserWithDID(
          email: email,
          password: password,
          walletAddress: wallet.accountId,
          displayName: displayName,
        );
        
        if (!didResult.success) {
          // Rollback wallet and Firebase user
          await _rollbackWalletCreation(firebaseUser.uid);
          await firebaseUser.delete();
          return OnboardingResult.error('Failed to create DID: ${didResult.error}');
        }
        
        // Step 4: Create comprehensive user document
        await _createUserDocument(
          userId: firebaseUser.uid,
          email: email,
          displayName: displayName,
          username: username,
          wallet: wallet,
          didData: didResult.data!,
        );
        
        // Step 5: Initialize user rewards and welcome bonus
        await _initializeUserRewards(firebaseUser.uid);
        
        _logDebug('✅ Complete user onboarding successful');
        return OnboardingResult.success(
          OnboardingData(
            firebaseUser: firebaseUser,
            wallet: wallet,
            didData: didResult.data!,
          ),
        );
        
      } catch (e) {
        // Rollback Firebase user on any error
        await firebaseUser.delete();
        rethrow;
      }
      
    } catch (e, stackTrace) {
      _logError('❌ Error during user onboarding: $e', stackTrace);
      return OnboardingResult.error('Onboarding failed: $e');
    }
  }
  
  /// Sign in existing user and verify wallet/DID setup
  Future<SignInResult> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      _logDebug('🔐 Signing in user: $email');
      
      // Step 1: Firebase sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return SignInResult.error('Sign in failed');
      }
      
      // Step 2: Verify user setup (wallet and DID)
      final setupStatus = await _verifyUserSetup(firebaseUser.uid);
      
      if (!setupStatus.isComplete) {
        // Complete missing setup
        final completionResult = await _completeUserSetup(
          firebaseUser,
          setupStatus,
        );
        
        if (!completionResult.success) {
          return SignInResult.error('Failed to complete user setup: ${completionResult.error}');
        }
      }
      
      _logDebug('✅ User signed in successfully');
      return SignInResult.success(firebaseUser);
      
    } catch (e, stackTrace) {
      _logError('❌ Error during sign in: $e', stackTrace);
      return SignInResult.error('Sign in failed: $e');
    }
  }
  
  /// Verify user has complete setup (wallet + DID)
  Future<UserSetupStatus> _verifyUserSetup(String userId) async {
    try {
      // Check user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return UserSetupStatus(hasUserDoc: false);
      }
      
      final userData = userDoc.data()!;
      final hasWallet = userData['hasWallet'] == true;
      final walletAddress = userData['walletAddress'] as String?;
      final didIdentifier = userData['didIdentifier'] as String?;
      
      // Check wallet exists
      CustodialWallet? wallet;
      if (hasWallet && walletAddress != null) {
        wallet = await WalletCreationService.instance.getUserWallet(userId);
      }
      
      return UserSetupStatus(
        hasUserDoc: true,
        hasWallet: wallet != null,
        hasDID: didIdentifier != null,
        walletAddress: walletAddress,
        didIdentifier: didIdentifier,
        wallet: wallet,
      );
      
    } catch (e) {
      _logError('❌ Error verifying user setup: $e');
      return UserSetupStatus(hasUserDoc: false);
    }
  }
  
  /// Complete missing user setup components
  Future<SetupCompletionResult> _completeUserSetup(
    User firebaseUser,
    UserSetupStatus status,
  ) async {
    try {
      _logDebug('🔧 Completing missing user setup for: ${firebaseUser.uid}');
      
      CustodialWallet? wallet = status.wallet;
      String? didIdentifier = status.didIdentifier;
      
      // Create wallet if missing
      if (!status.hasWallet) {
        final walletResult = await WalletCreationService.instance.createCustodialWallet(
          userId: firebaseUser.uid,
          userEmail: firebaseUser.email!,
          displayName: firebaseUser.displayName,
        );
        
        if (!walletResult.success) {
          return SetupCompletionResult.error('Failed to create wallet: ${walletResult.error}');
        }
        
        wallet = walletResult.wallet!;
      }
      
      // Create DID if missing
      if (!status.hasDID && wallet != null) {
        final didResult = await DIDAuthService.instance.registerUserWithDID(
          email: firebaseUser.email!,
          password: '', // User is already authenticated
          walletAddress: wallet.accountId,
          displayName: firebaseUser.displayName,
        );
        
        if (!didResult.success) {
          return SetupCompletionResult.error('Failed to create DID: ${didResult.error}');
        }
        
        didIdentifier = didResult.data!.didIdentifier;
      }
      
      // Update user document if needed
      if (!status.hasWallet || !status.hasDID) {
        await _firestore.collection('users').doc(firebaseUser.uid).update({
          'walletAddress': wallet?.accountId,
          'didIdentifier': didIdentifier,
          'hasWallet': wallet != null,
          'setupCompletedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return SetupCompletionResult.success();
      
    } catch (e, stackTrace) {
      _logError('❌ Error completing user setup: $e', stackTrace);
      return SetupCompletionResult.error('Setup completion failed: $e');
    }
  }
  
  /// Create comprehensive user document
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    required String displayName,
    String? username,
    required CustodialWallet wallet,
    required DIDUserData didData,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'uid': userId,
      'email': email,
      'displayName': displayName,
      'username': username?.toLowerCase(),
      'walletAddress': wallet.accountId,
      'didIdentifier': wallet.didIdentifier,
      'hasWallet': true,
      'hasDID': true,
      'createdAt': FieldValue.serverTimestamp(),
      'setupCompletedAt': FieldValue.serverTimestamp(),
      'onboardingVersion': '1.0',
      'walletType': 'custodial',
      'status': 'active',
    });
  }
  
  /// Initialize user rewards system
  Future<void> _initializeUserRewards(String userId) async {
    try {
      // This would integrate with the existing RewardService
      _logDebug('🎁 Initializing user rewards for: $userId');
      
      // Initialize user balance
      await _firestore.collection('user_balances').doc(userId).set({
        'availableBalance': 0.0,
        'lockedBalance': 0.0,
        'totalEarned': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Award welcome bonus (would integrate with actual reward service)
      const welcomeBonus = 100.0;
      await _firestore.collection('reward_logs').add({
        'userId': userId,
        'eventType': 'welcome_bonus',
        'amount': welcomeBonus,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'description': 'Welcome bonus for new user onboarding',
          'automatic': true,
        },
      });
      
    } catch (e) {
      _logError('❌ Error initializing user rewards: $e');
      // Don't throw - onboarding can continue without rewards
    }
  }
  
  /// Rollback wallet creation
  Future<void> _rollbackWalletCreation(String userId) async {
    try {
      // Delete wallet document
      await _firestore.collection('custodial_wallets').doc(userId).delete();
      
      // Log rollback
      await _firestore.collection('wallet_audit_log').add({
        'userId': userId,
        'action': 'wallet_rollback',
        'reason': 'onboarding_failure',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      _logError('❌ Error during wallet rollback: $e');
    }
  }
  
  void _logDebug(String message) {
    print('[EnhancedAuthService] $message');
  }
  
  void _logError(String message, [StackTrace? stackTrace]) {
    print('[EnhancedAuthService] ERROR: $message');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}

/// Result of user onboarding process
class OnboardingResult {
  final bool success;
  final OnboardingData? data;
  final String? error;
  
  OnboardingResult._({
    required this.success,
    this.data,
    this.error,
  });
  
  factory OnboardingResult.success(OnboardingData data) {
    return OnboardingResult._(success: true, data: data);
  }
  
  factory OnboardingResult.error(String error) {
    return OnboardingResult._(success: false, error: error);
  }
}

/// Data returned from successful onboarding
class OnboardingData {
  final User firebaseUser;
  final CustodialWallet wallet;
  final DIDUserData didData;
  
  OnboardingData({
    required this.firebaseUser,
    required this.wallet,
    required this.didData,
  });
}

/// Result of user sign in process
class SignInResult {
  final bool success;
  final User? user;
  final String? error;
  
  SignInResult._({
    required this.success,
    this.user,
    this.error,
  });
  
  factory SignInResult.success(User user) {
    return SignInResult._(success: true, user: user);
  }
  
  factory SignInResult.error(String error) {
    return SignInResult._(success: false, error: error);
  }
}

/// User setup status tracking
class UserSetupStatus {
  final bool hasUserDoc;
  final bool hasWallet;
  final bool hasDID;
  final String? walletAddress;
  final String? didIdentifier;
  final CustodialWallet? wallet;
  
  UserSetupStatus({
    required this.hasUserDoc,
    this.hasWallet = false,
    this.hasDID = false,
    this.walletAddress,
    this.didIdentifier,
    this.wallet,
  });
  
  bool get isComplete => hasUserDoc && hasWallet && hasDID;
}

/// Result of setup completion process
class SetupCompletionResult {
  final bool success;
  final String? error;
  
  SetupCompletionResult._({
    required this.success,
    this.error,
  });
  
  factory SetupCompletionResult.success() {
    return SetupCompletionResult._(success: true);
  }
  
  factory SetupCompletionResult.error(String error) {
    return SetupCompletionResult._(success: false, error: error);
  }
}
