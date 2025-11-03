// Clean up old rounds in Firestore
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'coinnewsextratv-9c75a'
  });
}

const db = admin.firestore();

async function cleanupOldRounds() {
  console.log('🧹 Cleaning up old rounds...');
  
  try {
    // Get all rounds that are not waiting status
    const oldRoundsSnapshot = await db.collection('timedRounds')
      .where('status', '!=', 'waiting')
      .get();
    
    console.log(`Found ${oldRoundsSnapshot.size} old rounds to delete`);
    
    // Delete old rounds
    const batch = db.batch();
    oldRoundsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log('✅ Old rounds deleted');
    
    // Show current waiting rounds
    const waitingRounds = await db.collection('timedRounds')
      .where('status', '==', 'waiting')
      .get();
    
    console.log(`\n📊 Current waiting rounds: ${waitingRounds.size}`);
    waitingRounds.docs.forEach(doc => {
      const data = doc.data();
      const endTime = data.roundEndTime?.toDate();
      const now = new Date();
      const timeRemaining = Math.max(0, Math.floor((endTime - now) / 1000));
      const minutes = Math.floor(timeRemaining / 60);
      const seconds = timeRemaining % 60;
      
      console.log(`  ${data.roomId}: ${minutes}:${seconds.toString().padStart(2, '0')} remaining`);
    });
    
  } catch (error) {
    console.error('❌ Error cleaning up rounds:', error);
  }
}

cleanupOldRounds().then(() => {
  console.log('\n🎉 Cleanup complete!');
  process.exit(0);
}).catch(error => {
  console.error('❌ Failed:', error);
  process.exit(1);
});
