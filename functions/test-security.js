/**
 * Security Hardening Test Script
 * Tests all security features in mainnet environment
 */

const admin = require('firebase-admin');
const SecurityHardening = require('./security-hardening');

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID
    });
}

async function runSecurityTests() {
    console.log('🔒 Running Security Hardening Tests');
    console.log('===================================');

    const security = new SecurityHardening();
    await security.initialize();

    const testUserId = 'test-user-' + Date.now();
    const tests = [];

    try {
        // Test 1: Rate Limiting
        console.log('\n1️⃣ Testing Rate Limiting...');
        for (let i = 0; i < 12; i++) {
            const result = await security.checkRateLimit(testUserId, 'rewards');
            if (!result.allowed) {
                console.log('✅ Rate limiting works - blocked at attempt', i + 1);
                tests.push({ name: 'Rate Limiting', passed: true });
                break;
            }
        }

        // Test 2: Input Validation
        console.log('\n2️⃣ Testing Input Validation...');
        const validationRules = {
            amount: { required: true, type: 'number', min: 1, max: 1000 },
            userId: { required: true, type: 'string', minLength: 1 }
        };

        const invalidInput = { amount: -100, userId: '' };
        const validationResult = security.validateInput(invalidInput, validationRules);
        
        if (!validationResult.isValid && validationResult.errors.length > 0) {
            console.log('✅ Input validation works - caught', validationResult.errors.length, 'errors');
            tests.push({ name: 'Input Validation', passed: true });
        } else {
            console.log('❌ Input validation failed');
            tests.push({ name: 'Input Validation', passed: false });
        }

        // Test 3: Fraud Detection
        console.log('\n3️⃣ Testing Fraud Detection...');
        const suspiciousData = {
            amount: 999999, // Very large amount
            userId: testUserId
        };

        const fraudResult = await security.detectFraud(testUserId, 'transfer', suspiciousData);
        if (fraudResult.fraudScore > 0.3) {
            console.log('✅ Fraud detection works - score:', fraudResult.fraudScore.toFixed(2));
            tests.push({ name: 'Fraud Detection', passed: true });
        } else {
            console.log('❌ Fraud detection needs tuning - score too low:', fraudResult.fraudScore);
            tests.push({ name: 'Fraud Detection', passed: false });
        }

        // Test 4: Security Event Logging
        console.log('\n4️⃣ Testing Security Logging...');
        await security.logSecurityEvent('TEST_EVENT', {
            testData: 'Security system test',
            userId: testUserId,
            timestamp: Date.now()
        });
        console.log('✅ Security logging works');
        tests.push({ name: 'Security Logging', passed: true });

        // Test 5: Metrics Collection
        console.log('\n5️⃣ Testing Metrics Collection...');
        const metrics = await security.collectSecurityMetrics();
        if (metrics && typeof metrics.totalEvents === 'number') {
            console.log('✅ Metrics collection works - found', metrics.totalEvents, 'recent events');
            tests.push({ name: 'Metrics Collection', passed: true });
        } else {
            console.log('❌ Metrics collection failed');
            tests.push({ name: 'Metrics Collection', passed: false });
        }

        // Test Summary
        console.log('\n📊 Security Test Results');
        console.log('========================');
        const passedTests = tests.filter(t => t.passed).length;
        const totalTests = tests.length;

        tests.forEach(test => {
            console.log(`${test.passed ? '✅' : '❌'} ${test.name}`);
        });

        console.log(`\nResults: ${passedTests}/${totalTests} tests passed`);

        if (passedTests === totalTests) {
            console.log('\n🎉 All security tests passed! Mainnet security is ready.');
            return { success: true, passedTests, totalTests };
        } else {
            console.log('\n⚠️  Some security tests failed. Review configuration.');
            return { success: false, passedTests, totalTests };
        }

    } catch (error) {
        console.error('❌ Security test error:', error);
        return { success: false, error: error.message };
    }
}

// Run tests if called directly
if (require.main === module) {
    runSecurityTests()
        .then(result => {
            console.log('\nTest completed:', result.success ? 'SUCCESS' : 'FAILED');
            process.exit(result.success ? 0 : 1);
        })
        .catch(error => {
            console.error('Test script error:', error);
            process.exit(1);
        });
}

module.exports = { runSecurityTests };