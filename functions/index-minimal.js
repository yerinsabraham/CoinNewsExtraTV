const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Essential: Username validation function
exports.checkUsernameAvailable = onCall({ cors: true }, async (request) => {
    try {
        const { username } = request.data;
        const uid = request.auth?.uid;

        if (!uid) {
            throw new HttpsError('unauthenticated', 'User must be authenticated');
        }

        if (!username || typeof username !== 'string') {
            throw new HttpsError('invalid-argument', 'Username is required');
        }

        const cleanUsername = username.toLowerCase().trim();

        // Validate username format
        if (cleanUsername.length < 3) {
            return { available: false, error: 'Username must be at least 3 characters' };
        }

        if (cleanUsername.length > 20) {
            return { available: false, error: 'Username must be less than 20 characters' };
        }

        if (!/^[a-zA-Z0-9_]+$/.test(cleanUsername)) {
            return { available: false, error: 'Username can only contain letters, numbers, and underscores' };
        }

        // Check for reserved words
        const reservedWords = ['admin', 'moderator', 'support', 'system', 'bot', 'api', 'root', 'user'];
        if (reservedWords.includes(cleanUsername)) {
            return { available: false, error: 'This username is reserved' };
        }

        // Check if username exists in Firestore
        const usernameQuery = await db.collection('users')
            .where('username', '==', cleanUsername)
            .limit(1)
            .get();

        const isAvailable = usernameQuery.empty;

        return {
            available: isAvailable,
            username: cleanUsername,
            message: isAvailable ? 'Username is available' : 'Username already taken'
        };

    } catch (error) {
        console.error('Username validation error:', error);
        throw new HttpsError('internal', 'Username validation failed');
    }
});

// Essential: Health check function
exports.health = onCall({ cors: true }, async (request) => {
    return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        message: 'Service is running'
    };
});
