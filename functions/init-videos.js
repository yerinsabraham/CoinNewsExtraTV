const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  // Try to initialize with default config first
  admin.initializeApp();
} catch (error) {
  console.log('Using Firebase Functions runtime initialization...');
  // If we're running in Firebase Functions, it should already be initialized
}

const db = admin.firestore();

const videoData = [
  {
    id: "p4kmPtTU4lw",
    youtubeId: "p4kmPtTU4lw",
    url: "https://youtu.be/p4kmPtTU4lw?si=EAZq9QCUWDCwPOat",
    title: "Crypto Market Analysis & Trends",
    subtitle: "CoinNews Extra",
    thumbnailUrl: "",
    duration: "12:45",
    views: "15K views",
    uploadTime: "2 hours ago", 
    channelName: "CoinNews Extra",
    description: "Watch and earn crypto rewards! This video covers the latest market analysis and trading strategies. Don't forget to like and subscribe for more crypto content.",
    category: "market-analysis",
    isActive: true,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "Xhq15-cr8mI",
    youtubeId: "Xhq15-cr8mI",
    url: "https://youtu.be/Xhq15-cr8mI?si=aRujNNaB1je-MQaC",
    title: "Bitcoin Price Prediction 2024",
    subtitle: "CoinNews Extra",
    thumbnailUrl: "",
    duration: "8:30",
    views: "23K views",
    uploadTime: "5 hours ago",
    channelName: "CoinNews Extra",
    description: "Get insights into Bitcoin's future price movements and market predictions for 2024. Expert analysis and technical indicators covered.",
    category: "bitcoin",
    isActive: true,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "hfDtTPkPy7E",
    youtubeId: "hfDtTPkPy7E", 
    url: "https://youtu.be/hfDtTPkPy7E?si=3PRfRt7hrWKNKbRN",
    title: "DeFi Protocol Deep Dive",
    subtitle: "CoinNews Extra",
    thumbnailUrl: "",
    duration: "15:20",
    views: "8.5K views",
    uploadTime: "1 day ago",
    channelName: "CoinNews Extra",
    description: "Comprehensive analysis of decentralized finance protocols, yield farming strategies, and DeFi ecosystem developments.",
    category: "defi",
    isActive: true,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "w6Rbpe_Sb3M",
    youtubeId: "w6Rbpe_Sb3M",
    url: "https://youtu.be/w6Rbpe_Sb3M?si=QKxmVnbfUv8_p2Df",
    title: "NFT Market Update & Analysis",
    subtitle: "CoinNews Extra",
    thumbnailUrl: "",
    duration: "10:15", 
    views: "12K views",
    uploadTime: "3 hours ago",
    channelName: "CoinNews Extra",
    description: "Latest updates from the NFT marketplace, trending collections, and market analysis for digital collectibles.",
    category: "nft",
    isActive: true,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    id: "EXqQwDbuW6M",
    youtubeId: "EXqQwDbuW6M",
    url: "https://youtu.be/EXqQwDbuW6M?si=kkIYhwl_qMoW4Uwg",
    title: "Blockchain Technology Explained",
    subtitle: "CoinNews Extra",
    thumbnailUrl: "",
    duration: "18:45",
    views: "31K views", 
    uploadTime: "6 hours ago",
    channelName: "CoinNews Extra",
    description: "Comprehensive guide to blockchain technology, consensus mechanisms, and real-world applications. Perfect for beginners and enthusiasts.",
    category: "education",
    isActive: true,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

async function initVideos() {
  try {
    console.log('🎥 Initializing video database...');
    
    const batch = db.batch();
    
    // Add each video to the videos collection
    for (const video of videoData) {
      const videoRef = db.collection('videos').doc(video.id);
      batch.set(videoRef, video);
      console.log(`📹 Added video: ${video.title}`);
    }
    
    // Commit the batch
    await batch.commit();
    
    console.log('✅ Video database initialized successfully!');
    console.log(`📊 Total videos added: ${videoData.length}`);
    
    // Verify the data
    const videosSnapshot = await db.collection('videos').get();
    console.log(`🔍 Verification: ${videosSnapshot.size} videos found in database`);
    
  } catch (error) {
    console.error('❌ Error initializing video database:', error);
    process.exit(1);
  }
}

// Run the initialization
initVideos().then(() => {
  console.log('🎬 Video initialization complete!');
  process.exit(0);
});
