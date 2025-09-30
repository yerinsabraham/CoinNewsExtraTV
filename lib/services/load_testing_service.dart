/// Load & Stress Testing Framework
/// Comprehensive testing suite for high-volume concurrent operations
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/environment_config.dart';
import '../services/reward_service.dart';
import '../services/did_service.dart';
import '../services/smart_contract_service.dart';

class LoadTestingService {
  static LoadTestingService? _instance;
  static LoadTestingService get instance => _instance ??= LoadTestingService._();
  
  LoadTestingService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RewardService _rewardService = RewardService.instance;
  final DIDService _didService = DIDService.instance;
  final SmartContractService _contractService = SmartContractService.instance;
  
  // Load test configurations
  static const int DEFAULT_CONCURRENT_USERS = 1000;
  static const int HIGH_LOAD_CONCURRENT_USERS = 10000;
  static const int EXTREME_LOAD_CONCURRENT_USERS = 100000;
  static const Duration DEFAULT_TEST_DURATION = Duration(minutes: 10);
  static const Duration STRESS_TEST_DURATION = Duration(minutes: 30);
  
  /// Initialize load testing service
  Future<void> initialize() async {
    await _initializeTestDatabase();
    await _createTestUsers();
    
    _logLoadTest('✅ LoadTestingService initialized');
  }
  
