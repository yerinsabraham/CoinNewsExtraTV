/**
 * Mainnet Configuration Test Suite
 * 
 * This script tests the updated mainnet configuration to ensure
 * all systems are properly configured and operational.
 */

const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TokenInfoQuery,
    AccountBalanceQuery,
    TopicInfoQuery,
    TokenId,
    TopicId 
} = require("@hashgraph/sdk");

class MainnetConfigTester {
    constructor() {
        this.client = null;
        this.config = {
            network: process.env.HEDERA_NETWORK || 'mainnet',
            operatorAccountId: process.env.HEDERA_ACCOUNT_ID || '0.0.9764298',
            operatorPrivateKey: process.env.HEDERA_PRIVATE_KEY,
            cneTokenId: process.env.CNE_TOKEN_ID || '0.0.10007647',
            treasuryAccountId: process.env.TREASURY_ACCOUNT_ID || '0.0.10007646',
            auditTopicId: process.env.HCS_TOPIC_ID || '0.0.10007691'
        };

        this.testResults = {
            networkConnection: false,
            operatorAccount: false,
            tokenConfiguration: false,
            treasuryAccount: false,
            auditTopic: false,
            permissions: false,
            overall: false
        };
    }

    /**
     * Initialize Hedera client and connection
     */
    async initializeClient() {
        console.log('🔌 INITIALIZING HEDERA CLIENT');
        console.log('=============================');

        try {
            const accountId = AccountId.fromString(this.config.operatorAccountId);
            const privateKey = PrivateKey.fromStringED25519(this.config.operatorPrivateKey);
            
            this.client = Client.forMainnet().setOperator(accountId, privateKey);
            
            console.log('Network:', this.config.network);
            console.log('Operator:', this.config.operatorAccountId);
            console.log('✅ Client initialized');

            this.testResults.networkConnection = true;
            return true;

        } catch (error) {
            console.error('❌ Client initialization failed:', error.message);
            return false;
        }
    }

    /**
     * Test operator account access and balance
     */
    async testOperatorAccount() {
        console.log('');
        console.log('👤 TESTING OPERATOR ACCOUNT');
        console.log('===========================');

        try {
            const accountId = AccountId.fromString(this.config.operatorAccountId);
            const balance = await new AccountBalanceQuery()
                .setAccountId(accountId)
                .execute(this.client);

            console.log('Account ID:', accountId.toString());
            console.log('HBAR Balance:', balance.hbars.toString());
            console.log('✅ Operator account accessible');

            // Check if account has sufficient HBAR for transactions
            const hbarAmount = balance.hbars.toBigNumber().toNumber();
            if (hbarAmount < 1) {
                console.log('⚠️  Low HBAR balance, may need to top up for transactions');
            }

            this.testResults.operatorAccount = true;
            return true;

        } catch (error) {
            console.error('❌ Operator account test failed:', error.message);
            return false;
        }
    }

    /**
     * Test CNE token configuration and properties
     */
    async testTokenConfiguration() {
        console.log('');
        console.log('🪙 TESTING CNE TOKEN CONFIGURATION');
        console.log('==================================');

        try {
            const tokenId = TokenId.fromString(this.config.cneTokenId);
            const tokenInfo = await new TokenInfoQuery()
                .setTokenId(tokenId)
                .execute(this.client);

            console.log('Token ID:', tokenId.toString());
            console.log('Token Name:', tokenInfo.name);
            console.log('Token Symbol:', tokenInfo.symbol);
            console.log('Decimals:', tokenInfo.decimals);
            console.log('Supply Type:', tokenInfo.supplyType.toString());
            console.log('Total Supply:', tokenInfo.totalSupply.toString());
            console.log('Treasury Account:', tokenInfo.treasuryAccountId.toString());

            // Validate token properties
            const isValid = 
                tokenInfo.symbol === 'CNE' &&
                tokenInfo.decimals === 8 &&
                tokenInfo.supplyType.toString() === 'INFINITE' &&
                tokenInfo.treasuryAccountId.toString() === this.config.treasuryAccountId;

            if (isValid) {
                console.log('✅ Token configuration valid');
                this.testResults.tokenConfiguration = true;
            } else {
                console.log('❌ Token configuration mismatch');
            }

            return isValid;

        } catch (error) {
            console.error('❌ Token configuration test failed:', error.message);
            return false;
        }
    }

