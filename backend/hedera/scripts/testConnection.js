// testConnection.js - Test Hedera testnet connection and basic operations
const { testConnection } = require('../src/hederaClient');

async function runConnectionTest() {
    console.log('🔧 Testing Hedera testnet connection...\n');
    
    try {
        const success = await testConnection();
        
        if (success) {
            console.log('\n✅ All connection tests passed!');
            console.log('🎉 Your Hedera environment is ready for Play Extra integration.');
            console.log('\n📋 Next steps:');
            console.log('1. Run: node scripts/createToken.js');
            console.log('2. Run: node scripts/createTopic.js');
            console.log('3. Update your .env file with the generated IDs');
            console.log('4. Start integrating with the backend API');
        } else {
            console.log('\n❌ Connection test failed!');
            console.log('💡 Please check your .env configuration and try again.');
        }
        
    } catch (error) {
        console.error('\n💥 Connection test error:', error.message);
        console.error('\n🔍 Troubleshooting steps:');
        console.error('1. Check your .env file has valid Hedera credentials');
        console.error('2. Ensure your testnet account has HBAR (use faucet)');
        console.error('3. Verify your account ID and private key format');
        console.error('4. Visit https://portal.hedera.com for account setup');
    }
}

// Run the test
runConnectionTest();
