// createToken.js - Create CNE_TEST token on Hedera testnet
const {
    TokenCreateTransaction,
    TokenType,
    TokenSupplyType,
    TokenMintTransaction,
    Hbar
} = require("@hashgraph/sdk");
const { client, OPERATOR_ID, operatorKey } = require('../src/hederaClient');

/**
 * Creates a test CNE token on Hedera testnet
 * This will be used for Play Extra game stakes and payouts
 */
async function createCNETestToken() {
    console.log('🎮 Creating CNE_TEST token for Play Extra...');
    
    try {
        // Create the token
        const tokenCreateTx = new TokenCreateTransaction()
            .setTokenName("CNE Test Token")
            .setTokenSymbol("CNE_TEST")
            .setDecimals(8) // Same as real CNE token
            .setInitialSupply(0) // Start with 0, will mint as needed
            .setTreasuryAccountId(OPERATOR_ID)
            .setTokenType(TokenType.FungibleCommon)
            .setSupplyType(TokenSupplyType.Infinite) // Allow unlimited minting for testing
            .setSupplyKey(operatorKey) // Allow operator to mint more tokens
            .setAdminKey(operatorKey) // Allow admin operations
            .setMaxTransactionFee(new Hbar(30)); // Set max fee for transaction

        // Freeze and sign the transaction
        const tokenCreateFreeze = await tokenCreateTx.freezeWith(client);
        const tokenCreateSign = await tokenCreateFreeze.sign(operatorKey);
        
        // Execute the transaction
        console.log('📤 Submitting token creation transaction...');
        const tokenCreateSubmit = await tokenCreateSign.execute(client);
        
        // Get the receipt
        const tokenCreateReceipt = await tokenCreateSubmit.getReceipt(client);
        const tokenId = tokenCreateReceipt.tokenId;
        
        console.log('✅ CNE_TEST token created successfully!');
        console.log(`🏷️  Token ID: ${tokenId.toString()}`);
        console.log(`📋 Token Name: CNE Test Token`);
        console.log(`🔤 Token Symbol: CNE_TEST`);
        console.log(`🔢 Decimals: 8`);
        console.log(`📊 Supply Type: Infinite`);
        console.log(`💰 Treasury: ${OPERATOR_ID}`);
        
        // Mint some initial tokens for testing (1 million CNE_TEST)
        console.log('\n💎 Minting initial test tokens...');
        const initialSupply = 1000000 * Math.pow(10, 8); // 1M tokens with 8 decimals
        
        const tokenMintTx = new TokenMintTransaction()
            .setTokenId(tokenId)
            .setAmount(initialSupply)
            .setMaxTransactionFee(new Hbar(20));
            
        const tokenMintFreeze = await tokenMintTx.freezeWith(client);
        const tokenMintSign = await tokenMintFreeze.sign(operatorKey);
        const tokenMintSubmit = await tokenMintSign.execute(client);
        const tokenMintReceipt = await tokenMintSubmit.getReceipt(client);
        
        console.log('✅ Initial tokens minted successfully!');
        console.log(`💰 Minted: 1,000,000 CNE_TEST tokens`);
        console.log(`🔢 Total Supply: ${tokenMintReceipt.totalSupply.toString()} (with decimals)`);
        
        // Update .env file with token ID
        console.log('\n📝 To use this token, update your .env file:');
        console.log(`CNE_TEST_TOKEN_ID=${tokenId.toString()}`);
        
        return {
            tokenId: tokenId.toString(),
            name: "CNE Test Token",
            symbol: "CNE_TEST",
            decimals: 8,
            totalSupply: tokenMintReceipt.totalSupply.toString(),
            treasury: OPERATOR_ID
        };
        
    } catch (error) {
        console.error('❌ Failed to create CNE_TEST token:', error.message);
        console.error('Full error:', error);
        
        if (error.message.includes('INSUFFICIENT_PAYER_BALANCE')) {
            console.error('\n💡 Tip: Fund your account with HBAR from the testnet faucet:');
            console.error('https://portal.hedera.com/');
        }
        
        throw error;
    }
}

// Run the function if this script is executed directly
if (require.main === module) {
    createCNETestToken()
        .then((result) => {
            console.log('\n🎉 Token creation completed successfully!');
            console.log(JSON.stringify(result, null, 2));
            process.exit(0);
        })
        .catch((error) => {
            console.error('\n💥 Token creation failed:', error.message);
            process.exit(1);
        });
}

module.exports = { createCNETestToken };
