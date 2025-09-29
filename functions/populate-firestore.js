const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function populateFirestore() {
  console.log('🚀 Starting Firestore population...');

  try {
    // Create battle rooms
    const battleRooms = [
      {
        id: 'crypto-kings',
        name: 'Crypto Kings Arena',
        description: 'Elite battles for cryptocurrency masters',
        entryFee: 100,
        maxPlayers: 4,
        difficulty: 'Hard',
        rewards: {
          first: 300,
          second: 150,
          third: 75
        },
        icon: '👑',
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        id: 'blockchain-warriors',
        name: 'Blockchain Warriors',
        description: 'Test your blockchain knowledge in combat',
        entryFee: 50,
        maxPlayers: 6,
        difficulty: 'Medium',
        rewards: {
          first: 200,
          second: 100,
          third: 50
        },
        icon: '⚔️',
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        id: 'defi-dojo',
        name: 'DeFi Dojo',
        description: 'Master the art of decentralized finance',
        entryFee: 25,
        maxPlayers: 8,
        difficulty: 'Easy',
        rewards: {
          first: 100,
          second: 60,
          third: 40
        },
        icon: '🥋',
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        id: 'nft-nexus',
        name: 'NFT Nexus',
        description: 'Battle in the world of non-fungible tokens',
        entryFee: 75,
        maxPlayers: 4,
        difficulty: 'Medium',
        rewards: {
          first: 250,
          second: 125,
          third: 75
        },
        icon: '🎨',
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }
    ];

    // Add battle rooms to Firestore
    const batch = db.batch();
    
    battleRooms.forEach(room => {
      const roomRef = db.collection('rooms').doc(room.id);
      batch.set(roomRef, room);
    });

    await batch.commit();
    console.log('✅ Created battle rooms:', battleRooms.map(r => r.name).join(', '));

    // Create some sample user stats (optional)
    const sampleUserStats = {
      totalGamesPlayed: 0,
      totalWins: 0,
      totalCoinsEarned: 0,
      totalCoinsSpent: 0,
      currentStreak: 0,
      longestStreak: 0,
      favoriteRoom: 'defi-dojo',
      achievements: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Note: We don't create user stats here as they should be created per-user
    // This is just a template for what user stats look like

    console.log('✅ Firestore population completed successfully!');
    console.log('📊 Battle rooms available:', battleRooms.length);
    console.log('🎮 Ready for Play Extra battles!');

  } catch (error) {
    console.error('❌ Error populating Firestore:', error);
    throw error;
  }
}

// Run the population script
if (require.main === module) {
  populateFirestore()
    .then(() => {
      console.log('🎯 Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { populateFirestore };