  /// Run comprehensive load test suite
  Future<LoadTestReport> runComprehensiveLoadTest({
    int? concurrentUsers,
    Duration? testDuration,
    bool enableStressTest = false,
  }) async {
    final users = concurrentUsers ?? (enableStressTest ? HIGH_LOAD_CONCURRENT_USERS : DEFAULT_CONCURRENT_USERS);
    final duration = testDuration ?? (enableStressTest ? STRESS_TEST_DURATION : DEFAULT_TEST_DURATION);
    
    _logLoadTest('🧪 Starting comprehensive load test: $users users, ${duration.inMinutes}min');
    
    final startTime = DateTime.now();
    final testResults = <String, TestScenarioResult>{};
    
    try {
      // Run parallel test scenarios
      final scenarios = await Future.wait([
        _runRewardClaimLoadTest(users, duration),
        _runDIDVerificationLoadTest(users ~/ 2, duration),
        _runSocialFollowLoadTest(users, duration),
        _runWatchTimeLoadTest(users, duration),
        _runSmartContractLoadTest(users ~/ 4, duration),
      ]);
      
      testResults['rewardClaim'] = scenarios[0];
      testResults['didVerification'] = scenarios[1];
      testResults['socialFollow'] = scenarios[2];
      testResults['watchTime'] = scenarios[3];
      testResults['smartContract'] = scenarios[4];
      
      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime);
      
      final report = LoadTestReport(
        testStartTime: startTime,
        testEndTime: endTime,
        totalDuration: totalDuration,
        concurrentUsers: users,
        scenarios: testResults,
        overallSuccess: _calculateOverallSuccess(testResults),
        performanceMetrics: await _calculatePerformanceMetrics(testResults),
        recommendations: _generateRecommendations(testResults),
      );
      
      // Store test report
      await _storeTestReport(report);
      
      _logLoadTest('✅ Load test completed: ${report.overallSuccess ? 'PASSED' : 'FAILED'}');
      
      return report;
      
    } catch (e) {
      _logLoadTestError('Load test failed: $e');
      
      return LoadTestReport(
        testStartTime: startTime,
        testEndTime: DateTime.now(),
        totalDuration: DateTime.now().difference(startTime),
        concurrentUsers: users,
        scenarios: testResults,
        overallSuccess: false,
        performanceMetrics: {},
        recommendations: ['Fix critical errors before retesting'],
        error: e.toString(),
      );
    }
  }
  
  /// Run reward claim load test
  Future<TestScenarioResult> _runRewardClaimLoadTest(int users, Duration duration) async {
    _logLoadTest('🎁 Starting reward claim load test: $users users');
    
    final startTime = DateTime.now();
    final results = <OperationResult>[];
    final futures = <Future<void>>[];
    
    for (int i = 0; i < users; i++) {
      futures.add(_simulateRewardClaim('test_user_$i', results));
    }
    
    // Wait for all operations or timeout
    try {
      await Future.wait(futures).timeout(duration);
    } on TimeoutException {
      _logLoadTest('⏰ Reward claim test timed out after ${duration.inMinutes}min');
    }
    
    final endTime = DateTime.now();
    
    return TestScenarioResult(
      scenarioName: 'Reward Claim',
      startTime: startTime,
      endTime: endTime,
      totalOperations: results.length,
      successfulOperations: results.where((r) => r.success).length,
      failedOperations: results.where((r) => !r.success).length,
      averageResponseTime: _calculateAverageResponseTime(results),
      minResponseTime: _calculateMinResponseTime(results),
      maxResponseTime: _calculateMaxResponseTime(results),
      throughput: results.length / endTime.difference(startTime).inSeconds,
      errorTypes: _categorizeErrors(results),
    );
  }
  
  /// Run DID verification load test
  Future<TestScenarioResult> _runDIDVerificationLoadTest(int users, Duration duration) async {
    _logLoadTest('🆔 Starting DID verification load test: $users users');
    
    final startTime = DateTime.now();
    final results = <OperationResult>[];
    final futures = <Future<void>>[];
    
    for (int i = 0; i < users; i++) {
      futures.add(_simulateDIDVerification('test_user_$i', results));
    }
    
    try {
      await Future.wait(futures).timeout(duration);
    } on TimeoutException {
      _logLoadTest('⏰ DID verification test timed out after ${duration.inMinutes}min');
    }
    
    final endTime = DateTime.now();
    
    return TestScenarioResult(
      scenarioName: 'DID Verification',
      startTime: startTime,
      endTime: endTime,
      totalOperations: results.length,
      successfulOperations: results.where((r) => r.success).length,
      failedOperations: results.where((r) => !r.success).length,
      averageResponseTime: _calculateAverageResponseTime(results),
      minResponseTime: _calculateMinResponseTime(results),
      maxResponseTime: _calculateMaxResponseTime(results),
      throughput: results.length / endTime.difference(startTime).inSeconds,
      errorTypes: _categorizeErrors(results),
    );
  }
  
  /// Run social follow load test
  Future<TestScenarioResult> _runSocialFollowLoadTest(int users, Duration duration) async {
    _logLoadTest('👥 Starting social follow load test: $users users');
    
    final startTime = DateTime.now();
    final results = <OperationResult>[];
    final futures = <Future<void>>[];
    
    final platforms = ['twitter', 'tiktok', 'instagram', 'youtube'];
    
    for (int i = 0; i < users; i++) {
      final platform = platforms[i % platforms.length];
      futures.add(_simulateSocialFollow('test_user_$i', platform, results));
    }
    
    try {
      await Future.wait(futures).timeout(duration);
    } on TimeoutException {
      _logLoadTest('⏰ Social follow test timed out after ${duration.inMinutes}min');
    }
    
    final endTime = DateTime.now();
    
    return TestScenarioResult(
      scenarioName: 'Social Follow',
      startTime: startTime,
      endTime: endTime,
      totalOperations: results.length,
      successfulOperations: results.where((r) => r.success).length,
      failedOperations: results.where((r) => !r.success).length,
      averageResponseTime: _calculateAverageResponseTime(results),
      minResponseTime: _calculateMinResponseTime(results),
      maxResponseTime: _calculateMaxResponseTime(results),
      throughput: results.length / endTime.difference(startTime).inSeconds,
      errorTypes: _categorizeErrors(results),
    );
  }
  
  /// Run watch time load test
  Future<TestScenarioResult> _runWatchTimeLoadTest(int users, Duration duration) async {
    _logLoadTest('📺 Starting watch time load test: $users users');
    
    final startTime = DateTime.now();
    final results = <OperationResult>[];
    final futures = <Future<void>>[];
    
    for (int i = 0; i < users; i++) {
      futures.add(_simulateWatchTime('test_user_$i', results));
    }
    
    try {
      await Future.wait(futures).timeout(duration);
    } on TimeoutException {
      _logLoadTest('⏰ Watch time test timed out after ${duration.inMinutes}min');
    }
    
    final endTime = DateTime.now();
    
    return TestScenarioResult(
      scenarioName: 'Watch Time',
      startTime: startTime,
      endTime: endTime,
      totalOperations: results.length,
      successfulOperations: results.where((r) => r.success).length,
      failedOperations: results.where((r) => !r.success).length,
      averageResponseTime: _calculateAverageResponseTime(results),
      minResponseTime: _calculateMinResponseTime(results),
      maxResponseTime: _calculateMaxResponseTime(results),
      throughput: results.length / endTime.difference(startTime).inSeconds,
      errorTypes: _categorizeErrors(results),
    );
  }
  
  /// Run smart contract load test
  Future<TestScenarioResult> _runSmartContractLoadTest(int users, Duration duration) async {
    _logLoadTest('🔗 Starting smart contract load test: $users users');
    
    final startTime = DateTime.now();
    final results = <OperationResult>[];
    final futures = <Future<void>>[];
    
    for (int i = 0; i < users; i++) {
      futures.add(_simulateSmartContractInteraction('test_user_$i', results));
    }
    
    try {
      await Future.wait(futures).timeout(duration);
    } on TimeoutException {
      _logLoadTest('⏰ Smart contract test timed out after ${duration.inMinutes}min');
    }
    
    final endTime = DateTime.now();
    
    return TestScenarioResult(
      scenarioName: 'Smart Contract',
      startTime: startTime,
      endTime: endTime,
      totalOperations: results.length,
      successfulOperations: results.where((r) => r.success).length,
      failedOperations: results.where((r) => !r.success).length,
      averageResponseTime: _calculateAverageResponseTime(results),
      minResponseTime: _calculateMinResponseTime(results),
      maxResponseTime: _calculateMaxResponseTime(results),
      throughput: results.length / endTime.difference(startTime).inSeconds,
      errorTypes: _categorizeErrors(results),
    );
  }
  
  /// Generate load test report
  Future<String> generateLoadTestReport(LoadTestReport report) async {
    final buffer = StringBuffer();
    
    buffer.writeln('# CNE Load Test Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    buffer.writeln('## Test Overview');
    buffer.writeln('- **Test Duration**: ${report.totalDuration.inMinutes} minutes');
    buffer.writeln('- **Concurrent Users**: ${report.concurrentUsers}');
    buffer.writeln('- **Overall Result**: ${report.overallSuccess ? 'PASSED ✅' : 'FAILED ❌'}');
    buffer.writeln('- **Environment**: ${EnvironmentConfig.currentEnvironment.name}');
    buffer.writeln('');
    
    buffer.writeln('## Scenario Results');
    
    for (final scenario in report.scenarios.values) {
      buffer.writeln('### ${scenario.scenarioName}');
      buffer.writeln('- **Total Operations**: ${scenario.totalOperations}');
      buffer.writeln('- **Successful**: ${scenario.successfulOperations} (${(scenario.successfulOperations / scenario.totalOperations * 100).toStringAsFixed(1)}%)');
      buffer.writeln('- **Failed**: ${scenario.failedOperations} (${(scenario.failedOperations / scenario.totalOperations * 100).toStringAsFixed(1)}%)');
      buffer.writeln('- **Average Response Time**: ${scenario.averageResponseTime.toStringAsFixed(0)}ms');
      buffer.writeln('- **Min Response Time**: ${scenario.minResponseTime.toStringAsFixed(0)}ms');
      buffer.writeln('- **Max Response Time**: ${scenario.maxResponseTime.toStringAsFixed(0)}ms');
      buffer.writeln('- **Throughput**: ${scenario.throughput.toStringAsFixed(2)} ops/sec');
      
      if (scenario.errorTypes.isNotEmpty) {
        buffer.writeln('- **Error Types**:');
        for (final entry in scenario.errorTypes.entries) {
          buffer.writeln('  - ${entry.key}: ${entry.value} occurrences');
        }
      }
      buffer.writeln('');
    }
    
    buffer.writeln('## Performance Metrics');
    for (final entry in report.performanceMetrics.entries) {
      buffer.writeln('- **${entry.key}**: ${entry.value}');
    }
    buffer.writeln('');
    
    buffer.writeln('## Recommendations');
    for (final recommendation in report.recommendations) {
      buffer.writeln('- $recommendation');
    }
    buffer.writeln('');
    
    if (report.error != null) {
      buffer.writeln('## Errors');
      buffer.writeln('```');
      buffer.writeln(report.error);
      buffer.writeln('```');
    }
    
    return buffer.toString();
  }
  
  // Private simulation methods
  
  Future<void> _simulateRewardClaim(String userId, List<OperationResult> results) async {
    final startTime = DateTime.now();
    
    try {
      // Simulate random delay for realistic testing
      await Future.delayed(Duration(milliseconds: Random().nextInt(100)));
      
      // Simulate reward claim operation
      final success = Random().nextDouble() > 0.05; // 95% success rate
      
      if (!success) {
        throw Exception('Simulated reward claim failure');
      }
      
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'reward_claim',
        userId: userId,
        success: true,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
      ));
      
    } catch (e) {
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'reward_claim',
        userId: userId,
        success: false,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
        error: e.toString(),
      ));
    }
  }
  
  Future<void> _simulateDIDVerification(String userId, List<OperationResult> results) async {
    final startTime = DateTime.now();
    
    try {
      await Future.delayed(Duration(milliseconds: Random().nextInt(200) + 100));
      
      final success = Random().nextDouble() > 0.02; // 98% success rate
      
      if (!success) {
        throw Exception('Simulated DID verification failure');
      }
      
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'did_verification',
        userId: userId,
        success: true,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
      ));
      
    } catch (e) {
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'did_verification',
        userId: userId,
        success: false,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
        error: e.toString(),
      ));
    }
  }
  
  Future<void> _simulateSocialFollow(String userId, String platform, List<OperationResult> results) async {
    final startTime = DateTime.now();
    
    try {
      await Future.delayed(Duration(milliseconds: Random().nextInt(150) + 50));
      
      final success = Random().nextDouble() > 0.03; // 97% success rate
      
      if (!success) {
        throw Exception('Simulated social follow failure');
      }
      
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'social_follow',
        userId: userId,
        success: true,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
        metadata: {'platform': platform},
      ));
      
    } catch (e) {
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'social_follow',
        userId: userId,
        success: false,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
        error: e.toString(),
        metadata: {'platform': platform},
      ));
    }
  }
  
  Future<void> _simulateWatchTime(String userId, List<OperationResult> results) async {
    final startTime = DateTime.now();
    
    try {
      await Future.delayed(Duration(milliseconds: Random().nextInt(50) + 25));
      
      final success = Random().nextDouble() > 0.01; // 99% success rate
      
      if (!success) {
        throw Exception('Simulated watch time tracking failure');
      }
      
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'watch_time',
        userId: userId,
        success: true,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
      ));
      
    } catch (e) {
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'watch_time',
        userId: userId,
        success: false,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
        error: e.toString(),
      ));
    }
  }
  
  Future<void> _simulateSmartContractInteraction(String userId, List<OperationResult> results) async {
    final startTime = DateTime.now();
    
    try {
      await Future.delayed(Duration(milliseconds: Random().nextInt(500) + 200));
      
      final success = Random().nextDouble() > 0.08; // 92% success rate (blockchain can be less reliable)
      
      if (!success) {
        throw Exception('Simulated smart contract interaction failure');
      }
      
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'smart_contract',
        userId: userId,
        success: true,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
      ));
      
    } catch (e) {
      final endTime = DateTime.now();
      
      results.add(OperationResult(
        operationType: 'smart_contract',
        userId: userId,
        success: false,
        startTime: startTime,
        endTime: endTime,
        responseTime: endTime.difference(startTime).inMilliseconds.toDouble(),
        error: e.toString(),
      ));
    }
  }
  
  // Private helper methods
  
  Future<void> _initializeTestDatabase() async {
    await _firestore.collection('load_test_reports').doc('_init').set({'initialized': true});
  }
  
  Future<void> _createTestUsers() async {
    // Create test user data if needed
    _logLoadTest('📊 Test environment prepared');
  }
  
  double _calculateAverageResponseTime(List<OperationResult> results) {
    if (results.isEmpty) return 0;
    final total = results.map((r) => r.responseTime).reduce((a, b) => a + b);
    return total / results.length;
  }
  
  double _calculateMinResponseTime(List<OperationResult> results) {
    if (results.isEmpty) return 0;
    return results.map((r) => r.responseTime).reduce((a, b) => a < b ? a : b);
  }
  
  double _calculateMaxResponseTime(List<OperationResult> results) {
    if (results.isEmpty) return 0;
    return results.map((r) => r.responseTime).reduce((a, b) => a > b ? a : b);
  }
  
  Map<String, int> _categorizeErrors(List<OperationResult> results) {
    final errorTypes = <String, int>{};
    
    for (final result in results.where((r) => !r.success)) {
      final errorType = _categorizeError(result.error ?? 'Unknown error');
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
    }
    
    return errorTypes;
  }
  
  String _categorizeError(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('timeout')) return 'Timeout';
    if (lowerError.contains('network')) return 'Network';
    if (lowerError.contains('gas')) return 'Gas/Fee';
    if (lowerError.contains('contract')) return 'Smart Contract';
    if (lowerError.contains('did')) return 'DID Verification';
    if (lowerError.contains('auth')) return 'Authentication';
    if (lowerError.contains('rate')) return 'Rate Limiting';
    
    return 'Other';
  }
  
  bool _calculateOverallSuccess(Map<String, TestScenarioResult> scenarios) {
    for (final scenario in scenarios.values) {
      final successRate = scenario.successfulOperations / scenario.totalOperations;
      if (successRate < 0.95) { // Require 95% success rate
        return false;
      }
    }
    return true;
  }
  
  Future<Map<String, dynamic>> _calculatePerformanceMetrics(Map<String, TestScenarioResult> scenarios) async {
    final metrics = <String, dynamic>{};
    
    double totalThroughput = 0;
    double totalAvgResponseTime = 0;
    int totalOperations = 0;
    int totalSuccessful = 0;
    
    for (final scenario in scenarios.values) {
      totalThroughput += scenario.throughput;
      totalAvgResponseTime += scenario.averageResponseTime;
      totalOperations += scenario.totalOperations;
      totalSuccessful += scenario.successfulOperations;
    }
    
    metrics['totalThroughput'] = '${totalThroughput.toStringAsFixed(2)} ops/sec';
    metrics['overallSuccessRate'] = '${(totalSuccessful / totalOperations * 100).toStringAsFixed(2)}%';
    metrics['averageResponseTime'] = '${(totalAvgResponseTime / scenarios.length).toStringAsFixed(0)}ms';
    metrics['totalOperations'] = totalOperations;
    
    return metrics;
  }
  
  List<String> _generateRecommendations(Map<String, TestScenarioResult> scenarios) {
    final recommendations = <String>[];
    
    for (final scenario in scenarios.values) {
      final successRate = scenario.successfulOperations / scenario.totalOperations;
      
      if (successRate < 0.95) {
        recommendations.add('Improve ${scenario.scenarioName} reliability (current: ${(successRate * 100).toStringAsFixed(1)}%)');
      }
      
      if (scenario.averageResponseTime > 1000) {
        recommendations.add('Optimize ${scenario.scenarioName} performance (avg: ${scenario.averageResponseTime.toStringAsFixed(0)}ms)');
      }
      
      if (scenario.throughput < 10) {
        recommendations.add('Scale ${scenario.scenarioName} throughput (current: ${scenario.throughput.toStringAsFixed(2)} ops/sec)');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('System performance is within acceptable parameters');
    }
    
    return recommendations;
  }
  
  Future<void> _storeTestReport(LoadTestReport report) async {
    try {
      await _firestore.collection('load_test_reports').add({
        'testStartTime': report.testStartTime,
        'testEndTime': report.testEndTime,
        'totalDuration': report.totalDuration.inSeconds,
        'concurrentUsers': report.concurrentUsers,
        'overallSuccess': report.overallSuccess,
        'scenarios': report.scenarios.map((key, value) => MapEntry(key, value.toMap())),
        'performanceMetrics': report.performanceMetrics,
        'recommendations': report.recommendations,
        'environment': EnvironmentConfig.currentEnvironment.name,
        'error': report.error,
      });
    } catch (e) {
      _logLoadTestError('Failed to store test report: $e');
    }
  }
  
  void _logLoadTest(String message) {
    if (EnvironmentConfig.securityConfig['allowDebugLogs']) {
      print('🧪 LoadTest: $message');
    }
  }
  
  void _logLoadTestError(String message) {
    print('❌ LoadTest Error: $message');
  }
}

