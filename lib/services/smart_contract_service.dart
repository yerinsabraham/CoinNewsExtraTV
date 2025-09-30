/// Smart Contract Service for Hedera Network Integration
/// Handles CNE token transfers, reward claims, and DID operations
import 'dart:convert';
import 'dart:math';
import '../config/environment_config.dart';
import '../config/contract_abis.dart';

class SmartContractService {
  static SmartContractService? _instance;
  static SmartContractService get instance => _instance ??= SmartContractService._();
  
  SmartContractService._();
  
  // Contract instances will be initialized when needed
  late final String _cneTokenId;
  late final String _rewardContractId;
  late final String _stakingContractId;
  late final String _didRegistryId;
  
  bool _initialized = false;
  
  /// Initialize smart contract service
  Future<void> initialize() async {
    if (_initialized) return;
    
    final hederaConfig = EnvironmentConfig.hederaConfig;
    final contractConfig = EnvironmentConfig.smartContractConfig;
    
    _cneTokenId = hederaConfig['cneTokenId'];
    _rewardContractId = contractConfig['rewardContractId'];
    _stakingContractId = contractConfig['stakingContractId'];
    _didRegistryId = contractConfig['didRegistryId'] ?? '';
    
    _initialized = true;
    _logDebug('✅ SmartContractService initialized for ${EnvironmentConfig.currentEnvironment.name}');
  }
  
  /// Get CNE token balance for user
  Future<ContractResult<double>> getCNEBalance(String walletAddress) async {
    try {
      await _ensureInitialized();
      
      _logDebug('🔍 Getting CNE balance for wallet: $walletAddress');
      
      // For Hedera, we'll use the mirror node to query token balance
      final mirrorNodeUrl = EnvironmentConfig.hederaConfig['mirrorNodeUrl'];
      final response = await _queryMirrorNode(
        '$mirrorNodeUrl/api/v1/accounts/$walletAddress/tokens?token.id=$_cneTokenId'
      );
      
      if (response.success && response.data != null) {
        final tokens = response.data['tokens'] as List?;
        if (tokens != null && tokens.isNotEmpty) {
          final balance = double.parse(tokens.first['balance'].toString());
          // Convert from smallest unit (8 decimals) to CNE
          final cneBalance = balance / 100000000;
          
          _logDebug('✅ CNE balance retrieved: $cneBalance CNE');
          return ContractResult.success(cneBalance);
        }
      }
      
      return ContractResult.success(0.0);
    } catch (e, stackTrace) {
      _logError('❌ Error getting CNE balance: $e', stackTrace);
      return ContractResult.error('Failed to get CNE balance: $e');
    }
  }
  
  /// Claim reward from smart contract
  Future<ContractResult<String>> claimReward({
    required String walletAddress,
    required double amount,
    required String eventType,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _ensureInitialized();
      
      _logDebug('🎯 Claiming reward: $amount CNE for event: $eventType');
      
      // Estimate gas first
      final gasEstimate = await _estimateGas(
        contractId: _rewardContractId,
        functionName: 'claimReward',
        parameters: [walletAddress, _cneToSmallestUnit(amount), eventType, jsonEncode(metadata)],
      );
      
      if (!gasEstimate.success) {
        return ContractResult.error('Gas estimation failed: ${gasEstimate.error}');
      }
      
      // Execute the contract call
      final result = await _executeContractCall(
        contractId: _rewardContractId,
        functionName: 'claimReward',
        parameters: [walletAddress, _cneToSmallestUnit(amount), eventType, jsonEncode(metadata)],
        gasLimit: gasEstimate.data!,
      );
      
      if (result.success) {
        _logDebug('✅ Reward claimed successfully: ${result.data}');
        return ContractResult.success(result.data!);
      } else {
        _logError('❌ Reward claim failed: ${result.error}');
        return ContractResult.error(result.error!);
      }
      
    } catch (e, stackTrace) {
      _logError('❌ Error claiming reward: $e', stackTrace);
      return ContractResult.error('Failed to claim reward: $e');
    }
  }
  
  /// Check if user can claim a specific reward
  Future<ContractResult<bool>> canClaimReward({
    required String walletAddress,
    required String eventType,
  }) async {
    try {
      await _ensureInitialized();
      
      final result = await _callContractView(
        contractId: _rewardContractId,
        functionName: 'canClaimReward',
        parameters: [walletAddress, eventType],
      );
      
      if (result.success && result.data != null) {
        final canClaim = result.data['result'][0] as bool;
        return ContractResult.success(canClaim);
      }
      
      return ContractResult.error('Failed to check claim eligibility');
    } catch (e, stackTrace) {
      _logError('❌ Error checking claim eligibility: $e', stackTrace);
      return ContractResult.error('Failed to check claim eligibility: $e');
    }
  }
  
