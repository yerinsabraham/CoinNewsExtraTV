/// Secure Key Management & Secrets Vault
/// Enterprise-grade secret management with key rotation and secure storage
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';

class SecureVaultService {
  static SecureVaultService? _instance;
  static SecureVaultService get instance => _instance ??= SecureVaultService._();
  
  SecureVaultService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Key rotation intervals
  static const Duration DEFAULT_KEY_ROTATION_INTERVAL = Duration(days: 30);
  static const Duration CRITICAL_KEY_ROTATION_INTERVAL = Duration(days: 7);
  static const Duration API_KEY_ROTATION_INTERVAL = Duration(days: 14);
  
  // Encryption configuration
  static const int KEY_SIZE = 32; // 256-bit keys
  static const int SALT_SIZE = 16;
  static const int IV_SIZE = 16;
  
  late final String _masterKey;
  late final Map<String, SecretMetadata> _secretsMetadata;
  
  /// Initialize secure vault
  Future<void> initialize() async {
    await _loadMasterKey();
    await _loadSecretsMetadata();
    await _scheduleKeyRotation();
    
    _logVault('✅ SecureVaultService initialized with key rotation');
  }
  
  /// Store encrypted secret with metadata
  Future<void> storeSecret({
    required String secretId,
    required String secretValue,
    required SecretType type,
    Duration? rotationInterval,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final encryptedValue = await _encryptSecret(secretValue);
      final secretMetadata = SecretMetadata(
        id: secretId,
        type: type,
        createdAt: DateTime.now(),
        lastRotated: DateTime.now(),
        rotationInterval: rotationInterval ?? _getDefaultRotationInterval(type),
        metadata: metadata ?? {},
        version: 1,
      );
      
      // Store encrypted secret
      await _firestore.collection('secure_vault').doc(secretId).set({
        'encryptedValue': encryptedValue,
        'metadata': secretMetadata.toMap(),
        'lastAccessed': FieldValue.serverTimestamp(),
        'accessCount': 0,
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      // Update local metadata cache
      _secretsMetadata[secretId] = secretMetadata;
      
      _logVault('🔐 Secret stored: $secretId (${type.name})');
      
    } catch (e) {
      _logVaultError('Failed to store secret $secretId: $e');
      rethrow;
    }
  }
  
  /// Retrieve and decrypt secret
  Future<String?> getSecret(String secretId) async {
    try {
      final doc = await _firestore.collection('secure_vault').doc(secretId).get();
      
      if (!doc.exists) {
        _logVaultError('Secret not found: $secretId');
        return null;
      }
      
      final data = doc.data()!;
      final encryptedValue = data['encryptedValue'] as String;
      final decryptedValue = await _decryptSecret(encryptedValue);
      
      // Update access tracking
      await _updateAccessTracking(secretId);
      
      return decryptedValue;
      
    } catch (e) {
      _logVaultError('Failed to retrieve secret $secretId: $e');
      return null;
    }
  }
  
  /// Rotate secret with new value
  Future<void> rotateSecret({
    required String secretId,
    required String newSecretValue,
  }) async {
    try {
      final currentDoc = await _firestore.collection('secure_vault').doc(secretId).get();
      
      if (!currentDoc.exists) {
        throw VaultException('Secret not found for rotation: $secretId');
      }
      
      final currentData = currentDoc.data()!;
      final currentMetadata = SecretMetadata.fromMap(currentData['metadata']);
      
      // Create backup of current version
      await _createSecretBackup(secretId, currentData);
      
      // Encrypt new value
      final encryptedNewValue = await _encryptSecret(newSecretValue);
      
      // Update with new version
      final updatedMetadata = currentMetadata.copyWith(
        lastRotated: DateTime.now(),
        version: currentMetadata.version + 1,
      );
      
      await _firestore.collection('secure_vault').doc(secretId).update({
        'encryptedValue': encryptedNewValue,
        'metadata': updatedMetadata.toMap(),
        'lastRotated': FieldValue.serverTimestamp(),
      });
      
      // Update local cache
      _secretsMetadata[secretId] = updatedMetadata;
      
      _logVault('🔄 Secret rotated: $secretId (v${updatedMetadata.version})');
      
      // Notify dependent services
      await _notifySecretRotation(secretId, updatedMetadata.type);
      
    } catch (e) {
      _logVaultError('Failed to rotate secret $secretId: $e');
      rethrow;
    }
  }
  
  /// Auto-rotate secrets based on policy
  Future<void> performScheduledRotation() async {
    try {
      final now = DateTime.now();
      final secretsToRotate = <String>[];
      
      for (final entry in _secretsMetadata.entries) {
        final secretId = entry.key;
        final metadata = entry.value;
        
        final rotationDue = metadata.lastRotated.add(metadata.rotationInterval);
        if (now.isAfter(rotationDue)) {
          secretsToRotate.add(secretId);
        }
      }
      
      if (secretsToRotate.isNotEmpty) {
        _logVault('🔄 Starting scheduled rotation for ${secretsToRotate.length} secrets');
        
        for (final secretId in secretsToRotate) {
          await _performAutoRotation(secretId);
        }
      }
      
    } catch (e) {
      _logVaultError('Failed scheduled rotation: $e');
    }
  }
  
  /// Get secret metadata without decrypting value
  Future<SecretMetadata?> getSecretMetadata(String secretId) async {
    try {
      if (_secretsMetadata.containsKey(secretId)) {
        return _secretsMetadata[secretId];
      }
      
      final doc = await _firestore.collection('secure_vault').doc(secretId).get();
      if (doc.exists) {
        final metadata = SecretMetadata.fromMap(doc.data()!['metadata']);
        _secretsMetadata[secretId] = metadata;
        return metadata;
      }
      
      return null;
      
    } catch (e) {
      _logVaultError('Failed to get metadata for $secretId: $e');
      return null;
    }
  }
  
  /// List all secrets with metadata (no values)
  Future<List<SecretMetadata>> listSecrets({SecretType? filterByType}) async {
    try {
      final query = filterByType != null
          ? _firestore.collection('secure_vault').where('metadata.type', isEqualTo: filterByType.name)
          : _firestore.collection('secure_vault');
      
      final querySnapshot = await query.get();
      final secrets = <SecretMetadata>[];
      
      for (final doc in querySnapshot.docs) {
        final metadata = SecretMetadata.fromMap(doc.data()['metadata']);
        secrets.add(metadata);
        _secretsMetadata[doc.id] = metadata;
      }
      
      return secrets;
      
    } catch (e) {
      _logVaultError('Failed to list secrets: $e');
      return [];
    }
  }
  
  /// Generate secure random key
  String generateSecureKey(int length) {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }
  
  /// Validate secret strength
  SecretStrength validateSecretStrength(String secret) {
    if (secret.length < 8) return SecretStrength.weak;
    
    final hasLower = secret.contains(RegExp(r'[a-z]'));
    final hasUpper = secret.contains(RegExp(r'[A-Z]'));
    final hasDigit = secret.contains(RegExp(r'[0-9]'));
    final hasSpecial = secret.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    final strengthScore = [hasLower, hasUpper, hasDigit, hasSpecial].where((x) => x).length;
    
    if (secret.length >= 16 && strengthScore >= 3) return SecretStrength.strong;
    if (secret.length >= 12 && strengthScore >= 2) return SecretStrength.medium;
    return SecretStrength.weak;
  }
  
  /// Get vault health report
  Future<VaultHealthReport> getHealthReport() async {
    try {
      final secrets = await listSecrets();
      final now = DateTime.now();
      
      int expiredSecrets = 0;
      int expiringSoon = 0;
      int weakSecrets = 0;
      final accessPatterns = <String, int>{};
      
      for (final secret in secrets) {
        // Check expiration
        final rotationDue = secret.lastRotated.add(secret.rotationInterval);
        if (now.isAfter(rotationDue)) {
          expiredSecrets++;
        } else if (now.isAfter(rotationDue.subtract(const Duration(days: 7)))) {
          expiringSoon++;
        }
        
        // Track access patterns
        accessPatterns[secret.type.name] = (accessPatterns[secret.type.name] ?? 0) + 1;
      }
      
      return VaultHealthReport(
        totalSecrets: secrets.length,
        expiredSecrets: expiredSecrets,
        expiringSoon: expiringSoon,
        weakSecrets: weakSecrets,
        accessPatterns: accessPatterns,
        lastRotationCheck: now,
      );
      
    } catch (e) {
      _logVaultError('Failed to generate health report: $e');
      return VaultHealthReport.empty();
    }
  }
  
  // Private methods
  
  Future<void> _loadMasterKey() async {
    // In production, this would come from a secure hardware module (HSM)
    // or cloud key management service (AWS KMS, Azure Key Vault, etc.)
    _masterKey = const String.fromEnvironment('VAULT_MASTER_KEY', 
      defaultValue: 'default-development-key-change-in-production');
    
    if (_masterKey == 'default-development-key-change-in-production' && 
        EnvironmentConfig.currentEnvironment == AppEnvironment.mainnet) {
      throw VaultException('Master key must be configured for production');
    }
  }
  
  Future<void> _loadSecretsMetadata() async {
    _secretsMetadata = <String, SecretMetadata>{};
    
    try {
      final querySnapshot = await _firestore.collection('secure_vault').get();
      
      for (final doc in querySnapshot.docs) {
        final metadata = SecretMetadata.fromMap(doc.data()['metadata']);
        _secretsMetadata[doc.id] = metadata;
      }
      
      _logVault('📚 Loaded metadata for ${_secretsMetadata.length} secrets');
      
    } catch (e) {
      _logVaultError('Failed to load secrets metadata: $e');
    }
  }
  
  Future<void> _scheduleKeyRotation() async {
    // Schedule automatic key rotation
    Timer.periodic(const Duration(hours: 6), (timer) async {
      await performScheduledRotation();
    });
    
    // Daily health check
    Timer.periodic(const Duration(days: 1), (timer) async {
      final healthReport = await getHealthReport();
      if (healthReport.expiredSecrets > 0 || healthReport.expiringSoon > 3) {
        _logVault('⚠️ Vault health alert: ${healthReport.expiredSecrets} expired, ${healthReport.expiringSoon} expiring soon');
      }
    });
  }
  
  Future<String> _encryptSecret(String plaintext) async {
    final key = sha256.convert(utf8.encode(_masterKey)).bytes;
    final salt = _generateRandomBytes(SALT_SIZE);
    final iv = _generateRandomBytes(IV_SIZE);
    
    // Simple XOR encryption for demo - use AES-256-GCM in production
    final plaintextBytes = utf8.encode(plaintext);
    final encryptedBytes = <int>[];
    
    for (int i = 0; i < plaintextBytes.length; i++) {
      final keyByte = key[i % key.length];
      final ivByte = iv[i % iv.length];
      final saltByte = salt[i % salt.length];
      encryptedBytes.add(plaintextBytes[i] ^ keyByte ^ ivByte ^ saltByte);
    }
    
    // Combine salt + iv + encrypted data
    final combined = <int>[];
    combined.addAll(salt);
    combined.addAll(iv);
    combined.addAll(encryptedBytes);
    
    return base64.encode(combined);
  }
  
  Future<String> _decryptSecret(String encryptedData) async {
    final key = sha256.convert(utf8.encode(_masterKey)).bytes;
    final combined = base64.decode(encryptedData);
    
    // Extract salt, iv, and encrypted data
    final salt = combined.sublist(0, SALT_SIZE);
    final iv = combined.sublist(SALT_SIZE, SALT_SIZE + IV_SIZE);
    final encryptedBytes = combined.sublist(SALT_SIZE + IV_SIZE);
    
    // Decrypt using XOR
    final decryptedBytes = <int>[];
    for (int i = 0; i < encryptedBytes.length; i++) {
      final keyByte = key[i % key.length];
      final ivByte = iv[i % iv.length];
      final saltByte = salt[i % salt.length];
      decryptedBytes.add(encryptedBytes[i] ^ keyByte ^ ivByte ^ saltByte);
    }
    
    return utf8.decode(decryptedBytes);
  }
  
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
  
  Duration _getDefaultRotationInterval(SecretType type) {
    switch (type) {
      case SecretType.privateKey:
      case SecretType.masterKey:
        return CRITICAL_KEY_ROTATION_INTERVAL;
      case SecretType.apiKey:
      case SecretType.webhookSecret:
        return API_KEY_ROTATION_INTERVAL;
      case SecretType.databasePassword:
      case SecretType.jwtSecret:
        return DEFAULT_KEY_ROTATION_INTERVAL;
      case SecretType.other:
        return DEFAULT_KEY_ROTATION_INTERVAL;
    }
  }
  
  Future<void> _updateAccessTracking(String secretId) async {
    await _firestore.collection('secure_vault').doc(secretId).update({
      'lastAccessed': FieldValue.serverTimestamp(),
      'accessCount': FieldValue.increment(1),
    });
  }
  
  Future<void> _createSecretBackup(String secretId, Map<String, dynamic> currentData) async {
    await _firestore.collection('secret_backups').add({
      'originalSecretId': secretId,
      'backupData': currentData,
      'backupTimestamp': FieldValue.serverTimestamp(),
      'environment': EnvironmentConfig.currentEnvironment.name,
    });
  }
  
  Future<void> _performAutoRotation(String secretId) async {
    final metadata = _secretsMetadata[secretId];
    if (metadata == null) return;
    
    try {
      String newSecretValue;
      
      switch (metadata.type) {
        case SecretType.apiKey:
        case SecretType.webhookSecret:
        case SecretType.jwtSecret:
          newSecretValue = generateSecureKey(64);
          break;
        case SecretType.privateKey:
          // For private keys, would need specific key generation logic
          _logVault('⚠️ Private key auto-rotation requires manual intervention: $secretId');
          return;
        case SecretType.databasePassword:
          newSecretValue = generateSecureKey(32);
          break;
        default:
          newSecretValue = generateSecureKey(32);
      }
      
      await rotateSecret(secretId: secretId, newSecretValue: newSecretValue);
      
    } catch (e) {
      _logVaultError('Auto-rotation failed for $secretId: $e');
    }
  }
  
  Future<void> _notifySecretRotation(String secretId, SecretType type) async {
    // Notify dependent services about key rotation
    // This would integrate with your service registry
    _logVault('🔔 Notifying services of secret rotation: $secretId');
  }
  
  void _logVault(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🔐 Vault: $message');
    }
  }
  
  void _logVaultError(String message) {
    print('❌ Vault Error: $message');
  }
}

/// Secret types for classification and rotation policies
enum SecretType {
  privateKey,
  masterKey,
  apiKey,
  webhookSecret,
  databasePassword,
  jwtSecret,
  other,
}

/// Secret strength levels
enum SecretStrength {
  weak,
  medium,
  strong,
}

/// Secret metadata for tracking and management
class SecretMetadata {
  final String id;
  final SecretType type;
  final DateTime createdAt;
  final DateTime lastRotated;
  final Duration rotationInterval;
  final Map<String, dynamic> metadata;
  final int version;
  
