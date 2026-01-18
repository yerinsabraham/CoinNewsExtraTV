const admin = require('./functions/node_modules/firebase-admin');
const serviceAccount = require('./functions/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyData() {
  console.log('🔍 Checking Firestore for Hedera accounts...\n');
  
  try {
    // Check hedera_generated_accounts collection
    const generatedSnapshot = await db.collection('hedera_generated_accounts').get();
    console.log(`✅ hedera_generated_accounts collection: ${generatedSnapshot.size} documents`);
    
    if (generatedSnapshot.size > 0) {
      console.log('\n📋 Sample accounts:');
      let count = 0;
      generatedSnapshot.forEach(doc => {
        if (count < 5) {
          const data = doc.data();
          console.log(`  - Account ID: ${data.accountId || 'N/A'}`);
          console.log(`    DID: ${data.did || 'N/A'}`);
          console.log(`    Created: ${data.createdAt ? new Date(data.createdAt._seconds * 1000).toLocaleString() : 'N/A'}`);
          console.log('');
          count++;
        }
      });
      
      // Get total count
      const countSnapshot = await db.collection('hedera_generated_accounts').count().get();
      console.log(`\n📊 Total count: ${countSnapshot.data().count}`);
    }
    
    // Check hedera_key_pairs collection (new system)
    const keyPairsSnapshot = await db.collection('hedera_key_pairs').get();
    console.log(`\n✅ hedera_key_pairs collection: ${keyPairsSnapshot.size} documents`);
    
    if (keyPairsSnapshot.size > 0) {
      console.log('\n📋 Sample key pairs:');
      let count = 0;
      keyPairsSnapshot.forEach(doc => {
        if (count < 3) {
          const data = doc.data();
          console.log(`  - Index: ${data.index || 'N/A'}`);
          console.log(`    Status: ${data.status || 'N/A'}`);
          console.log(`    Public Key: ${data.publicKey ? data.publicKey.substring(0, 30) + '...' : 'N/A'}`);
          console.log('');
          count++;
        }
      });
    }
    
    // Check admin_created_accounts collection
    const adminSnapshot = await db.collection('admin_created_accounts').get();
    console.log(`\n✅ admin_created_accounts collection: ${adminSnapshot.size} documents`);
    
    console.log('\n✅ Verification complete!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

verifyData();
