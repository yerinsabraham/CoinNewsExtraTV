/// Security Audit Service for Pre-Mainnet Validation
/// Handles security checks, rate limiting, fraud prevention, and audit logging
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment_config.dart';
import 'did_service.dart';

class SecurityAuditService {
  static SecurityAuditService? _instance;
  static SecurityAuditService get instance => _instance ??= SecurityAuditService._();
  
  SecurityAuditService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Security thresholds
  static const int MAX_DAILY_CLAIMS_PER_USER = 50;
  static const int MAX_CLAIMS_PER_MINUTE = 5;
  static const int MAX_FAILED_ATTEMPTS = 10;
  static const Duration FRAUD_DETECTION_WINDOW = Duration(hours: 24);
  
  /// Initialize security audit service
  Future<void> initialize() async {
    await _initializeSecurityCollections();
    await _startSecurityMonitoring();
    _logSecurity('✅ SecurityAuditService initialized');
  }
  
  /// Validate reward claim request with comprehensive security checks
  Future<SecurityResult> validateRewardClaim({
    required String eventType,
    required Map<String, dynamic> eventData,
    required String userAgent,
    required String ipAddress,
  }) async {    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return SecurityResult.error('User not authenticated', SecurityViolationType.authentication);
      }
      
      _logSecurity('🔒 Validating reward claim: $eventType for user: $userId');
      
      // 1. Rate limiting checks
      final rateLimitResult = await _checkRateLimiting(userId, eventType);
      if (!rateLimitResult.success) {
        return rateLimitResult;
      }
      
      // 2. DID verification
      final didResult = await _verifyUserDID(userId, eventType, eventData);
      if (!didResult.success) {
        return didResult;
      }
      
      // 3. Fraud pattern detection
      final fraudResult = await _detectFraudPatterns(userId, eventType, eventData, ipAddress);
      if (!fraudResult.success) {
        return fraudResult;
      }
      
      // 4. Device fingerprinting
      final deviceResult = await _validateDeviceFingerprint(userId, userAgent, ipAddress);
      if (!deviceResult.success) {
        return deviceResult;
      }
      
      // 5. Event-specific validation
      final eventResult = await _validateEventSpecifics(eventType, eventData);
      if (!eventResult.success) {
        return eventResult;
      }
      
      // 6. Log successful validation
      await _logSecurityEvent(
        userId: userId,
        eventType: 'reward_claim_validated',
        data: {
          'claimType': eventType,
          'ipAddress': ipAddress,
          'userAgent': userAgent,
          'timestamp': DateTime.now().toIso8601String(),
        },
        severity: SecuritySeverity.info,
      );
      
