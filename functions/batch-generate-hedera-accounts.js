const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

// Import Hedera SDK
let Client, PrivateKey, AccountCreateTransaction, Hbar, AccountId;
try {
  const hederaSdk = require('@hashgraph/sdk');
  Client = hederaSdk.Client;
  PrivateKey = hederaSdk.PrivateKey;
  AccountCreateTransaction = hederaSdk.AccountCreateTransaction;
  Hbar = hederaSdk.Hbar;
  AccountId = hederaSdk.AccountId;
} catch (e) {
  console.error('Failed to load Hedera SDK:', e);
}

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Hedera Configuration from environment variables
// Set these in Firebase Console > Functions > Configuration or in .env file
const HEDERA_ACCOUNT_ID = process.env.HEDERA_ACCOUNT_ID || '0.0.9741152';
const HEDERA_PRIVATE_KEY = process.env.HEDERA_PRIVATE_KEY;

/**
 * Batch Generate Hedera Accounts
 * Creates individual Hedera blockchain accounts without requiring email
 * Each account is standalone with its own keypair
 */
exports.batchGenerateHederaAccounts = functions
  .runWith({
    timeoutSeconds: 120,
    memory: '512MB'
  })
  .https.onCall(async (data, context) => {
    const { network, memo } = data;
    
    console.log(`🔐 Generating Hedera account on mainnet`);
    
    // Check if Hedera SDK loaded
    if (!Client || !PrivateKey || !AccountCreateTransaction || !Hbar) {
      throw new functions.https.HttpsError('failed-precondition', 'Hedera SDK not properly loaded');
    }

    // Use mainnet credentials
    const operatorId = HEDERA_ACCOUNT_ID;
    const operatorKeyString = HEDERA_PRIVATE_KEY;

    // Check if operator key is set
    if (!operatorKeyString || operatorKeyString.includes('YOUR_')) {
      throw new functions.https.HttpsError(
        'failed-precondition', 
        `Hedera operator key not configured. Please set HEDERA_PRIVATE_KEY environment variable.`
      );
    }

    try {
      // Parse the private key - try fromString which auto-detects format
      console.log('Parsing operator private key...');
      let operatorKey;
      try {
        operatorKey = PrivateKey.fromString(operatorKeyString);
      } catch (e) {
        console.error('Failed to parse with fromString, trying fromStringDer:', e.message);
        operatorKey = PrivateKey.fromStringDer(operatorKeyString);
      }
      
      console.log('✅ Private key parsed successfully');
      
      // Set up Hedera client for mainnet only
      const client = Client.forMainnet();
      client.setOperator(operatorId, operatorKey);
      client.setDefaultMaxTransactionFee(new Hbar(0.5)); // Network requires ~0.43 HBAR minimum
      
      console.log(`✅ Hedera client initialized for mainnet`);
      console.log(`Operator ID: ${operatorId}`);

      // Generate new ED25519 keypair
      console.log('Generating ED25519 keypair...');
      const newPrivateKey = PrivateKey.generateED25519();
      
      if (!newPrivateKey) {
        throw new Error('Failed to generate private key');
      }
      
      const newPublicKey = newPrivateKey.publicKey;
      
      if (!newPublicKey) {
        throw new Error('Failed to get public key from private key');
      }
      
      console.log('✅ Keypair generated successfully');
      console.log(`Public Key: ${newPublicKey.toString()}`);

      // Create Hedera account
      const accountMemo = memo || `CNE-Generated-${Date.now()}`;
      
      const transaction = new AccountCreateTransaction()
        .setKey(newPublicKey)
        .setInitialBalance(new Hbar(0.001)) // Minimum balance: 0.001 HBAR
        .setAccountMemo(accountMemo)
        .setMaxTransactionFee(new Hbar(0.5)); // Network requires ~0.43 HBAR minimum
      
      console.log('Executing account creation transaction...');
      const response = await transaction.execute(client);
      const receipt = await response.getReceipt(client);
      const newAccountId = receipt.accountId;
      
      console.log(`✅ Hedera account created: ${newAccountId.toString()}`);
      console.log(`Transaction ID: ${response.transactionId.toString()}`);

      // Create DID (Decentralized Identifier)
      const did = `did:hedera:mainnet:${newAccountId.toString()}_0.0.0`;

      // Prepare account data
      const accountData = {
        accountId: newAccountId.toString(),
        publicKey: newPublicKey.toString(),
        privateKey: newPrivateKey.toString(), // ⚠️ Store securely in production!
        did: did,
        network: 'mainnet',
        memo: accountMemo,
        initialBalance: 0.001,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdVia: 'batch_generator',
        transactionId: response.transactionId.toString(),
        // Blockchain explorer links
        explorerUrl: `https://hashscan.io/mainnet/account/${newAccountId.toString()}`,
        // Additional metadata
        keyType: 'ED25519',
        isStandalone: true, // Not linked to email/user
        isActive: true
      };

      // Store in Firestore for tracking
      const docRef = await admin.firestore()
        .collection('hedera_generated_accounts')
        .add(accountData);

      console.log(`✅ Account data stored in Firestore: ${docRef.id}`);

      // Close client
      client.close();

      // Return account details
      return {
        success: true,
        accountId: newAccountId.toString(),
        publicKey: newPublicKey.toString(),
        privateKey: newPrivateKey.toString(),
        did: did,
        network: network || 'testnet',
        memo: accountMemo,
        transactionId: response.transactionId.toString(),
        explorerUrl: accountData.explorerUrl,
        firestoreId: docRef.id,
        message: `Hedera account created successfully on ${network || 'testnet'}`
      };

    } catch (error) {
      console.error('❌ Error creating Hedera account:', error);
      console.error(`Error details - Code: ${error.code}, Message: ${error.message}`);
      console.error(`Stack: ${error.stack}`);
      
      throw new functions.https.HttpsError(
        'internal',
        `Failed to create Hedera account: ${error.message}`,
        { code: error.code || 'unknown', details: error.toString() }
      );
    }
  });

