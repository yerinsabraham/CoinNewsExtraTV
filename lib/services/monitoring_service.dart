/// Real-Time Monitoring & Alerting System
/// Provides comprehensive monitoring for blockchain operations, DID verification, and security events
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';

class MonitoringService {
  static MonitoringService? _instance;
  static MonitoringService get instance => _instance ??= MonitoringService._();
  
  MonitoringService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Alert thresholds
  static const int REWARD_FAILURE_THRESHOLD = 5; // per 10 minutes
  static const int CONTRACT_REVERT_THRESHOLD = 3; // per 10 minutes
  static const int DID_FAILURE_THRESHOLD = 10; // per 10 minutes
  static const double ERROR_RATE_THRESHOLD = 0.05; // 5%
  static const int RESPONSE_TIME_THRESHOLD = 5000; // 5 seconds
  
  // Alert channels
  late final String _slackWebhookUrl;
  late final String _telegramBotToken;
  late final String _telegramChatId;
  late final List<String> _emailAlerts;
  
  /// Initialize monitoring service
  Future<void> initialize() async {
    await _loadAlertConfiguration();
    await _initializeMetricsCollection();
    await _startMonitoringTasks();
    
    _logMonitoring('✅ MonitoringService initialized with real-time alerting');
  }
  
  /// Report reward distribution error
  Future<void> reportRewardError({
    required String userId,
    required String eventType,
    required String errorMessage,
    required Map<String, dynamic> context,
  }) async {
    try {
      await _recordMetric(
        metric: 'reward_distribution_error',
        value: 1,
        metadata: {
          'userId': userId,
          'eventType': eventType,
          'errorMessage': errorMessage,
          'context': context,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Check if threshold exceeded
      await _checkRewardErrorThreshold();
      
    } catch (e) {
      _logMonitoringError('Failed to report reward error: $e');
    }
  }
  
  /// Report smart contract revert
  Future<void> reportContractRevert({
    required String contractId,
    required String functionName,
    required String revertReason,
    required Map<String, dynamic> transactionDetails,
  }) async {
    try {
      await _recordMetric(
        metric: 'contract_revert',
        value: 1,
        metadata: {
          'contractId': contractId,
          'functionName': functionName,
          'revertReason': revertReason,
          'transactionDetails': transactionDetails,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Immediate alert for contract reverts
      await _sendAlert(
        AlertLevel.critical,
        'Smart Contract Revert',
        'Contract: $contractId\nFunction: $functionName\nReason: $revertReason',
        {'contractId': contractId, 'functionName': functionName},
      );
      
      await _checkContractRevertThreshold();
      
    } catch (e) {
      _logMonitoringError('Failed to report contract revert: $e');
    }
  }
  
  /// Report DID verification failure
  Future<void> reportDIDFailure({
    required String userId,
    required String didIdentifier,
    required String failureReason,
    required Map<String, dynamic> verificationContext,
  }) async {
    try {
      await _recordMetric(
        metric: 'did_verification_failure',
        value: 1,
        metadata: {
          'userId': userId,
          'didIdentifier': didIdentifier,
          'failureReason': failureReason,
          'verificationContext': verificationContext,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      await _checkDIDFailureThreshold();
      
    } catch (e) {
      _logMonitoringError('Failed to report DID failure: $e');
    }
  }
  
  /// Report performance metrics
  Future<void> reportPerformanceMetric({
    required String operation,
    required int responseTimeMs,
    required bool success,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _recordMetric(
        metric: 'performance_metric',
        value: responseTimeMs.toDouble(),
        metadata: {
          'operation': operation,
          'responseTimeMs': responseTimeMs,
          'success': success,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Check response time threshold
      if (responseTimeMs > RESPONSE_TIME_THRESHOLD) {
        await _sendAlert(
          AlertLevel.warning,
          'High Response Time',
          'Operation: $operation\nResponse Time: ${responseTimeMs}ms\nThreshold: ${RESPONSE_TIME_THRESHOLD}ms',
          {'operation': operation, 'responseTimeMs': responseTimeMs},
        );
      }
      
    } catch (e) {
      _logMonitoringError('Failed to report performance metric: $e');
    }
  }
  
  /// Report system health metrics
  Future<void> reportSystemHealth({
    required double cpuUsage,
    required double memoryUsage,
    required double diskUsage,
    required int activeUsers,
    required int queuedTasks,
  }) async {
    try {
      await _recordMetric(
        metric: 'system_health',
        value: 1,
        metadata: {
          'cpuUsage': cpuUsage,
          'memoryUsage': memoryUsage,
          'diskUsage': diskUsage,
          'activeUsers': activeUsers,
          'queuedTasks': queuedTasks,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // Check critical thresholds
      if (cpuUsage > 80) {
        await _sendAlert(
          AlertLevel.warning,
          'High CPU Usage',
          'CPU Usage: ${cpuUsage.toStringAsFixed(1)}%',
          {'cpuUsage': cpuUsage},
        );
      }
      
      if (memoryUsage > 85) {
        await _sendAlert(
          AlertLevel.critical,
          'High Memory Usage',
          'Memory Usage: ${memoryUsage.toStringAsFixed(1)}%',
          {'memoryUsage': memoryUsage},
        );
      }
      
    } catch (e) {
      _logMonitoringError('Failed to report system health: $e');
    }
  }
  
  /// Generate monitoring dashboard data
  Future<Map<String, dynamic>> getDashboardMetrics({
    Duration? timeWindow,
  }) async {
    try {
      final window = timeWindow ?? const Duration(hours: 24);
      final cutoffTime = DateTime.now().subtract(window);
      
      // Get metrics from Firestore
      final metricsQuery = await _firestore
          .collection('monitoring_metrics')
          .where('timestamp', isGreaterThan: cutoffTime)
          .get();
      
      final metrics = <String, dynamic>{};
      int totalOperations = 0;
      int successfulOperations = 0;
      double totalResponseTime = 0;
      int responseTimeCount = 0;
      
      for (final doc in metricsQuery.docs) {
        final data = doc.data();
        final metric = data['metric'] as String;
        
        // Count by metric type
        metrics[metric] = (metrics[metric] ?? 0) + 1;
        
        // Calculate success rates and performance
        if (data['metadata'] != null) {
          final metadata = data['metadata'] as Map<String, dynamic>;
          
          if (metadata.containsKey('success')) {
            totalOperations++;
            if (metadata['success'] == true) {
              successfulOperations++;
            }
          }
          
          if (metadata.containsKey('responseTimeMs')) {
            totalResponseTime += metadata['responseTimeMs'];
            responseTimeCount++;
          }
        }
      }
      
      return {
        'timeWindow': window.inHours,
        'totalMetrics': metricsQuery.docs.length,
        'metricBreakdown': metrics,
        'successRate': totalOperations > 0 ? successfulOperations / totalOperations : 1.0,
        'averageResponseTime': responseTimeCount > 0 ? totalResponseTime / responseTimeCount : 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      _logMonitoringError('Failed to generate dashboard metrics: $e');
      return {'error': 'Failed to load metrics'};
    }
  }
  
  // Private methods
  
  Future<void> _loadAlertConfiguration() async {
    // Load from environment or secure configuration
    _slackWebhookUrl = const String.fromEnvironment('SLACK_WEBHOOK_URL', defaultValue: '');
    _telegramBotToken = const String.fromEnvironment('TELEGRAM_BOT_TOKEN', defaultValue: '');
    _telegramChatId = const String.fromEnvironment('TELEGRAM_CHAT_ID', defaultValue: '');
    _emailAlerts = const String.fromEnvironment('ALERT_EMAILS', defaultValue: '').split(',');
  }
  
  Future<void> _initializeMetricsCollection() async {
    // Initialize Firestore collections for metrics
    await _firestore.collection('monitoring_metrics').doc('_init').set({'initialized': true});
    await _firestore.collection('alert_history').doc('_init').set({'initialized': true});
  }
  
  Future<void> _startMonitoringTasks() async {
    // Start periodic monitoring tasks
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkAllThresholds();
      await _generateHealthReport();
    });
    
    Timer.periodic(const Duration(hours: 1), (timer) async {
      await _cleanupOldMetrics();
    });
  }
  
  Future<void> _recordMetric({
    required String metric,
    required double value,
    required Map<String, dynamic> metadata,
  }) async {
    await _firestore.collection('monitoring_metrics').add({
      'metric': metric,
      'value': value,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
      'environment': EnvironmentConfig.currentEnvironment.name,
    });
  }
  
  Future<void> _checkRewardErrorThreshold() async {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    
    final recentErrors = await _firestore
        .collection('monitoring_metrics')
        .where('metric', isEqualTo: 'reward_distribution_error')
        .where('timestamp', isGreaterThan: tenMinutesAgo)
        .get();
    
    if (recentErrors.docs.length >= REWARD_FAILURE_THRESHOLD) {
      await _sendAlert(
        AlertLevel.critical,
        'High Reward Failure Rate',
        'Reward failures: ${recentErrors.docs.length} in last 10 minutes\nThreshold: $REWARD_FAILURE_THRESHOLD',
        {'failureCount': recentErrors.docs.length, 'threshold': REWARD_FAILURE_THRESHOLD},
      );
    }
  }
  
  Future<void> _checkContractRevertThreshold() async {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    
    final recentReverts = await _firestore
        .collection('monitoring_metrics')
        .where('metric', isEqualTo: 'contract_revert')
        .where('timestamp', isGreaterThan: tenMinutesAgo)
        .get();
    
    if (recentReverts.docs.length >= CONTRACT_REVERT_THRESHOLD) {
      await _sendAlert(
        AlertLevel.critical,
        'High Contract Revert Rate',
        'Contract reverts: ${recentReverts.docs.length} in last 10 minutes\nThreshold: $CONTRACT_REVERT_THRESHOLD',
        {'revertCount': recentReverts.docs.length, 'threshold': CONTRACT_REVERT_THRESHOLD},
      );
    }
  }
  
  Future<void> _checkDIDFailureThreshold() async {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    
    final recentFailures = await _firestore
        .collection('monitoring_metrics')
        .where('metric', isEqualTo: 'did_verification_failure')
        .where('timestamp', isGreaterThan: tenMinutesAgo)
        .get();
    
    if (recentFailures.docs.length >= DID_FAILURE_THRESHOLD) {
      await _sendAlert(
        AlertLevel.warning,
        'High DID Failure Rate',
        'DID failures: ${recentFailures.docs.length} in last 10 minutes\nThreshold: $DID_FAILURE_THRESHOLD',
        {'failureCount': recentFailures.docs.length, 'threshold': DID_FAILURE_THRESHOLD},
      );
    }
  }
  
  Future<void> _checkAllThresholds() async {
    await Future.wait([
      _checkRewardErrorThreshold(),
      _checkContractRevertThreshold(),
      _checkDIDFailureThreshold(),
    ]);
  }
  
  Future<void> _generateHealthReport() async {
    try {
      final dashboardData = await getDashboardMetrics(
        timeWindow: const Duration(hours: 1),
      );
      
      // Record health status
      await _recordMetric(
        metric: 'health_report',
        value: 1,
        metadata: dashboardData,
      );
      
    } catch (e) {
      _logMonitoringError('Failed to generate health report: $e');
    }
  }
  
  Future<void> _cleanupOldMetrics() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      final oldMetricsQuery = await _firestore
          .collection('monitoring_metrics')
          .where('timestamp', isLessThan: cutoffDate)
          .limit(100)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in oldMetricsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (oldMetricsQuery.docs.isNotEmpty) {
        _logMonitoring('🧹 Cleaned up ${oldMetricsQuery.docs.length} old metrics');
      }
    } catch (e) {
      _logMonitoringError('Failed to cleanup old metrics: $e');
    }
  }
  
  Future<void> _sendAlert(
    AlertLevel level,
    String title,
    String message,
    Map<String, dynamic> context,
  ) async {
    try {
      // Record alert
      await _firestore.collection('alert_history').add({
        'level': level.name,
        'title': title,
        'message': message,
        'context': context,
        'timestamp': FieldValue.serverTimestamp(),
        'environment': EnvironmentConfig.currentEnvironment.name,
      });
      
      // Send to configured channels
      await Future.wait([
        _sendSlackAlert(level, title, message, context),
        _sendTelegramAlert(level, title, message, context),
        _sendEmailAlert(level, title, message, context),
      ]);
      
    } catch (e) {
      _logMonitoringError('Failed to send alert: $e');
    }
  }
  
  Future<void> _sendSlackAlert(
    AlertLevel level,
    String title,
    String message,
    Map<String, dynamic> context,
  ) async {
    if (_slackWebhookUrl.isEmpty) return;
    
    try {
      final color = _getAlertColor(level);
      final payload = {
        'attachments': [
          {
            'color': color,
            'title': '🚨 CNE Alert: $title',
            'text': message,
            'fields': [
              {
                'title': 'Environment',
                'value': EnvironmentConfig.currentEnvironment.name,
                'short': true,
              },
              {
                'title': 'Level',
                'value': level.name.toUpperCase(),
                'short': true,
              },
              {
                'title': 'Time',
                'value': DateTime.now().toIso8601String(),
                'short': true,
              },
            ],
            'footer': 'CNE Monitoring',
            'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          }
        ]
      };
      
      final response = await http.post(
        Uri.parse(_slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode != 200) {
        _logMonitoringError('Slack alert failed: ${response.body}');
      }
      
    } catch (e) {
      _logMonitoringError('Failed to send Slack alert: $e');
    }
  }
  
  Future<void> _sendTelegramAlert(
    AlertLevel level,
    String title,
    String message,
    Map<String, dynamic> context,
  ) async {
    if (_telegramBotToken.isEmpty || _telegramChatId.isEmpty) return;
    
    try {
      final emoji = _getAlertEmoji(level);
      final text = '$emoji *CNE Alert: $title*\n\n$message\n\n'
                  'Environment: ${EnvironmentConfig.currentEnvironment.name}\n'
                  'Level: ${level.name.toUpperCase()}\n'
                  'Time: ${DateTime.now().toIso8601String()}';
      
      final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage';
      final payload = {
        'chat_id': _telegramChatId,
        'text': text,
        'parse_mode': 'Markdown',
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      
      if (response.statusCode != 200) {
        _logMonitoringError('Telegram alert failed: ${response.body}');
      }
      
    } catch (e) {
      _logMonitoringError('Failed to send Telegram alert: $e');
    }
  }
  
  Future<void> _sendEmailAlert(
    AlertLevel level,
    String title,
    String message,
    Map<String, dynamic> context,
  ) async {
    // Email implementation would go here
    // For now, just log the alert
    _logMonitoring('📧 Email Alert: $title - $message');
  }
  
  String _getAlertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return '#36a64f'; // Green
      case AlertLevel.warning:
        return '#ff9500'; // Orange
      case AlertLevel.error:
        return '#ff0000'; // Red
      case AlertLevel.critical:
        return '#8b0000'; // Dark Red
    }
  }
  
  String _getAlertEmoji(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return 'ℹ️';
      case AlertLevel.warning:
        return '⚠️';
      case AlertLevel.error:
        return '❌';
      case AlertLevel.critical:
        return '🚨';
    }
  }
  
  void _logMonitoring(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('📊 Monitoring: $message');
    }
  }
  
  void _logMonitoringError(String message) {
    print('❌ Monitoring Error: $message');
  }
}

/// Alert severity levels
enum AlertLevel {
  info,
  warning,
  error,
  critical,
}
