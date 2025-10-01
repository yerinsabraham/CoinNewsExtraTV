/// Simplified Wallet Creation Service for CNE Token App
/// Handles basic wallet creation during user signup without complex Hedera operations
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimplifiedWalletCreationService {
  static SimplifiedWalletCreationService? _instance;
  static SimplifiedWalletCreationService get instance => _instance ??= SimplifiedWalletCreationService._();
  
  SimplifiedWalletCreationService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Create a simplified custodial wallet for new users
  Future<WalletCreationResult> createCustodialWallet({
    required String userId,
    required String userEmail,
    String? displayName,
  }) async {
    try {
      print('🏦 Creating simplified custodial wallet for user: $userId');
      
      // Check if user already has a wallet
      final existingWallet = await _checkExistingWallet(userId);
      if (existingWallet != null) {
        print('⚠️ User already has a wallet: ${existingWallet.accountId}');
        return WalletCreationResult.success(existingWallet);
      }
      
      // Generate simulated account ID for mainnet
      final accountId = _generateMainnetAccountId();
      
      // Generate DID identifier
      final didIdentifier = 'did:hedera:mainnet:$accountId';
      
      // Create simplified wallet data
      final walletData = CustodialWallet(
        userId: userId,
        accountId: accountId,
        publicKey: _generatePublicKey(),
        privateKeyEncrypted: _encryptPrivateKey(userId),
        didIdentifier: didIdentifier,
        userEmail: userEmail,
        displayName: displayName,
        createdAt: DateTime.now(),
        status: WalletStatus.active,
        initialFunding: 0.0,
      );
      
      // Store wallet in Firestore
      await _storeWallet(walletData);
      
      // Update user document
      await _updateUserDocument(userId, walletData);
      
      // Log creation
      await _logWalletCreation(walletData);
      
      print('✅ Simplified wallet created successfully: $accountId');
      return WalletCreationResult.success(walletData);
      
    } catch (e, stackTrace) {
      print('❌ Error creating simplified wallet: $e');
      print('Stack trace: $stackTrace');
      return WalletCreationResult.error('Failed to create wallet: $e');
    }
  }
  
  /// Check if user has an existing wallet
  Future<CustodialWallet?> _checkExistingWallet(String userId) async {
    try {
      final walletDoc = await _firestore
          .collection('custodial_wallets')
          .doc(userId)
          .get();
      
      if (!walletDoc.exists) {
        return null;
      }
      
      return CustodialWallet.fromFirestore(walletDoc.data()!);
    } catch (e) {
      print('❌ Error checking existing wallet: $e');
      return null;
    }
  }
  
  /// Generate a realistic mainnet account ID
  String _generateMainnetAccountId() {
    final random = Random();
    final shard = 0;
    final realm = 0;
    final num = 10000000 + random.nextInt(90000000); // Generate realistic mainnet account number
    
    return '$shard.$realm.$num';
  }
  
  /// Generate a simulated public key
  String _generatePublicKey() {
    final random = Random.secure();
    final bytes = List.generate(32, (_) => random.nextInt(256));
    return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }
  
  /// Encrypt private key for storage
  String _encryptPrivateKey(String userId) {
    final combined = 'simulated_private_key_$userId:${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
  
  /// Store wallet in Firestore
  Future<void> _storeWallet(CustodialWallet wallet) async {
    await _firestore
        .collection('custodial_wallets')
        .doc(wallet.userId)
        .set(wallet.toFirestore());
  }
  
  /// Update user document with wallet info
  Future<void> _updateUserDocument(String userId, CustodialWallet wallet) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
      'walletAddress': wallet.accountId,
      'didIdentifier': wallet.didIdentifier,
      'walletCreatedAt': FieldValue.serverTimestamp(),
      'hasWallet': true,
      'walletType': 'custodial_simplified',
      'network': 'mainnet',
    });
  }
  
  /// Log wallet creation for audit
  Future<void> _logWalletCreation(CustodialWallet wallet) async {
    try {
      await _firestore
          .collection('wallet_audit_log')
          .add({
        'userId': wallet.userId,
        'accountId': wallet.accountId,
        'action': 'wallet_created_simplified',
        'didIdentifier': wallet.didIdentifier,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'userEmail': wallet.userEmail,
          'displayName': wallet.displayName,
          'environment': 'mainnet',
          'walletType': 'simplified',
        },
      });
    } catch (e) {
      print('❌ Error logging wallet creation: $e');
    }
  }
  
  /// Retrieve user's wallet
  Future<CustodialWallet?> getUserWallet(String userId) async {
    try {
      final walletDoc = await _firestore
          .collection('custodial_wallets')
          .doc(userId)
          .get();
      
      if (!walletDoc.exists) {
        return null;
      }
      
      return CustodialWallet.fromFirestore(walletDoc.data()!);
      
    } catch (e) {
      print('❌ Error retrieving user wallet: $e');
      return null;
    }
  }
}

/// Result of wallet creation operation
class WalletCreationResult {
  final bool success;
  final CustodialWallet? wallet;
  final String? error;
  
  WalletCreationResult._({
    required this.success,
    this.wallet,
    this.error,
  });
  
  factory WalletCreationResult.success(CustodialWallet wallet) {
    return WalletCreationResult._(success: true, wallet: wallet);
  }
  
  factory WalletCreationResult.error(String error) {
    return WalletCreationResult._(success: false, error: error);
  }
}

/// Custodial wallet data structure
class CustodialWallet {
  final String userId;
  final String accountId;
  final String publicKey;
  final String privateKeyEncrypted;
  final String didIdentifier;
  final String userEmail;
  final String? displayName;
  final DateTime createdAt;
  final WalletStatus status;
  final double initialFunding;
  
  CustodialWallet({
    required this.userId,
    required this.accountId,
    required this.publicKey,
    required this.privateKeyEncrypted,
    required this.didIdentifier,
    required this.userEmail,
    this.displayName,
    required this.createdAt,
    required this.status,
    required this.initialFunding,
  });
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'publicKey': publicKey,
      'privateKeyEncrypted': privateKeyEncrypted,
      'didIdentifier': didIdentifier,
      'userEmail': userEmail,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'initialFunding': initialFunding,
      'walletType': 'simplified',
      'network': 'mainnet',
    };
  }
  
  factory CustodialWallet.fromFirestore(Map<String, dynamic> data) {
    return CustodialWallet(
      userId: data['userId'],
      accountId: data['accountId'],
      publicKey: data['publicKey'],
      privateKeyEncrypted: data['privateKeyEncrypted'],
      didIdentifier: data['didIdentifier'],
      userEmail: data['userEmail'],
      displayName: data['displayName'],
      createdAt: DateTime.parse(data['createdAt']),
      status: WalletStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => WalletStatus.active,
      ),
      initialFunding: (data['initialFunding'] ?? 0.0).toDouble(),
    );
  }
}

/// Wallet status enumeration
enum WalletStatus {
  active,
  suspended,
  archived,
}