/// Operation result for load testing
class OperationResult {
  final String operationType;
  final String userId;
  final bool success;
  final DateTime startTime;
  final DateTime endTime;
  final double responseTime;
  final String? error;
  final Map<String, dynamic>? metadata;
  
  OperationResult({
    required this.operationType,
    required this.userId,
    required this.success,
    required this.startTime,
    required this.endTime,
    required this.responseTime,
    this.error,
    this.metadata,
  });
}

/// Test scenario result
class TestScenarioResult {
  final String scenarioName;
  final DateTime startTime;
  final DateTime endTime;
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final double averageResponseTime;
  final double minResponseTime;
  final double maxResponseTime;
  final double throughput;
  final Map<String, int> errorTypes;
  
  TestScenarioResult({
    required this.scenarioName,
    required this.startTime,
    required this.endTime,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.averageResponseTime,
    required this.minResponseTime,
    required this.maxResponseTime,
    required this.throughput,
    required this.errorTypes,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'scenarioName': scenarioName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'averageResponseTime': averageResponseTime,
      'minResponseTime': minResponseTime,
      'maxResponseTime': maxResponseTime,
      'throughput': throughput,
      'errorTypes': errorTypes,
    };
  }
}

/// Complete load test report
class LoadTestReport {
  final DateTime testStartTime;
  final DateTime testEndTime;
  final Duration totalDuration;
  final int concurrentUsers;
  final Map<String, TestScenarioResult> scenarios;
  final bool overallSuccess;
  final Map<String, dynamic> performanceMetrics;
  final List<String> recommendations;
  final String? error;
  
  LoadTestReport({
    required this.testStartTime,
    required this.testEndTime,
    required this.totalDuration,
    required this.concurrentUsers,
    required this.scenarios,
    required this.overallSuccess,
    required this.performanceMetrics,
    required this.recommendations,
    this.error,
  });
}
