// Simple Firestore initialization script for Firebase Web SDK
// This will be run in the browser console or as a simple web page

// Initialize Firebase (you'll need to run this in a context where Firebase is available)
// For now, we'll create a simple data structure that can be manually added to Firestore

const firestoreInitData = {
  rooms: [
    {
      id: "rookie",
      data: {
        name: "Rookie Room",
        minStake: 10,
        maxStake: 100,
        description: "Perfect for beginners",
        maxPlayers: 4,
        colors: ["red", "blue", "green", "yellow"],
        active: true,
        createdAt: new Date()
      }
    },
    {
      id: "pro", 
      data: {
        name: "Pro Room",
        minStake: 100,
        maxStake: 500,
        description: "For experienced players",
        maxPlayers: 6,
        colors: ["red", "blue", "green", "yellow", "purple", "orange"],
        active: true,
        createdAt: new Date()
      }
    },
    {
      id: "elite",
      data: {
        name: "Elite Room",
        minStake: 500,
        maxStake: 5000,
        description: "High stakes battles",
        maxPlayers: 8,
        colors: ["red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan"],
        active: true,
        createdAt: new Date()
      }
    }
  ],
  
  sampleRound: {
    roomId: "rookie",
    status: "completed",
    players: [
      {
        uid: "test-user-1",
        stake: 50,
        color: "red",
        joinedAt: new Date()
      },
      {
        uid: "test-user-2",
        stake: 75,
        color: "blue", 
        joinedAt: new Date()
      }
    ],
    winner: "test-user-1",
    resultColor: "red",
    totalStake: 125,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  
  sampleJoins: [
    {
      roundId: "sample-round-id", // Replace with actual round ID
      uid: "test-user-1",
      stake: 50,
      color: "red",
      joinedAt: new Date()
    },
    {
      roundId: "sample-round-id", // Replace with actual round ID
      uid: "test-user-2",
      stake: 75,
      color: "blue",
      joinedAt: new Date()
    }
  ]
};

console.log("🎮 Firestore Initialization Data:");
console.log("Copy the following data to your Firestore console:\n");

console.log("📋 ROOMS COLLECTION:");
firestoreInitData.rooms.forEach(room => {
  console.log(`\nDocument ID: ${room.id}`);
  console.log("Data:", JSON.stringify(room.data, null, 2));
});

console.log("\n🎯 SAMPLE ROUND (for testing):");
console.log("Collection: rounds");
console.log("Data:", JSON.stringify(firestoreInitData.sampleRound, null, 2));

console.log("\n📝 SAMPLE JOINS (for testing):");
console.log("Collection: joins");
firestoreInitData.sampleJoins.forEach((join, index) => {
  console.log(`\nJoin ${index + 1}:`, JSON.stringify(join, null, 2));
});

console.log("\n🔗 Next Steps:");
console.log("1. Go to: https://console.firebase.google.com/project/coinnewsextratv-9c75a/firestore");
console.log("2. Create the collections and documents using the data above");
console.log("3. Upgrade to Blaze plan to deploy Cloud Functions");
console.log("4. Run: firebase deploy --only functions");

// Export for manual use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = firestoreInitData;
}
