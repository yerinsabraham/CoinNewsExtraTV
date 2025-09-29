// Check the status of our test rounds
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'coinnewsextra-tv'
  });
}

const db = admin.firestore();

async function checkRounds() {
  console.log('🔍 Checking timedRounds collection...\n');
  
  try {
    const now = admin.firestore.Timestamp.now();
    const roundsSnapshot = await db.collection('timedRounds').get();
    
    console.log(`📊 Total rounds found: ${roundsSnapshot.size}`);
    
    roundsSnapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      const startTime = data.startTime?.toDate();
      const endTime = data.endTime?.toDate();
      const nowDate = now.toDate();
      
      const isActive = startTime <= nowDate && nowDate <= endTime;
      const timeRemaining = isActive ? Math.max(0, Math.floor((endTime - nowDate) / 1000)) : 0;
      
      console.log(`\n🎮 Round ${index + 1} (${doc.id}):`);
      console.log(`   Room: ${data.roomId}`);
      console.log(`   Status: ${isActive ? '🟢 ACTIVE' : '🔴 INACTIVE'}`);
      console.log(`   Start: ${startTime?.toLocaleString()}`);
      console.log(`   End: ${endTime?.toLocaleString()}`);
      console.log(`   Players: ${data.players?.length || 0}`);
      console.log(`   Total Stake: ${data.totalStake || 0} CNE`);
      
      if (isActive) {
        const minutes = Math.floor(timeRemaining / 60);
        const seconds = timeRemaining % 60;
        console.log(`   ⏰ Time Remaining: ${minutes}:${seconds.toString().padStart(2, '0')}`);
      }
    });
    
    // Check for active rounds
    const activeRounds = roundsSnapshot.docs.filter(doc => {
      const data = doc.data();
      const startTime = data.startTime?.toDate();
      const endTime = data.endTime?.toDate();
      const nowDate = now.toDate();
      return startTime <= nowDate && nowDate <= endTime;
    });
    
    console.log(`\n✅ Active rounds: ${activeRounds.length}`);
    console.log(`❌ Inactive rounds: ${roundsSnapshot.size - activeRounds.length}`);
    
  } catch (error) {
    console.error('❌ Error checking rounds:', error);
  }
}

checkRounds().then(() => {
  console.log('\n🏁 Check complete!');
  process.exit(0);
}).catch(error => {
  console.error('❌ Failed to check rounds:', error);
  process.exit(1);
});
