// Test connection to Firebase and check user exists
const admin = require('firebase-admin');

async function testUserLookup() {
  try {
    console.log('🔍 Testing Firebase connection and user lookup...');
    
    // Initialize Firebase Admin
    admin.initializeApp();
    console.log('✅ Firebase Admin initialized');

    // Look for the user
    const email = 'yerinsmgmt@gmail.com';
    console.log(`📧 Looking up user: ${email}`);
    
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      console.log('✅ User found!');
      console.log(`👤 User ID: ${userRecord.uid}`);
      console.log(`📧 Email: ${userRecord.email}`);
      console.log(`📅 Created: ${userRecord.metadata.creationTime}`);
      console.log(`📅 Last Sign In: ${userRecord.metadata.lastSignInTime || 'Never'}`);
      
      // Check if user document exists in Firestore
      const db = admin.firestore();
      const userDoc = await db.collection('users').doc(userRecord.uid).get();
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        console.log('📄 User document found in Firestore');
        console.log(`💰 Points: ${userData.points_balance || 0}`);
        console.log(`💳 Available: ${userData.available_balance || 0}`);
        console.log(`🔒 Locked: ${userData.locked_balance || 0}`);
      } else {
        console.log('📄 No user document in Firestore');
      }
      
      return { found: true, uid: userRecord.uid };
      
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log('❌ User not found in Firebase Auth');
        return { found: false };
      }
      throw error;
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    return { error: error.message };
  }
}

testUserLookup().then(result => {
  if (result.found) {
    console.log('\n🎯 User exists and can be deleted. Ready to proceed with deletion.');
  } else if (result.error) {
    console.log('\n💥 Error occurred during lookup.');
  } else {
    console.log('\n⚠️ User not found. Nothing to delete.');
  }
  process.exit(0);
}).catch(error => {
  console.error('💥 Unhandled error:', error);
  process.exit(1);
});