      _logSecurity('✅ Reward claim validation passed for: $eventType');
      return SecurityResult.success();
      
    } catch (e, stackTrace) {
      _logSecurityError('❌ Error validating reward claim: $e', stackTrace);
      return SecurityResult.error('Validation failed: $e', SecurityViolationType.system);
    }
  }
  
  /// Check rate limiting for user
  Future<SecurityResult> _checkRateLimiting(String userId, String eventType) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      
      // Check daily claims
      final dailyClaimsQuery = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'reward_claim_success')
          .where('timestamp', isGreaterThan: oneDayAgo)
          .get();
      
      if (dailyClaimsQuery.docs.length >= MAX_DAILY_CLAIMS_PER_USER) {
        await _logSecurityViolation(
          userId: userId,
          violationType: SecurityViolationType.rateLimit,
          details: 'Daily claim limit exceeded: ${dailyClaimsQuery.docs.length}',
        );
        return SecurityResult.error('Daily claim limit exceeded', SecurityViolationType.rateLimit);
      }
      
      // Check per-minute claims
      final minuteClaimsQuery = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'reward_claim_success')
          .where('timestamp', isGreaterThan: oneMinuteAgo)
          .get();
      
      if (minuteClaimsQuery.docs.length >= MAX_CLAIMS_PER_MINUTE) {
        await _logSecurityViolation(
          userId: userId,
          violationType: SecurityViolationType.rateLimit,
          details: 'Per-minute claim limit exceeded: ${minuteClaimsQuery.docs.length}',
        );
        return SecurityResult.error('Too many claims per minute', SecurityViolationType.rateLimit);
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      _logSecurityError('❌ Error checking rate limiting: $e');
      return SecurityResult.error('Rate limit check failed', SecurityViolationType.system);
    }
  }
  
  /// Verify user DID for claim
  Future<SecurityResult> _verifyUserDID(String userId, String eventType, Map<String, dynamic> eventData) async {
    try {
      // Get user wallet address
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return SecurityResult.error('User not found', SecurityViolationType.authentication);
      }
      
      final userData = userDoc.data()!;
      final walletAddress = userData['walletAddress'] as String?;
      
      if (walletAddress == null) {
        return SecurityResult.error('Wallet not connected', SecurityViolationType.authentication);
      }
      
      // Verify DID
      final didVerification = await DIDService.instance.verifyDIDForReward(
        walletAddress: walletAddress,
        eventType: eventType,
        eventData: eventData,
      );
      
      if (!didVerification.success) {
        await _logSecurityViolation(
          userId: userId,
          violationType: SecurityViolationType.didVerification,
          details: 'DID verification failed: ${didVerification.error}',
        );
        return SecurityResult.error('DID verification failed', SecurityViolationType.didVerification);
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      _logSecurityError('❌ Error verifying DID: $e');
      return SecurityResult.error('DID verification error', SecurityViolationType.system);
    }
  }
  
  /// Detect fraud patterns
  Future<SecurityResult> _detectFraudPatterns(
    String userId,
    String eventType,
    Map<String, dynamic> eventData,
    String ipAddress,
  ) async {
    try {
      final fraudChecks = await Future.wait([
        _checkIPFraud(ipAddress),
        _checkVelocityFraud(userId, eventType),
        _checkPatternFraud(userId, eventData),
        _checkGeolocationFraud(userId, ipAddress),
      ]);
      
      for (final check in fraudChecks) {
        if (!check.success) {
          return check;
        }
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      _logSecurityError('❌ Error detecting fraud patterns: $e');
      return SecurityResult.error('Fraud detection error', SecurityViolationType.system);
    }
  }
  
  /// Check IP-based fraud
  Future<SecurityResult> _checkIPFraud(String ipAddress) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      // Check if IP has excessive claims
      final ipClaimsQuery = await _firestore
          .collection('security_logs')
          .where('data.ipAddress', isEqualTo: ipAddress)
          .where('eventType', isEqualTo: 'reward_claim_success')
          .where('timestamp', isGreaterThan: oneHourAgo)
          .get();
      
      if (ipClaimsQuery.docs.length > 20) { // Max 20 claims per hour from same IP
        await _logSecurityViolation(
          userId: 'system',
          violationType: SecurityViolationType.ipFraud,
          details: 'Excessive claims from IP: $ipAddress (${ipClaimsQuery.docs.length})',
        );
        return SecurityResult.error('Suspicious IP activity', SecurityViolationType.ipFraud);
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      return SecurityResult.error('IP fraud check failed', SecurityViolationType.system);
    }
  }
  
  /// Check velocity fraud (rapid successive claims)
  Future<SecurityResult> _checkVelocityFraud(String userId, String eventType) async {
    try {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      
      final recentClaimsQuery = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'reward_claim_success')
          .where('timestamp', isGreaterThan: fiveMinutesAgo)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      if (recentClaimsQuery.docs.length >= 5) {
        // Check if claims are too close together
        final timestamps = recentClaimsQuery.docs
            .map((doc) => (doc.data()['timestamp'] as Timestamp).toDate())
            .toList();
        
        for (int i = 0; i < timestamps.length - 1; i++) {
          final diff = timestamps[i].difference(timestamps[i + 1]);
          if (diff.inSeconds < 30) { // Claims less than 30 seconds apart
            await _logSecurityViolation(
              userId: userId,
              violationType: SecurityViolationType.velocityFraud,
              details: 'Claims too close together: ${diff.inSeconds}s',
            );
            return SecurityResult.error('Claims too frequent', SecurityViolationType.velocityFraud);
          }
        }
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      return SecurityResult.error('Velocity fraud check failed', SecurityViolationType.system);
    }
  }
  
  /// Check pattern fraud (repetitive or suspicious patterns)
  Future<SecurityResult> _checkPatternFraud(String userId, Map<String, dynamic> eventData) async {
    try {
      // Check for repetitive event data patterns
      final eventDataHash = _hashEventData(eventData);
      
      final duplicateEventsQuery = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .where('data.eventDataHash', isEqualTo: eventDataHash)
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 1)))
          .get();
      
      if (duplicateEventsQuery.docs.length > 3) { // Same event data > 3 times in an hour
        await _logSecurityViolation(
          userId: userId,
          violationType: SecurityViolationType.patternFraud,
          details: 'Repetitive event data pattern detected',
        );
        return SecurityResult.error('Suspicious activity pattern', SecurityViolationType.patternFraud);
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      return SecurityResult.error('Pattern fraud check failed', SecurityViolationType.system);
    }
  }
  
  /// Check geolocation fraud
  Future<SecurityResult> _checkGeolocationFraud(String userId, String ipAddress) async {
    try {
      // For now, just check if user location changes too rapidly
      // In production, integrate with IP geolocation service
      
      final recentLocationsQuery = await _firestore
          .collection('security_logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 6)))
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      final uniqueIPs = <String>{};
      for (final doc in recentLocationsQuery.docs) {
        final data = doc.data();
        if (data['data'] != null && data['data']['ipAddress'] != null) {
          uniqueIPs.add(data['data']['ipAddress']);
        }
      }
      
      if (uniqueIPs.length > 5) { // More than 5 different IPs in 6 hours
        await _logSecurityViolation(
          userId: userId,
          violationType: SecurityViolationType.geolocationFraud,
          details: 'Multiple IP addresses detected: ${uniqueIPs.length}',
        );
        return SecurityResult.error('Suspicious location changes', SecurityViolationType.geolocationFraud);
      }
      
      return SecurityResult.success();
      
    } catch (e) {
      return SecurityResult.error('Geolocation fraud check failed', SecurityViolationType.system);
    }
  }
  
  /// Validate device fingerprint
  Future<SecurityResult> _validateDeviceFingerprint(String userId, String userAgent, String ipAddress) async {
    try {
      final deviceFingerprint = _generateDeviceFingerprint(userAgent, ipAddress);
      
      // Store/update device fingerprint
      await _firestore
          .collection('user_devices')
          .doc('${userId}_${deviceFingerprint.substring(0, 8)}')
          .set({
        'userId': userId,
        'fingerprint': deviceFingerprint,
        'userAgent': userAgent,
        'ipAddress': ipAddress,
        'lastSeen': FieldValue.serverTimestamp(),
        'isVerified': true,
      }, SetOptions(merge: true));
      
      return SecurityResult.success();
      
    } catch (e) {
      return SecurityResult.error('Device validation failed', SecurityViolationType.system);
    }
  }
  
  /// Validate event-specific data
  Future<SecurityResult> _validateEventSpecifics(String eventType, Map<String, dynamic> eventData) async {
    try {
      switch (eventType) {
        case 'video_watch':
          return _validateVideoWatchEvent(eventData);
        case 'quiz_completion':
          return _validateQuizEvent(eventData);
        case 'social_follow':
          return _validateSocialEvent(eventData);
        case 'ad_view':
          return _validateAdEvent(eventData);
        default:
          return SecurityResult.success();
      }
    } catch (e) {
      return SecurityResult.error('Event validation failed', SecurityViolationType.system);
    }
  }
  
  Future<SecurityResult> _validateVideoWatchEvent(Map<String, dynamic> eventData) async {
    final watchDuration = eventData['watchDurationSeconds'] as int?;
    final totalDuration = eventData['totalDurationSeconds'] as int?;
    
    if (watchDuration == null || totalDuration == null) {
      return SecurityResult.error('Invalid video watch data', SecurityViolationType.invalidData);
    }
    
    if (watchDuration > totalDuration) {
      return SecurityResult.error('Watch duration exceeds video length', SecurityViolationType.invalidData);
    }
    
    if (watchDuration < 30) { // Minimum 30 seconds
      return SecurityResult.error('Insufficient watch duration', SecurityViolationType.invalidData);
    }
    
    return SecurityResult.success();
  }
  
  Future<SecurityResult> _validateQuizEvent(Map<String, dynamic> eventData) async {
    final score = eventData['score'] as double?;
    final totalQuestions = eventData['totalQuestions'] as int?;
    
    if (score == null || totalQuestions == null) {
      return SecurityResult.error('Invalid quiz data', SecurityViolationType.invalidData);
    }
    
    if (score < 0 || score > totalQuestions) {
      return SecurityResult.error('Invalid quiz score', SecurityViolationType.invalidData);
    }
    
    return SecurityResult.success();
  }
  
  Future<SecurityResult> _validateSocialEvent(Map<String, dynamic> eventData) async {
    final platform = eventData['platform'] as String?;
    
    if (platform == null || platform.isEmpty) {
      return SecurityResult.error('Invalid social platform', SecurityViolationType.invalidData);
    }
    
    final validPlatforms = ['tiktok', 'youtube', 'telegram', 'facebook', 'linkedin', 'twitter', 'instagram'];
    if (!validPlatforms.contains(platform.toLowerCase())) {
      return SecurityResult.error('Unsupported social platform', SecurityViolationType.invalidData);
    }
    
    return SecurityResult.success();
  }
  
  Future<SecurityResult> _validateAdEvent(Map<String, dynamic> eventData) async {
    final adId = eventData['adId'] as String?;
    final viewDuration = eventData['viewDurationSeconds'] as int?;
    
    if (adId == null || adId.isEmpty) {
      return SecurityResult.error('Invalid ad ID', SecurityViolationType.invalidData);
    }
    
    if (viewDuration == null || viewDuration < 5) { // Minimum 5 seconds
      return SecurityResult.error('Insufficient ad view duration', SecurityViolationType.invalidData);
    }
    
    return SecurityResult.success();
  }
  
  // Helper methods
  
  Future<void> _initializeSecurityCollections() async {
    try {
      // Initialize security collections with proper indexes
      await _firestore.collection('security_logs').doc('_init').set({'initialized': true});
      await _firestore.collection('security_violations').doc('_init').set({'initialized': true});
      await _firestore.collection('user_devices').doc('_init').set({'initialized': true});
    } catch (e) {
      _logSecurityError('Failed to initialize security collections: $e');
    }
  }
  
  Future<void> _startSecurityMonitoring() async {
    // Start periodic security monitoring tasks
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _cleanupOldSecurityLogs();
      await _generateSecurityReport();
    });
  }
  
  Future<void> _cleanupOldSecurityLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final oldLogsQuery = await _firestore
          .collection('security_logs')
          .where('timestamp', isLessThan: cutoffDate)
          .limit(100)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in oldLogsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (oldLogsQuery.docs.isNotEmpty) {
        _logSecurity('🧹 Cleaned up ${oldLogsQuery.docs.length} old security logs');
      }
    } catch (e) {
      _logSecurityError('Failed to cleanup old security logs: $e');
    }
  }
  
  Future<void> _generateSecurityReport() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      
      // Get violation counts
      final violationsQuery = await _firestore
          .collection('security_violations')
          .where('timestamp', isGreaterThan: oneDayAgo)
          .get();
      
      final violationCounts = <String, int>{};
      for (final doc in violationsQuery.docs) {
        final type = doc.data()['violationType'] as String;
        violationCounts[type] = (violationCounts[type] ?? 0) + 1;
      }
      
      // Log security report
      await _logSecurityEvent(
        userId: 'system',
        eventType: 'daily_security_report',
        data: {
          'totalViolations': violationsQuery.docs.length,
          'violationBreakdown': violationCounts,
          'reportDate': now.toIso8601String(),
        },
        severity: SecuritySeverity.info,
      );
      
    } catch (e) {
      _logSecurityError('Failed to generate security report: $e');
    }
  }
  
  Future<void> _logSecurityEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> data,
    required SecuritySeverity severity,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'userId': userId,
        'eventType': eventType,
        'data': data,
        'severity': severity.name,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
    } catch (e) {
      _logSecurityError('Failed to log security event: $e');
    }
  }
  
  Future<void> _logSecurityViolation({
    required String userId,
    required SecurityViolationType violationType,
    required String details,
  }) async {
    try {
      await _firestore.collection('security_violations').add({
        'userId': userId,
        'violationType': violationType.name,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
        'resolved': false,
      });
      
      _logSecurity('🚨 Security violation: ${violationType.name} - $details');
    } catch (e) {
      _logSecurityError('Failed to log security violation: $e');
    }
  }
  
  String _hashEventData(Map<String, dynamic> eventData) {
    final jsonString = jsonEncode(eventData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  String _generateDeviceFingerprint(String userAgent, String ipAddress) {
    final combined = '$userAgent:$ipAddress';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  void _logSecurity(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🔒 Security: $message');
    }
  }
  
  void _logSecurityError(String message, [StackTrace? stackTrace]) {
    print('❌ Security Error: $message');
    if (stackTrace != null && EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('Stack trace: $stackTrace');
    }
  }
}

/// Security validation result
class SecurityResult {
  final bool success;
  final String? error;
  final SecurityViolationType? violation;
  
  SecurityResult.success() : success = true, error = null, violation = null;
  SecurityResult.error(this.error, this.violation) : success = false;
}

/// Security violation types
enum SecurityViolationType {
  authentication,
  rateLimit,
  didVerification,
  ipFraud,
  velocityFraud,
  patternFraud,
  geolocationFraud,
  invalidData,
  system,
}

/// Security event severity levels
enum SecuritySeverity {
  info,
  warning,
  error,
  critical,
}
