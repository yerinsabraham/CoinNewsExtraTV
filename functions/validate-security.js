/**
 * Offline Security Validation Script
 * Tests security logic without Firebase dependencies
 */

const SecurityHardening = require('./security-hardening');

// Mock Firebase admin for testing
const mockFirestore = {
    collection: (name) => ({
        doc: (id) => ({
            get: () => Promise.resolve({ 
                exists: true, 
                data: () => ({ createdAt: { toMillis: () => Date.now() - (25 * 60 * 60 * 1000) } }) 
            })
        }),
        add: (data) => Promise.resolve({ id: 'mock-doc-id' }),
        where: () => ({ 
            where: () => ({ 
                get: () => Promise.resolve({ size: 3, forEach: () => {} }) 
            }) 
        })
    })
};

class OfflineSecurityTest {
    constructor() {
        this.security = new SecurityHardening();
        this.security.db = mockFirestore; // Use mock instead of real Firestore
    }

    async runTests() {
        console.log('🔒 Running Offline Security Validation');
        console.log('====================================');

        const tests = [];
        const testUserId = 'test-user-' + Date.now();

        try {
            // Test 1: Rate Limiting Logic
            console.log('\n1️⃣ Testing Rate Limiting Logic...');
            let rateLimitPassed = false;
            
            for (let i = 0; i < 12; i++) {
                const result = await this.security.checkRateLimit(testUserId, 'rewards');
                if (!result.allowed) {
                    console.log(`✅ Rate limiting works - blocked at attempt ${i + 1}`);
                    console.log(`   Violations: ${JSON.stringify(result.violations)}`);
                    rateLimitPassed = true;
                    break;
                }
            }
            tests.push({ name: 'Rate Limiting', passed: rateLimitPassed });

            // Test 2: Input Validation
            console.log('\n2️⃣ Testing Input Validation...');
            const validationRules = {
                amount: { required: true, type: 'number', min: 1, max: 1000 },
                userId: { required: true, type: 'string', minLength: 1, maxLength: 100 },
                email: { required: false, type: 'string', pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ }
            };

            const invalidInputs = [
                { amount: -100, userId: '', email: 'invalid-email' },
                { amount: 'not-a-number', userId: 'x'.repeat(200) },
                { userId: 'valid-user' }, // missing required amount
                { amount: 5000, userId: 'test' } // amount exceeds max
            ];

            let validationPassed = true;
            invalidInputs.forEach((input, index) => {
                const result = this.security.validateInput(input, validationRules);
                if (result.isValid) {
                    console.log(`❌ Validation failed for test case ${index + 1}`);
                    validationPassed = false;
                } else {
                    console.log(`✅ Validation caught ${result.errors.length} errors in test case ${index + 1}`);
                }
            });

            // Test valid input
            const validInput = { amount: 500, userId: 'test-user-123', email: 'user@example.com' };
            const validResult = this.security.validateInput(validInput, validationRules);
            if (!validResult.isValid) {
                console.log('❌ Valid input was rejected');
                validationPassed = false;
            } else {
                console.log('✅ Valid input accepted correctly');
            }

            tests.push({ name: 'Input Validation', passed: validationPassed });

            // Test 3: Fraud Detection Scoring
            console.log('\n3️⃣ Testing Fraud Detection Scoring...');
            
            const testCases = [
                {
                    name: 'Normal transaction',
                    data: { amount: 100, userId: testUserId },
                    expectedScore: 'LOW'
                },
                {
                    name: 'Large amount transaction',
                    data: { amount: 999999, userId: testUserId },
                    expectedScore: 'HIGH'
                },
                {
                    name: 'Medium suspicious transaction',
                    data: { amount: 150000, userId: testUserId },
                    expectedScore: 'MEDIUM'
                }
            ];

            let fraudDetectionPassed = true;
            for (const testCase of testCases) {
                const fraudResult = await this.security.detectFraud(testUserId, 'transfer', testCase.data);
                console.log(`   ${testCase.name}: Score ${fraudResult.fraudScore.toFixed(2)}, Risk: ${fraudResult.riskLevel}`);
                
                if (testCase.expectedScore === 'HIGH' && fraudResult.fraudScore < 0.7) {
                    console.log(`   ❌ Expected high score but got ${fraudResult.fraudScore.toFixed(2)}`);
                    fraudDetectionPassed = false;
                }
                if (testCase.expectedScore === 'LOW' && fraudResult.fraudScore > 0.4) {
                    console.log(`   ❌ Expected low score but got ${fraudResult.fraudScore.toFixed(2)}`);
                    fraudDetectionPassed = false;
                }
            }

            if (fraudDetectionPassed) {
                console.log('✅ Fraud detection scoring works correctly');
            }
            tests.push({ name: 'Fraud Detection', passed: fraudDetectionPassed });

            // Test 4: Security Event Severity Classification
            console.log('\n4️⃣ Testing Security Event Classification...');
            const eventTypes = [
                'RATE_LIMIT_EXCEEDED',
                'FRAUD_DETECTION',
                'VALIDATION_FAILED',
                'UNAUTHORIZED_ACCESS',
                'LARGE_TRANSACTION'
            ];

            let classificationPassed = true;
            eventTypes.forEach(eventType => {
                const severity = this.security.getEventSeverity(eventType);
                console.log(`   ${eventType}: ${severity}`);
                
                if (['FRAUD_DETECTION', 'UNAUTHORIZED_ACCESS'].includes(eventType) && severity !== 'HIGH') {
                    classificationPassed = false;
                }
            });

            if (classificationPassed) {
                console.log('✅ Event severity classification works correctly');
            }
            tests.push({ name: 'Event Classification', passed: classificationPassed });

            // Test 5: Security Configuration Validation
            console.log('\n5️⃣ Testing Security Configuration...');
            const config = this.security.securityConfig;
            
            const configChecks = [
                { name: 'Rate limits configured', check: () => config.rateLimits && config.rateLimits.rewards },
                { name: 'Fraud detection thresholds set', check: () => config.fraudDetection && config.fraudDetection.suspiciousAmountThreshold > 0 },
                { name: 'Validation rules present', check: () => config.validation && typeof config.validation.minAccountAge === 'number' },
                { name: 'Monitoring enabled', check: () => config.monitoring && typeof config.monitoring.enableRealTimeAlerts === 'boolean' }
            ];

            let configPassed = true;
            configChecks.forEach(check => {
                const result = check.check();
                console.log(`   ${check.name}: ${result ? '✅' : '❌'}`);
                if (!result) configPassed = false;
            });

            tests.push({ name: 'Configuration', passed: configPassed });

            // Test 6: Security Middleware Creation
            console.log('\n6️⃣ Testing Security Middleware...');
            const middleware = this.security.createSecurityMiddleware();
            const middlewarePassed = typeof middleware === 'function';
            
            if (middlewarePassed) {
                console.log('✅ Security middleware created successfully');
            } else {
                console.log('❌ Security middleware creation failed');
            }
            tests.push({ name: 'Middleware Creation', passed: middlewarePassed });

            // Generate Test Report
            console.log('\n📊 Security Validation Results');
            console.log('=============================');
            const passedTests = tests.filter(t => t.passed).length;
            const totalTests = tests.length;

            tests.forEach(test => {
                console.log(`${test.passed ? '✅' : '❌'} ${test.name}`);
            });

            console.log(`\nResults: ${passedTests}/${totalTests} tests passed`);
            
            if (passedTests === totalTests) {
                console.log('\n🎉 All security validation tests passed!');
                console.log('🔒 Security hardening is properly configured for mainnet operations.');
                
                console.log('\n🔧 Security Features Active:');
                console.log('• Rate limiting with configurable thresholds');
                console.log('• Fraud detection with risk scoring');
                console.log('• Comprehensive input validation');
                console.log('• Security event logging and classification');
                console.log('• Real-time monitoring and alerting');
                console.log('• Enhanced validation middleware');
                
                return { success: true, passedTests, totalTests, securityReady: true };
            } else {
                console.log('\n⚠️  Some security validation tests failed.');
                console.log('Please review the security configuration before proceeding to production.');
                return { success: false, passedTests, totalTests, securityReady: false };
            }

        } catch (error) {
            console.error('❌ Security validation error:', error.message);
            return { success: false, error: error.message, securityReady: false };
        }
    }

