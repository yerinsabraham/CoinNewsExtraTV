const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'coinnewsextratv-9c75a'
  });
}

const db = admin.firestore();

async function createInitialTimedRounds() {
  console.log('🎯 Creating initial timed rounds...');
  
  try {
    const now = new Date();
    const batch = db.batch();
    
    // Create next round (starts in 30 seconds, ends in 2 minutes 30 seconds)
    const nextRoundStart = new Date(now.getTime() + 30 * 1000);
    const nextRoundEnd = new Date(nextRoundStart.getTime() + 2 * 60 * 1000);
    
    const nextRoundData = {
      id: 'round-' + Date.now(),
      roomId: 'crypto-kings',
      status: 'active',
      startsAt: admin.firestore.Timestamp.fromDate(nextRoundStart),
      endsAt: admin.firestore.Timestamp.fromDate(nextRoundEnd),
      duration: 120, // 2 minutes in seconds
      minPlayers: 2,
      maxPlayers: 10,
      participants: [],
      totalStake: 0,
      createdAt: admin.firestore.Timestamp.fromDate(now),
      updatedAt: admin.firestore.Timestamp.fromDate(now)
    };
    
    const nextRoundRef = db.collection('timedRounds').doc(nextRoundData.id);
    batch.set(nextRoundRef, nextRoundData);
    
    // Create a future round (starts in 3 minutes)
    const futureRoundStart = new Date(now.getTime() + 3 * 60 * 1000);
    const futureRoundEnd = new Date(futureRoundStart.getTime() + 2 * 60 * 1000);
    
    const futureRoundData = {
      id: 'round-' + (Date.now() + 1),
      roomId: 'blockchain-warriors',
      status: 'active',
      startsAt: admin.firestore.Timestamp.fromDate(futureRoundStart),
      endsAt: admin.firestore.Timestamp.fromDate(futureRoundEnd),
      duration: 120, // 2 minutes in seconds
      minPlayers: 2,
      maxPlayers: 8,
      participants: [],
      totalStake: 0,
      createdAt: admin.firestore.Timestamp.fromDate(now),
      updatedAt: admin.firestore.Timestamp.fromDate(now)
    };
    
    const futureRoundRef = db.collection('timedRounds').doc(futureRoundData.id);
    batch.set(futureRoundRef, futureRoundData);
    
    await batch.commit();
    
    console.log('✅ Created initial timed rounds:');
    console.log(`📍 Next round: ${nextRoundData.id} (${nextRoundData.roomId})`);
    console.log(`⏰ Starts: ${nextRoundStart.toISOString()}`);
    console.log(`⏰ Ends: ${nextRoundEnd.toISOString()}`);
    console.log(`📍 Future round: ${futureRoundData.id} (${futureRoundData.roomId})`);
    console.log(`⏰ Starts: ${futureRoundStart.toISOString()}`);
    console.log(`⏰ Ends: ${futureRoundEnd.toISOString()}`);
    
  } catch (error) {
    console.error('❌ Error creating timed rounds:', error);
  }
}

async function main() {
  await createInitialTimedRounds();
  process.exit(0);
}

if (require.main === module) {
  main();
}

module.exports = { createInitialTimedRounds };
