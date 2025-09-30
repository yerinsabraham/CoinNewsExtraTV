/// Fail-Safe UX & Error Recovery System
/// Provides graceful error handling, retry mechanisms, and fallback queues
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';
import 'monitoring_service.dart';

class FailSafeService {
  static FailSafeService? _instance;
  static FailSafeService get instance => _instance ??= FailSafeService._();
  
  FailSafeService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MonitoringService _monitoring = MonitoringService.instance;
  
  // Retry configuration
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const Duration INITIAL_RETRY_DELAY = Duration(seconds: 2);
  static const Duration MAX_RETRY_DELAY = Duration(seconds: 30);
  static const Duration QUEUE_PROCESSING_INTERVAL = Duration(minutes: 5);
  
  // Circuit breaker configuration
  static const int CIRCUIT_BREAKER_THRESHOLD = 5;
  static const Duration CIRCUIT_BREAKER_TIMEOUT = Duration(minutes: 10);
  
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  late Timer _queueProcessor;
  
  /// Initialize fail-safe service
  Future<void> initialize() async {
    await _initializeFailQueues();
    await _initializeCircuitBreakers();
    _startQueueProcessor();
    
    _logFailSafe('✅ FailSafeService initialized with retry and fallback mechanisms');
  }
  
  /// Execute operation with fail-safe mechanisms
  Future<T> executeWithFailSafe<T>({
    required String operationId,
    required Future<T> Function() operation,
    required String userId,
    Map<String, dynamic>? context,
    int? maxRetries,
    Duration? initialDelay,
    bool enableCircuitBreaker = true,
  }) async {
    final retries = maxRetries ?? MAX_RETRY_ATTEMPTS;
    final delay = initialDelay ?? INITIAL_RETRY_DELAY;
    
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        // Check circuit breaker
        if (enableCircuitBreaker && _isCircuitBreakerOpen(operationId)) {
          throw FailSafeException('Circuit breaker is open for operation: $operationId');
        }
        
        final result = await operation();
        
        // Reset circuit breaker on success
        if (enableCircuitBreaker) {
          _resetCircuitBreaker(operationId);
        }
        
        // Log successful execution
        if (attempt > 1) {
          _logFailSafe('✅ Operation succeeded on attempt $attempt: $operationId');
        }
        
        return result;
        
      } catch (e) {
        // Record failure
        if (enableCircuitBreaker) {
          _recordCircuitBreakerFailure(operationId);
        }
        
        // Log attempt failure
        _logFailSafe('❌ Operation failed (attempt $attempt/$retries): $operationId - $e');
        
        // If this is the last attempt, queue for later retry
        if (attempt == retries) {
          await _queueForRetry(
            operationId: operationId,
            userId: userId,
            context: context ?? {},
            lastError: e.toString(),
          );
          
          throw FailSafeException('Operation failed after $retries attempts: $e');
        }
        
        // Wait before next attempt with exponential backoff
        final nextDelay = Duration(
          milliseconds: (delay.inMilliseconds * (attempt * attempt)).clamp(
            delay.inMilliseconds,
            MAX_RETRY_DELAY.inMilliseconds,
          ),
        );
        
        await Future.delayed(nextDelay);
      }
    }
    
    throw FailSafeException('Unexpected error in fail-safe execution');
  }
  
  /// Queue failed operation for later retry
  Future<void> _queueForRetry({
    required String operationId,
    required String userId,
    required Map<String, dynamic> context,
    required String lastError,
  }) async {
    try {
      final queueItem = {
        'operationId': operationId,
        'userId': userId,
        'context': context,
        'lastError': lastError,
        'queuedAt': FieldValue.serverTimestamp(),
        'retryCount': 0,
        'maxRetries': MAX_RETRY_ATTEMPTS,
        'status': 'queued',
        'nextRetryAt': DateTime.now().add(const Duration(minutes: 5)),
        'environment': EnvironmentConfig.currentEnvironment.name,
      };
      
      await _firestore.collection('retry_queue').add(queueItem);
      
      _logFailSafe('📥 Operation queued for retry: $operationId');
      
    } catch (e) {
      _logFailSafeError('Failed to queue operation for retry: $e');
    }
  }
  
  /// Process retry queue
  Future<void> processRetryQueue() async {
    try {
      final now = DateTime.now();
      
      final queuedItems = await _firestore
          .collection('retry_queue')
          .where('status', isEqualTo: 'queued')
          .where('nextRetryAt', isLessThanOrEqualTo: now)
          .limit(50)
          .get();
      
      if (queuedItems.docs.isEmpty) {
        return;
      }
      
      _logFailSafe('🔄 Processing ${queuedItems.docs.length} queued operations');
      
      for (final doc in queuedItems.docs) {
        await _processQueuedItem(doc);
      }
      
    } catch (e) {
      _logFailSafeError('Failed to process retry queue: $e');
    }
  }
  
  /// Get user-friendly error message
  String getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection issue. Please check your internet and try again.';
    }
    
    // Gas/fee errors
    if (errorString.contains('gas') || errorString.contains('fee')) {
      return 'Transaction fee issue. Please try again or contact support.';
    }
    
    // DID errors
    if (errorString.contains('did') || errorString.contains('identity')) {
      return 'Identity verification failed. Please ensure your account is properly set up.';
    }
    
    // Smart contract errors
    if (errorString.contains('contract') || errorString.contains('revert')) {
      return 'Blockchain operation failed. This may be temporary - please try again.';
    }
    
    // Rate limiting
    if (errorString.contains('rate limit') || errorString.contains('too many')) {
      return 'You\'re doing that too often. Please wait a moment and try again.';
    }
    
    // Insufficient balance
    if (errorString.contains('insufficient') || errorString.contains('balance')) {
      return 'Insufficient balance for this transaction.';
    }
    
    // Default friendly message
    return 'Something went wrong. We\'re working to fix it. Please try again in a few minutes.';
  }
  
  /// Show error dialog with retry options
  Future<ErrorDialogResult> showErrorDialog({
    required String title,
    required String error,
    required String operationId,
    bool canRetry = true,
    bool canContact = true,
  }) async {
    final friendlyMessage = getUserFriendlyErrorMessage(error);
    
    // Record error display
    await _recordErrorDisplay(operationId, error, friendlyMessage);
    
    // For now, return a simulated user choice
    // In a real app, this would show a dialog and return user's choice
    return ErrorDialogResult(
      action: canRetry ? DialogAction.retry : DialogAction.dismiss,
      userMessage: friendlyMessage,
    );
  }
  
  /// Get fallback data when primary source fails
  Future<T?> getFallbackData<T>({
    required String dataType,
    required String userId,
    T? defaultValue,
  }) async {
    try {
      final fallbackDoc = await _firestore
          .collection('fallback_data')
          .doc('${dataType}_$userId')
          .get();
      
      if (fallbackDoc.exists) {
        final data = fallbackDoc.data()!;
        _logFailSafe('📋 Using fallback data for $dataType');
        return data['value'] as T;
      }
      
      return defaultValue;
      
    } catch (e) {
      _logFailSafeError('Failed to get fallback data: $e');
      return defaultValue;
    }
  }
  
  /// Store fallback data
  Future<void> storeFallbackData<T>({
    required String dataType,
    required String userId,
    required T value,
    Duration? ttl,
  }) async {
    try {
      final expiresAt = ttl != null 
          ? DateTime.now().add(ttl) 
          : DateTime.now().add(const Duration(hours: 24));
      
      await _firestore.collection('fallback_data').doc('${dataType}_$userId').set({
        'value': value,
        'storedAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'dataType': dataType,
        'userId': userId,
      });
      
      _logFailSafe('💾 Stored fallback data for $dataType');
      
    } catch (e) {
      _logFailSafeError('Failed to store fallback data: $e');
    }
  }
  
  /// Get error recovery suggestions
  List<RecoverySuggestion> getRecoverySuggestions(String error) {
    final suggestions = <RecoverySuggestion>[];
    final errorString = error.toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      suggestions.addAll([
        RecoverySuggestion(
          title: 'Check Internet Connection',
          description: 'Ensure you have a stable internet connection',
          action: RecoveryAction.checkConnection,
        ),
        RecoverySuggestion(
          title: 'Switch Networks',
          description: 'Try switching between WiFi and mobile data',
          action: RecoveryAction.switchNetwork,
        ),
      ]);
    }
    
    if (errorString.contains('gas') || errorString.contains('fee')) {
      suggestions.addAll([
        RecoverySuggestion(
          title: 'Wait for Lower Fees',
          description: 'Network fees fluctuate - try again in a few minutes',
          action: RecoveryAction.waitAndRetry,
        ),
        RecoverySuggestion(
          title: 'Check Balance',
          description: 'Ensure you have enough funds for transaction fees',
          action: RecoveryAction.checkBalance,
        ),
      ]);
    }
    
    if (errorString.contains('did') || errorString.contains('identity')) {
      suggestions.addAll([
        RecoverySuggestion(
          title: 'Verify Identity Setup',
          description: 'Check your identity verification in settings',
          action: RecoveryAction.verifyIdentity,
        ),
        RecoverySuggestion(
          title: 'Re-authenticate',
          description: 'Sign out and sign back in to refresh your identity',
          action: RecoveryAction.reauthenticate,
        ),
      ]);
    }
    
    // Always include contact support option
    suggestions.add(
      RecoverySuggestion(
        title: 'Contact Support',
        description: 'Get help from our support team',
        action: RecoveryAction.contactSupport,
      ),
    );
    
    return suggestions;
  }
  
  /// Get operation status for user
  Future<OperationStatus> getOperationStatus(String operationId, String userId) async {
    try {
      // Check retry queue
      final queueQuery = await _firestore
          .collection('retry_queue')
          .where('operationId', isEqualTo: operationId)
          .where('userId', isEqualTo: userId)
          .orderBy('queuedAt', descending: true)
          .limit(1)
          .get();
      
      if (queueQuery.docs.isNotEmpty) {
        final queueData = queueQuery.docs.first.data();
        return OperationStatus(
          operationId: operationId,
          status: queueData['status'],
          lastError: queueData['lastError'],
          retryCount: queueData['retryCount'],
          nextRetryAt: (queueData['nextRetryAt'] as Timestamp).toDate(),
          isInQueue: true,
        );
      }
      
      return OperationStatus(
        operationId: operationId,
        status: 'unknown',
        lastError: null,
        retryCount: 0,
        nextRetryAt: null,
        isInQueue: false,
      );
      
    } catch (e) {
      _logFailSafeError('Failed to get operation status: $e');
      return OperationStatus(
        operationId: operationId,
        status: 'error',
        lastError: e.toString(),
        retryCount: 0,
        nextRetryAt: null,
        isInQueue: false,
      );
    }
  }
  
  // Private methods
  
  Future<void> _initializeFailQueues() async {
    await _firestore.collection('retry_queue').doc('_init').set({'initialized': true});
    await _firestore.collection('fallback_data').doc('_init').set({'initialized': true});
    await _firestore.collection('error_displays').doc('_init').set({'initialized': true});
  }
  
  Future<void> _initializeCircuitBreakers() async {
    // Initialize circuit breakers for common operations
    final operations = ['reward_claim', 'did_verification', 'contract_interaction', 'social_follow'];
    
    for (final operation in operations) {
      _circuitBreakers[operation] = CircuitBreaker(
        operation: operation,
        threshold: CIRCUIT_BREAKER_THRESHOLD,
        timeout: CIRCUIT_BREAKER_TIMEOUT,
      );
    }
  }
  
  void _startQueueProcessor() {
    _queueProcessor = Timer.periodic(QUEUE_PROCESSING_INTERVAL, (timer) async {
      await processRetryQueue();
    });
  }
  
  bool _isCircuitBreakerOpen(String operationId) {
    final breaker = _circuitBreakers[operationId];
    return breaker?.isOpen ?? false;
  }
  
  void _resetCircuitBreaker(String operationId) {
    final breaker = _circuitBreakers[operationId];
    breaker?.reset();
  }
  
  void _recordCircuitBreakerFailure(String operationId) {
    final breaker = _circuitBreakers[operationId];
    breaker?.recordFailure();
  }
  
  Future<void> _processQueuedItem(QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final operationId = data['operationId'] as String;
      final userId = data['userId'] as String;
      final retryCount = data['retryCount'] as int;
      final maxRetries = data['maxRetries'] as int;
      
      // Mark as processing
      await doc.reference.update({
        'status': 'processing',
        'processingStartedAt': FieldValue.serverTimestamp(),
      });
      
      try {
        // Attempt to retry the operation based on operationId
        final success = await _retryOperation(operationId, userId, data['context']);
        
        if (success) {
          // Mark as completed
          await doc.reference.update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
          
          _logFailSafe('✅ Queued operation completed: $operationId');
          
        } else {
          throw Exception('Operation retry returned false');
        }
        
      } catch (e) {
        if (retryCount >= maxRetries) {
          // Mark as failed permanently
          await doc.reference.update({
            'status': 'failed',
            'failedAt': FieldValue.serverTimestamp(),
            'finalError': e.toString(),
          });
          
          _logFailSafe('❌ Queued operation failed permanently: $operationId');
          
        } else {
          // Schedule for another retry
          await doc.reference.update({
            'status': 'queued',
            'retryCount': retryCount + 1,
            'lastRetryError': e.toString(),
            'nextRetryAt': DateTime.now().add(Duration(minutes: 5 * (retryCount + 1))),
          });
          
          _logFailSafe('🔄 Queued operation scheduled for retry: $operationId');
        }
      }
      
    } catch (e) {
      _logFailSafeError('Failed to process queued item: $e');
    }
  }
  
  Future<bool> _retryOperation(String operationId, String userId, Map<String, dynamic> context) async {
    // This would contain the actual retry logic for different operation types
    // For now, return a simulated success/failure
    
    switch (operationId) {
      case 'reward_claim':
        return await _retryRewardClaim(userId, context);
      case 'did_verification':
        return await _retryDIDVerification(userId, context);
      case 'social_follow':
        return await _retrySocialFollow(userId, context);
      default:
        _logFailSafeError('Unknown operation type for retry: $operationId');
        return false;
    }
  }
  
  Future<bool> _retryRewardClaim(String userId, Map<String, dynamic> context) async {
    // Implement reward claim retry logic
    return true; // Simulated success
  }
  
  Future<bool> _retryDIDVerification(String userId, Map<String, dynamic> context) async {
    // Implement DID verification retry logic
    return true; // Simulated success
  }
  
  Future<bool> _retrySocialFollow(String userId, Map<String, dynamic> context) async {
    // Implement social follow retry logic
    return true; // Simulated success
  }
  
  Future<void> _recordErrorDisplay(String operationId, String error, String friendlyMessage) async {
    try {
      await _firestore.collection('error_displays').add({
        'operationId': operationId,
        'originalError': error,
        'friendlyMessage': friendlyMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
    } catch (e) {
      _logFailSafeError('Failed to record error display: $e');
    }
  }
  
  void _logFailSafe(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🛡️ FailSafe: $message');
    }
  }
  
  void _logFailSafeError(String message) {
    print('❌ FailSafe Error: $message');
  }
}

