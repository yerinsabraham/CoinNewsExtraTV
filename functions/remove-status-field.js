const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Remove 'status' field from all documents in hedera_generated_accounts
 */
exports.removeStatusField = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '1GB'
  })
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    const collectionRef = db.collection('hedera_generated_accounts');
    
    console.log('Starting to remove status field from all documents...');
    
    let totalUpdated = 0;
    let batch = db.batch();
    let batchCount = 0;
    const MAX_BATCH_SIZE = 500;
    
    try {
      // Get all documents
      const snapshot = await collectionRef.get();
      console.log(`Found ${snapshot.size} documents`);
      
      for (const doc of snapshot.docs) {
        const data = doc.data();
        
        // Only update if status field exists
        if (data.status) {
          batch.update(doc.ref, { status: admin.firestore.FieldValue.delete() });
          batchCount++;
          totalUpdated++;
          
          // Commit batch if we reach limit
          if (batchCount >= MAX_BATCH_SIZE) {
            await batch.commit();
            console.log(`Committed batch of ${batchCount} updates`);
            batch = db.batch();
            batchCount = 0;
          }
        }
      }
      
      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
        console.log(`Committed final batch of ${batchCount} updates`);
      }
      
      console.log(`✅ Removed status field from ${totalUpdated} documents`);
      
      return {
        success: true,
        totalDocuments: snapshot.size,
        updatedDocuments: totalUpdated
      };
      
    } catch (error) {
      console.error('Error removing status field:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });
