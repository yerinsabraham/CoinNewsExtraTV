const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Verify and get statistics about all Hedera data in Firestore
 */
exports.verifyHederaData = functions.https.onCall(async (data, context) => {
  try {
    const results = {
      collections: {}
    };
    
    // Check hedera_generated_accounts
    const generatedSnapshot = await admin.firestore()
      .collection('hedera_generated_accounts')
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();
    
    const generatedCount = await admin.firestore()
      .collection('hedera_generated_accounts')
      .count()
      .get();
    
    results.collections.hedera_generated_accounts = {
      count: generatedCount.data().count,
      samples: generatedSnapshot.docs.map(doc => ({
        id: doc.id,
        accountId: doc.data().accountId,
        did: doc.data().did,
        network: doc.data().network,
        createdAt: doc.data().createdAt
      }))
    };
    
    // Check hedera_key_pairs
    const keyPairsCount = await admin.firestore()
      .collection('hedera_key_pairs')
      .count()
      .get();
    
    const keyPairsSample = await admin.firestore()
      .collection('hedera_key_pairs')
      .limit(5)
      .get();
    
    results.collections.hedera_key_pairs = {
      count: keyPairsCount.data().count,
      samples: keyPairsSample.docs.map(doc => ({
        id: doc.id,
        index: doc.data().index,
        status: doc.data().status,
        accountId: doc.data().accountId,
        publicKey: doc.data().publicKey ? doc.data().publicKey.substring(0, 30) + '...' : null
      }))
    };
    
    // Check admin_created_accounts
    const adminCount = await admin.firestore()
      .collection('admin_created_accounts')
      .count()
      .get();
    
    results.collections.admin_created_accounts = {
      count: adminCount.data().count
    };
    
    return {
      success: true,
      data: results
    };
    
  } catch (error) {
    console.error('Error verifying data:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
