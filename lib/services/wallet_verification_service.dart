/// Wallet Verification Service
/// Provides functions to verify custodial wallet creation and status
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_creation_service.dart';

class WalletVerificationService {
  static WalletVerificationService? _instance;
  static WalletVerificationService get instance => _instance ??= WalletVerificationService._();
  
  WalletVerificationService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Verify that a user has a properly created custodial wallet
  Future<WalletVerificationResult> verifyUserWallet(String userId) async {
    try {
      _logDebug('🔍 Verifying wallet for user: $userId');
      
      // Check user document for wallet reference
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return WalletVerificationResult.error('User document not found');
      }
      
      final userData = userDoc.data()!;
      final hasWallet = userData['hasWallet'] == true;
      final walletAddress = userData['walletAddress'] as String?;
      
      if (!hasWallet || walletAddress == null) {
        return WalletVerificationResult.error('User has no wallet address');
      }
      
      // Retrieve actual wallet data
      final wallet = await WalletCreationService.instance.getUserWallet(userId);
      if (wallet == null) {
        return WalletVerificationResult.error('Wallet data not found');
      }
      
      // Verify wallet integrity
      final integrityCheck = await _verifyWalletIntegrity(wallet);
      if (!integrityCheck.isValid) {
        return WalletVerificationResult.error('Wallet integrity check failed: ${integrityCheck.error}');
      }
      
      // Check wallet status
      if (wallet.status != WalletStatus.active) {
        return WalletVerificationResult.error('Wallet is not active: ${wallet.status.name}');
      }
      
      // Verify DID association
      if (wallet.didIdentifier.isEmpty) {
        return WalletVerificationResult.error('Wallet has no DID identifier');
      }
      
      _logDebug('✅ Wallet verification successful: ${wallet.accountId}');
      return WalletVerificationResult.success(
        WalletVerificationData(
          wallet: wallet,
          isActive: true,
          hasValidDID: true,
          lastVerified: DateTime.now(),
        ),
      );
      
    } catch (e, stackTrace) {
      _logError('❌ Error verifying wallet: $e', stackTrace);
      return WalletVerificationResult.error('Wallet verification failed: $e');
    }
  }
  
  /// Verify wallet integrity and consistency
  Future<WalletIntegrityResult> _verifyWalletIntegrity(CustodialWallet wallet) async {
    try {
      // Check required fields
      if (wallet.accountId.isEmpty) {
        return WalletIntegrityResult.invalid('Missing account ID');
      }
      
      if (wallet.publicKey.isEmpty) {
        return WalletIntegrityResult.invalid('Missing public key');
      }
      
      if (wallet.privateKeyEncrypted.isEmpty) {
        return WalletIntegrityResult.invalid('Missing encrypted private key');
      }
      
      if (wallet.didIdentifier.isEmpty) {
        return WalletIntegrityResult.invalid('Missing DID identifier');
      }
      
      // Verify account ID format (Hedera format: shard.realm.num)
      final accountIdPattern = RegExp(r'^\d+\.\d+\.\d+$');
      if (!accountIdPattern.hasMatch(wallet.accountId)) {
        return WalletIntegrityResult.invalid('Invalid account ID format');
      }
      
      // Verify DID format
      if (!wallet.didIdentifier.startsWith('did:hedera:')) {
        return WalletIntegrityResult.invalid('Invalid DID format');
      }
      
      // Check creation timestamp
      final now = DateTime.now();
      if (wallet.createdAt.isAfter(now)) {
        return WalletIntegrityResult.invalid('Invalid creation timestamp');
      }
      
      return WalletIntegrityResult.valid();
      
    } catch (e) {
      return WalletIntegrityResult.invalid('Integrity check error: $e');
    }
  }
  
  /// Get wallet verification statistics for admin dashboard
  Future<WalletVerificationStats> getVerificationStats() async {
    try {
      // Count total custodial wallets
      final walletsQuery = await _firestore
          .collection('custodial_wallets')
          .get();
      
      final totalWallets = walletsQuery.docs.length;
      
      // Count active wallets
      final activeWallets = walletsQuery.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      
      // Count users with wallets
      final usersQuery = await _firestore
          .collection('users')
          .where('hasWallet', isEqualTo: true)
          .get();
      
      final usersWithWallets = usersQuery.docs.length;
      
      // Get recent wallet creations (last 24 hours)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final recentWallets = walletsQuery.docs
          .where((doc) {
            final createdAt = DateTime.parse(doc.data()['createdAt']);
            return createdAt.isAfter(yesterday);
          })
          .length;
      
      return WalletVerificationStats(
        totalWallets: totalWallets,
        activeWallets: activeWallets,
        usersWithWallets: usersWithWallets,
        recentCreations: recentWallets,
        verificationRate: usersWithWallets / (usersWithWallets == 0 ? 1 : usersWithWallets),
        lastUpdated: DateTime.now(),
      );
      
    } catch (e) {
      _logError('❌ Error getting verification stats: $e');
      return WalletVerificationStats(
        totalWallets: 0,
        activeWallets: 0,
        usersWithWallets: 0,
        recentCreations: 0,
        verificationRate: 0.0,
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Audit wallet creation process for specific time period
  Future<List<WalletAuditEntry>> auditWalletCreations({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('wallet_audit_log')
          .where('action', isEqualTo: 'wallet_created')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      
      final auditDocs = await query.get();
      
      return auditDocs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WalletAuditEntry(
          userId: data['userId'],
          accountId: data['accountId'],
          action: data['action'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          metadata: data['metadata'] as Map<String, dynamic>?,
        );
      }).toList();
      
    } catch (e) {
      _logError('❌ Error auditing wallet creations: $e');
      return [];
    }
  }
  
  void _logDebug(String message) {
    print('[WalletVerificationService] $message');
  }
  
  void _logError(String message, [StackTrace? stackTrace]) {
    print('[WalletVerificationService] ERROR: $message');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}

/// Result of wallet verification
class WalletVerificationResult {
  final bool success;
  final WalletVerificationData? data;
  final String? error;
  
  WalletVerificationResult._({
    required this.success,
    this.data,
    this.error,
  });
  
  factory WalletVerificationResult.success(WalletVerificationData data) {
    return WalletVerificationResult._(success: true, data: data);
  }
  
  factory WalletVerificationResult.error(String error) {
    return WalletVerificationResult._(success: false, error: error);
  }
}

/// Wallet verification data
class WalletVerificationData {
  final CustodialWallet wallet;
  final bool isActive;
  final bool hasValidDID;
  final DateTime lastVerified;
  
  WalletVerificationData({
    required this.wallet,
    required this.isActive,
    required this.hasValidDID,
    required this.lastVerified,
  });
}

/// Wallet integrity check result
class WalletIntegrityResult {
  final bool isValid;
  final String? error;
  
  WalletIntegrityResult._({
    required this.isValid,
    this.error,
  });
  
  factory WalletIntegrityResult.valid() {
    return WalletIntegrityResult._(isValid: true);
  }
  
  factory WalletIntegrityResult.invalid(String error) {
    return WalletIntegrityResult._(isValid: false, error: error);
  }
}

/// Wallet verification statistics
class WalletVerificationStats {
  final int totalWallets;
  final int activeWallets;
  final int usersWithWallets;
  final int recentCreations;
  final double verificationRate;
  final DateTime lastUpdated;
  
  WalletVerificationStats({
    required this.totalWallets,
    required this.activeWallets,
    required this.usersWithWallets,
    required this.recentCreations,
    required this.verificationRate,
    required this.lastUpdated,
  });
}

/// Wallet audit entry
class WalletAuditEntry {
  final String userId;
  final String accountId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  WalletAuditEntry({
    required this.userId,
    required this.accountId,
    required this.action,
    required this.timestamp,
    this.metadata,
  });
}
