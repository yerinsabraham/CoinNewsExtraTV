// User Account Reset Script - Run this in Firebase Console
// This script will clean up existing user data for fresh testing

const admin = require('firebase-admin');

// Initialize Firebase Admin (you'll need to set up service account)
const serviceAccount = require('./path-to-service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'coinnewsextratv-9c75a'
});

const db = admin.firestore();

async function resetUserAccount(userId) {
  try {
    console.log(`🔄 Resetting account for user: ${userId}`);
    
    // 1. Delete all social verifications
    const socialVerifications = await db
      .collection('users')
      .doc(userId)
      .collection('social_verifications')
      .get();
    
    const batch = db.batch();
    socialVerifications.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    // 2. Reset user document to clean state
    batch.update(db.collection('users').doc(userId), {
      tokenBalance: 0,
      totalEarned: 0,
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      socialVerificationsReset: true,
      resetAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await batch.commit();
    console.log('✅ User account reset successfully');
    
  } catch (error) {
    console.error('❌ Error resetting account:', error);
  }
}

// Usage: Replace 'YOUR_USER_ID' with actual Firebase Auth UID
// resetUserAccount('YOUR_USER_ID');
