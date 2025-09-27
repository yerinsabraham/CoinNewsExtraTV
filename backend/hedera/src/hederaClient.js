// hederaClient.js - Hedera testnet client setup
require('dotenv').config();
const { Client, PrivateKey, AccountId, AccountBalanceQuery } = require("@hashgraph/sdk");

// Environment variables
const OPERATOR_ID = process.env.HEDERA_OPERATOR_ID;
const OPERATOR_KEY = process.env.HEDERA_OPERATOR_KEY;
const POOL_ACCOUNT_ID = process.env.POOL_ACCOUNT_ID;
const POOL_PRIVATE_KEY = process.env.POOL_PRIVATE_KEY;
const HEDERA_NETWORK = process.env.HEDERA_NETWORK || 'testnet';

// Validate required environment variables
if (!OPERATOR_ID || !OPERATOR_KEY) {
    console.error('❌ Missing required Hedera credentials in .env file');
    console.error('Please add HEDERA_OPERATOR_ID and HEDERA_OPERATOR_KEY');
    console.error('Get these from Hedera Portal: https://portal.hedera.com');
    process.exit(1);
}

// Create client for testnet
const client = Client.forTestnet();

try {
    const operatorKey = PrivateKey.fromString(OPERATOR_KEY);
    client.setOperator(OPERATOR_ID, operatorKey);
    
    console.log(`✅ Hedera ${HEDERA_NETWORK} client initialized`);
    console.log(`📋 Operator Account: ${OPERATOR_ID}`);
    console.log(`💰 Pool Account: ${POOL_ACCOUNT_ID || 'Not configured'}`);
} catch (error) {
    console.error('❌ Failed to initialize Hedera client:', error.message);
    console.error('Please check your HEDERA_OPERATOR_KEY format');
    process.exit(1);
}

// Pool account setup
let poolAccountId = null;
let poolPrivateKey = null;

if (POOL_ACCOUNT_ID && POOL_PRIVATE_KEY) {
    try {
        poolAccountId = AccountId.fromString(POOL_ACCOUNT_ID);
        poolPrivateKey = PrivateKey.fromString(POOL_PRIVATE_KEY);
        console.log(`💼 Pool account configured: ${POOL_ACCOUNT_ID}`);
    } catch (error) {
        console.warn('⚠️ Pool account configuration invalid:', error.message);
    }
}

// Helper function to check connection
async function testConnection() {
    try {
        const query = new AccountBalanceQuery()
            .setAccountId(OPERATOR_ID);
            
        const balance = await query.execute(client);
        console.log(`🔗 Connection test successful`);
        console.log(`💎 Operator HBAR balance: ${balance.hbars.toString()}`);
        
        // Check if we have enough HBAR for transactions
        const hbarBalance = balance.hbars.toTinybars();
        if (hbarBalance.lt(1_00_000_000)) { // Less than 1 HBAR
            console.warn('⚠️ Low HBAR balance. You may need more HBAR for transactions.');
            console.warn('Get HBAR from testnet faucet: https://portal.hedera.com');
        }
        
        return true;
    } catch (error) {
        console.error('❌ Connection test failed:', error.message);
        console.error('💡 Common issues:');
        console.error('- Invalid account ID or private key');
        console.error('- Network connectivity problems');
        console.error('- Account not found on testnet');
        return false;
    }
}

// Helper function to get transaction fee estimate
async function estimateTransactionFee(transaction) {
    try {
        const cost = await transaction.getCost(client);
        return cost.toTinybars();
    } catch (error) {
        console.warn('Could not estimate transaction fee:', error.message);
        return null;
    }
}

module.exports = {
    client,
    OPERATOR_ID,
    operatorKey: PrivateKey.fromString(OPERATOR_KEY),
    poolAccountId,
    poolPrivateKey,
    testConnection,
    estimateTransactionFee,
    // Constants
    CNE_DECIMALS: 8, // CNE token has 8 decimals
    MIN_HBAR_BALANCE: 1, // Minimum HBAR needed for transactions
};