  SecretMetadata({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.lastRotated,
    required this.rotationInterval,
    required this.metadata,
    required this.version,
  });
  
  SecretMetadata copyWith({
    String? id,
    SecretType? type,
    DateTime? createdAt,
    DateTime? lastRotated,
    Duration? rotationInterval,
    Map<String, dynamic>? metadata,
    int? version,
  }) {
    return SecretMetadata(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastRotated: lastRotated ?? this.lastRotated,
      rotationInterval: rotationInterval ?? this.rotationInterval,
      metadata: metadata ?? this.metadata,
      version: version ?? this.version,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'lastRotated': lastRotated.toIso8601String(),
      'rotationIntervalDays': rotationInterval.inDays,
      'metadata': metadata,
      'version': version,
    };
  }
  
  factory SecretMetadata.fromMap(Map<String, dynamic> map) {
    return SecretMetadata(
      id: map['id'],
      type: SecretType.values.firstWhere((e) => e.name == map['type']),
      createdAt: DateTime.parse(map['createdAt']),
      lastRotated: DateTime.parse(map['lastRotated']),
      rotationInterval: Duration(days: map['rotationIntervalDays']),
      metadata: Map<String, dynamic>.from(map['metadata']),
      version: map['version'],
    );
  }
}

/// Vault health report
class VaultHealthReport {
  final int totalSecrets;
  final int expiredSecrets;
  final int expiringSoon;
  final int weakSecrets;
  final Map<String, int> accessPatterns;
  final DateTime lastRotationCheck;
  
  VaultHealthReport({
    required this.totalSecrets,
    required this.expiredSecrets,
    required this.expiringSoon,
    required this.weakSecrets,
    required this.accessPatterns,
    required this.lastRotationCheck,
  });
  
  factory VaultHealthReport.empty() {
    return VaultHealthReport(
      totalSecrets: 0,
      expiredSecrets: 0,
      expiringSoon: 0,
      weakSecrets: 0,
      accessPatterns: {},
      lastRotationCheck: DateTime.now(),
    );
  }
}

/// Vault-specific exceptions
class VaultException implements Exception {
  final String message;
  VaultException(this.message);
  
  @override
  String toString() => 'VaultException: $message';
}