/// Circuit breaker implementation
class CircuitBreaker {
  final String operation;
  final int threshold;
  final Duration timeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;
  
  CircuitBreaker({
    required this.operation,
    required this.threshold,
    required this.timeout,
  });
  
  bool get isOpen {
    if (_isOpen && _lastFailureTime != null) {
      if (DateTime.now().difference(_lastFailureTime!) > timeout) {
        reset();
        return false;
      }
    }
    return _isOpen;
  }
  
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= threshold) {
      _isOpen = true;
    }
  }
  
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _isOpen = false;
  }
}

/// Error dialog result
class ErrorDialogResult {
  final DialogAction action;
  final String userMessage;
  
  ErrorDialogResult({
    required this.action,
    required this.userMessage,
  });
}

/// Dialog actions
enum DialogAction {
  retry,
  dismiss,
  contactSupport,
  viewQueue,
}

/// Recovery suggestion
class RecoverySuggestion {
  final String title;
  final String description;
  final RecoveryAction action;
  
  RecoverySuggestion({
    required this.title,
    required this.description,
    required this.action,
  });
}

/// Recovery actions
enum RecoveryAction {
  checkConnection,
  switchNetwork,
  waitAndRetry,
  checkBalance,
  verifyIdentity,
  reauthenticate,
  contactSupport,
}

/// Operation status
class OperationStatus {
  final String operationId;
  final String status;
  final String? lastError;
  final int retryCount;
  final DateTime? nextRetryAt;
  final bool isInQueue;
  
  OperationStatus({
    required this.operationId,
    required this.status,
    required this.lastError,
    required this.retryCount,
    required this.nextRetryAt,
    required this.isInQueue,
  });
}

/// Fail-safe specific exceptions
class FailSafeException implements Exception {
  final String message;
  FailSafeException(this.message);
  
  @override
  String toString() => 'FailSafeException: $message';
}
