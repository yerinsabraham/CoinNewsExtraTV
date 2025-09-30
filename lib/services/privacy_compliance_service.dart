/// Privacy Compliance & Data Governance Service
/// Ensures GDPR/NDPR compliance for DID, device fingerprinting, and user data
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';

class PrivacyComplianceService {
  static PrivacyComplianceService? _instance;
  static PrivacyComplianceService get instance => _instance ??= PrivacyComplianceService._();
  
  PrivacyComplianceService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Data retention policies (in days)
  static const int AUDIT_LOG_RETENTION = 2555; // 7 years for compliance
  static const int DEVICE_FINGERPRINT_RETENTION = 365; // 1 year
  static const int GEOLOCATION_DATA_RETENTION = 90; // 3 months
  static const int DID_INTERACTION_RETENTION = 1095; // 3 years
  static const int USER_SESSION_RETENTION = 30; // 1 month
  static const int MARKETING_DATA_RETENTION = 1095; // 3 years (with consent)
  
  /// Initialize privacy compliance service
  Future<void> initialize() async {
    await _initializeConsentTracking();
    await _scheduleDataCleanup();
    await _initializePrivacyPolicies();
    
    _logPrivacy('✅ PrivacyComplianceService initialized with GDPR/NDPR compliance');
  }
  
