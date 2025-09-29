const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function createTestRounds() {
  console.log('🔄 Creating test timed rounds...');
  
  const rooms = ['rookie', 'pro', 'elite'];
  const now = new Date();
  
  try {
    for (const roomId of rooms) {
      // Create an active round that starts now and ends in 5 minutes
      const roundStartTime = new Date(now.getTime());
      const roundEndTime = new Date(now.getTime() + 5 * 60 * 1000); // 5 minutes from now
      
      const roundData = {
        roomId: roomId,
        status: 'active',
        roundStartTime: admin.firestore.Timestamp.fromDate(roundStartTime),
        roundEndTime: admin.firestore.Timestamp.fromDate(roundEndTime),
        endsAt: admin.firestore.Timestamp.fromDate(roundEndTime),
        players: [],
        maxPlayers: roomId === 'rookie' ? 4 : roomId === 'pro' ? 6 : 8,
        totalStakes: 0,
        createdAt: admin.firestore.Timestamp.fromDate(now),
      };
      
      const docRef = await db.collection('timedRounds').add(roundData);
      console.log(`✅ Created round for ${roomId}: ${docRef.id}`);
    }
    
    console.log('🎉 All test rounds created successfully!');
  } catch (error) {
    console.error('❌ Error creating test rounds:', error);
  }
}

createTestRounds();
