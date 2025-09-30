/// DID-Enabled User Registration and Authentication Service
/// Integrates DID creation with user signup and wallet connection
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';
import 'did_service.dart';
import 'smart_contract_service.dart';

class DIDAuthService {
  static DIDAuthService? _instance;
  static DIDAuthService get instance => _instance ??= DIDAuthService._();
  
  DIDAuthService._();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Register user with DID creation
  Future<DIDAuthResult> registerUserWithDID({
    required String email,
    required String password,
    required String walletAddress,
    String? displayName,
  }) async {
    try {
      _logDebug('🔐 Registering user with DID: $email');
      
      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return DIDAuthResult.error('Failed to create Firebase user');
      }
      
      // 2. Update display name
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }
      
      // 3. Create DID for user
      final didResult = await DIDService.instance.createDID(
        walletAddress: walletAddress,
        userEmail: email,
        userName: displayName,
      );
      
      if (!didResult.success) {
        // Rollback Firebase user creation
        await firebaseUser.delete();
        return DIDAuthResult.error('Failed to create DID: ${didResult.error}');
      }
      
      // 4. Store user data in Firestore with DID
      await _createUserDocument(
        userId: firebaseUser.uid,
        email: email,
        displayName: displayName,
        walletAddress: walletAddress,
        didIdentifier: didResult.data!,
      );
      
      // 5. Initialize smart contract service
      await SmartContractService.instance.initialize();
      
      final userData = DIDUserData(
        firebaseUid: firebaseUser.uid,
        email: email,
        displayName: displayName,
        walletAddress: walletAddress,
        didIdentifier: didResult.data!,
        createdAt: DateTime.now(),
      );
      
