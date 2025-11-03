const admin = require("firebase-admin");

// Initialize Firebase Admin (you'll need to set up credentials)
// For local testing, set GOOGLE_APPLICATION_CREDENTIALS environment variable
// or use Firebase CLI: firebase login && firebase use coinnewsextratv-9c75a

admin.initializeApp({
    projectId: "coinnewsextratv-9c75a"
});

const db = admin.firestore();

async function initializeCollections() {
    console.log("🎮 Initializing Play Extra Firestore collections...\n");

    try {
        // Initialize Rooms Collection
        console.log("📋 Creating battle rooms...");
        
        const rooms = [
            {
                id: "rookie",
                name: "Rookie Room",
                minStake: 10,
                maxStake: 100,
                description: "Perfect for beginners",
                maxPlayers: 4,
                colors: ["red", "blue", "green", "yellow"]
            },
            {
                id: "pro",
                name: "Pro Room", 
                minStake: 100,
                maxStake: 500,
                description: "For experienced players",
                maxPlayers: 6,
                colors: ["red", "blue", "green", "yellow", "purple", "orange"]
            },
            {
                id: "elite",
                name: "Elite Room",
                minStake: 500,
                maxStake: 5000,
                description: "High stakes battles",
                maxPlayers: 8,
                colors: ["red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan"]
            }
        ];

        for (const room of rooms) {
            await db.collection("rooms").doc(room.id).set({
                ...room,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                active: true
            });
            console.log(`✅ Created room: ${room.name} (${room.minStake}-${room.maxStake} CNE)`);
        }

        // Create some sample data for testing
        console.log("\n🧪 Creating sample test data...");
        
        // Sample completed round for demo
        const sampleRound = {
            roomId: "rookie",
            status: "completed",
            players: [
                {
                    uid: "test-user-1",
                    stake: 50,
                    color: "red",
                    joinedAt: admin.firestore.Timestamp.now()
                },
                {
                    uid: "test-user-2", 
                    stake: 75,
                    color: "blue",
                    joinedAt: admin.firestore.Timestamp.now()
                }
            ],
            winner: "test-user-1",
            resultColor: "red",
            totalStake: 125,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now()
        };

        const sampleRoundRef = await db.collection("rounds").add(sampleRound);
        console.log(`✅ Created sample round: ${sampleRoundRef.id}`);

        // Sample joins for the round
        const sampleJoins = [
            {
                roundId: sampleRoundRef.id,
                uid: "test-user-1",
                stake: 50,
                color: "red",
                joinedAt: admin.firestore.Timestamp.now()
            },
            {
                roundId: sampleRoundRef.id,
                uid: "test-user-2",
                stake: 75,
                color: "blue", 
                joinedAt: admin.firestore.Timestamp.now()
            }
        ];

        for (const join of sampleJoins) {
            await db.collection("joins").add(join);
        }
        console.log("✅ Created sample join records");

        console.log("\n🎉 Firestore collections initialized successfully!");
        console.log("\n📊 Collection Summary:");
        console.log("- rooms: 3 battle rooms (rookie, pro, elite)");
        console.log("- rounds: 1 sample completed round");
        console.log("- joins: 2 sample join records");
        
        console.log("\n🔗 Next steps:");
        console.log("1. Deploy Cloud Functions: firebase deploy --only functions");
        console.log("2. Update Flutter app to use Firebase backend");
        console.log("3. Test the complete flow");

    } catch (error) {
        console.error("❌ Error initializing collections:", error);
    }
}

// Run the initialization
initializeCollections().then(() => {
    console.log("✅ Initialization complete");
    process.exit(0);
}).catch((error) => {
    console.error("❌ Initialization failed:", error);
    process.exit(1);
});