  /// Get user reward statistics
  Future<ContractResult<UserRewardStats>> getUserRewardStats(String walletAddress) async {
    try {
      await _ensureInitialized();
      
      final result = await _callContractView(
        contractId: _rewardContractId,
        functionName: 'getUserRewards',
        parameters: [walletAddress],
      );
      
      if (result.success && result.data != null) {
        final data = result.data['result'] as List;
        final stats = UserRewardStats(
          totalEarned: _smallestUnitToCNE(data[0]),
          totalClaimed: _smallestUnitToCNE(data[1]),
          lockedBalance: _smallestUnitToCNE(data[2]),
        );
        return ContractResult.success(stats);
      }
      
      return ContractResult.error('Failed to get user reward stats');
    } catch (e, stackTrace) {
      _logError('❌ Error getting user reward stats: $e', stackTrace);
      return ContractResult.error('Failed to get user reward stats: $e');
    }
  }
  
  /// Transfer CNE tokens
  Future<ContractResult<String>> transferCNE({
    required String fromAddress,
    required String toAddress,
    required double amount,
  }) async {
    try {
      await _ensureInitialized();
      
      _logDebug('💸 Transferring $amount CNE from $fromAddress to $toAddress');
      
      // For Hedera, we'll use HTS (Hedera Token Service) transfer
      final result = await _executeTokenTransfer(
        tokenId: _cneTokenId,
        fromAccount: fromAddress,
        toAccount: toAddress,
        amount: _cneToSmallestUnit(amount),
      );
      
      if (result.success) {
        _logDebug('✅ CNE transfer successful: ${result.data}');
        return ContractResult.success(result.data!);
      } else {
        _logError('❌ CNE transfer failed: ${result.error}');
        return ContractResult.error(result.error!);
      }
      
    } catch (e, stackTrace) {
      _logError('❌ Error transferring CNE: $e', stackTrace);
      return ContractResult.error('Failed to transfer CNE: $e');
    }
  }
  
  /// Lock tokens for staking
  Future<ContractResult<String>> lockTokens({
    required String walletAddress,
    required double amount,
    required int lockDurationDays,
  }) async {
    try {
      await _ensureInitialized();
      
      final result = await _executeContractCall(
        contractId: _rewardContractId,
        functionName: 'lockTokens',
        parameters: [walletAddress, _cneToSmallestUnit(amount)],
        gasLimit: 500000,
      );
      
      if (result.success) {
        _logDebug('✅ Tokens locked successfully: ${result.data}');
        return ContractResult.success(result.data!);
      } else {
        return ContractResult.error(result.error!);
      }
      
    } catch (e, stackTrace) {
      _logError('❌ Error locking tokens: $e', stackTrace);
      return ContractResult.error('Failed to lock tokens: $e');
    }
  }
  
  /// Create DID for user
  Future<ContractResult<String>> createDID({
    required String walletAddress,
    required Map<String, dynamic> didDocument,
  }) async {
    try {
      await _ensureInitialized();
      
      if (_didRegistryId.isEmpty) {
        return ContractResult.error('DID registry not configured');
      }
      
      final identifier = _generateDIDIdentifier(walletAddress);
      final documentJson = jsonEncode(didDocument);
      
      final result = await _executeContractCall(
        contractId: _didRegistryId,
        functionName: 'createDID',
        parameters: [identifier, documentJson],
        gasLimit: 1000000,
      );
      
      if (result.success) {
        _logDebug('✅ DID created successfully: $identifier');
        return ContractResult.success(identifier);
      } else {
        return ContractResult.error(result.error!);
      }
      
    } catch (e, stackTrace) {
      _logError('❌ Error creating DID: $e', stackTrace);
      return ContractResult.error('Failed to create DID: $e');
    }
  }
  
  /// Resolve DID document
  Future<ContractResult<Map<String, dynamic>>> resolveDID(String identifier) async {
    try {
      await _ensureInitialized();
      
      if (_didRegistryId.isEmpty) {
        return ContractResult.error('DID registry not configured');
      }
      
      final result = await _callContractView(
        contractId: _didRegistryId,
        functionName: 'resolveDID',
        parameters: [identifier],
      );
      
      if (result.success && result.data != null) {
        final data = result.data['result'] as List;
        final documentJson = data[0] as String;
        final lastUpdated = data[1] as int;
        
        return ContractResult.success({
          'document': jsonDecode(documentJson),
          'lastUpdated': lastUpdated,
        });
      }
      
      return ContractResult.error('Failed to resolve DID');
    } catch (e, stackTrace) {
      _logError('❌ Error resolving DID: $e', stackTrace);
      return ContractResult.error('Failed to resolve DID: $e');
    }
  }
  