/**
 * Query Generated Accounts
 * Retrieves all standalone Hedera accounts from Firestore
 */
exports.getGeneratedHederaAccounts = functions
  .runWith({
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    try {
      const { limit = 100, network = null } = data;

      console.log(`📊 Querying generated Hedera accounts (limit: ${limit})`);

      let query = admin.firestore()
        .collection('hedera_generated_accounts')
        .where('isStandalone', '==', true)
        .orderBy('createdAt', 'desc')
        .limit(limit);

      if (network) {
        query = query.where('network', '==', network);
      }

      const snapshot = await query.get();

      const accounts = [];
      snapshot.forEach(doc => {
        accounts.push({
          id: doc.id,
          ...doc.data(),
          // Don't return private key by default for security
          privateKey: '***HIDDEN***'
        });
      });

      console.log(`✅ Retrieved ${accounts.length} accounts`);

      return {
        success: true,
        count: accounts.length,
        accounts: accounts,
        total: snapshot.size
      };

    } catch (error) {
      console.error('❌ Error querying accounts:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Get Account Details (including private key)
 * Requires Firestore document ID
 */
exports.getHederaAccountDetails = functions
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    try {
      const { accountId } = data;

      if (!accountId) {
        throw new functions.https.HttpsError('invalid-argument', 'Account ID required');
      }

      console.log(`🔍 Fetching details for account: ${accountId}`);

      // Query by accountId field
      const snapshot = await admin.firestore()
        .collection('hedera_generated_accounts')
        .where('accountId', '==', accountId)
        .limit(1)
        .get();

      if (snapshot.empty) {
        throw new functions.https.HttpsError('not-found', 'Account not found');
      }

      const doc = snapshot.docs[0];
      const accountData = {
        id: doc.id,
        ...doc.data()
      };

      console.log(`✅ Account details retrieved`);

      return {
        success: true,
        account: accountData
      };

    } catch (error) {
      console.error('❌ Error fetching account details:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Export Accounts to CSV/JSON
 * Generates exportable data for backup
 */
exports.exportGeneratedAccounts = functions
  .runWith({
    timeoutSeconds: 120,
    memory: '512MB'
  })
  .https.onCall(async (data, context) => {
    try {
      const { format = 'json', includePrivateKeys = false } = data;

      console.log(`📦 Exporting accounts in ${format} format`);

      const snapshot = await admin.firestore()
        .collection('hedera_generated_accounts')
        .where('isStandalone', '==', true)
        .orderBy('createdAt', 'desc')
        .get();

      const accounts = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        accounts.push({
          accountId: data.accountId,
          publicKey: data.publicKey,
          privateKey: includePrivateKeys ? data.privateKey : '***HIDDEN***',
          did: data.did,
          network: data.network,
          memo: data.memo,
          explorerUrl: data.explorerUrl,
          createdAt: data.createdAt?.toDate?.()?.toISOString() || 'N/A'
        });
      });

      console.log(`✅ Exported ${accounts.length} accounts`);

      return {
        success: true,
        count: accounts.length,
        accounts: accounts,
        format: format
      };

    } catch (error) {
      console.error('❌ Error exporting accounts:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });
