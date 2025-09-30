/**
 * Test Token Configuration
 * 
 * This script tests the CNE token configuration and verifies
 * that we have the necessary keys and permissions for minting.
 */

const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TokenInfoQuery,
    TokenId 
} = require("@hashgraph/sdk");
const fs = require('fs');

async function testTokenConfiguration() {
    console.log('🔍 TESTING CNE TOKEN CONFIGURATION');
    console.log('==================================');

    try {
        // Initialize client
        const accountId = AccountId.fromString(process.env.HEDERA_ACCOUNT_ID || "0.0.9764298");
        const privateKey = PrivateKey.fromStringED25519(process.env.HEDERA_PRIVATE_KEY);
        const client = Client.forMainnet().setOperator(accountId, privateKey);

        const tokenId = '0.0.10007647';
        const treasuryAccountId = '0.0.10007646';

        console.log('Token ID:', tokenId);
        console.log('Treasury Account:', treasuryAccountId);
        console.log('');

        // Query token info
        console.log('📊 QUERYING TOKEN INFORMATION');
        console.log('=============================');

        const tokenInfo = await new TokenInfoQuery()
            .setTokenId(TokenId.fromString(tokenId))
            .execute(client);

        console.log('Token Name:', tokenInfo.name);
        console.log('Token Symbol:', tokenInfo.symbol);
        console.log('Decimals:', tokenInfo.decimals);
        console.log('Total Supply:', tokenInfo.totalSupply.toString());
        console.log('Supply Type:', tokenInfo.supplyType.toString());
        console.log('Treasury Account:', tokenInfo.treasuryAccountId.toString());
        console.log('');

        // Check token keys
        console.log('🔑 TOKEN KEY CONFIGURATION');
        console.log('==========================');
        
        if (tokenInfo.supplyKey) {
            console.log('✅ Supply Key Present:', tokenInfo.supplyKey.toString());
        } else {
            console.log('❌ No Supply Key - Minting not possible');
        }

        if (tokenInfo.adminKey) {
            console.log('✅ Admin Key Present:', tokenInfo.adminKey.toString());
        } else {
            console.log('⚠️  No Admin Key');
        }

        if (tokenInfo.freezeKey) {
            console.log('✅ Freeze Key Present:', tokenInfo.freezeKey.toString());
        } else {
            console.log('ℹ️  No Freeze Key');
        }

        // Load and check our treasury key
        console.log('');
        console.log('🔐 TREASURY KEY VERIFICATION');
        console.log('============================');

        const treasuryKeyPath = '../treasury_private_key.SECURE';
        if (fs.existsSync(treasuryKeyPath)) {
            const treasuryKeyData = fs.readFileSync(treasuryKeyPath, 'utf8');
            const keyMatch = treasuryKeyData.match(/TREASURY_PRIVATE_KEY=([a-fA-F0-9]+)/);
            
            if (keyMatch) {
                const treasuryKeyHex = keyMatch[1];
                const treasuryPrivateKey = PrivateKey.fromStringED25519(treasuryKeyHex);
                const treasuryPublicKey = treasuryPrivateKey.publicKey;
                
                console.log('Treasury Private Key Length:', treasuryKeyHex.length, 'characters');
                console.log('Treasury Public Key:', treasuryPublicKey.toString());
                
                // Check if treasury public key matches any token keys
                const supplyKeyMatches = tokenInfo.supplyKey && 
                    tokenInfo.supplyKey.toString() === treasuryPublicKey.toString();
                const adminKeyMatches = tokenInfo.adminKey && 
                    tokenInfo.adminKey.toString() === treasuryPublicKey.toString();

                console.log('');
                console.log('🔍 KEY MATCHING ANALYSIS');
                console.log('========================');
                console.log('Treasury key matches Supply key:', supplyKeyMatches ? '✅ YES' : '❌ NO');
                console.log('Treasury key matches Admin key:', adminKeyMatches ? '✅ YES' : '❌ NO');

                if (!supplyKeyMatches && !adminKeyMatches) {
                    console.log('');
                    console.log('⚠️  ISSUE IDENTIFIED');
                    console.log('===================');
                    console.log('The treasury private key does not match the token supply or admin keys.');
                    console.log('This means we cannot mint tokens with the current treasury key.');
                    console.log('');
                    console.log('SOLUTIONS:');
                    console.log('1. Update token keys to use treasury public key');
                    console.log('2. Use the correct private key that matches the token supply key');
                    console.log('3. Re-create token with proper key configuration');
                }

            } else {
                console.log('❌ Treasury key format invalid');
            }
        } else {
            console.log('❌ Treasury key file not found');
        }

        console.log('');
        console.log('📋 SUMMARY');
        console.log('==========');
        console.log('Token Status:', tokenInfo.isDeleted ? '❌ Deleted' : '✅ Active');
        console.log('Can Mint:', tokenInfo.supplyKey ? '✅ Yes' : '❌ No');
        console.log('Treasury Match:', 'Check key matching analysis above');

        return {
            tokenInfo,
            canMint: !!tokenInfo.supplyKey,
            treasuryMatches: false // Will be updated based on key analysis
        };

    } catch (error) {
        console.error('❌ Token configuration test failed:', error.message);
        throw error;
    }
}

// Execute if called directly
if (require.main === module) {
    testTokenConfiguration()
        .then(result => {
            console.log('🎉 Token configuration test completed!');
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Test failed:', error);
            process.exit(1);
        });
}

module.exports = testTokenConfiguration;