      _logDebug('✅ User registered successfully with DID: ${didResult.data}');
      return DIDAuthResult.success(userData);
      
    } catch (e, stackTrace) {
      _logError('❌ Error registering user with DID: $e', stackTrace);
      return DIDAuthResult.error('Registration failed: $e');
    }
  }
  
  /// Sign in user and load DID
  Future<DIDAuthResult> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      _logDebug('🔐 Signing in user: $email');
      
      // 1. Sign in with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return DIDAuthResult.error('Sign in failed');
      }
      
      // 2. Load user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      
      if (!userDoc.exists) {
        return DIDAuthResult.error('User data not found');
      }
      
      final userData = userDoc.data()!;
      
      // 3. Initialize DID service with stored DID
      await DIDService.instance.initialize();
      
      // 4. Verify DID is still valid
      final didIdentifier = userData['didIdentifier'] as String?;
      if (didIdentifier != null) {
        final didVerification = await DIDService.instance.resolveDID(didIdentifier);
        if (!didVerification.success) {
          _logError('⚠️ DID verification failed for user: $didIdentifier');
        }
      }
      
      // 5. Initialize smart contract service
      await SmartContractService.instance.initialize();
      
      final user = DIDUserData(
        firebaseUid: firebaseUser.uid,
        email: userData['email'],
        displayName: userData['displayName'],
        walletAddress: userData['walletAddress'],
        didIdentifier: didIdentifier,
        createdAt: DateTime.parse(userData['createdAt']),
      );
      
      _logDebug('✅ User signed in successfully');
      return DIDAuthResult.success(user);
      
    } catch (e, stackTrace) {
      _logError('❌ Error signing in user: $e', stackTrace);
      return DIDAuthResult.error('Sign in failed: $e');
    }
  }
  
  /// Connect or update wallet address
  Future<DIDAuthResult> connectWallet({
    required String newWalletAddress,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return DIDAuthResult.error('User not authenticated');
      }
      
      _logDebug('🔗 Connecting wallet: $newWalletAddress');
      
      // 1. Update user document in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'walletAddress': newWalletAddress,
        'walletConnectedAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Update DID document with new wallet
      final didUpdateResult = await DIDService.instance.updateDIDDocument(
        updates: {
          'controller': newWalletAddress,
          'credentialSubject.walletAddress': newWalletAddress,
        },
      );
      
      if (!didUpdateResult.success) {
        return DIDAuthResult.error('Failed to update DID: ${didUpdateResult.error}');
      }
      
      _logDebug('✅ Wallet connected successfully');
      return DIDAuthResult.success(null);
      
    } catch (e, stackTrace) {
      _logError('❌ Error connecting wallet: $e', stackTrace);
      return DIDAuthResult.error('Wallet connection failed: $e');
    }
  }
  
  /// Verify user for reward claim (integrated with DID)
  Future<DIDAuthResult> verifyUserForReward({
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return DIDAuthResult.error('User not authenticated');
      }
      
      // Get user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        return DIDAuthResult.error('User data not found');
      }
      
      final userData = userDoc.data()!;
      final walletAddress = userData['walletAddress'] as String?;
      
      if (walletAddress == null) {
        return DIDAuthResult.error('Wallet not connected');
      }
      
      // Verify with DID service
      final didVerification = await DIDService.instance.verifyDIDForReward(
        walletAddress: walletAddress,
        eventType: eventType,
        eventData: eventData,
      );
      
      if (!didVerification.success) {
        return DIDAuthResult.error('DID verification failed: ${didVerification.error}');
      }
      
      _logDebug('✅ User verified for reward claim');
      return DIDAuthResult.success(null);
      
    } catch (e, stackTrace) {
      _logError('❌ Error verifying user for reward: $e', stackTrace);
      return DIDAuthResult.error('User verification failed: $e');
    }
  }
  
  /// Get current user data
  Future<DIDAuthResult<DIDUserData>> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return DIDAuthResult.error('User not authenticated');
      }
      
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        return DIDAuthResult.error('User data not found');
      }
      
      final userData = userDoc.data()!;
      
      final user = DIDUserData(
        firebaseUid: currentUser.uid,
        email: userData['email'],
        displayName: userData['displayName'],
        walletAddress: userData['walletAddress'],
        didIdentifier: userData['didIdentifier'],
        createdAt: DateTime.parse(userData['createdAt']),
      );
      
      return DIDAuthResult.success(user);
      
    } catch (e, stackTrace) {
      _logError('❌ Error getting current user: $e', stackTrace);
      return DIDAuthResult.error('Failed to get user data: $e');
    }
  }
  
  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logDebug('✅ User signed out');
    } catch (e) {
      _logError('❌ Error signing out: $e');
    }
  }
  
  /// Delete user account and DID
  Future<DIDAuthResult> deleteAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return DIDAuthResult.error('User not authenticated');
      }
      
      _logDebug('🗑️ Deleting user account: ${currentUser.uid}');
      
      // 1. Delete user document from Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .delete();
      
      // 2. Delete Firebase Auth user
      await currentUser.delete();
      
      // 3. Clear local DID storage
      // Note: DID on blockchain cannot be deleted, but can be deactivated
      
      _logDebug('✅ User account deleted');
      return DIDAuthResult.success(null);
      
    } catch (e, stackTrace) {
      _logError('❌ Error deleting account: $e', stackTrace);
      return DIDAuthResult.error('Account deletion failed: $e');
    }
  }
  
  // Private helper methods
  
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    String? displayName,
    required String walletAddress,
    required String didIdentifier,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'displayName': displayName,
      'walletAddress': walletAddress,
      'didIdentifier': didIdentifier,
      'createdAt': DateTime.now().toIso8601String(),
      'walletConnectedAt': FieldValue.serverTimestamp(),
      'environment': EnvironmentConfig.currentEnvironment.name,
      'appVersion': '1.0.0',
      'isActive': true,
    });
  }
  
  void _logDebug(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🔐 DIDAuth: $message');
    }
  }
  
  void _logError(String message, [StackTrace? stackTrace]) {
    print('❌ DIDAuth Error: $message');
    if (stackTrace != null && EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('Stack trace: $stackTrace');
    }
  }
}

/// DID authentication result wrapper
class DIDAuthResult<T> {
  final bool success;
  final T? data;
  final String? error;
  
  DIDAuthResult.success(this.data) : success = true, error = null;
  DIDAuthResult.error(this.error) : success = false, data = null;
}

/// User data with DID information
class DIDUserData {
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? walletAddress;
  final String? didIdentifier;
  final DateTime createdAt;
  
  DIDUserData({
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.walletAddress,
    this.didIdentifier,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'firebaseUid': firebaseUid,
      'email': email,
      'displayName': displayName,
      'walletAddress': walletAddress,
      'didIdentifier': didIdentifier,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  bool get hasWallet => walletAddress != null && walletAddress!.isNotEmpty;
  bool get hasDID => didIdentifier != null && didIdentifier!.isNotEmpty;
  bool get isFullySetup => hasWallet && hasDID;
}
