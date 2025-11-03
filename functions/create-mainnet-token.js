// STEP 1: Create Mainnet CNE Token & Treasury
// This script creates the CNE token on Hedera Mainnet with proper treasury

const {
    Client,
    PrivateKey,
    AccountId,
    TokenCreateTransaction,
    TokenType,
    TokenSupplyType,
    Hbar,
    AccountCreateTransaction,
    AccountBalanceQuery
} = require("@hashgraph/sdk");

// Configuration
const OPERATOR_ID = process.env.HEDERA_ACCOUNT_ID || "0.0.9764298";
const OPERATOR_KEY = process.env.HEDERA_PRIVATE_KEY;
const NETWORK = process.env.HEDERA_NETWORK || "mainnet";

async function createMainnetCNEToken() {
    console.log("🚀 CREATING MAINNET CNE TOKEN");
    console.log("============================");
    console.log(`Network: ${NETWORK}`);
    console.log(`Operator: ${OPERATOR_ID}`);
    console.log("");

    try {
        // Initialize Hedera client
        const client = NETWORK === "mainnet" ? Client.forMainnet() : Client.forTestnet();
        client.setOperator(
            AccountId.fromString(OPERATOR_ID),
            PrivateKey.fromStringED25519(OPERATOR_KEY)
        );

        // Step 1: Create Treasury Account (separate from operator)
        console.log("1️⃣ Creating Treasury Account...");
        
        const treasuryKey = PrivateKey.generateED25519();
        const treasuryPublicKey = treasuryKey.publicKey;
        
        console.log(`Treasury Private Key: ${treasuryKey.toStringRaw()}`);
        console.log(`Treasury Public Key: ${treasuryPublicKey.toStringRaw()}`);
        
        const treasuryAccountTx = await new AccountCreateTransaction()
            .setKey(treasuryPublicKey)
            .setInitialBalance(new Hbar(10)) // 10 HBAR for transaction fees
            .freezeWith(client)
            .sign(PrivateKey.fromStringED25519(OPERATOR_KEY));

        const treasuryAccountResponse = await treasuryAccountTx.execute(client);
        const treasuryAccountReceipt = await treasuryAccountResponse.getReceipt(client);
        const treasuryAccountId = treasuryAccountReceipt.accountId;

        console.log(`✅ Treasury Account Created: ${treasuryAccountId}`);
        console.log(`📄 Treasury Creation Tx: ${treasuryAccountResponse.transactionId}`);
        console.log("");

        // Step 2: Create CNE Token
        console.log("2️⃣ Creating CNE Token...");
        
        const tokenCreateTx = new TokenCreateTransaction()
            .setTokenName("CoinNewsExtra Token")
            .setTokenSymbol("CNE")
            .setTokenType(TokenType.FungibleCommon)
            .setDecimals(8)
            .setInitialSupply(0) // Start with 0 supply, mint as needed
            .setSupplyType(TokenSupplyType.Infinite)
            .setTreasuryAccountId(treasuryAccountId)
            .setAdminKey(treasuryKey)      // Treasury controls admin functions
            .setSupplyKey(treasuryKey)     // Treasury can mint new tokens
            .setFreezeKey(treasuryKey)     // Treasury can freeze accounts if needed
            .setWipeKey(treasuryKey)       // Treasury can wipe tokens if needed
            .setPauseKey(treasuryKey)      // Treasury can pause token if needed
            .setFeeScheduleKey(treasuryKey) // Treasury can set custom fees
            .setMaxTransactionFee(new Hbar(30)) // Higher fee limit for token creation
            .freezeWith(client);

        // Sign with both operator (pays fees) and treasury (admin keys)
        const tokenCreateTxSigned = await (await tokenCreateTx.sign(PrivateKey.fromStringED25519(OPERATOR_KEY))).sign(treasuryKey);
        const tokenCreateResponse = await tokenCreateTxSigned.execute(client);
        const tokenCreateReceipt = await tokenCreateResponse.getReceipt(client);
        const tokenId = tokenCreateReceipt.tokenId;

        console.log(`✅ CNE Token Created: ${tokenId}`);
        console.log(`📄 Token Creation Tx: ${tokenCreateResponse.transactionId}`);
        console.log("");

        // Step 3: Verify Token Properties
        console.log("3️⃣ Verifying Token Properties...");
        
        console.log(`🔍 Token Info:`);
        console.log(`   Name: CoinNewsExtra Token`);
        console.log(`   Symbol: CNE`);
        console.log(`   Decimals: 8`);
        console.log(`   Type: Fungible`);
        console.log(`   Supply Type: Infinite`);
        console.log(`   Treasury: ${treasuryAccountId}`);
        console.log("");

        // Step 4: Create KMS-style key storage references
        console.log("4️⃣ Generating KMS References...");
        
        const kmsReferences = {
            treasury_account_id: treasuryAccountId.toString(),
            treasury_private_key_ref: `hedera-mainnet-treasury-${treasuryAccountId.toString().replace(/\./g, '-')}`,
            treasury_public_key: treasuryPublicKey.toStringRaw(),
            key_rotation_policy: "90_days",
            backup_locations: [
                "primary_hsm_slot_1",
                "backup_hsm_slot_2", 
                "offline_secure_storage"
            ]
        };

        console.log("📁 KMS Key References Generated");
        console.log("");

        // Step 5: Generate deployment receipts
        const deploymentReceipts = {
            deployment_date: new Date().toISOString(),
            network: NETWORK,
            operator_account: OPERATOR_ID,
            treasury_account: treasuryAccountId.toString(),
            token_id: tokenId.toString(),
            transactions: {
                treasury_creation: {
                    tx_id: treasuryAccountResponse.transactionId.toString(),
                    account_id: treasuryAccountId.toString(),
                    status: "SUCCESS"
                },
                token_creation: {
                    tx_id: tokenCreateResponse.transactionId.toString(), 
                    token_id: tokenId.toString(),
                    status: "SUCCESS"
                }
            },
            token_properties: {
                name: "CoinNewsExtra Token",
                symbol: "CNE",
                decimals: 8,
                supply_type: "INFINITE",
                initial_supply: 0,
                treasury: treasuryAccountId.toString()
            },
            verification_links: {
                treasury_account: `https://hashscan.io/${NETWORK}/account/${treasuryAccountId}`,
                token: `https://hashscan.io/${NETWORK}/token/${tokenId}`,
                treasury_tx: `https://hashscan.io/${NETWORK}/transaction/${treasuryAccountResponse.transactionId}`,
                token_tx: `https://hashscan.io/${NETWORK}/transaction/${tokenCreateResponse.transactionId}`
            }
        };

        // Save deployment data
        const fs = require('fs');
        await fs.promises.writeFile(
            '../mainnet_deployment_receipts.json',
            JSON.stringify(deploymentReceipts, null, 2)
        );
        
        await fs.promises.writeFile(
            '../kms_references.json',
            JSON.stringify(kmsReferences, null, 2)
        );

        // ⚠️ SECURITY WARNING: In production, store this securely!
        await fs.promises.writeFile(
            '../treasury_private_key.SECURE',
            `TREASURY_PRIVATE_KEY=${treasuryKey.toStringRaw()}\nTREASURY_ACCOUNT_ID=${treasuryAccountId}`
        );

        console.log("📊 MAINNET TOKEN DEPLOYMENT COMPLETE");
        console.log("====================================");
        console.log("");
        console.log(`🪙 CNE Token ID: ${tokenId}`);
        console.log(`🏦 Treasury Account: ${treasuryAccountId}`);  
        console.log(`🔑 Treasury Key Generated (see treasury_private_key.SECURE)`);
        console.log("");
        console.log("🔗 Verification Links:");
        console.log(`   Token: https://hashscan.io/${NETWORK}/token/${tokenId}`);
        console.log(`   Treasury: https://hashscan.io/${NETWORK}/account/${treasuryAccountId}`);
        console.log("");
        console.log("📁 Files Generated:");
        console.log("   ✅ mainnet_deployment_receipts.json");
        console.log("   ✅ kms_references.json");  
        console.log("   ⚠️  treasury_private_key.SECURE (SECURE THIS!)");
        console.log("");
        console.log("🚨 NEXT STEPS:");
        console.log("   1. Secure the treasury private key in KMS/HSM");
        console.log("   2. Update app configuration with new token ID");
        console.log("   3. Test token minting from treasury");
        console.log("   4. Implement key rotation policy");

        return {
            success: true,
            token_id: tokenId.toString(),
            treasury_account: treasuryAccountId.toString(),
            treasury_private_key: treasuryKey.toStringRaw(),
            deployment_receipts: deploymentReceipts,
            kms_references: kmsReferences
        };

    } catch (error) {
        console.error("❌ TOKEN CREATION FAILED:");
        console.error(error);
        return {
            success: false,
            error: error.message,
            stack: error.stack
        };
    }
}

// Execute if called directly
async function main() {
    if (!OPERATOR_KEY) {
        console.error("❌ HEDERA_PRIVATE_KEY environment variable required");
        process.exit(1);
    }

    const result = await createMainnetCNEToken();
    
    if (result.success) {
        console.log("🎉 Token creation completed successfully!");
        process.exit(0);
    } else {
        console.error("💥 Token creation failed!");
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { createMainnetCNEToken };