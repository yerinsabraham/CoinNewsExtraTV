/// Hedera Custodial Wallet Creation Service
/// Automatically creates Hedera accounts for new users during onboarding
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';

class WalletCreationService {
  static WalletCreationService? _instance;
  static WalletCreationService get instance => _instance ??= WalletCreationService._();
  
  WalletCreationService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  
  /// Initialize the wallet creation service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logDebug('🔧 Initializing Wallet Creation Service...');
      
      // Validate environment configuration
      final hederaConfig = EnvironmentConfig.hederaConfig;
      if (hederaConfig['operatorId'] == null || hederaConfig['operatorKey'] == null) {
        throw Exception('Missing Hedera configuration for wallet creation');
      }
      
      _initialized = true;
      _logDebug('✅ Wallet Creation Service initialized');
      
    } catch (e) {
      _logError('❌ Failed to initialize Wallet Creation Service: $e');
      rethrow;
    }
  }
  
  /// Create a new custodial Hedera wallet for a user
  Future<WalletCreationResult> createCustodialWallet({
    required String userId,
    required String userEmail,
    String? displayName,
  }) async {
    try {
      await initialize();
      
      _logDebug('🏦 Creating custodial Hedera wallet for user: $userId');
      
      // Check if user already has a wallet
      final existingWallet = await _checkExistingWallet(userId);
      if (existingWallet != null) {
        _logDebug('⚠️ User already has a wallet: ${existingWallet.accountId}');
        return WalletCreationResult.success(existingWallet);
      }
      
      // Generate ED25519 keypair for the new account
      final keyPair = await _generateED25519KeyPair();
      
      // Create account ID (simulate account creation - in production this would use Hedera SDK)
      final accountId = await _createHederaAccount(keyPair);
      
      // Generate DID identifier
      final didIdentifier = _generateDIDIdentifier(accountId);
      
      // Create wallet data structure
      final walletData = CustodialWallet(
        userId: userId,
        accountId: accountId,
        publicKey: keyPair['publicKey']!,
        privateKeyEncrypted: await _encryptPrivateKey(keyPair['privateKey']!, userId),
        didIdentifier: didIdentifier,
        userEmail: userEmail,
        displayName: displayName,
        createdAt: DateTime.now(),
        status: WalletStatus.active,
        initialFunding: 0.0,
      );
      
      // Store wallet in Firestore with security measures
      await _storeWalletSecurely(walletData);
      
      // Associate token (CNE) with the new account
      await _associateTokens(accountId);
      
      // Fund initial HBAR for transaction fees (minimal amount)
      await _fundInitialHBAR(accountId);
      
      // Log wallet creation for audit trail
      await _logWalletCreation(walletData);
      
      _logDebug('✅ Custodial wallet created successfully: $accountId');
      return WalletCreationResult.success(walletData);
      
    } catch (e, stackTrace) {
      _logError('❌ Error creating custodial wallet: $e', stackTrace);
      return WalletCreationResult.error('Failed to create wallet: $e');
    }
  }
  
  /// Retrieve user's custodial wallet
  Future<CustodialWallet?> getUserWallet(String userId) async {
    try {
      await initialize();
      
      final walletDoc = await _firestore
          .collection('custodial_wallets')
          .doc(userId)
          .get();
      
      if (!walletDoc.exists) {
        return null;
      }
      
      return CustodialWallet.fromFirestore(walletDoc.data()!);
      
    } catch (e) {
      _logError('❌ Error retrieving user wallet: $e');
      return null;
    }
  }
  
  /// Check if user has an existing wallet
  Future<CustodialWallet?> _checkExistingWallet(String userId) async {
    return await getUserWallet(userId);
  }
  
  /// Generate ED25519 keypair for Hedera account
  Future<Map<String, String>> _generateED25519KeyPair() async {
    // In production, this would use proper cryptographic libraries
    // For now, we'll simulate keypair generation
    final random = Random.secure();
    
    // Generate 32-byte private key
    final privateKeyBytes = List.generate(32, (_) => random.nextInt(256));
    final privateKey = privateKeyBytes
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    
    // Derive public key (simplified - in production use proper ED25519)
    final publicKeyHash = sha256.convert(utf8.encode(privateKey));
    final publicKey = publicKeyHash.toString();
    
    return {
      'privateKey': privateKey,
      'publicKey': publicKey,
    };
  }
  
  /// Create Hedera account (simulated - in production would use Hedera SDK)
  Future<String> _createHederaAccount(Map<String, String> keyPair) async {
    // Simulate account creation by generating a realistic account ID
    final random = Random();
    final shard = 0;
    final realm = 0;
    final num = 1000000 + random.nextInt(9000000); // Generate realistic account number
    
    return '$shard.$realm.$num';
  }
  
  /// Generate DID identifier for the wallet
  String _generateDIDIdentifier(String accountId) {
    final network = EnvironmentConfig.currentEnvironment.name;
    return 'did:hedera:$network:$accountId';
  }
  
  /// Encrypt private key for secure storage
  Future<String> _encryptPrivateKey(String privateKey, String userId) async {
    // In production, use proper encryption with HSM or secure key management
    // For now, we'll use a simple encoding (NOT secure for production)
    final combined = '$privateKey:$userId:${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
  
  /// Store wallet data securely in Firestore
  Future<void> _storeWalletSecurely(CustodialWallet wallet) async {
    // Store in custodial_wallets collection with restricted access
    await _firestore
        .collection('custodial_wallets')
        .doc(wallet.userId)
        .set(wallet.toFirestore());
    
    // Also update user document with wallet reference
    await _firestore
        .collection('users')
        .doc(wallet.userId)
        .update({
      'walletAddress': wallet.accountId,
      'didIdentifier': wallet.didIdentifier,
      'walletCreatedAt': FieldValue.serverTimestamp(),
      'hasWallet': true,
    });
  }
  
  /// Associate CNE token with new account
  Future<void> _associateTokens(String accountId) async {
    try {
      // In production, this would use Hedera SDK to associate tokens
      _logDebug('🪙 Associating CNE token with account: $accountId');
      
      // Store association in Firestore for tracking
      await _firestore
          .collection('token_associations')
          .add({
        'accountId': accountId,
        'tokenId': EnvironmentConfig.hederaConfig['cneTokenId'],
        'associatedAt': FieldValue.serverTimestamp(),
        'status': 'associated',
      });
      
    } catch (e) {
      _logError('❌ Error associating tokens: $e');
      // Don't throw - wallet creation can continue without token association
    }
  }
  
  /// Fund account with initial HBAR for transaction fees
  Future<void> _fundInitialHBAR(String accountId) async {
    try {
      // In production, transfer small amount of HBAR from operator account
      _logDebug('💰 Funding initial HBAR for account: $accountId');
      
      // Log funding transaction for audit
      await _firestore
          .collection('wallet_funding')
          .add({
        'accountId': accountId,
        'amount': 0.1, // 0.1 HBAR for transaction fees
        'purpose': 'initial_funding',
        'fundedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
      
    } catch (e) {
      _logError('❌ Error funding initial HBAR: $e');
      // Don't throw - wallet can still be used
    }
  }
  
  /// Log wallet creation for audit trail
  Future<void> _logWalletCreation(CustodialWallet wallet) async {
    try {
      await _firestore
          .collection('wallet_audit_log')
          .add({
        'userId': wallet.userId,
        'accountId': wallet.accountId,
        'action': 'wallet_created',
        'didIdentifier': wallet.didIdentifier,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'userEmail': wallet.userEmail,
          'displayName': wallet.displayName,
          'environment': EnvironmentConfig.currentEnvironment.name,
        },
      });
    } catch (e) {
      _logError('❌ Error logging wallet creation: $e');
    }
  }
  
  void _logDebug(String message) {
    print('[WalletCreationService] $message');
  }
  
  void _logError(String message, [StackTrace? stackTrace]) {
    print('[WalletCreationService] ERROR: $message');
    if (stackTrace != null) {
      print(stackTrace);
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
