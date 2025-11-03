// Minimal empty index.js - nuclear cleanup
const functions = require("firebase-functions/v2");

// Health check only
exports.health = functions.https.onRequest((req, res) => {
    res.json({
        status: "clean_slate",
        timestamp: new Date().toISOString(),
        message: "All reward functions removed - starting fresh"
    });
});