    /**
     * Test treasury account access
     */
    async testTreasuryAccount() {
        console.log('');
        console.log('🏦 TESTING TREASURY ACCOUNT');
        console.log('===========================');

        try {
            const treasuryId = AccountId.fromString(this.config.treasuryAccountId);
            const balance = await new AccountBalanceQuery()
                .setAccountId(treasuryId)
                .execute(this.client);

            console.log('Treasury ID:', treasuryId.toString());
            console.log('HBAR Balance:', balance.hbars.toString());

            // Check CNE token balance
            const cneTokenId = TokenId.fromString(this.config.cneTokenId);
            const cneBalance = balance.tokens.get(cneTokenId);
            
            if (cneBalance) {
                console.log('CNE Token Balance:', cneBalance.toString());
            } else {
                console.log('CNE Token Balance: 0 (or not associated)');
            }

            console.log('✅ Treasury account accessible');
            this.testResults.treasuryAccount = true;
            return true;

        } catch (error) {
            console.error('❌ Treasury account test failed:', error.message);
            return false;
        }
    }

    /**
     * Test HCS audit topic
     */
    async testAuditTopic() {
        console.log('');
        console.log('📡 TESTING HCS AUDIT TOPIC');
        console.log('==========================');

        try {
            const topicId = TopicId.fromString(this.config.auditTopicId);
            const topicInfo = await new TopicInfoQuery()
                .setTopicId(topicId)
                .execute(this.client);

            console.log('Topic ID:', topicId.toString());
            console.log('Topic Memo:', topicInfo.topicMemo || 'None');
            console.log('Running Hash:', topicInfo.runningHash.length > 0 ? 'Present' : 'Empty');
            console.log('Sequence Number:', topicInfo.sequenceNumber.toString());

            if (topicInfo.sequenceNumber.toNumber() > 0) {
                console.log('✅ Audit topic active with messages');
            } else {
                console.log('ℹ️  Audit topic exists but no messages yet');
            }

            this.testResults.auditTopic = true;
            return true;

        } catch (error) {
            console.error('❌ Audit topic test failed:', error.message);
            return false;
        }
    }

    /**
     * Test token permissions and keys
     */
    async testTokenPermissions() {
        console.log('');
        console.log('🔑 TESTING TOKEN PERMISSIONS');
        console.log('============================');

        try {
            const tokenId = TokenId.fromString(this.config.cneTokenId);
            const tokenInfo = await new TokenInfoQuery()
                .setTokenId(tokenId)
                .execute(this.client);

            console.log('Supply Key Present:', tokenInfo.supplyKey ? '✅ Yes' : '❌ No');
            console.log('Admin Key Present:', tokenInfo.adminKey ? '✅ Yes' : '❌ No');
            console.log('Freeze Key Present:', tokenInfo.freezeKey ? '✅ Yes' : '❌ No');
            console.log('Wipe Key Present:', tokenInfo.wipeKey ? '✅ Yes' : '❌ No');

            // Check if we have necessary permissions for operations
            const canMint = !!tokenInfo.supplyKey;
            const canAdmin = !!tokenInfo.adminKey;

            console.log('');
            console.log('Permission Status:');
            console.log('Can Mint Tokens:', canMint ? '✅ Yes' : '❌ No');
            console.log('Can Admin Token:', canAdmin ? '✅ Yes' : '❌ No');

            if (canMint && canAdmin) {
                console.log('✅ Sufficient permissions for mainnet operations');
                this.testResults.permissions = true;
            } else {
                console.log('⚠️  Limited permissions may affect some operations');
            }

            return canMint; // Minimum requirement is minting capability

        } catch (error) {
            console.error('❌ Permission test failed:', error.message);
            return false;
        }
    }

