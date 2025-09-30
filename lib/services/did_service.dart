/// Decentralized Identity (DID) Service for CNE Token App
/// Implements W3C DID standard with Hedera integration
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment_config.dart';
import 'smart_contract_service.dart';

class DIDService {
  static DIDService? _instance;
  static DIDService get instance => _instance ??= DIDService._();
  
  DIDService._();
  
  static const String _didStorageKey = 'user_did';
  static const String _didDocumentKey = 'did_document';
  static const String _didKeysKey = 'did_keys';
  
  bool _initialized = false;
  String? _userDID;
  Map<String, dynamic>? _didDocument;
  Map<String, dynamic>? _keyPair;
  
  /// Initialize DID service
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _loadStoredDID();
    _initialized = true;
    
    _logDebug('✅ DIDService initialized');
  }
  
  /// Create DID for new user
  Future<DIDResult<String>> createDID({
    required String walletAddress,
    required String userEmail,
    String? userName,
  }) async {
    try {
      await _ensureInitialized();
      
      _logDebug('🆔 Creating DID for wallet: $walletAddress');
      
      // Generate key pair for DID
      final keyPair = await _generateKeyPair();
      
      // Create DID identifier
      final didIdentifier = _generateDIDIdentifier(walletAddress);
      
      // Create DID document
      final didDocument = _createDIDDocument(
        identifier: didIdentifier,
        walletAddress: walletAddress,
        publicKey: keyPair['publicKey'],
        userEmail: userEmail,
        userName: userName,
      );
      
      // Store DID on blockchain via smart contract
      final contractResult = await SmartContractService.instance.createDID(
        walletAddress: walletAddress,
        didDocument: didDocument,
      );
      
      if (!contractResult.success) {
        return DIDResult.error('Failed to store DID on blockchain: ${contractResult.error}');
      }
      
      // Store DID locally
      await _storeDIDLocally(didIdentifier, didDocument, keyPair);
      
      _userDID = didIdentifier;
      _didDocument = didDocument;
      _keyPair = keyPair;
      
      _logDebug('✅ DID created successfully: $didIdentifier');
      return DIDResult.success(didIdentifier);
      
    } catch (e, stackTrace) {
      _logError('❌ Error creating DID: $e', stackTrace);
      return DIDResult.error('Failed to create DID: $e');
    }
  }
  
  /// Get current user's DID
  String? getCurrentDID() {
    return _userDID;
  }
  
  /// Get current user's DID document
  Map<String, dynamic>? getCurrentDIDDocument() {
    return _didDocument;
  }
  
  /// Verify user's DID for reward claims
  Future<DIDResult<bool>> verifyDIDForReward({
    required String walletAddress,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _ensureInitialized();
      
      if (_userDID == null) {
        return DIDResult.error('User DID not found');
      }
      
      _logDebug('🔐 Verifying DID for reward claim: $eventType');
      
      // Check if DID is valid and not revoked
      final didValid = await _validateDID(_userDID!);
      if (!didValid.success) {
        return DIDResult.error('DID validation failed: ${didValid.error}');
      }
      
      // Verify wallet ownership
      final walletValid = await _verifyWalletOwnership(walletAddress);
      if (!walletValid.success) {
        return DIDResult.error('Wallet ownership verification failed: ${walletValid.error}');
      }
      
      // Check for duplicate claims (anti-fraud)
      final duplicateCheck = await _checkDuplicateClaim(_userDID!, eventType, eventData);
      if (!duplicateCheck.success) {
        return DIDResult.error('Duplicate claim detected: ${duplicateCheck.error}');
      }
      
      // Create verification proof
      final proof = await _createVerificationProof(eventType, eventData);
      if (!proof.success) {
        return DIDResult.error('Failed to create verification proof: ${proof.error}');
      }
      
      _logDebug('✅ DID verification successful for reward claim');
      return DIDResult.success(true);
      
    } catch (e, stackTrace) {
      _logError('❌ Error verifying DID for reward: $e', stackTrace);
      return DIDResult.error('DID verification failed: $e');
    }
  }
  
  /// Update DID document
  Future<DIDResult<bool>> updateDIDDocument({
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _ensureInitialized();
      
      if (_userDID == null || _didDocument == null) {
        return DIDResult.error('User DID not found');
      }
      
      _logDebug('📝 Updating DID document');
      
      // Merge updates with existing document
      final updatedDocument = Map<String, dynamic>.from(_didDocument!);
      updates.forEach((key, value) {
        updatedDocument[key] = value;
      });
      
      // Update timestamp
      updatedDocument['updated'] = DateTime.now().toIso8601String();
      
      // Update on blockchain
      final contractResult = await SmartContractService.instance.createDID(
        walletAddress: updatedDocument['controller'],
        didDocument: updatedDocument,
      );
      
      if (!contractResult.success) {
        return DIDResult.error('Failed to update DID on blockchain: ${contractResult.error}');
      }
      
      // Update local storage
      await _updateDIDDocumentLocally(updatedDocument);
      
      _didDocument = updatedDocument;
      
      _logDebug('✅ DID document updated successfully');
      return DIDResult.success(true);
      
    } catch (e, stackTrace) {
      _logError('❌ Error updating DID document: $e', stackTrace);
      return DIDResult.error('Failed to update DID document: $e');
    }
  }
  
  /// Resolve DID from identifier
  Future<DIDResult<Map<String, dynamic>>> resolveDID(String identifier) async {
    try {
      await _ensureInitialized();
      
      _logDebug('🔍 Resolving DID: $identifier');
      
      // Try to resolve from blockchain first
      final contractResult = await SmartContractService.instance.resolveDID(identifier);
      
      if (contractResult.success && contractResult.data != null) {
        return DIDResult.success(contractResult.data!);
      }
      
      // Fallback to local storage if it's the current user's DID
      if (identifier == _userDID && _didDocument != null) {
        return DIDResult.success(_didDocument!);
      }
      
      return DIDResult.error('DID not found');
      
    } catch (e, stackTrace) {
      _logError('❌ Error resolving DID: $e', stackTrace);
      return DIDResult.error('Failed to resolve DID: $e');
    }
  }
  
  /// Sign data with DID key
  Future<DIDResult<String>> signWithDID(Map<String, dynamic> data) async {
    try {
      await _ensureInitialized();
      
      if (_keyPair == null) {
        return DIDResult.error('DID key pair not found');
      }
      
      final dataJson = jsonEncode(data);
      final signature = await _signData(dataJson, _keyPair!['privateKey']);
      
      return DIDResult.success(signature);
      
    } catch (e, stackTrace) {
      _logError('❌ Error signing with DID: $e', stackTrace);
      return DIDResult.error('Failed to sign with DID: $e');
    }
  }
  
  /// Verify signature with DID
  Future<DIDResult<bool>> verifyDIDSignature({
    required String signature,
    required Map<String, dynamic> data,
    required String didIdentifier,
  }) async {
    try {
      await _ensureInitialized();
      
      // Resolve DID to get public key
      final didResult = await resolveDID(didIdentifier);
      if (!didResult.success) {
        return DIDResult.error('Failed to resolve DID for verification');
      }
      
      final didDocument = didResult.data!['document'] as Map<String, dynamic>;
      final publicKey = didDocument['verificationMethod'][0]['publicKeyBase58'] as String;
      
      // Verify signature
      final dataJson = jsonEncode(data);
      final isValid = await _verifySignature(dataJson, signature, publicKey);
      
      return DIDResult.success(isValid);
      
    } catch (e, stackTrace) {
      _logError('❌ Error verifying DID signature: $e', stackTrace);
      return DIDResult.error('Failed to verify DID signature: $e');
    }
  }
  
  /// Get DID analytics for user
  Future<DIDResult<DIDAnalytics>> getDIDAnalytics() async {
    try {
      await _ensureInitialized();
      
      if (_userDID == null) {
        return DIDResult.error('User DID not found');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final createdAt = prefs.getString('did_created_at') ?? DateTime.now().toIso8601String();
      final lastUsed = prefs.getString('did_last_used') ?? DateTime.now().toIso8601String();
      final usageCount = prefs.getInt('did_usage_count') ?? 0;
      
      final analytics = DIDAnalytics(
        didIdentifier: _userDID!,
        createdAt: DateTime.parse(createdAt),
        lastUsed: DateTime.parse(lastUsed),
        usageCount: usageCount,
        isActive: true,
      );
      
      return DIDResult.success(analytics);
      
    } catch (e, stackTrace) {
      _logError('❌ Error getting DID analytics: $e', stackTrace);
      return DIDResult.error('Failed to get DID analytics: $e');
    }
  }
  
  // Private helper methods
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
  
  Future<void> _loadStoredDID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _userDID = prefs.getString(_didStorageKey);
      
      final didDocumentJson = prefs.getString(_didDocumentKey);
      if (didDocumentJson != null) {
        _didDocument = jsonDecode(didDocumentJson);
      }
      
      final keyPairJson = prefs.getString(_didKeysKey);
      if (keyPairJson != null) {
        _keyPair = jsonDecode(keyPairJson);
      }
      
      if (_userDID != null) {
        _logDebug('📱 Loaded stored DID: $_userDID');
      }
    } catch (e) {
      _logError('❌ Error loading stored DID: $e');
    }
  }
  
  Future<Map<String, String>> _generateKeyPair() async {
    // Mock key pair generation - replace with actual cryptographic implementation
    final random = Random.secure();
    final privateKey = List.generate(32, (_) => random.nextInt(256))
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
    
    final publicKey = sha256.convert(utf8.encode(privateKey)).toString();
    
    return {
      'privateKey': privateKey,
      'publicKey': publicKey,
    };
  }
  
  String _generateDIDIdentifier(String walletAddress) {
    final didMethod = EnvironmentConfig.didConfig['didMethod'];
    final network = EnvironmentConfig.currentEnvironment.name;
    return '$didMethod:$network:$walletAddress';
  }
  
  Map<String, dynamic> _createDIDDocument({
    required String identifier,
    required String walletAddress,
    required String publicKey,
    required String userEmail,
    String? userName,
  }) {
    final now = DateTime.now().toIso8601String();
    
    return {
      '@context': [
        'https://www.w3.org/ns/did/v1',
        'https://w3id.org/security/v1',
      ],
      'id': identifier,
      'controller': walletAddress,
      'created': now,
      'updated': now,
      'verificationMethod': [
        {
          'id': '$identifier#key-1',
          'type': EnvironmentConfig.didConfig['verificationMethod'],
          'controller': identifier,
          'publicKeyBase58': publicKey,
        }
      ],
      'authentication': ['$identifier#key-1'],
      'service': [
        {
          'id': '$identifier#cne-wallet',
          'type': 'CNEWalletService',
          'serviceEndpoint': walletAddress,
        }
      ],
      'credentialSubject': {
        'id': identifier,
        'email': userEmail,
        'name': userName,
        'walletAddress': walletAddress,
        'platform': 'CoinNewsExtra TV',
      },
    };
  }
  
  Future<void> _storeDIDLocally(
    String identifier,
    Map<String, dynamic> document,
    Map<String, dynamic> keyPair,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_didStorageKey, identifier);
    await prefs.setString(_didDocumentKey, jsonEncode(document));
    await prefs.setString(_didKeysKey, jsonEncode(keyPair));
    await prefs.setString('did_created_at', DateTime.now().toIso8601String());
    await prefs.setInt('did_usage_count', 0);
  }
  
  Future<void> _updateDIDDocumentLocally(Map<String, dynamic> document) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_didDocumentKey, jsonEncode(document));
  }
  
  Future<DIDResult<bool>> _validateDID(String identifier) async {
    try {
      // Check if DID exists and is not revoked
      final resolveResult = await resolveDID(identifier);
      if (!resolveResult.success) {
        return DIDResult.error('DID not found or invalid');
      }
      
      final document = resolveResult.data!['document'] as Map<String, dynamic>;
      
      // Check if DID is not deactivated
      if (document.containsKey('deactivated') && document['deactivated'] == true) {
        return DIDResult.error('DID has been deactivated');
      }
      
      return DIDResult.success(true);
    } catch (e) {
      return DIDResult.error('DID validation failed: $e');
    }
  }
  
  Future<DIDResult<bool>> _verifyWalletOwnership(String walletAddress) async {
    try {
      if (_didDocument == null) {
        return DIDResult.error('DID document not found');
      }
      
      final documentWallet = _didDocument!['controller'] as String;
      if (documentWallet != walletAddress) {
        return DIDResult.error('Wallet address mismatch');
      }
      
      return DIDResult.success(true);
    } catch (e) {
      return DIDResult.error('Wallet ownership verification failed: $e');
    }
  }
  
  Future<DIDResult<bool>> _checkDuplicateClaim(
    String didIdentifier,
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      // Create unique claim identifier
      final claimId = _generateClaimId(didIdentifier, eventType, eventData);
      
      final prefs = await SharedPreferences.getInstance();
      final existingClaims = prefs.getStringList('did_claims') ?? [];
      
      if (existingClaims.contains(claimId)) {
        return DIDResult.error('Claim already exists');
      }
      
      // Record this claim
      existingClaims.add(claimId);
      await prefs.setStringList('did_claims', existingClaims);
      
      return DIDResult.success(true);
    } catch (e) {
      return DIDResult.error('Duplicate claim check failed: $e');
    }
  }
  
  String _generateClaimId(String didIdentifier, String eventType, Map<String, dynamic> eventData) {
    final data = '$didIdentifier:$eventType:${jsonEncode(eventData)}';
    return sha256.convert(utf8.encode(data)).toString();
  }
  
  Future<DIDResult<String>> _createVerificationProof(
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final proofData = {
        'did': _userDID,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final signature = await signWithDID(proofData);
      if (!signature.success) {
        return DIDResult.error('Failed to sign proof: ${signature.error}');
      }
      
      return DIDResult.success(signature.data!);
    } catch (e) {
      return DIDResult.error('Proof creation failed: $e');
    }
  }
  
  Future<String> _signData(String data, String privateKey) async {
    // Mock signing - replace with actual cryptographic signing
    final combined = '$data:$privateKey';
    final hash = sha256.convert(utf8.encode(combined)).toString();
    return 'sig_$hash';
  }
  
  Future<bool> _verifySignature(String data, String signature, String publicKey) async {
    // Mock verification - replace with actual cryptographic verification
    final expectedHash = sha256.convert(utf8.encode('$data:mock_private_key')).toString();
    return signature == 'sig_$expectedHash';
  }
  
  void _logDebug(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🆔 DID: $message');
    }
  }
  
  void _logError(String message, [StackTrace? stackTrace]) {
    print('❌ DID Error: $message');
    if (stackTrace != null && EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('Stack trace: $stackTrace');
    }
  }
}

/// DID operation result wrapper
class DIDResult<T> {
  final bool success;
  final T? data;
  final String? error;
  
  DIDResult.success(this.data) : success = true, error = null;
  DIDResult.error(this.error) : success = false, data = null;
}

/// DID analytics data
class DIDAnalytics {
  final String didIdentifier;
  final DateTime createdAt;
  final DateTime lastUsed;
  final int usageCount;
  final bool isActive;
  
  DIDAnalytics({
    required this.didIdentifier,
    required this.createdAt,
    required this.lastUsed,
    required this.usageCount,
    required this.isActive,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'didIdentifier': didIdentifier,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'usageCount': usageCount,
      'isActive': isActive,
    };
  }
}
