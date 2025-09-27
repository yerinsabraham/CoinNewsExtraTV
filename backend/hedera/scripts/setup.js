// setup.js - Complete Hedera testnet setup for Play Extra
const fs = require('fs');
const path = require('path');
const { createCNETestToken } = require('./createToken');
const { createHCSTopic } = require('./createTopic');

/**
 * Interactive setup script for Hedera testnet integration
 */
async function setupHederaEnvironment() {
    console.log('🎮 Play Extra - Hedera Testnet Setup');
    console.log('=====================================\n');
    
    try {
        // Step 1: Check .env file
        console.log('📋 Step 1: Checking environment configuration...');
        const envPath = path.join(__dirname, '..', '.env');
        
        if (!fs.existsSync(envPath)) {
            console.log('❌ .env file not found!');
            console.log('📝 Please copy .env.template to .env and fill in your credentials');
            console.log('🌐 Get testnet credentials from: https://portal.hedera.com');
            return;
        }
        
        // Load and validate env
        require('dotenv').config();
        
        const operatorId = process.env.HEDERA_OPERATOR_ID;
        const operatorKey = process.env.HEDERA_OPERATOR_KEY;
        
        if (!operatorId || operatorId === '0.0.PLACEHOLDER') {
            console.log('❌ HEDERA_OPERATOR_ID not configured in .env');
            console.log('🌐 Get your testnet account from: https://portal.hedera.com');
            return;
        }
        
        if (!operatorKey || operatorKey === 'PLACEHOLDER_KEY') {
            console.log('❌ HEDERA_OPERATOR_KEY not configured in .env');
            console.log('🔑 Add your private key to .env file');
            return;
        }
        
        console.log(`✅ Environment configured for account: ${operatorId}`);
        
        // Step 2: Test connection
        console.log('\n📡 Step 2: Testing Hedera connection...');
        const { testConnection } = require('../src/hederaClient');
        const connectionOk = await testConnection();
        
        if (!connectionOk) {
            console.log('❌ Connection failed! Please check your credentials and HBAR balance.');
            return;
        }
        
        // Step 3: Create CNE test token
        console.log('\n🪙 Step 3: Creating CNE test token...');
        let tokenResult;
        try {
            tokenResult = await createCNETestToken();
            console.log('✅ CNE test token created successfully');
            
            // Update .env with token ID
            await updateEnvFile('CNE_TEST_TOKEN_ID', tokenResult.tokenId);
            
        } catch (error) {
            console.error('❌ Token creation failed:', error.message);
            return;
        }
        
        // Step 4: Create HCS topic
        console.log('\n📡 Step 4: Creating HCS topic for transparency...');
        let topicResult;
        try {
            topicResult = await createHCSTopic();
            console.log('✅ HCS topic created successfully');
            
            // Update .env with topic ID
            await updateEnvFile('HCS_TOPIC_ID', topicResult.topicId);
            
        } catch (error) {
            console.error('❌ Topic creation failed:', error.message);
            return;
        }
        
        // Step 5: Summary
        console.log('\n🎉 Setup completed successfully!');
        console.log('================================');
        console.log(`🪙 CNE Test Token: ${tokenResult.tokenId}`);
        console.log(`📡 HCS Topic: ${topicResult.topicId}`);
        console.log(`💰 Initial Supply: 1,000,000 CNE_TEST`);
        console.log(`🏦 Treasury: ${operatorId}`);
        
        console.log('\n📋 Your .env file has been updated with:');
        console.log(`CNE_TEST_TOKEN_ID=${tokenResult.tokenId}`);
        console.log(`HCS_TOPIC_ID=${topicResult.topicId}`);
        
        console.log('\n🚀 Next steps:');
        console.log('1. Start the Hedera-enabled backend server');
        console.log('2. Test the end-to-end battle flow');
        console.log('3. Integrate wallet connect for frontend');
        console.log('4. Fund user accounts for testing');
        
        console.log('\n💡 Useful commands:');
        console.log(`- Subscribe to HCS messages: node scripts/createTopic.js subscribe ${topicResult.topicId}`);
        console.log('- Test backend: npm run test');
        console.log('- Monitor transactions: https://hashscan.io/testnet');
        
        return {
            success: true,
            tokenId: tokenResult.tokenId,
            topicId: topicResult.topicId
        };
        
    } catch (error) {
        console.error('\n💥 Setup failed:', error.message);
        console.error('\n🔍 Common issues:');
        console.error('- Insufficient HBAR balance (get from faucet)');
        console.error('- Invalid private key format');
        console.error('- Network connectivity issues');
        console.error('- Hedera service temporarily unavailable');
        
        return { success: false, error: error.message };
    }
}

/**
 * Update .env file with new values
 */
async function updateEnvFile(key, value) {
    const envPath = path.join(__dirname, '..', '.env');
    let envContent = fs.readFileSync(envPath, 'utf8');
    
    const regex = new RegExp(`^${key}=.*$`, 'm');
    if (regex.test(envContent)) {
        envContent = envContent.replace(regex, `${key}=${value}`);
    } else {
        envContent += `\n${key}=${value}`;
    }
    
    fs.writeFileSync(envPath, envContent);
    console.log(`📝 Updated .env: ${key}=${value}`);
}

// Run setup if this script is executed directly
if (require.main === module) {
    setupHederaEnvironment()
        .then((result) => {
            if (result.success) {
                console.log('\n✨ Hedera setup completed successfully!');
                process.exit(0);
            } else {
                console.log('\n💥 Setup failed. Please check the errors above.');
                process.exit(1);
            }
        })
        .catch((error) => {
            console.error('\n💥 Unexpected error:', error.message);
            process.exit(1);
        });
}

module.exports = { setupHederaEnvironment };