    /**
     * Test environment variables and configuration
     */
    testEnvironmentConfig() {
        console.log('');
        console.log('⚙️ TESTING ENVIRONMENT CONFIGURATION');
        console.log('====================================');

        const requiredVars = {
            'HEDERA_NETWORK': this.config.network,
            'HEDERA_ACCOUNT_ID': this.config.operatorAccountId,
            'HEDERA_PRIVATE_KEY': this.config.operatorPrivateKey ? '***SET***' : 'MISSING',
            'CNE_TOKEN_ID': this.config.cneTokenId,
            'TREASURY_ACCOUNT_ID': this.config.treasuryAccountId,
            'HCS_TOPIC_ID': this.config.auditTopicId
        };

        let allSet = true;
        for (const [key, value] of Object.entries(requiredVars)) {
            const status = value && value !== 'MISSING' ? '✅' : '❌';
            console.log(`${key}: ${status} ${value}`);
            if (!value || value === 'MISSING') {
                allSet = false;
            }
        }

        console.log('');
        console.log('Configuration Status:', allSet ? '✅ Complete' : '❌ Incomplete');
        return allSet;
    }

    /**
     * Generate test report
     */
    generateReport() {
        console.log('');
        console.log('📊 MAINNET CONFIGURATION TEST REPORT');
        console.log('====================================');
        console.log('');

        // Check if all critical tests passed (excluding overall which is calculated)
        const criticalTests = Object.keys(this.testResults).filter(key => key !== 'overall');
        const overallPass = criticalTests.every(key => this.testResults[key]);
        this.testResults.overall = overallPass;

        console.log('🔍 Test Results:');
        console.log('================');
        console.log('Network Connection:', this.testResults.networkConnection ? '✅ PASS' : '❌ FAIL');
        console.log('Operator Account:', this.testResults.operatorAccount ? '✅ PASS' : '❌ FAIL');
        console.log('Token Configuration:', this.testResults.tokenConfiguration ? '✅ PASS' : '❌ FAIL');
        console.log('Treasury Account:', this.testResults.treasuryAccount ? '✅ PASS' : '❌ FAIL');
        console.log('Audit Topic:', this.testResults.auditTopic ? '✅ PASS' : '❌ FAIL');
        console.log('Token Permissions:', this.testResults.permissions ? '✅ PASS' : '❌ FAIL');
        console.log('');
        console.log('Overall Status:', overallPass ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED');

        console.log('');
        console.log('🔗 Verification Links:');
        console.log('======================');
        console.log('Token Explorer:', `https://hashscan.io/mainnet/token/${this.config.cneTokenId}`);
        console.log('Treasury Explorer:', `https://hashscan.io/mainnet/account/${this.config.treasuryAccountId}`);
        console.log('Audit Topic:', `https://hashscan.io/mainnet/topic/${this.config.auditTopicId}`);

        if (overallPass) {
            console.log('');
            console.log('🎉 MAINNET CONFIGURATION READY');
            console.log('==============================');
            console.log('✅ All systems operational');
            console.log('✅ Ready for security hardening (Step 7)');
            console.log('✅ Ready for pilot testing (Step 8)');
        } else {
            console.log('');
            console.log('⚠️  CONFIGURATION ISSUES DETECTED');
            console.log('==================================');
            console.log('❌ Fix failing tests before proceeding');
            console.log('❌ Review configuration and network settings');
        }

        return this.testResults;
    }

    /**
     * Execute complete test suite
     */
    async execute() {
        try {
            console.log('🧪 MAINNET CONFIGURATION TEST SUITE');
            console.log('===================================');
            console.log('Testing mainnet readiness...');
            console.log('');

            // Test environment configuration
            this.testEnvironmentConfig();

            // Initialize client
            await this.initializeClient();

            // Run network tests
            await this.testOperatorAccount();
            await this.testTokenConfiguration();
            await this.testTreasuryAccount();
            await this.testAuditTopic();
            await this.testTokenPermissions();

            // Generate final report
            return this.generateReport();

        } catch (error) {
            console.error('💥 Test suite failed:', error);
            throw error;
        }
    }
}

// Execute if called directly
if (require.main === module) {
    const tester = new MainnetConfigTester();
    tester.execute()
        .then(results => {
            const success = results.overall;
            console.log(success ? '🎉 All tests passed!' : '💥 Some tests failed!');
            process.exit(success ? 0 : 1);
        })
        .catch(error => {
            console.error('💥 Test execution failed:', error);
            process.exit(1);
        });
}

module.exports = MainnetConfigTester;