  // Private helper methods
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
  
  /// Estimate gas for contract call
  Future<ContractResult<int>> _estimateGas({
    required String contractId,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    try {
      // Mock gas estimation for now - in real implementation, this would
      // call the Hedera SDK to estimate gas costs
      final baseGas = 100000;
      final parameterGas = parameters.length * 10000;
      final estimatedGas = baseGas + parameterGas;
      
      _logDebug('⛽ Estimated gas for $functionName: $estimatedGas');
      return ContractResult.success(estimatedGas);
    } catch (e) {
      return ContractResult.error('Gas estimation failed: $e');
    }
  }
  
  /// Execute contract call
  Future<ContractResult<String>> _executeContractCall({
    required String contractId,
    required String functionName,
    required List<dynamic> parameters,
    required int gasLimit,
  }) async {
    try {
      // Mock implementation - replace with actual Hedera SDK calls
      _logDebug('📋 Executing $functionName on contract $contractId');
      _logDebug('📋 Parameters: $parameters');
      _logDebug('📋 Gas limit: $gasLimit');
      
      // Simulate transaction hash
      final transactionId = _generateTransactionId();
      
      return ContractResult.success(transactionId);
    } catch (e) {
      return ContractResult.error('Contract call failed: $e');
    }
  }
  
  /// Call contract view function
  Future<ContractResult<Map<String, dynamic>>> _callContractView({
    required String contractId,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    try {
      // Mock implementation - replace with actual Hedera SDK calls
      _logDebug('👁️ Calling view function $functionName on contract $contractId');
      
      // Mock response
      return ContractResult.success({
        'result': [true], // Mock return value
      });
    } catch (e) {
      return ContractResult.error('View call failed: $e');
    }
  }
  
  /// Execute token transfer using HTS
  Future<ContractResult<String>> _executeTokenTransfer({
    required String tokenId,
    required String fromAccount,
    required String toAccount,
    required int amount,
  }) async {
    try {
      // Mock implementation - replace with actual Hedera Token Service calls
      _logDebug('🔄 HTS Transfer: $amount units of token $tokenId from $fromAccount to $toAccount');
      
      final transactionId = _generateTransactionId();
      return ContractResult.success(transactionId);
    } catch (e) {
      return ContractResult.error('Token transfer failed: $e');
    }
  }
  
  /// Query Hedera mirror node
  Future<ContractResult<Map<String, dynamic>>> _queryMirrorNode(String url) async {
    try {
      // Mock implementation - replace with actual HTTP calls
      _logDebug('🔍 Querying mirror node: $url');
      
      // Mock response
      return ContractResult.success({
        'tokens': [
          {'balance': '50000000000'} // 500 CNE in smallest unit
        ]
      });
    } catch (e) {
      return ContractResult.error('Mirror node query failed: $e');
    }
  }
  
  /// Convert CNE to smallest unit (8 decimals)
  int _cneToSmallestUnit(double cne) {
    return (cne * 100000000).round();
  }
  
  /// Convert smallest unit to CNE
  double _smallestUnitToCNE(dynamic smallestUnit) {
    final amount = smallestUnit is String ? int.parse(smallestUnit) : smallestUnit as int;
    return amount / 100000000;
  }
  
  /// Generate DID identifier
  String _generateDIDIdentifier(String walletAddress) {
    final method = EnvironmentConfig.didConfig['didMethod'];
    return '$method:$walletAddress';
  }
  
  /// Generate mock transaction ID
  String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = random.nextInt(999999);
    return '0.0.${random.nextInt(999999)}@$timestamp.$randomId';
  }
  
  void _logDebug(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🔗 SmartContract: $message');
    }
  }
  
  void _logError(String message, [StackTrace? stackTrace]) {
    print('❌ SmartContract Error: $message');
    if (stackTrace != null && EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('Stack trace: $stackTrace');
    }
  }
}

/// Contract operation result wrapper
class ContractResult<T> {
  final bool success;
  final T? data;
  final String? error;
  
  ContractResult.success(this.data) : success = true, error = null;
  ContractResult.error(this.error) : success = false, data = null;
}

/// User reward statistics
class UserRewardStats {
  final double totalEarned;
  final double totalClaimed;
  final double lockedBalance;
  
  UserRewardStats({
    required this.totalEarned,
    required this.totalClaimed,
    required this.lockedBalance,
  });
  
  double get availableBalance => totalEarned - totalClaimed - lockedBalance;
  
  Map<String, dynamic> toMap() {
    return {
      'totalEarned': totalEarned,
      'totalClaimed': totalClaimed,
      'lockedBalance': lockedBalance,
      'availableBalance': availableBalance,
    };
  }
}