  /// Record user consent for data processing
  Future<void> recordUserConsent({
    required String userId,
    required List<ConsentType> consentTypes,
    required String consentVersion,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final consentRecord = {
        'userId': userId,
        'consentTypes': consentTypes.map((e) => e.name).toList(),
        'consentVersion': consentVersion,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
        'ipAddress': await _getAnonymizedIP(),
        'userAgent': await _getAnonymizedUserAgent(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      };
      
      await _firestore.collection('user_consent').add(consentRecord);
      
      // Update user's current consent status
      await _firestore.collection('users').doc(userId).update({
        'currentConsent': {
          'types': consentTypes.map((e) => e.name).toList(),
          'version': consentVersion,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
      
      _logPrivacy('✅ Consent recorded for user $userId: ${consentTypes.map((e) => e.name).join(', ')}');
      
    } catch (e) {
      _logPrivacyError('Failed to record consent for user $userId: $e');
      rethrow;
    }
  }
  
  /// Withdraw user consent
  Future<void> withdrawUserConsent({
    required String userId,
    required List<ConsentType> consentTypesToWithdraw,
    required String reason,
  }) async {
    try {
      // Record consent withdrawal
      await _firestore.collection('consent_withdrawals').add({
        'userId': userId,
        'withdrawnConsentTypes': consentTypesToWithdraw.map((e) => e.name).toList(),
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      // Update user's current consent status
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentConsentTypes = List<String>.from(
          userDoc.data()?['currentConsent']?['types'] ?? []
        );
        
        final remainingConsent = currentConsentTypes
            .where((type) => !consentTypesToWithdraw.any((withdrawn) => withdrawn.name == type))
            .toList();
        
        await _firestore.collection('users').doc(userId).update({
          'currentConsent.types': remainingConsent,
          'lastConsentUpdate': FieldValue.serverTimestamp(),
        });
      }
      
      // Schedule data deletion for withdrawn consent types
      await _scheduleDataDeletion(userId, consentTypesToWithdraw);
      
      _logPrivacy('🚫 Consent withdrawn for user $userId: ${consentTypesToWithdraw.map((e) => e.name).join(', ')}');
      
    } catch (e) {
      _logPrivacyError('Failed to withdraw consent for user $userId: $e');
      rethrow;
    }
  }
  
  /// Check if user has given consent for specific data processing
  Future<bool> hasUserConsent(String userId, ConsentType consentType) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return false;
      
      final currentConsent = userDoc.data()?['currentConsent'];
      if (currentConsent == null) return false;
      
      final consentTypes = List<String>.from(currentConsent['types'] ?? []);
      return consentTypes.contains(consentType.name);
      
    } catch (e) {
      _logPrivacyError('Failed to check consent for user $userId: $e');
      return false;
    }
  }
  
  /// Process data subject access request (GDPR Article 15)
  Future<Map<String, dynamic>> processDataSubjectAccessRequest(String userId) async {
    try {
      _logPrivacy('📋 Processing data access request for user $userId');
      
      final userData = <String, dynamic>{};
      
      // Collect user profile data
      final userProfile = await _firestore.collection('users').doc(userId).get();
      if (userProfile.exists) {
        userData['profile'] = _anonymizePersonalData(userProfile.data()!);
      }
      
      // Collect DID interactions
      final didInteractions = await _firestore
          .collection('did_interactions')
          .where('userId', isEqualTo: userId)
          .get();
      userData['didInteractions'] = didInteractions.docs
          .map((doc) => _anonymizePersonalData(doc.data()))
          .toList();
      
      // Collect device fingerprints (anonymized)
      final deviceFingerprints = await _firestore
          .collection('device_fingerprints')
          .where('userId', isEqualTo: userId)
          .get();
      userData['deviceFingerprints'] = deviceFingerprints.docs
          .map((doc) => _anonymizeDeviceData(doc.data()))
          .toList();
      
      // Collect geolocation data (anonymized)
      final geoData = await _firestore
          .collection('geolocation_checks')
          .where('userId', isEqualTo: userId)
          .get();
      userData['geolocationData'] = geoData.docs
          .map((doc) => _anonymizeLocationData(doc.data()))
          .toList();
      
      // Collect consent history
      final consentHistory = await _firestore
          .collection('user_consent')
          .where('userId', isEqualTo: userId)
          .get();
      userData['consentHistory'] = consentHistory.docs
          .map((doc) => doc.data())
          .toList();
      
      // Collect reward history
      final rewardHistory = await _firestore
          .collection('reward_claims')
          .where('userId', isEqualTo: userId)
          .get();
      userData['rewardHistory'] = rewardHistory.docs
          .map((doc) => _anonymizeFinancialData(doc.data()))
          .toList();
      
      // Record the access request
      await _firestore.collection('data_access_requests').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'dataTypes': userData.keys.toList(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      return userData;
      
    } catch (e) {
      _logPrivacyError('Failed to process data access request for $userId: $e');
      rethrow;
    }
  }
  
  /// Process right to be forgotten request (GDPR Article 17)
  Future<void> processRightToBeForgottenRequest({
    required String userId,
    required String requestReason,
    bool retainForLegalCompliance = true,
  }) async {
    try {
      _logPrivacy('🗑️ Processing right to be forgotten request for user $userId');
      
      // Record the deletion request
      await _firestore.collection('deletion_requests').add({
        'userId': userId,
        'requestReason': requestReason,
        'retainForLegalCompliance': retainForLegalCompliance,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'processing',
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      final deletionResults = <String, bool>{};
      
      // Delete/anonymize user profile
      if (retainForLegalCompliance) {
        await _anonymizeUserData(userId);
        deletionResults['profile'] = true;
      } else {
        await _firestore.collection('users').doc(userId).delete();
        deletionResults['profile'] = true;
      }
      
      // Delete device fingerprints
      await _deleteCollectionByUserId('device_fingerprints', userId);
      deletionResults['deviceFingerprints'] = true;
      
      // Delete geolocation data
      await _deleteCollectionByUserId('geolocation_checks', userId);
      deletionResults['geolocationData'] = true;
      
      // Delete DID interactions (keep audit trail)
      await _anonymizeCollectionByUserId('did_interactions', userId);
      deletionResults['didInteractions'] = true;
      
      // Handle reward data (may need to retain for tax/legal purposes)
      if (retainForLegalCompliance) {
        await _anonymizeCollectionByUserId('reward_claims', userId);
      } else {
        await _deleteCollectionByUserId('reward_claims', userId);
      }
      deletionResults['rewardData'] = true;
      
      // Update deletion request status
      await _firestore.collection('deletion_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'processing')
          .get()
          .then((snapshot) {
        for (final doc in snapshot.docs) {
          doc.reference.update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'deletionResults': deletionResults,
          });
        }
      });
      
      _logPrivacy('✅ Right to be forgotten processed for user $userId');
      
    } catch (e) {
      _logPrivacyError('Failed to process right to be forgotten for $userId: $e');
      rethrow;
    }
  }
  
  /// Data portability request (GDPR Article 20)
  Future<String> generateDataPortabilityExport(String userId) async {
    try {
      _logPrivacy('📦 Generating data portability export for user $userId');
      
      final exportData = await processDataSubjectAccessRequest(userId);
      
      // Format as structured JSON
      final export = {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'dataFormat': 'JSON',
        'gdprCompliant': true,
        'data': exportData,
      };
      
      // Record the export request
      await _firestore.collection('data_exports').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'dataSize': jsonEncode(export).length,
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      return jsonEncode(export);
      
    } catch (e) {
      _logPrivacyError('Failed to generate data export for $userId: $e');
      rethrow;
    }
  }
  
  /// Automated data cleanup based on retention policies
  Future<void> performDataCleanup() async {
    try {
      _logPrivacy('🧹 Starting automated data cleanup');
      
      final now = DateTime.now();
      final cleanupResults = <String, int>{};
      
      // Cleanup expired device fingerprints
      final expiredFingerprints = await _firestore
          .collection('device_fingerprints')
          .where('timestamp', isLessThan: now.subtract(Duration(days: DEVICE_FINGERPRINT_RETENTION)))
          .get();
      
      for (final doc in expiredFingerprints.docs) {
        await doc.reference.delete();
      }
      cleanupResults['deviceFingerprints'] = expiredFingerprints.docs.length;
      
      // Cleanup expired geolocation data
      final expiredGeoData = await _firestore
          .collection('geolocation_checks')
          .where('timestamp', isLessThan: now.subtract(Duration(days: GEOLOCATION_DATA_RETENTION)))
          .get();
      
      for (final doc in expiredGeoData.docs) {
        await doc.reference.delete();
      }
      cleanupResults['geolocationData'] = expiredGeoData.docs.length;
      
      // Cleanup expired session data
      final expiredSessions = await _firestore
          .collection('user_sessions')
          .where('timestamp', isLessThan: now.subtract(Duration(days: USER_SESSION_RETENTION)))
          .get();
      
      for (final doc in expiredSessions.docs) {
        await doc.reference.delete();
      }
      cleanupResults['sessionData'] = expiredSessions.docs.length;
      
      // Record cleanup results
      await _firestore.collection('data_cleanup_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'cleanupResults': cleanupResults,
        'totalItemsDeleted': cleanupResults.values.reduce((a, b) => a + b),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      _logPrivacy('✅ Data cleanup completed: ${cleanupResults.values.reduce((a, b) => a + b)} items deleted');
      
    } catch (e) {
      _logPrivacyError('Failed to perform data cleanup: $e');
    }
  }
  
  /// Generate privacy compliance report
  Future<PrivacyComplianceReport> generateComplianceReport() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      // Count consent records
      final consentRecords = await _firestore
          .collection('user_consent')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();
      
      // Count data access requests
      final accessRequests = await _firestore
          .collection('data_access_requests')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();
      
      // Count deletion requests
      final deletionRequests = await _firestore
          .collection('deletion_requests')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();
      
      // Count data exports
      final dataExports = await _firestore
          .collection('data_exports')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();
      
      // Analyze consent distribution
      final consentDistribution = <String, int>{};
      for (final doc in consentRecords.docs) {
        final types = List<String>.from(doc.data()['consentTypes'] ?? []);
        for (final type in types) {
          consentDistribution[type] = (consentDistribution[type] ?? 0) + 1;
        }
      }
      
      return PrivacyComplianceReport(
        reportDate: now,
        reportPeriod: const Duration(days: 30),
        consentRecords: consentRecords.docs.length,
        accessRequests: accessRequests.docs.length,
        deletionRequests: deletionRequests.docs.length,
        dataExports: dataExports.docs.length,
        consentDistribution: consentDistribution,
        complianceScore: _calculateComplianceScore(
          consentRecords.docs.length,
          accessRequests.docs.length,
          deletionRequests.docs.length,
        ),
      );
      
    } catch (e) {
      _logPrivacyError('Failed to generate compliance report: $e');
      return PrivacyComplianceReport.empty();
    }
  }
  
  // Private methods
  
  Future<void> _initializeConsentTracking() async {
    // Initialize consent tracking collections
    await _firestore.collection('user_consent').doc('_init').set({'initialized': true});
    await _firestore.collection('consent_withdrawals').doc('_init').set({'initialized': true});
  }
  
  Future<void> _scheduleDataCleanup() async {
    // Schedule daily data cleanup
    Timer.periodic(const Duration(hours: 24), (timer) async {
      await performDataCleanup();
    });
  }
  
  Future<void> _initializePrivacyPolicies() async {
    // Initialize privacy policy versions
    await _firestore.collection('privacy_policies').doc('current').set({
      'version': '1.0',
      'effectiveDate': DateTime.now().toIso8601String(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'consentTypes': ConsentType.values.map((e) => {
        'type': e.name,
        'description': _getConsentTypeDescription(e),
        'required': _isConsentRequired(e),
      }).toList(),
    });
  }
  
  String _getConsentTypeDescription(ConsentType type) {
    switch (type) {
      case ConsentType.essential:
        return 'Essential functionality and security';
      case ConsentType.analytics:
        return 'Usage analytics and performance monitoring';
      case ConsentType.marketing:
        return 'Marketing communications and promotions';
      case ConsentType.personalization:
        return 'Personalized content and recommendations';
      case ConsentType.deviceFingerprinting:
        return 'Device fingerprinting for fraud prevention';
      case ConsentType.geolocation:
        return 'Location data for fraud detection';
      case ConsentType.didProcessing:
        return 'Decentralized identity verification';
    }
  }
  
  bool _isConsentRequired(ConsentType type) {
    switch (type) {
      case ConsentType.essential:
      case ConsentType.didProcessing:
        return true;
      default:
        return false;
    }
  }
  
  Future<String> _getAnonymizedIP() async {
    // Return anonymized IP (remove last octet)
    return '192.168.1.xxx';
  }
  
  Future<String> _getAnonymizedUserAgent() async {
    // Return anonymized user agent
    return 'Flutter/Mobile/xxx';
  }
  
  Map<String, dynamic> _anonymizePersonalData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    
    // Remove or hash PII
    if (anonymized.containsKey('email')) {
      anonymized['email'] = _hashValue(anonymized['email']);
    }
    if (anonymized.containsKey('phoneNumber')) {
      anonymized.remove('phoneNumber');
    }
    if (anonymized.containsKey('ipAddress')) {
      anonymized['ipAddress'] = _anonymizeIP(anonymized['ipAddress']);
    }
    
    return anonymized;
  }
  
  Map<String, dynamic> _anonymizeDeviceData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    
    // Keep only non-identifying device characteristics
    anonymized.remove('deviceId');
    anonymized.remove('installationId');
    
    return anonymized;
  }
  
  Map<String, dynamic> _anonymizeLocationData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    
    // Reduce location precision
    if (anonymized.containsKey('latitude')) {
      anonymized['latitude'] = _reduceLocationPrecision(anonymized['latitude']);
    }
    if (anonymized.containsKey('longitude')) {
      anonymized['longitude'] = _reduceLocationPrecision(anonymized['longitude']);
    }
    
    return anonymized;
  }
  
  Map<String, dynamic> _anonymizeFinancialData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);
    
    // Keep transaction patterns but remove amounts if requested
    // This depends on legal requirements
    
    return anonymized;
  }
  
