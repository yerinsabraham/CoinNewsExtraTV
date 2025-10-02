const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const functions = require('firebase-functions');
const { Client, PrivateKey, AccountCreateTransaction, AccountId, Hbar } = require("@hashgraph/sdk");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Hedera configuration
const HEDERA_NETWORK = 'testnet';
const HEDERA_OPERATOR_ID = '0.0.4506257';
const HEDERA_OPERATOR_KEY = 'YOUR_HEDERA_PRIVATE_KEY_HERE'; // You'll need to set this

// processSignup function with Hedera wallet creation
exports.processSignup = onCall({
    cors: true
}, async (request) => {
    console.log('🎯 processSignup called with Hedera wallet creation');
    
    if (!request.auth || !request.auth.uid) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = request.auth.uid;
    const email = request.auth.token.email || '';
    
    try {
        console.log('Creating Hedera custodian wallet for user:', uid);
        
        // Create Hedera client
        const client = Client.forTestnet();
        client.setOperator(HEDERA_OPERATOR_ID, HEDERA_OPERATOR_KEY);
        
        // Generate new key pair for the user
        const userPrivateKey = PrivateKey.generateED25519();
        const userPublicKey = userPrivateKey.publicKey;
        
        console.log('Generated keypair for user');
        
        // Create new Hedera account (custodian wallet)
        const transaction = new AccountCreateTransaction()
            .setKey(userPublicKey)
            .setInitialBalance(new Hbar(0.1)) // Minimum required balance
            .setAccountMemo(CNE-User-);
        
        const response = await transaction.execute(client);
        const receipt = await response.getReceipt(client);
        const newAccountId = receipt.accountId;
        
        console.log('Created Hedera account:', newAccountId.toString());
        
        // Prepare user data with Hedera wallet info
        const userData = {
            uid: uid,
            email: email,
            cneBalance: 700, // Signup bonus
            signupBonusProcessed: true,
            signupTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            // Hedera wallet data (custodian - private key stored server-side)
            hederaWallet: {
                accountId: newAccountId.toString(),
                publicKey: userPublicKey.toString(),
                privateKey: userPrivateKey.toString(), // Stored securely server-side
                network: HEDERA_NETWORK,
                custodianWallet: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }
        };

        // Save to Firestore
        await db.collection('users').doc(uid).set(userData, { merge: true });
        
        console.log('User data saved with Hedera wallet:', newAccountId.toString());

        return {
            success: true,
            cneBalance: 700,
            hederaAccountId: newAccountId.toString(),
            message: 'Signup completed with Hedera wallet created'
        };
        
    } catch (error) {
        console.error('Error creating Hedera wallet:', error);
        
        // Fallback: Create user without Hedera wallet but still give bonus
        const fallbackData = {
            uid: uid,
            email: email,
            cneBalance: 700,
            signupBonusProcessed: true,
            signupTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            hederaWalletCreationFailed: true,
            hederaWalletError: error.message
        };

        await db.collection('users').doc(uid).set(fallbackData, { merge: true });

        return {
            success: true,
            cneBalance: 700,
            hederaAccountId: null,
            message: 'Signup completed (Hedera wallet creation failed but user created)',
            error: error.message
        };
    }
});

// Import bypass functions
const bypass = require('./bypass');
exports.getBalanceHttp = bypass.getBalanceHttp;
exports.claimRewardHttp = bypass.claimRewardHttp;
exports.processSignupHttp = bypass.processSignupHttp;