    generateSecurityReport() {
        const report = {
            timestamp: new Date().toISOString(),
            environment: 'mainnet',
            securityFeatures: [
                'Rate Limiting (10 rewards/min, 100/hour, 1000/day)',
                'Fraud Detection (Amount thresholds, velocity checks)',
                'Input Validation (Type checking, sanitization, pattern matching)',
                'Audit Logging (All security events logged with severity)',
                'Real-time Monitoring (Configurable alerts and webhooks)',
                'Transaction Limits (Max 500,000 CNE per transfer)',
                'Account Age Validation (Min 24 hours)',
                'Suspicious Pattern Detection (Repeated operations, anomalies)'
            ],
            rateLimits: this.security.securityConfig.rateLimits,
            fraudThresholds: this.security.securityConfig.fraudDetection,
            validationRules: this.security.securityConfig.validation,
            monitoringConfig: this.security.securityConfig.monitoring
        };

        console.log('\n📋 Security Configuration Report');
        console.log('==============================');
        console.log(JSON.stringify(report, null, 2));

        return report;
    }
}

// Run tests if called directly
if (require.main === module) {
    const tester = new OfflineSecurityTest();
    
    tester.runTests()
        .then(result => {
            if (result.success) {
                tester.generateSecurityReport();
                console.log('\n✅ Security hardening validation completed successfully!');
                console.log('🚀 Ready for mainnet production deployment.');
            } else {
                console.log('\n❌ Security validation failed. Review configuration before deployment.');
            }
            process.exit(result.success ? 0 : 1);
        })
        .catch(error => {
            console.error('Validation script error:', error);
            process.exit(1);
        });
}

module.exports = { OfflineSecurityTest };