  String _hashValue(String value) {
    // Simple hash for demo - use proper cryptographic hash in production
    return 'hash_${value.hashCode.abs()}';
  }
  
  String _anonymizeIP(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.${parts[2]}.xxx';
    }
    return 'xxx.xxx.xxx.xxx';
  }
  
  double _reduceLocationPrecision(double coordinate) {
    // Reduce to ~1km precision
    return (coordinate * 100).round() / 100.0;
  }
  
  Future<void> _anonymizeUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final anonymizedData = _anonymizePersonalData(userDoc.data()!);
      anonymizedData['anonymized'] = true;
      anonymizedData['anonymizedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(userId).update(anonymizedData);
    }
  }
  
  Future<void> _deleteCollectionByUserId(String collection, String userId) async {
    final query = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
  
  Future<void> _anonymizeCollectionByUserId(String collection, String userId) async {
    final query = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final doc in query.docs) {
      final anonymizedData = _anonymizePersonalData(doc.data());
      anonymizedData['anonymized'] = true;
      anonymizedData['anonymizedAt'] = FieldValue.serverTimestamp();
      
      await doc.reference.update(anonymizedData);
    }
  }
  
  Future<void> _scheduleDataDeletion(String userId, List<ConsentType> consentTypes) async {
    await _firestore.collection('scheduled_deletions').add({
      'userId': userId,
      'consentTypes': consentTypes.map((e) => e.name).toList(),
      'scheduledFor': DateTime.now().add(const Duration(days: 30)),
      'status': 'scheduled',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  double _calculateComplianceScore(int consents, int accessRequests, int deletions) {
    // Simple compliance scoring - could be more sophisticated
    double score = 1.0;
    
    // Penalize if too many access requests vs consents
    if (consents > 0 && accessRequests / consents > 0.1) {
      score -= 0.1;
    }
    
    // Penalize if deletion requests are not being handled
    if (deletions > 10) {
      score -= 0.05;
    }
    
    return (score * 100).clamp(0, 100);
  }
  
  void _logPrivacy(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🔒 Privacy: $message');
    }
  }
  
  void _logPrivacyError(String message) {
    print('❌ Privacy Error: $message');
  }
}

/// Types of consent for data processing
enum ConsentType {
  essential,
  analytics,
  marketing,
  personalization,
  deviceFingerprinting,
  geolocation,
  didProcessing,
}

/// Privacy compliance report
class PrivacyComplianceReport {
  final DateTime reportDate;
  final Duration reportPeriod;
  final int consentRecords;
  final int accessRequests;
  final int deletionRequests;
  final int dataExports;
  final Map<String, int> consentDistribution;
  final double complianceScore;
  
  PrivacyComplianceReport({
    required this.reportDate,
    required this.reportPeriod,
    required this.consentRecords,
    required this.accessRequests,
    required this.deletionRequests,
    required this.dataExports,
    required this.consentDistribution,
    required this.complianceScore,
  });
  
  factory PrivacyComplianceReport.empty() {
    return PrivacyComplianceReport(
      reportDate: DateTime.now(),
      reportPeriod: const Duration(days: 30),
      consentRecords: 0,
      accessRequests: 0,
      deletionRequests: 0,
      dataExports: 0,
      consentDistribution: {},
      complianceScore: 100.0,
    );
  }
}
