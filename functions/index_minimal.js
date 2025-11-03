// Minimal index.js for testing simple functions only
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Import simple functions
const { simpleEarnReward, simpleGetBalance } = require('./simple_rewards');

// Export simple functions
exports.simpleEarnReward = simpleEarnReward;
exports.simpleGetBalance = simpleGetBalance;

// Health check
exports.health = onRequest((req, res) => {
    res.json({
        status: "healthy",
        timestamp: new Date().toISOString(),
        environment: "firebase-functions"
    });
});