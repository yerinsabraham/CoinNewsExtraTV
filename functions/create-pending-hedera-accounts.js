const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Import Hedera SDK - use the same pattern as index.js
let Client, PrivateKey, AccountCreateTransaction, Hbar;
try {
  const hederaSdk = require('@hashgraph/sdk');
  Client = hederaSdk.Client;
  PrivateKey = hederaSdk.PrivateKey;
  AccountCreateTransaction = hederaSdk.AccountCreateTransaction;
  Hbar = hederaSdk.Hbar;
} catch (e) {
  console.error('Failed to load Hedera SDK:', e);
}

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const HEDERA_NETWORK = 'mainnet';
const HEDERA_OPERATOR_ID = process.env.HEDERA_ACCOUNT_ID || '0.0.9764298';
const HEDERA_OPERATOR_KEY = process.env.HEDERA_PRIVATE_KEY;

/**
 * Process Pending Hedera Accounts
 * Goes through admin_created_accounts with status='pending_hedera' 
 * and creates Hedera accounts for each one
 */
exports.createPendingHederaAccounts = functions.https.onCall(
  {
    timeoutSeconds: 540, // 9 minutes (max allowed)
    memory: '1GiB',
    invoker: 'public'
  },
  async (data, context) => {
    const batchSize = data.batchSize || 50; // Process 50 at a time to avoid timeout
    const startAfterEmail = data.startAfter || null;
    
    console.log(`Starting Hedera account creation for pending accounts. Batch size: ${batchSize}`);
    
    // Check if Hedera SDK loaded
    if (!Client || !PrivateKey || !AccountCreateTransaction || !Hbar) {
      throw new functions.https.HttpsError('failed-precondition', 'Hedera SDK not properly loaded');
    }
    
    // Check if operator key is set
    if (!HEDERA_OPERATOR_KEY || HEDERA_OPERATOR_KEY.includes('YOUR_HEDERA')) {
      throw new functions.https.HttpsError('failed-precondition', 'Hedera operator key not configured');
    }
    
    try {
      // Set up Hedera client
      const client = Client.forMainnet();
      client.setOperator(HEDERA_OPERATOR_ID, HEDERA_OPERATOR_KEY);
      client.setDefaultMaxTransactionFee(new Hbar(2));
      
      console.log('✅ Hedera client initialized successfully');
      console.log(`Operator ID: ${HEDERA_OPERATOR_ID}`);
      
      // Query pending accounts
      let query = admin.firestore()
        .collection('admin_created_accounts')
        .where('status', '==', 'pending_hedera')
        .limit(batchSize);
      
      if (startAfterEmail) {
        query = query.startAfter(startAfterEmail);
      }
      
      const snapshot = await query.get();
      
      if (snapshot.empty) {
        return {
          success: true,
          message: 'No more pending accounts to process',
          processed: 0,
          hasMore: false
        };
      }
      
      const results = {
        successful: [],
        failed: [],
        total: snapshot.size
      };
      
      // Process each account
      for (const doc of snapshot.docs) {
        const accountData = doc.data();
        const { email, firebaseUid } = accountData;
        
        try {
          console.log(`Creating Hedera account for: ${email}`);
          
          // Generate new key pair
          console.log('Generating ED25519 keypair...');
          const userPrivateKey = PrivateKey.generateED25519();
          
          if (!userPrivateKey) {
            throw new Error('Failed to generate private key');
          }
          
          const userPublicKey = userPrivateKey.publicKey;
          
          if (!userPublicKey) {
            throw new Error('Failed to get public key from private key');
          }
          
          console.log(`Generated keys for ${email}`);
          
          // Create Hedera account
          const transaction = new AccountCreateTransaction()
            .setKey(userPublicKey)
            .setInitialBalance(new Hbar(0.1))
            .setAccountMemo(`CNE-${firebaseUid.substring(0, 8)}`);
          
          const response = await transaction.execute(client);
          const receipt = await response.getReceipt(client);
          const newAccountId = receipt.accountId;
          
          console.log(`✅ Created Hedera account ${newAccountId.toString()} for ${email}`);
          
          // Create DID
          const did = `did:hedera:${HEDERA_NETWORK}:${newAccountId.toString()}_0.0.0`;
          
          console.log(`✅ Created: ${newAccountId.toString()} with DID: ${did}`);
          
          // Update admin_created_accounts
          await doc.ref.update({
            hederaAccountId: newAccountId.toString(),
            did: did,
            status: 'active',
            hederaCreatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          // Update users collection
          await admin.firestore().collection('users').doc(firebaseUid).set({
            hederaWallet: {
              accountId: newAccountId.toString(),
              publicKey: userPublicKey.toString(),
              privateKey: userPrivateKey.toString(), // Encrypted storage recommended in production
              network: HEDERA_NETWORK,
              custodianWallet: true,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            },
            did: did,
            hederaAccountId: newAccountId.toString()
          }, { merge: true });
          
          results.successful.push({
            email: email,
            firebaseUid: firebaseUid,
            hederaAccountId: newAccountId.toString(),
            did: did
          });
          
          // Longer delay to avoid rate limiting (1 second per account)
          await new Promise(resolve => setTimeout(resolve, 1000));
          
        } catch (error) {
          console.error(`❌ Failed to create Hedera account for ${email}:`, error);
          console.error(`Error details - Code: ${error.code}, Message: ${error.message}`);
          console.error(`Stack: ${error.stack}`);
          
          results.failed.push({
            email: email,
            error: error.message,
            errorCode: error.code || 'unknown',
            errorDetails: error.toString()
          });
        }
      }
      
      client.close();
      
      const hasMore = snapshot.size === batchSize;
      const lastEmail = snapshot.docs[snapshot.docs.length - 1].data().email;
      
      console.log(`Batch complete: ${results.successful.length} successful, ${results.failed.length} failed`);
      
      return {
        success: true,
        processed: results.successful.length,
        failed: results.failed.length,
        hasMore: hasMore,
        nextStartAfter: hasMore ? lastEmail : null,
        results: results
      };
      
    } catch (error) {
      console.error('Error in createPendingHederaAccounts:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);
