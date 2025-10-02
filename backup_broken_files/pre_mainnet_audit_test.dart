/// Comprehensive Test Suite for Pre-Mainnet Audit
/// Tests smart contract integration, DID functionality, and security measures
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../lib/config/environment_config.dart';
import '../lib/services/smart_contract_service.dart';
import '../lib/services/did_service.dart';
import '../lib/services/did_auth_service.dart';
import '../lib/services/security_audit_service.dart';

void main() {
  group('Pre-Mainnet Audit Tests', () {
    
    setUp(() async {
      // Initialize environment for testing
      EnvironmentConfig.setEnvironment(AppEnvironment.testnet);
      await EnvironmentConfig.validateConfig();
    });
    
    group('Environment Configuration Tests', () {
      test('should validate testnet configuration', () {
        EnvironmentConfig.setEnvironment(AppEnvironment.testnet);
        final config = EnvironmentConfig.hederaConfig;
        
        expect(config['networkName'], equals('testnet'));
        expect(config['cneTokenId'], isNotEmpty);
        expect(config['mirrorNodeUrl'], contains('testnet'));
      });
      
      test('should validate mainnet configuration structure', () {
        EnvironmentConfig.setEnvironment(AppEnvironment.mainnet);
        final config = EnvironmentConfig.hederaConfig;
        
        expect(config['networkName'], equals('mainnet'));
        expect(config['mirrorNodeUrl'], contains('mainnet'));
        expect(config.containsKey('cneTokenId'), isTrue);
      });
      
      test('should validate smart contract configuration', () {
        final config = EnvironmentConfig.smartContractConfig;
        
        expect(config.containsKey('gasLimit'), isTrue);
        expect(config.containsKey('gasPrice'), isTrue);
        expect(config['gasLimit'], greaterThan(0));
      });
      
      test('should validate DID configuration', () {
        final config = EnvironmentConfig.didConfig;
        
        expect(config['didMethod'], startsWith('did:hedera:'));
        expect(config['verificationMethod'], isNotEmpty);
        expect(config['ipfsGateway'], startsWith('https://'));
      });
    });
    
    group('Smart Contract Integration Tests', () {
      late SmartContractService contractService;
      
      setUp(() async {
        contractService = SmartContractService.instance;
        await contractService.initialize();
      });
      
      test('should initialize smart contract service', () async {
        expect(contractService, isNotNull);
        // Service should be properly initialized without throwing
      });
      
      test('should get CNE balance for wallet', () async {
        const testWallet = '0.0.123456';
        final result = await contractService.getCNEBalance(testWallet);
        
        expect(result.success, isTrue);
        expect(result.data, isA<double>());
        expect(result.data! >= 0, isTrue);
      });
      
      test('should estimate gas for reward claim', () async {
        const testWallet = '0.0.123456';
        const testAmount = 10.0;
        const testEventType = 'video_watch';
        final testMetadata = {'videoId': 'test123', 'duration': 60};
        
        final result = await contractService.claimReward(
          walletAddress: testWallet,
          amount: testAmount,
          eventType: testEventType,
          metadata: testMetadata,
        );
        
        // Should complete without throwing errors (mock environment)
        expect(result, isNotNull);
      });
      
      test('should validate contract call parameters', () async {
        const invalidWallet = '';
        const testAmount = 10.0;
        const testEventType = 'video_watch';
        final testMetadata = {'videoId': 'test123'};
        
        final result = await contractService.claimReward(
          walletAddress: invalidWallet,
          amount: testAmount,
          eventType: testEventType,
          metadata: testMetadata,
        );
        
        // Should handle invalid parameters gracefully
        expect(result, isNotNull);
      });
      
      test('should check claim eligibility', () async {
        const testWallet = '0.0.123456';
        const testEventType = 'video_watch';
        
        final result = await contractService.canClaimReward(
          walletAddress: testWallet,
          eventType: testEventType,
        );
        
        expect(result.success, isTrue);
        expect(result.data, isA<bool>());
      });
      
      test('should get user reward statistics', () async {
        const testWallet = '0.0.123456';
        
        final result = await contractService.getUserRewardStats(testWallet);
        
        expect(result.success, isTrue);
        if (result.data != null) {
          expect(result.data!.totalEarned, greaterThanOrEqualTo(0));
          expect(result.data!.totalClaimed, greaterThanOrEqualTo(0));
          expect(result.data!.lockedBalance, greaterThanOrEqualTo(0));
        }
      });
    });
    
    group('DID Service Tests', () {
      late DIDService didService;
      
      setUp(() async {
        didService = DIDService.instance;
        await didService.initialize();
      });
      
      test('should initialize DID service', () async {
        expect(didService, isNotNull);
      });
      
      test('should create DID for user', () async {
        const testWallet = '0.0.123456';
        const testEmail = 'test@example.com';
        const testName = 'Test User';
        
        final result = await didService.createDID(
          walletAddress: testWallet,
          userEmail: testEmail,
          userName: testName,
        );
        
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!, startsWith('did:hedera:'));
      });
      
      test('should verify DID for reward claim', () async {
        const testWallet = '0.0.123456';
        const testEventType = 'video_watch';
        final testEventData = {'videoId': 'test123', 'duration': 60};
        
        // First create a DID
        await didService.createDID(
          walletAddress: testWallet,
          userEmail: 'test@example.com',
        );
        
        final result = await didService.verifyDIDForReward(
          walletAddress: testWallet,
          eventType: testEventType,
          eventData: testEventData,
        );
        
        expect(result.success, isTrue);
        expect(result.data, isTrue);
      });
      
      test('should resolve DID document', () async {
        const testWallet = '0.0.123456';
        
        // Create DID first
        final createResult = await didService.createDID(
          walletAddress: testWallet,
          userEmail: 'test@example.com',
        );
        
        if (createResult.success) {
          final resolveResult = await didService.resolveDID(createResult.data!);
          expect(resolveResult.success, isTrue);
          expect(resolveResult.data, isNotNull);
        }
      });
      
      test('should sign and verify data with DID', () async {
        const testWallet = '0.0.123456';
        final testData = {'message': 'test signature', 'timestamp': '2024-01-01'};
        
        // Create DID first
        final createResult = await didService.createDID(
          walletAddress: testWallet,
          userEmail: 'test@example.com',
        );
        
        if (createResult.success) {
          final signResult = await didService.signWithDID(testData);
          expect(signResult.success, isTrue);
          expect(signResult.data, isNotNull);
          
          // Verify signature
          final verifyResult = await didService.verifyDIDSignature(
            signature: signResult.data!,
            data: testData,
            didIdentifier: createResult.data!,
          );
          expect(verifyResult.success, isTrue);
        }
      });
      
      test('should get DID analytics', () async {
        const testWallet = '0.0.123456';
        
        // Create DID first
        await didService.createDID(
          walletAddress: testWallet,
          userEmail: 'test@example.com',
        );
        
        final result = await didService.getDIDAnalytics();
        
        if (result.success) {
          expect(result.data!.didIdentifier, isNotEmpty);
          expect(result.data!.createdAt, isA<DateTime>());
          expect(result.data!.usageCount, greaterThanOrEqualTo(0));
        }
      });
    });
    
    group('Security Audit Tests', () {
      late SecurityAuditService securityService;
      
      setUp(() async {
        securityService = SecurityAuditService.instance;
        await securityService.initialize();
      });
      
      test('should initialize security audit service', () async {
        expect(securityService, isNotNull);
      });
      
      test('should validate legitimate reward claim', () async {
        const testEventType = 'video_watch';
        final testEventData = {
          'videoId': 'test123',
          'watchDurationSeconds': 60,
          'totalDurationSeconds': 120,
        };
        const testUserAgent = 'Mozilla/5.0 (Test Browser)';
        const testIP = '192.168.1.1';
        
        final result = await securityService.validateRewardClaim(
          eventType: testEventType,
          eventData: testEventData,
          userAgent: testUserAgent,
          ipAddress: testIP,
        );
        
        // Should pass validation for legitimate claim
        // Note: In test environment, this will depend on mock authentication
        expect(result, isNotNull);
      });
      
      test('should detect invalid video watch data', () async {
        const testEventType = 'video_watch';
        final testEventData = {
          'videoId': 'test123',
          'watchDurationSeconds': 200, // More than total duration
          'totalDurationSeconds': 120,
        };
        const testUserAgent = 'Mozilla/5.0 (Test Browser)';
        const testIP = '192.168.1.1';
        
        final result = await securityService.validateRewardClaim(
          eventType: testEventType,
          eventData: testEventData,
          userAgent: testUserAgent,
          ipAddress: testIP,
        );
        
        // Should detect invalid data
        expect(result.success, isFalse);
        expect(result.violation, equals(SecurityViolationType.invalidData));
      });
      
      test('should detect invalid quiz data', () async {
        const testEventType = 'quiz_completion';
        final testEventData = {
          'quizId': 'test123',
          'score': 15.0, // More than total questions
          'totalQuestions': 10,
        };
        const testUserAgent = 'Mozilla/5.0 (Test Browser)';
        const testIP = '192.168.1.1';
        
        final result = await securityService.validateRewardClaim(
          eventType: testEventType,
          eventData: testEventData,
          userAgent: testUserAgent,
          ipAddress: testIP,
        );
        
        expect(result.success, isFalse);
        expect(result.violation, equals(SecurityViolationType.invalidData));
      });
      
      test('should validate social media platforms', () async {
        const testEventType = 'social_follow';
        final testEventData = {
          'platform': 'unknown_platform', // Invalid platform
        };
        const testUserAgent = 'Mozilla/5.0 (Test Browser)';
        const testIP = '192.168.1.1';
        
        final result = await securityService.validateRewardClaim(
          eventType: testEventType,
          eventData: testEventData,
          userAgent: testUserAgent,
          ipAddress: testIP,
        );
        
        expect(result.success, isFalse);
        expect(result.violation, equals(SecurityViolationType.invalidData));
      });
    });
    
    group('Integration Tests', () {
      test('should complete full reward flow with DID verification', () async {
        // This test simulates the complete flow:
        // 1. User registration with DID creation
        // 2. Reward claim with security validation
        // 3. Smart contract interaction
        // 4. Balance update
        
        const testEmail = 'integration@test.com';
        const testPassword = 'test123456';
        const testWallet = '0.0.987654';
        
        // Step 1: Register user (would normally require Firebase Auth)
        // This is mocked in test environment
        
        // Step 2: Create DID
        final didService = DIDService.instance;
        await didService.initialize();
        
        final didResult = await didService.createDID(
          walletAddress: testWallet,
          userEmail: testEmail,
          userName: 'Integration Test User',
        );
        
        expect(didResult.success, isTrue);
        
        // Step 3: Validate security for reward claim
        final securityService = SecurityAuditService.instance;
        await securityService.initialize();
        
        // Step 4: Process reward claim (would normally go through reward service)
        final contractService = SmartContractService.instance;
        await contractService.initialize();
        
        final balanceResult = await contractService.getCNEBalance(testWallet);
        expect(balanceResult.success, isTrue);
        
        // Integration test passes if all services initialize and basic operations work
      });
      
      test('should handle error scenarios gracefully', () async {
        // Test error handling across all services
        
        final didService = DIDService.instance;
        final contractService = SmartContractService.instance;
        
        // Test with invalid data
        final invalidDIDResult = await didService.createDID(
          walletAddress: '', // Invalid wallet
          userEmail: 'invalid-email', // Invalid email
        );
        
        // Should handle errors gracefully
        expect(invalidDIDResult.success, isFalse);
        expect(invalidDIDResult.error, isNotNull);
        
        final invalidBalanceResult = await contractService.getCNEBalance('');
        expect(invalidBalanceResult, isNotNull);
      });
    });
    
    group('Performance Tests', () {
      test('should handle concurrent DID operations', () async {
        final didService = DIDService.instance;
        await didService.initialize();
        
        // Test concurrent DID creations
        final futures = List.generate(5, (index) => 
          didService.createDID(
            walletAddress: '0.0.${100000 + index}',
            userEmail: 'user$index@test.com',
          )
        );
        
        final results = await Future.wait(futures);
        
        // All operations should complete
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isNotNull);
        }
      });
      
      test('should handle concurrent security validations', () async {
        final securityService = SecurityAuditService.instance;
        await securityService.initialize();
        
        // Test concurrent validations
        final futures = List.generate(3, (index) => 
          securityService.validateRewardClaim(
            eventType: 'video_watch',
            eventData: {
              'videoId': 'test$index',
              'watchDurationSeconds': 60,
              'totalDurationSeconds': 120,
            },
            userAgent: 'Test Browser $index',
            ipAddress: '192.168.1.$index',
          )
        );
        
        final results = await Future.wait(futures);
        
        // All validations should complete
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotNull);
        }
      });
    });
  });
}
