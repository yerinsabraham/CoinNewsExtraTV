const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { PrivateKey } = require('@hashgraph/sdk');

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Bulk Generate Mock Hedera Accounts (NO BLOCKCHAIN TRANSACTIONS - FREE)
 * Generates fake Account IDs, private/public keys, and DIDs
 * Saves to hedera_generated_accounts collection (same as existing accounts)
 * NO HBAR cost - completely local generation
 */
exports.bulkGenerateKeys = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '2GB'
  })
  .https.onCall(async (data, context) => {
    const batchSize = Math.min(data.batchSize || 1000, 2000); // Max 2000 per call
    
    console.log(`Generating ${batchSize} mock Hedera accounts...`);
    
    const results = {
      successful: [],
      failed: [],
      startTime: Date.now()
    };
    
    let batch = admin.firestore().batch();
    let batchCount = 0;
    const MAX_BATCH_SIZE = 500; // Firestore limit
    
    try {
      for (let i = 0; i < batchSize; i++) {
        
        try {
          // Generate ED25519 key pair (completely local, no network call)
          const privateKey = PrivateKey.generateED25519();
          const publicKey = privateKey.publicKey;
          
          // Generate FAKE Account ID (random number, NOT on blockchain)
          const randomAccountNum = Math.floor(Math.random() * 90000000) + 10000000; // 8-digit number
          const fakeAccountId = `0.0.${randomAccountNum}`;
          
          // Create DID based on fake account ID
          const did = `did:hedera:mainnet:${fakeAccountId}_0.0.0`;
          
          const accountData = {
            accountId: fakeAccountId,
            did: did,
            privateKey: privateKey.toString(),
            publicKey: publicKey.toString(),
            network: 'mainnet',
            createdBy: 'CoinNewsExtra',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          };
          
          // Add to batch - use hedera_generated_accounts collection
          const docRef = admin.firestore()
            .collection('hedera_generated_accounts')
            .doc(); // Auto-generate document ID
          
          batch.set(docRef, accountData);
          batchCount++;
          
          // Commit batch if we reach Firestore limit
          if (batchCount >= MAX_BATCH_SIZE) {
            await batch.commit();
            console.log(`Committed batch of ${batchCount} documents`);
            batch = admin.firestore().batch(); // Create new batch
            batchCount = 0;
          }
          
          results.successful.push({
            accountId: fakeAccountId,
            did: did,
            publicKey: publicKey.toString()
          });
          
        } catch (error) {
          console.error(`Failed to generate mock account:`, error);
          results.failed.push({
            error: error.message
          });
        }
      }
      
      // Commit remaining documents
      if (batchCount > 0) {
        await batch.commit();
        console.log(`Committed final batch of ${batchCount} documents`);
      }
      
      const endTime = Date.now();
      const duration = ((endTime - results.startTime) / 1000).toFixed(2);
      
      console.log(`✅ Generated ${results.successful.length} key pairs in ${duration}s`);
      console.log(`Rate: ${(results.successful.length / parseFloat(duration)).toFixed(0)} keys/second`);
      
      return {
        success: true,
        generated: results.successful.length,
        failed: results.failed.length,
        duration: duration,
        rate: `${(results.successful.length / parseFloat(duration)).toFixed(0)} keys/sec`,
        failedKeys: results.failed
      };
      
    } catch (error) {
      console.error('Error in bulkGenerateKeys:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Get count of generated keys and blockchain accounts
 */
exports.getKeyStats = functions.https.onCall(async (data, context) => {
  try {
    // Count key pairs (not yet on blockchain)
    const keyPairsSnapshot = await admin.firestore()
      .collection('hedera_key_pairs')
      .where('status', '==', 'keys_generated')
      .count()
      .get();
    
    // Count activated accounts (on blockchain)
    const activatedSnapshot = await admin.firestore()
      .collection('hedera_key_pairs')
      .where('status', '==', 'activated')
      .count()
      .get();
    
    // Count old generated accounts (from previous system)
    const generatedAccountsSnapshot = await admin.firestore()
      .collection('hedera_generated_accounts')
      .count()
      .get();
    
    return {
      success: true,
      keysGenerated: keyPairsSnapshot.data().count,
      accountsActivated: activatedSnapshot.data().count,
      oldGeneratedAccounts: generatedAccountsSnapshot.data().count,
      totalKeys: keyPairsSnapshot.data().count + activatedSnapshot.data().count
    };
    
  } catch (error) {
    console.error('Error getting stats:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
