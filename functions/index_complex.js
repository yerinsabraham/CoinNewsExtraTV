

// MAINNET MIGRATION - 2025-09-30T17:24:29.281Z
// Token ID: 0.0.10007647
// Treasury: 0.0.10007646
// Network: mainnet
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

// Initialize Firebase Admin first
admin.initializeApp();

// Security Hardening Import - Added by mainnet security integration
const SecurityHardening = require('./security-hardening');
const securitySystem = new SecurityHardening();

// Initialize security system
let securityInitialized = false;
async function initializeSecurity() {
    if (!securityInitialized) {
        await securitySystem.initialize();
        securityInitialized = true;
        console.log('🔒 Security system active for mainnet operations');
    }
}
const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TokenTransferTransaction, 
    TopicMessageSubmitTransaction,
    AccountBalanceQuery,
    Hbar 
} = require("@hashgraph/sdk");

// Import reward engine
const {
    getHalvingTier,
    getRewardAmount,
    applyReward,
    validateAntiAbuse,
    queueTransfer,
    publishToHCS: publishRewardToHCS,
    roundToCNEPrecision
} = require("./src/rewards/rewardEngine");

// Import lock manager
const {
    processTokenUnlocks,
    forceUnlockTokens,
    getUserLocksSummary,
    getSystemLocksStats
} = require("./src/rewards/lockManager");

// Import Hedera transfers
const {
    processPendingTransfers,
    getTransferQueueStats,
    retryFailedTransfers,
    cleanupOldTransfers
} = require("./src/rewards/hederaTransfers");

const db = admin.firestore();

// Hedera Configuration
const HEDERA_ACCOUNT_ID = process.env.HEDERA_ACCOUNT_ID || "0.0.9764298";
const HEDERA_PRIVATE_KEY = process.env.HEDERA_PRIVATE_KEY;
const CNE_TOKEN_ID = process.env.CNE_MAINNET_TOKEN_ID || "0.0.9764298";
const HCS_TOPIC_ID = process.env.HCS_TOPIC_ID || "0.0.6917128";

// Initialize Hedera Client
let hederaClient;
try {
    if (HEDERA_PRIVATE_KEY) {
        hederaClient = Client.forMainnet();
        hederaClient.setOperator(
            AccountId.fromString(HEDERA_ACCOUNT_ID),
            PrivateKey.fromStringED25519(HEDERA_PRIVATE_KEY)
        );
    }
} catch (error) {
    console.warn("Hedera client initialization failed:", error.message);
}

// Utility function to get user's Hedera balance
async function getUserHederaBalance(hederaAccountId) {
    if (!hederaClient || !hederaAccountId) return 0;
    
    try {
        const accountBalance = await new AccountBalanceQuery()
            .setAccountId(hederaAccountId)
            .execute(hederaClient);
        
        const tokenBalance = accountBalance.tokens.get(CNE_TOKEN_ID);
        return tokenBalance ? tokenBalance.toNumber() : 0;
    } catch (error) {
        console.error("Error getting Hedera balance:", error);
        return 0;
    }
}

// Utility function to transfer tokens via Hedera
async function transferTokens(fromAccountId, toAccountId, amount) {
    if (!hederaClient || !fromAccountId || !toAccountId || amount <= 0) {
        throw new Error("Invalid transfer parameters");
    }

    try {
        const transferTx = new TokenTransferTransaction()
            .addTokenTransfer(CNE_TOKEN_ID, fromAccountId, -amount)
            .addTokenTransfer(CNE_TOKEN_ID, toAccountId, amount)
            .freezeWith(hederaClient);

        const response = await transferTx.execute(hederaClient);
        const receipt = await response.getReceipt(hederaClient);
        
        return {
            success: receipt.status.toString() === "SUCCESS",
            transactionId: response.transactionId.toString()
        };
    } catch (error) {
        console.error("Token transfer failed:", error);
        throw error;
    }
}

// Utility function to publish to HCS
async function publishToHCS(message) {
    if (!hederaClient || !HCS_TOPIC_ID) return null;

    try {
        const submitTx = new TopicMessageSubmitTransaction()
            .setTopicId(HCS_TOPIC_ID)
            .setMessage(JSON.stringify(message));

        const response = await submitTx.execute(hederaClient);
        const receipt = await response.getReceipt(hederaClient);
        
        return {
            success: receipt.status.toString() === "SUCCESS",
            transactionId: response.transactionId.toString()
        };
    } catch (error) {
        console.error("HCS publish failed:", error);
        return null;
    }
}

// Cloud Function: Join Timed Battle Round
exports.joinBattle = onCall({ cors: true }, async (request) => {
    try {
        console.log("joinBattle called with data:", JSON.stringify(request.data));
        
        const { roomId, stake, color } = request.data;
        const uid = request.auth?.uid;

        console.log("joinBattle auth check - uid:", uid);

        if (!uid) {
            console.error("joinBattle: Authentication required");
            return { success: false, error: "Authentication required" };
        }

        if (!roomId || !stake || !color) {
            console.error("joinBattle: Missing parameters", { roomId, stake, color });
            return { success: false, error: "Missing required parameters: roomId, stake, color" };
        }

        // Validate room exists and stake is within range
        console.log("joinBattle: Fetching room", roomId);
        const roomDoc = await db.collection("rooms").doc(roomId).get();
        if (!roomDoc.exists) {
            console.error("joinBattle: Room not found", roomId);
            return { success: false, error: "Room not found" };
        }

        const room = roomDoc.data();
        console.log("joinBattle: Room data", room);
        
        if (stake < room.minStake || stake > room.maxStake) {
            console.error("joinBattle: Invalid stake", { stake, min: room.minStake, max: room.maxStake });
            return { success: false, error: `Stake must be between ${room.minStake} and ${room.maxStake}` };
        }

        // Find current active (waiting) round for this room - use current time for comparison
        const now = admin.firestore.Timestamp.now();
        console.log("joinBattle: Searching for active rounds at", now.toDate().toISOString());
        
        const activeRoundsQuery = await db.collection("timedRounds")
            .where("roomId", "==", roomId)
            .where("status", "==", "waiting")
            .where("roundEndTime", ">", now)
            .limit(1)
            .get();

        console.log("joinBattle: Found", activeRoundsQuery.size, "active rounds");

        if (activeRoundsQuery.empty) {
            console.error("joinBattle: No active rounds found");
            return { success: false, error: "No active round available to join. Wait for the next round to start." };
        }

        const roundDoc = activeRoundsQuery.docs[0];
        const roundData = roundDoc.data();
        const roundId = roundDoc.id;

        console.log("joinBattle: Found round", roundId, "with", roundData.players?.length || 0, "players");

        // Double-check if round is still joinable (not expired)
        const roundEndTime = roundData.roundEndTime.toDate();
        const currentTime = new Date();
        
        if (currentTime >= roundEndTime) {
            console.error("joinBattle: Round expired", { currentTime, roundEndTime });
            return { success: false, error: "Round has expired. Wait for the next round to start." };
        }

        // Check if user already joined this round
        const existingPlayer = roundData.players?.find(p => p.uid === uid);
        if (existingPlayer) {
            console.error("joinBattle: User already joined", uid);
            return { success: false, error: "You have already joined this round" };
        }

        // Check if round is full
        const currentPlayerCount = roundData.players?.length || 0;
        const maxPlayers = room.maxPlayers || 8;
        if (currentPlayerCount >= maxPlayers) {
            console.error("joinBattle: Round full", { currentPlayerCount, maxPlayers });
            return { success: false, error: "Round is full. Wait for the next round." };
        }

        // Add player to round
        const newPlayer = {
            uid,
            username: request.auth.token.name || `Player${uid.substring(0, 8)}`,
            avatarColor: color,
            stakeAmount: stake,
            joinedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        console.log("joinBattle: Adding player", newPlayer);

        await roundDoc.ref.update({
            players: admin.firestore.FieldValue.arrayUnion(newPlayer),
            totalStake: admin.firestore.FieldValue.increment(stake),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Log the join in the joins collection
        await db.collection("joins").add({
            roundId,
            uid,
            stake,
            color,
            joinedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log("joinBattle: Successfully joined round", roundId);

        return {
            success: true,
            roundId,
            roundEndTime: roundEndTime.toISOString(),
            message: "Successfully joined battle round"
        };

    } catch (error) {
        console.error("Error in joinBattle:", error);
        console.error("Error stack:", error.stack);
        return { success: false, error: error.message || "Internal server error" };
    }
});

// Cloud Function: Get Active Rounds
exports.getActiveRounds = onCall({ cors: true }, async (request) => {
    try {
        const activeRounds = await db.collection("rounds")
            .where("status", "in", ["waiting", "active"])
            .orderBy("createdAt", "desc")
            .limit(10)
            .get();

        const rounds = [];
        for (const doc of activeRounds.docs) {
            const data = doc.data();
            rounds.push({
                id: doc.id,
                ...data,
                createdAt: data.createdAt?.toDate(),
                updatedAt: data.updatedAt?.toDate()
            });
        }

        return { success: true, rounds };
    } catch (error) {
        console.error("Error in getActiveRounds:", error);
        throw new Error(error.message);
    }
});

// Cloud Function: Get User Stats
exports.getUserStats = onCall({ cors: true }, async (request) => {
    try {
        const uid = request.auth?.uid;
        if (!uid) {
            throw new Error("Authentication required");
        }

        // Get user's battle history
        const userRounds = await db.collection("rounds")
            .where("players", "array-contains-any", [{ uid }])
            .orderBy("createdAt", "desc")
            .limit(10)
            .get();

        let wins = 0;
        let losses = 0;
        const recentBattles = [];

        userRounds.docs.forEach(doc => {
            const data = doc.data();
            const isWinner = data.winner === uid;
            
            if (data.status === "completed") {
                if (isWinner) wins++;
                else losses++;
            }

            recentBattles.push({
                id: doc.id,
                roomId: data.roomId,
                status: data.status,
                isWinner,
                resultColor: data.resultColor,
                createdAt: data.createdAt?.toDate()
            });
        });

        // In a real implementation, we'd get the actual Hedera balance here
        const coinBalance = 1000; // Placeholder

        return {
            success: true,
            stats: {
                coinBalance,
                wins,
                losses,
                totalBattles: wins + losses,
                recentBattles
            }
        };
    } catch (error) {
        console.error("Error in getUserStats:", error);
        throw new Error(error.message);
    }
});

// Firestore Trigger: Handle timed round expiry and auto-create new ones
exports.handleRoundExpiry = onDocumentUpdated("timedRounds/{roundId}", async (event) => {
    const roundId = event.params.roundId;
    const roundData = event.data.after.data();
    
    // Only process waiting rounds that have reached their end time
    if (roundData.status !== "waiting") {
        return null;
    }

    const now = new Date();
    const roundEndTime = roundData.roundEndTime.toDate();
    
    // Check if round has expired (with 30 second buffer for processing)
    if (now.getTime() < (roundEndTime.getTime() + 30000)) {
        return null;
    }
    
    console.log(`🕐 Round ${roundId} for room ${roundData.roomId} has expired, processing...`);

    try {
        console.log(`⏰ Processing expired timed round ${roundId}`);
        
        const playerCount = roundData.players?.length || 0;
        const roomId = roundData.roomId;

        if (playerCount < 2) {
            // Cancel round - not enough players
            await db.collection("timedRounds").doc(roundId).update({
                status: "cancelled",
                cancelReason: "Not enough players",
                completedAt: admin.firestore.Timestamp.fromDate(now),
                updatedAt: admin.firestore.Timestamp.fromDate(now)
            });

            // Refund all players (if any)
            if (playerCount > 0) {
                console.log(`💰 Refunding ${playerCount} players from cancelled round`);
                // TODO: Implement refund logic here
            }

            console.log(`❌ Timed round ${roundId} cancelled - only ${playerCount} players`);
        } else {
            // Start the battle
            await db.collection("timedRounds").doc(roundId).update({
                status: "active",
                updatedAt: admin.firestore.Timestamp.fromDate(now)
            });

            // TODO: Process battle and determine winner
            console.log(`🎯 Timed round ${roundId} started battle with ${playerCount} players`);
        }

        // Automatically create a new round for this room
        console.log(`🔄 Auto-creating replacement round for room ${roomId}...`);
        
        const nextRoundStart = new Date(now.getTime() + 30000); // 30 seconds from now
        const nextRoundDuration = 10 * 60 * 1000; // 10 minutes
        const nextRoundEnd = new Date(nextRoundStart.getTime() + nextRoundDuration);

        const nextRound = {
            roomId,
            status: "waiting",
            roundStartTime: admin.firestore.Timestamp.fromDate(nextRoundStart),
            roundEndTime: admin.firestore.Timestamp.fromDate(nextRoundEnd),
            endsAt: admin.firestore.Timestamp.fromDate(nextRoundEnd), // For compatibility
            players: [],
            maxPlayers: roomId === 'rookie' ? 4 : roomId === 'pro' ? 6 : 8,
            winnerId: null,
            resultColor: null,
            totalStakes: 0,
            createdAt: admin.firestore.Timestamp.fromDate(now),
            updatedAt: admin.firestore.Timestamp.fromDate(now)
        };

        const nextRoundRef = await db.collection("timedRounds").add(nextRound);
        console.log(`✅ Auto-created next round for room ${roomId}: ${nextRoundRef.id}`);
        
        return null;
    } catch (error) {
        console.error(`Error processing round expiry ${roundId}:`, error);
        return null;
    }
});

// Scheduled Function: Auto-create new rounds every 2 minutes
exports.autoCreateRounds = onSchedule({
    schedule: "every 1 minutes",
    timeZone: "UTC"
}, async (event) => {
    try {
        console.log("🕐 Auto-creating new timed rounds for all rooms...");
        
        // Standard room IDs (we'll always ensure these have active rounds)
        const roomIds = ['rookie', 'pro', 'elite'];
        
        const promises = roomIds.map(async (roomId) => {
            try {
                // Check if there's already a waiting round for this room
                const existingRoundQuery = await db.collection("timedRounds")
                    .where("roomId", "==", roomId)
                    .where("status", "==", "waiting")
                    .where("roundEndTime", ">", admin.firestore.Timestamp.now())
                    .limit(1)
                    .get();

                if (!existingRoundQuery.empty) {
                    console.log(`Room ${roomId} already has an active round`);
                    return { roomId, status: 'exists' };
                }

                // Create new round with longer duration
                const now = new Date();
                const roundDuration = 10 * 60 * 1000; // 10 minutes
                const roundEndTime = new Date(now.getTime() + roundDuration);

                const newRound = {
                    roomId,
                    status: "waiting",
                    roundStartTime: admin.firestore.Timestamp.fromDate(now),
                    roundEndTime: admin.firestore.Timestamp.fromDate(roundEndTime),
                    endsAt: admin.firestore.Timestamp.fromDate(roundEndTime), // For compatibility
                    players: [],
                    maxPlayers: roomId === 'rookie' ? 4 : roomId === 'pro' ? 6 : 8,
                    winnerId: null,
                    resultColor: null,
                    totalStakes: 0,
                    createdAt: admin.firestore.Timestamp.fromDate(now),
                    updatedAt: admin.firestore.Timestamp.fromDate(now)
                };

                const docRef = await db.collection("timedRounds").add(newRound);
                console.log(`✅ Created new timed round for room ${roomId}: ${docRef.id}`);
                return { roomId, status: 'created', roundId: docRef.id };
                
            } catch (error) {
                console.error(`❌ Error creating round for room ${roomId}:`, error);
                return { roomId, status: 'error', error: error.message };
            }
        });

        const results = await Promise.all(promises);
        const created = results.filter(r => r?.status === 'created').length;
        const existing = results.filter(r => r?.status === 'exists').length;
        
        console.log(`🎯 Auto-round creation completed: ${created} created, ${existing} existing`);
        
    } catch (error) {
        console.error("❌ Error in auto-create rounds:", error);
    }
});

// ===== CUSTODIAL HEDERA WALLET & CME TOKEN SYSTEM =====

// Constants for CME token system
const CME_TOKEN_DECIMALS = 8; // 8 decimal places for CME token
const CME_MULTIPLIER = Math.pow(10, CME_TOKEN_DECIMALS); // 100,000,000

// Helper functions for CME token units
function toCMEUnits(humanAmount) {
    return Math.floor(humanAmount * CME_MULTIPLIER);
}

function fromCMEUnits(rawUnits) {
    return rawUnits / CME_MULTIPLIER;
}

function roundToCMEPrecision(amount) {
    return Math.floor(amount * CME_MULTIPLIER) / CME_MULTIPLIER;
}

// Cloud Function: Check Username Availability (Secure)
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
        console.error('Error checking username availability:', error);
        throw new HttpsError('internal', 'Failed to check username availability');
    }
});

// Cloud Function: User Onboarding - Creates Custodial Hedera Wallet
exports.onboardUser = onCall({ cors: true }, async (request) => {
    try {
        const { firebaseUid, publicKey } = request.data;
        const uid = request.auth?.uid;

        if (!uid || uid !== firebaseUid) {
            throw new Error('Authentication mismatch');
        }

        // Check if user already exists
        const userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists) {
            const userData = userDoc.data();
            return {
                success: true,
                uid: userData.uid,
                did: userData.did,
                walletAddress: userData.walletAddress,
                hederaAccountId: userData.hederaAccountId,
                message: 'User already onboarded'
            };
        }

        // Generate ED25519 keypair for custodial wallet
        const newPrivateKey = PrivateKey.generateED25519();
        const newPublicKey = newPrivateKey.publicKey;

        // Create Hedera account
        let hederaAccountId;
        try {
            if (hederaClient) {
                const accountCreateTx = new AccountCreateTransaction()
                    .setKey(newPublicKey)
                    .setInitialBalance(new Hbar(0))
                    .freezeWith(hederaClient);

                const response = await accountCreateTx.execute(hederaClient);
                const receipt = await response.getReceipt(hederaClient);
                hederaAccountId = receipt.accountId.toString();
            } else {
                // Mock account ID for testing
                hederaAccountId = `0.0.${Date.now().toString().slice(-7)}`;
            }
        } catch (error) {
            console.error('Hedera account creation failed:', error);
            hederaAccountId = `0.0.${Date.now().toString().slice(-7)}`;
        }

        // Create DID
        const did = `did:hedera:${hederaAccountId}`;

        // Store user data (encrypt private key in production)
        const userData = {
            uid: uid,
            did: did,
            hederaAccountId: hederaAccountId,
            hederaPublicKey: newPublicKey.toString(),
            hederaPrivateKeyEncrypted: newPrivateKey.toString(), // In production: encrypt this!
            points_balance: toCMEUnits(100), // Welcome bonus: 100 CME
            available_balance: toCMEUnits(50), // 50 CME immediately available
            locked_balance: toCMEUnits(50), // 50 CME locked for 2 years
            locks: [{
                lockId: `signup_${uid}`,
                amount: toCMEUnits(50),
                unlockAt: Date.now() + (2 * 365 * 24 * 60 * 60 * 1000), // 2 years
                source: 'signup_bonus'
            }],
            walletAddress: hederaAccountId,
            createdAt: Date.now(),
            lastRedemptionAt: null,
            daily_claimed_at: null
        };

        await db.collection('users').doc(uid).set(userData);

        // Log the signup reward
        await db.collection('rewards_log').add({
            id: `signup_${uid}_${Date.now()}`,
            uid: uid,
            did: did,
            eventType: 'signup_bonus',
            amount: toCMEUnits(100),
            immediate: toCMEUnits(50),
            locked: toCMEUnits(50),
            status: 'COMPLETED',
            idempotencyKey: `signup_${uid}`,
            createdAt: Date.now()
        });

        // Update metrics
        await updateSystemMetrics('signup_bonus', toCMEUnits(100));

        // Publish to HCS for audit trail
        const hcsMessage = {
            type: 'user_onboarded',
            uid: uid,
            did: did,
            hederaAccountId: hederaAccountId,
            initialBalance: toCMEUnits(100),
            timestamp: Date.now()
        };
        await publishToHCS(hcsMessage);

        return {
            success: true,
            uid: uid,
            did: did,
            walletAddress: hederaAccountId,
            hederaAccountId: hederaAccountId,
            initialBalance: fromCMEUnits(toCMEUnits(100)),
            message: 'User onboarded successfully with 100 CME welcome bonus'
        };

    } catch (error) {
        console.error('Error in user onboarding:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Earn Event Processing - Universal reward handler
exports.earnEvent = onCall({ 
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 60,
    region: "us-central1"
}, async (request) => {
    try {
        const { uid, eventType, meta, idempotencyKey } = request.data;
        const authUid = request.auth?.uid;

        // Debug authentication - comprehensive logging
        console.log('🔍 DEBUG earnEvent - Received uid:', uid);
        console.log('🔍 DEBUG earnEvent - Auth uid:', authUid);
        console.log('🔍 DEBUG earnEvent - Auth token present:', !!request.auth?.token);
        console.log('🔍 DEBUG earnEvent - Auth object keys:', request.auth ? Object.keys(request.auth) : 'null');
        console.log('🔍 DEBUG earnEvent - Event type:', eventType);
        console.log('🔍 DEBUG earnEvent - Idempotency key:', idempotencyKey);

        if (!request.auth) {
            console.log('❌ DEBUG earnEvent - No auth object present');
            throw new HttpsError('unauthenticated', 'No authentication provided');
        }

        if (!authUid) {
            console.log('❌ DEBUG earnEvent - No auth UID present');
            throw new HttpsError('unauthenticated', 'Authentication token invalid - no user ID');
        }

        if (!uid) {
            console.log('❌ DEBUG earnEvent - No uid parameter provided');
            throw new HttpsError('invalid-argument', 'User ID parameter required');
        }

        if (authUid !== uid) {
            console.log('❌ DEBUG earnEvent - UID mismatch:', { authUid, providedUid: uid });
            throw new HttpsError('unauthenticated', `Authentication mismatch: token uid(${authUid}) != provided uid(${uid})`);
        }

        console.log('✅ DEBUG earnEvent - Authentication successful for user:', authUid);

        if (!idempotencyKey) {
            throw new HttpsError('invalid-argument', 'Idempotency key is required');
        }

        // Check for duplicate events
        const existingEvent = await db.collection('rewards_log')
            .where('idempotencyKey', '==', idempotencyKey)
            .limit(1)
            .get();

        if (!existingEvent.empty) {
            const existingData = existingEvent.docs[0].data();
            return {
                success: true,
                reward: {
                    amount: existingData.amount,
                    immediate: existingData.immediate,
                    locked: existingData.locked
                },
                message: 'Reward already processed',
                duplicate: true
            };
        }

        // Get user data or create user if doesn't exist  
        const userDoc = await db.collection('users').doc(uid).get();
        let userData;
        
        if (!userDoc.exists) {
            // Create new user document with default values
            userData = {
                points_balance: 0,
                available_balance: 0,
                locked_balance: 0,
                total_earned: 0,
                locks: [],
                did: `did:temp:${uid}`, // Temporary DID until user completes onboarding
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                lastActiveAt: admin.firestore.FieldValue.serverTimestamp()
            };
            
            await db.collection('users').doc(uid).set(userData);
            console.log(`Created new user document for ${uid}`);
        } else {
            userData = userDoc.data();
            // Ensure did exists (for backwards compatibility)
            if (!userData.did) {
                userData.did = `did:temp:${uid}`;
            }
        }

        // Calculate reward based on event type and current tier
        const rewardData = await calculateReward(eventType, meta, userData);
        
        if (!rewardData || rewardData.amount === 0) {
            throw new Error('No reward available for this event');
        }

        // Process reward in transaction
        await db.runTransaction(async (transaction) => {
            const userRef = db.collection('users').doc(uid);
            const userSnapshot = await transaction.get(userRef);
            const currentData = userSnapshot.data();

            // Update user balances
            const newAvailableBalance = currentData.available_balance + rewardData.immediate;
            const newLockedBalance = currentData.locked_balance + rewardData.locked;
            const newTotalBalance = currentData.points_balance + rewardData.amount;
            const newTotalEarned = (currentData.total_earned || 0) + rewardData.amount;
            
            const updates = {
                points_balance: newTotalBalance,
                available_balance: newAvailableBalance,
                locked_balance: newLockedBalance,
                total_earned: newTotalEarned
            };

            // Add lock if there's locked amount
            if (rewardData.locked > 0) {
                const newLock = {
                    lockId: `${eventType}_${uid}_${Date.now()}`,
                    amount: rewardData.locked,
                    unlockAt: Date.now() + (2 * 365 * 24 * 60 * 60 * 1000), // 2 years
                    source: eventType
                };
                
                updates.locks = [...(currentData.locks || []), newLock];
            }

            transaction.update(userRef, updates);

            // Log the reward
            const rewardLogRef = db.collection('rewards_log').doc();
            transaction.set(rewardLogRef, {
                id: rewardLogRef.id,
                uid: uid,
                did: userData.did,
                eventType: eventType,
                amount: rewardData.amount,
                immediate: rewardData.immediate,
                locked: rewardData.locked,
                status: 'COMPLETED',
                idempotencyKey: idempotencyKey,
                meta: meta,
                createdAt: Date.now()
            });
        });

        // Update system metrics
        await updateSystemMetrics(eventType, rewardData.amount);

        // Publish to HCS
        const hcsMessage = {
            type: 'reward_earned',
            uid: uid,
            did: userData.did,
            eventType: eventType,
            amount: rewardData.amount,
            immediate: rewardData.immediate,
            locked: rewardData.locked,
            timestamp: Date.now()
        };
        await publishToHCS(hcsMessage);

        return {
            success: true,
            reward: {
                amount: fromCMEUnits(rewardData.amount),
                immediate: fromCMEUnits(rewardData.immediate),
                locked: fromCMEUnits(rewardData.locked),
                eventType: eventType
            },
            newBalance: {
                available: fromCMEUnits(userData.available_balance + rewardData.immediate),
                locked: fromCMEUnits(userData.locked_balance + rewardData.locked),
                total: fromCMEUnits(userData.points_balance + rewardData.amount)
            },
            message: `Earned ${fromCMEUnits(rewardData.amount)} CME tokens`
        };

    } catch (error) {
        console.error('Error processing earn event:', error);
        
        // Return proper Firebase Functions error
        if (error.code && error.message) {
            throw new HttpsError(error.code, error.message);
        } else {
            throw new HttpsError('internal', `Internal error: ${error.message || error}`);
        }
    }
});

// Cloud Function: Get User Balance
exports.getUserBalance = onCall({ cors: true }, async (request) => {
    try {
        const { uid } = request.data;
        const authUid = request.auth?.uid;

        if (!authUid || authUid !== uid) {
            throw new Error('Authentication mismatch');
        }

        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
            return {
                success: true,
                balance: {
                    available: 0,
                    locked: 0,
                    total: 0,
                    humanAvailable: 0,
                    humanLocked: 0,
                    humanTotal: 0
                }
            };
        }

        const userData = userDoc.data();
        
        // Calculate unlockable tokens
        const now = Date.now();
        let unlockableAmount = 0;
        const activeLocks = [];
        
        if (userData.locks) {
            userData.locks.forEach(lock => {
                if (lock.unlockAt <= now) {
                    unlockableAmount += lock.amount;
                } else {
                    activeLocks.push({
                        lockId: lock.lockId,
                        amount: fromCMEUnits(lock.amount),
                        unlockAt: lock.unlockAt,
                        unlockDate: new Date(lock.unlockAt).toISOString(),
                        source: lock.source,
                        daysRemaining: Math.ceil((lock.unlockAt - now) / (24 * 60 * 60 * 1000))
                    });
                }
            });
        }

        return {
            success: true,
            balance: {
                available: userData.available_balance || 0,
                locked: userData.locked_balance || 0,
                total: userData.points_balance || 0,
                humanAvailable: fromCMEUnits(userData.available_balance || 0),
                humanLocked: fromCMEUnits(userData.locked_balance || 0),
                humanTotal: fromCMEUnits(userData.points_balance || 0),
                unlockable: fromCMEUnits(unlockableAmount),
                activeLocks: activeLocks,
                walletAddress: userData.walletAddress,
                did: userData.did
            }
        };

    } catch (error) {
        console.error('Error getting user balance:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Deduct Tokens (for quiz entry fees, purchases, etc.)
exports.deductTokens = onCall({ cors: true }, async (request) => {
    try {
        const { uid, amount, reason, metadata } = request.data;
        const authUid = request.auth?.uid;

        if (!authUid || authUid !== uid) {
            throw new HttpsError('unauthenticated', 'Authentication mismatch');
        }

        if (!amount || amount <= 0) {
            throw new HttpsError('invalid-argument', 'Invalid deduction amount');
        }

        // Get user data
        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
            throw new HttpsError('not-found', 'User not found');
        }

        const userData = userDoc.data();
        const currentBalance = userData.available_balance || 0;

        // Check if user has sufficient balance
        if (currentBalance < amount) {
            return {
                success: false,
                message: `Insufficient balance. Required: ${amount}, Available: ${currentBalance}`,
                currentBalance: fromCMEUnits(currentBalance)
            };
        }

        // Process deduction in transaction
        await db.runTransaction(async (transaction) => {
            const userRef = db.collection('users').doc(uid);
            const userSnapshot = await transaction.get(userRef);
            const currentData = userSnapshot.data();

            const newAvailableBalance = currentData.available_balance - amount;
            const newTotalBalance = currentData.points_balance - amount;

            // Update user balances
            transaction.update(userRef, {
                available_balance: newAvailableBalance,
                points_balance: newTotalBalance,
                lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Log the deduction
            const deductionLogRef = db.collection('deductions_log').doc();
            transaction.set(deductionLogRef, {
                id: deductionLogRef.id,
                uid: uid,
                amount: amount,
                reason: reason || 'Token deduction',
                metadata: metadata || {},
                balanceBefore: currentData.available_balance,
                balanceAfter: newAvailableBalance,
                status: 'COMPLETED',
                createdAt: Date.now()
            });
        });

        console.log(`Successfully deducted ${amount} tokens from user ${uid} for reason: ${reason}`);

        return {
            success: true,
            message: 'Tokens deducted successfully',
            deductedAmount: fromCMEUnits(amount),
            newBalance: fromCMEUnits(currentBalance - amount)
        };

    } catch (error) {
        console.error('Error deducting tokens:', error);
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError('internal', error.message);
    }
});

// Cloud Function: Redeem CME Tokens (Convert points to on-chain tokens)
exports.redeemTokens = onCall({ cors: true }, async (request) => {
    try {
        const { uid, amount } = request.data; // amount in raw units
        const authUid = request.auth?.uid;

        if (!authUid || authUid !== uid) {
            throw new Error('Authentication mismatch');
        }

        if (!amount || amount <= 0) {
            throw new Error('Invalid redemption amount');
        }

        // Get user data
        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const userData = userDoc.data();
        
        if (userData.available_balance < amount) {
            throw new Error('Insufficient available balance');
        }

        // Create redemption record and lock tokens
        const redemptionId = `redeem_${uid}_${Date.now()}`;
        
        await db.runTransaction(async (transaction) => {
            const userRef = db.collection('users').doc(uid);
            const userSnapshot = await transaction.get(userRef);
            const currentData = userSnapshot.data();

            if (currentData.available_balance < amount) {
                throw new Error('Insufficient available balance');
            }

            // Lock the redemption amount
            transaction.update(userRef, {
                available_balance: currentData.available_balance - amount,
                lastRedemptionAt: Date.now()
            });

            // Create redemption record
            const redemptionRef = db.collection('redemptions').doc(redemptionId);
            transaction.set(redemptionRef, {
                id: redemptionId,
                uid: uid,
                did: userData.did,
                amount: amount,
                status: 'ENQUEUED',
                hederaAccountId: userData.hederaAccountId,
                createdAt: Date.now()
            });
        });

        // Queue for processing
        await queueTransfer(uid, userData.hederaAccountId, amount, redemptionId);

        return {
            success: true,
            redemptionId: redemptionId,
            amount: fromCMEUnits(amount),
            status: 'ENQUEUED',
            message: `Redemption of ${fromCMEUnits(amount)} CME tokens queued for processing`
        };

    } catch (error) {
        console.error('Error processing redemption:', error);
        throw new Error(error.message);
    }
});

// Helper function to calculate rewards based on configurable rates and halving tiers
async function calculateReward(eventType, meta, userData) {
    try {
        // Get reward configuration
        const configDoc = await db.collection('config').doc('reward_rates').get();
        const rewardConfig = configDoc.exists ? configDoc.data() : null;
        
        // Get current user count for halving tier
        const metricsDoc = await db.collection('config').doc('metrics').get();
        const metrics = metricsDoc.data() || {};
        const userCount = metrics.user_count || 0;
        
        // Get halving configuration
        const halvingDoc = await db.collection('config').doc('halving_config').get();
        const halvingData = halvingDoc.data() || {
            users_per_tier: 10000,
            max_tier: 10,
            min_reward_multiplier: 0.001
        };
        
        // Calculate tier and multiplier
        const tier = Math.min(halvingData.max_tier || 10, Math.floor(userCount / (halvingData.users_per_tier || 10000)));
        const tierMultiplier = Math.max(halvingData.min_reward_multiplier || 0.001, 1.0 / Math.pow(2, tier));
        
        // Get base reward amount from configuration
        let baseRewardAmount = 0;
        console.log(`Calculating reward for eventType: ${eventType}, tier: ${tier}, tierMultiplier: ${tierMultiplier}`);
        
        if (rewardConfig && rewardConfig[eventType]) {
            const eventConfig = rewardConfig[eventType];
            if (eventConfig.enabled) {
                baseRewardAmount = eventConfig.base || 0;
                console.log(`Using config reward: ${baseRewardAmount} for ${eventType}`);
            } else {
                // Reward type is disabled
                console.log(`Reward type ${eventType} is disabled in config`);
                return { amount: 0, immediate: 0, locked: 0 };
            }
        } else {
            // Fallback to default amounts
            const defaultRewards = {
                video_watch: 5.0,
                ad_view: 2.0,
                daily_airdrop: 10.0,
                daily_checkin: 10.0,      // Added missing daily check-in reward
                social_follow: 3.0,
                referral_bonus: 25.0,
                live_stream: 8.0,
                quiz_completion: 15.0,
                spin2earn: 50.0,          // Added missing spin game reward
                test: 1.0                 // Added test reward for debugging
            };
            baseRewardAmount = defaultRewards[eventType] || 0;
            console.log(`Using default reward: ${baseRewardAmount} for ${eventType}`);
        }
        
        if (baseRewardAmount <= 0) {
            return { amount: 0, immediate: 0, locked: 0 };
        }
        
        // Apply tier multiplier
        let finalAmount = baseRewardAmount * tierMultiplier;
        console.log(`Final amount after tier multiplier: ${finalAmount} (base: ${baseRewardAmount} * tier: ${tierMultiplier})`);
        
        // Apply event-specific validation and logic
        switch (eventType) {
            case 'video_watch':
                // Calculate watch percentage from duration data
                const watchDuration = meta.watchDuration || 0;
                const totalDuration = meta.totalDuration || 0;
                const watchPercentage = totalDuration > 0 ? watchDuration / totalDuration : 0;
                
                // Require minimum 30 seconds OR 70% completion (whichever is more lenient)
                const minWatchTime = 30;
                const requiredPercentage = 0.7;
                
                if (watchDuration < minWatchTime && watchPercentage < requiredPercentage) {
                    console.log(`Video watch validation failed: ${watchDuration}s watched, ${(watchPercentage * 100).toFixed(1)}% complete`);
                    return { amount: 0, immediate: 0, locked: 0 };
                }
                console.log(`Video watch validation passed: ${watchDuration}s watched, ${(watchPercentage * 100).toFixed(1)}% complete`);
                break;
                
            case 'ad_view':
                // Require minimum 25 seconds viewing
                if (!meta.adDuration || meta.adDuration < 25) {
                    return { amount: 0, immediate: 0, locked: 0 };
                }
                break;
                
            case 'live_stream':
                // Require minimum 2 minutes
                if (!meta.watchDuration || meta.watchDuration < 120) {
                    return { amount: 0, immediate: 0, locked: 0 };
                }
                // Reward per 10-minute segment
                const segments = Math.floor(meta.watchDuration / 600);
                finalAmount = finalAmount * Math.max(1, segments);
                break;
                
            case 'daily_airdrop':
                // Check daily limit
                const today = new Date().toISOString().split('T')[0];
                if (userData.daily_claimed_at === today) {
                    return { amount: 0, immediate: 0, locked: 0 };
                }
                break;
                
            case 'quiz_completion':
                // Apply accuracy bonus
                if (meta.accuracy) {
                    const accuracyBonus = Math.max(0.5, meta.accuracy); // Minimum 50% of reward
                    finalAmount = finalAmount * accuracyBonus;
                }
                // Apply speed bonus
                if (meta.speedBonus) {
                    finalAmount = finalAmount * meta.speedBonus;
                }
                break;
        }
        
        // Convert to raw units and split immediate/locked
        const rawAmount = toCMEUnits(finalAmount);
        const immediate = Math.floor(rawAmount * 0.5); // 50% immediate
        const locked = Math.floor(rawAmount * 0.5);    // 50% locked for 2 years

        console.log(`Reward calculation result: rawAmount=${rawAmount}, immediate=${immediate}, locked=${locked}, finalAmount=${finalAmount}`);

        return {
            amount: rawAmount,
            immediate: immediate,
            locked: locked,
            tier: tier,
            tierMultiplier: tierMultiplier,
            baseAmount: baseRewardAmount
        };
        
    } catch (error) {
        console.error('Error calculating reward:', error);
        return { amount: 0, immediate: 0, locked: 0 };
    }
}

// Helper function to update system metrics
async function updateSystemMetrics(eventType, amount) {
    try {
        const metricsRef = db.collection('config').doc('metrics');
        await db.runTransaction(async (transaction) => {
            const metricsDoc = await transaction.get(metricsRef);
            const currentData = metricsDoc.exists ? metricsDoc.data() : {};
            
            const updates = {
                total_distributed: (currentData.total_distributed || 0) + amount,
                daily_distribution: (currentData.daily_distribution || 0) + amount,
                [`event_stats.${eventType}`]: ((currentData.event_stats || {})[eventType] || 0) + 1,
                last_updated: Date.now()
            };
            
            transaction.set(metricsRef, updates, { merge: true });
        });
    } catch (error) {
        console.error('Error updating system metrics:', error);
    }
}

// queueTransfer is imported from rewardEngine module

// ===== LEGACY REWARD SYSTEM FUNCTIONS (for compatibility) =====

// Cloud Function: Process Video Watch Reward (Live Videos - 10 min segments)
exports.processLiveWatchReward = onCall({ cors: true }, async (request) => {
    try {
        const { videoId, sessionId, watchDuration } = request.data;
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        // Validate minimum watch duration (10 minutes = 600 seconds)
        if (watchDuration < 600) {
            throw new Error('Insufficient watch time - minimum 10 minutes required');
        }

        // Anti-abuse: validate watch session
        await validateWatchSession(sessionId, watchDuration);

        // Calculate how many 10-minute segments completed
        const segments = Math.floor(watchDuration / 600);
        const idempotencyKey = `live_${uid}_${videoId}_${segments}`;

        const reward = await applyReward(uid, 'live_10min', {
            video_id: videoId,
            session_id: sessionId,
            watch_duration: watchDuration,
            segments_completed: segments
        }, idempotencyKey);

        return {
            success: true,
            reward,
            segments_rewarded: segments,
            message: `Rewarded for ${segments} segments (${watchDuration} seconds total)`
        };

    } catch (error) {
        console.error('Error processing live watch reward:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Process Video Watch Reward (Other Videos - 25% completion)
exports.processVideoWatchReward = onCall({ cors: true }, async (request) => {
    try {
        const { videoId, watchedPercentage, totalDuration } = request.data;
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        if (watchedPercentage < 0.25) {
            throw new Error('Insufficient watch percentage - minimum 25% required');
        }

        const idempotencyKey = `video_${uid}_${videoId}_25pct`;

        const reward = await applyReward(uid, 'other_25pct', {
            video_id: videoId,
            watched_percentage: watchedPercentage,
            total_duration: totalDuration
        }, idempotencyKey);

        return {
            success: true,
            reward,
            message: `Rewarded for watching ${Math.round(watchedPercentage * 100)}% of video`
        };

    } catch (error) {
        console.error('Error processing video watch reward:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Process Ad View Reward
exports.processAdViewReward = onCall({ cors: true }, async (request) => {
    try {
        const { adId, adProvider, completionToken, adDuration } = request.data;
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        // Verify ad completion (in production, validate with 3rd party provider)
        if (!completionToken) {
            throw new Error('Invalid ad completion - no completion token');
        }

        const idempotencyKey = `ad_${uid}_${adId}_${completionToken}`;

        const reward = await applyReward(uid, 'ad_view', {
            ad_id: adId,
            ad_provider: adProvider,
            completion_token: completionToken,
            ad_duration: adDuration
        }, idempotencyKey);

        return {
            success: true,
            reward,
            message: 'Ad view reward processed successfully'
        };

    } catch (error) {
        console.error('Error processing ad view reward:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Process Signup Bonus
exports.processSignupBonus = onCall({ cors: true }, async (request) => {
    try {
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        // Verify this is a new user (check creation timestamp)
        const userRecord = await admin.auth().getUser(uid);
        const accountAge = Date.now() - new Date(userRecord.metadata.creationTime).getTime();

        if (accountAge > 24 * 60 * 60 * 1000) { // More than 24 hours old
            throw new Error('Signup bonus expired - must claim within 24 hours of registration');
        }

        const idempotencyKey = `signup_${uid}`;

        const reward = await applyReward(uid, 'signup_bonus', {
            account_created: userRecord.metadata.creationTime,
            user_email: userRecord.email || null
        }, idempotencyKey);

        return {
            success: true,
            reward,
            message: 'Signup bonus processed successfully'
        };

    } catch (error) {
        console.error('Error processing signup bonus:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Process Referral Bonus
exports.processReferralBonus = onCall({ cors: true }, async (request) => {
    try {
        const { referredUserId } = request.data;
        const referrerUid = request.auth?.uid;

        if (!referrerUid) {
            throw new Error('Authentication required');
        }

        // Validate referral relationship
        await validateReferral(referrerUid, referredUserId);

        const idempotencyKey = `referral_${referrerUid}_${referredUserId}`;

        const reward = await applyReward(referrerUid, 'referral_bonus', {
            referred_user: referredUserId,
            referrer_user: referrerUid
        }, idempotencyKey);

        return {
            success: true,
            reward,
            message: 'Referral bonus processed successfully'
        };

    } catch (error) {
        console.error('Error processing referral bonus:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Claim Daily Airdrop
exports.claimDailyAirdrop = onCall({ cors: true }, async (request) => {
    try {
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        const today = new Date().toISOString().split('T')[0]; // UTC date

        // Check if already claimed today
        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        const userData = userDoc.data();

        if (userData?.daily_claimed_at === today) {
            throw new Error('Daily airdrop already claimed today');
        }

        const idempotencyKey = `daily_${uid}_${today}`;

        // Update claim date first
        await admin.firestore().doc(`users/${uid}`).set({
            daily_claimed_at: today
        }, { merge: true });

        const reward = await applyReward(uid, 'daily_airdrop', {
            claim_date: today
        }, idempotencyKey);

        return {
            success: true,
            reward,
            message: 'Daily airdrop claimed successfully',
            next_claim_available: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        };

    } catch (error) {
        console.error('Error processing daily airdrop:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Process Social Follow Reward
exports.processSocialFollowReward = onCall({ cors: true }, async (request) => {
    try {
        const { platform, accountHandle, verificationToken } = request.data;
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        // In production, validate social follow with OAuth or API verification
        if (!verificationToken) {
            throw new Error('Social follow verification required');
        }

        const idempotencyKey = `social_${uid}_${platform}_${accountHandle}`;

        const reward = await applyReward(uid, 'social_follow', {
            platform,
            account_handle: accountHandle,
            verification_token: verificationToken
        }, idempotencyKey);

        return {
            success: true,
            reward,
            message: `Social follow reward for ${platform} processed successfully`
        };

    } catch (error) {
        console.error('Error processing social follow reward:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Get User Reward Balance
exports.getUserRewardBalance = onCall({ cors: true }, async (request) => {
    try {
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        
        if (!userDoc.exists) {
            return {
                success: true,
                balance: {
                    available_balance: 0,
                    locked_balance: 0,
                    total_earned: 0,
                    locks: []
                }
            };
        }

        const userData = userDoc.data();

        // Calculate unlockable amounts
        const now = new Date();
        let unlockableAmount = 0;
        const upcomingUnlocks = [];

        if (userData.locks) {
            userData.locks.forEach(lock => {
                const unlockDate = new Date(lock.unlockAt);
                if (unlockDate <= now) {
                    unlockableAmount += lock.amount;
                } else {
                    upcomingUnlocks.push({
                        amount: lock.amount,
                        unlockAt: lock.unlockAt,
                        source: lock.source,
                        daysRemaining: Math.ceil((unlockDate - now) / (24 * 60 * 60 * 1000))
                    });
                }
            });
        }

        return {
            success: true,
            balance: {
                available_balance: userData.available_balance || 0,
                locked_balance: userData.locked_balance || 0,
                total_earned: userData.total_earned || 0,
                unlockable_amount: unlockableAmount,
                upcoming_unlocks: upcomingUnlocks,
                daily_claimed_at: userData.daily_claimed_at,
                wallet_address: userData.wallet_address
            }
        };

    } catch (error) {
        console.error('Error getting user reward balance:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Get Reward System Status
exports.getRewardSystemStatus = onCall({ cors: true }, async (request) => {
    try {
        const [metricsDoc, systemDoc, halvingDoc] = await Promise.all([
            admin.firestore().doc('metrics/totals').get(),
            admin.firestore().doc('config/system').get(),
            admin.firestore().doc('config/halving').get()
        ]);

        const metrics = metricsDoc.data() || {};
        const system = systemDoc.data() || {};
        const halving = halvingDoc.data() || {};

        const currentUserCount = metrics.user_count || 0;
        const currentTier = getHalvingTier(currentUserCount);

        return {
            success: true,
            status: {
                rewards_active: !system.rewards_paused,
                network: system.network || 'testnet',
                current_user_count: currentUserCount,
                current_tier: currentTier,
                total_distributed: metrics.total_distributed || 0,
                total_locked: metrics.total_locked || 0,
                daily_distribution: metrics.daily_distribution || 0,
                event_stats: metrics.event_stats || {},
                current_reward_amounts: halving.mapping ? halving.mapping[currentTier.toString()] : null
            }
        };

    } catch (error) {
        console.error('Error getting reward system status:', error);
        throw new Error(error.message);
    }
});

// Helper function to validate watch sessions
async function validateWatchSession(sessionId, watchDuration) {
    // In production, validate against session tracking data
    // For now, basic validation
    if (!sessionId || watchDuration < 60) {
        throw new Error('Invalid watch session');
    }
    
    // TODO: Implement proper session validation
    // - Check for excessive skipping
    // - Verify continuous watch time
    // - Detect bot behavior
    
    return true;
}

// Helper function to validate referrals
async function validateReferral(referrerUid, referredUserId) {
    // Prevent self-referral
    if (referrerUid === referredUserId) {
        throw new Error('Self-referral not allowed');
    }

    // Check if referred user has minimum activity (7 days)
    const referredUser = await admin.auth().getUser(referredUserId);
    const accountAge = Date.now() - new Date(referredUser.metadata.creationTime).getTime();
    const sevenDays = 7 * 24 * 60 * 60 * 1000;

    if (accountAge < sevenDays) {
        throw new Error('Referred user must be active for at least 7 days');
    }

    // Check for existing referral relationship
    const existingReferral = await admin.firestore()
        .collection('rewards_log')
        .where('uid', '==', referrerUid)
        .where('event_type', '==', 'referral_bonus')
        .where('event_metadata.referred_user', '==', referredUserId)
        .limit(1)
        .get();

    if (!existingReferral.empty) {
        throw new Error('Referral bonus already claimed for this user');
    }

    return true;
}

// ===== TOKEN LOCKING SYSTEM =====

// Scheduled function to unlock tokens (runs daily at midnight UTC)
exports.processTokenUnlocks = onSchedule({
    schedule: '0 0 * * *', // Daily at midnight UTC
    timeZone: 'UTC'
}, async (context) => {
    try {
        console.log('🕐 Starting scheduled token unlock process...');
        const result = await processTokenUnlocks();
        console.log('✅ Scheduled token unlock completed:', result);
        return result;
    } catch (error) {
        console.error('❌ Scheduled token unlock failed:', error);
        throw error;
    }
});

// Cloud Function: Manual Token Unlock (Admin Only)
exports.forceUnlockTokens = onCall({ cors: true }, async (request) => {
    try {
        const { targetUserId, lockId, reason } = request.data;
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        const result = await forceUnlockTokens(adminUid, targetUserId, lockId, reason);

        return {
            success: true,
            result,
            message: 'Tokens force unlocked successfully'
        };

    } catch (error) {
        console.error('Error in force unlock tokens:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Get User Locks Summary
exports.getUserLocksSummary = onCall({ cors: true }, async (request) => {
    try {
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error('Authentication required');
        }

        const summary = await getUserLocksSummary(uid);

        return {
            success: true,
            locks_summary: summary
        };

    } catch (error) {
        console.error('Error getting user locks summary:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Get System Locks Statistics (Admin Only)
exports.getSystemLocksStats = onCall({ cors: true }, async (request) => {
    try {
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists) {
            throw new Error('Admin access required');
        }

        const stats = await getSystemLocksStats();

        return {
            success: true,
            locks_stats: stats
        };

    } catch (error) {
        console.error('Error getting system locks stats:', error);
        throw new Error(error.message);
    }
});

// ===== USER ACCOUNT MANAGEMENT =====

// Cloud Function: Delete User Account (Admin Only)
exports.deleteUserAccount = onCall({ cors: true }, async (request) => {
    try {
        const { email, reason } = request.data;
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new HttpsError('unauthenticated', 'Authentication required');
        }

        // Verify admin permissions
        const adminDoc = await db.collection('admins').doc(adminUid).get();
        if (!adminDoc.exists) {
            throw new HttpsError('permission-denied', 'Admin access required');
        }

        console.log(`🗑️ Admin ${adminUid} requesting deletion of account: ${email}`);

        // Find user by email
        let userRecord;
        try {
            userRecord = await admin.auth().getUserByEmail(email);
        } catch (error) {
            if (error.code === 'auth/user-not-found') {
                return {
                    success: false,
                    message: `No user found with email: ${email}`
                };
            }
            throw error;
        }

        const userId = userRecord.uid;
        console.log(`Found user: ${userId} with email: ${email}`);

        // Collect user data before deletion for logging
        const userDoc = await db.collection('users').doc(userId).get();
        const userData = userDoc.exists ? userDoc.data() : null;

        // Start deletion process
        const deletionResults = {
            auth: false,
            userData: false,
            rewardsLog: 0,
            socialVerifications: 0,
            redemptions: 0,
            battles: 0,
            pendingTransfers: 0,
            adminActions: 0
        };

        try {
            // 1. Delete from Firebase Auth
            await admin.auth().deleteUser(userId);
            deletionResults.auth = true;
            console.log(`✅ Deleted Firebase Auth user: ${userId}`);

            // 2. Delete user document
            if (userDoc.exists) {
                await db.collection('users').doc(userId).delete();
                deletionResults.userData = true;
                console.log(`✅ Deleted user document: ${userId}`);
            }

            // 3. Delete rewards log entries
            const rewardsQuery = await db.collection('rewards_log')
                .where('uid', '==', userId)
                .get();
            
            const rewardsBatch = db.batch();
            rewardsQuery.docs.forEach(doc => {
                rewardsBatch.delete(doc.ref);
            });
            await rewardsBatch.commit();
            deletionResults.rewardsLog = rewardsQuery.size;
            console.log(`✅ Deleted ${rewardsQuery.size} rewards log entries`);

            // 4. Delete social verifications
            const socialQuery = await db.collection('users').doc(userId)
                .collection('social_verifications').get();
            
            const socialBatch = db.batch();
            socialQuery.docs.forEach(doc => {
                socialBatch.delete(doc.ref);
            });
            await socialBatch.commit();
            deletionResults.socialVerifications = socialQuery.size;
            console.log(`✅ Deleted ${socialQuery.size} social verification entries`);

            // 5. Delete redemptions
            const redemptionsQuery = await db.collection('redemptions')
                .where('uid', '==', userId)
                .get();
            
            const redemptionsBatch = db.batch();
            redemptionsQuery.docs.forEach(doc => {
                redemptionsBatch.delete(doc.ref);
            });
            await redemptionsBatch.commit();
            deletionResults.redemptions = redemptionsQuery.size;
            console.log(`✅ Deleted ${redemptionsQuery.size} redemption entries`);

            // 6. Remove from battle rounds (update arrays, don't delete rounds)
            const battlesQuery = await db.collection('timedRounds')
                .where('players', 'array-contains-any', [{ uid: userId }])
                .get();
            
            const battlesBatch = db.batch();
            battlesQuery.docs.forEach(battleDoc => {
                const battleData = battleDoc.data();
                const updatedPlayers = battleData.players.filter(player => player.uid !== userId);
                battlesBatch.update(battleDoc.ref, { 
                    players: updatedPlayers,
                    totalStake: updatedPlayers.reduce((sum, p) => sum + p.stakeAmount, 0)
                });
            });
            await battlesBatch.commit();
            deletionResults.battles = battlesQuery.size;
            console.log(`✅ Removed user from ${battlesQuery.size} battle rounds`);

            // 7. Delete pending transfers
            const transfersQuery = await db.collection('pending_transfers')
                .where('uid', '==', userId)
                .get();
            
            const transfersBatch = db.batch();
            transfersQuery.docs.forEach(doc => {
                transfersBatch.delete(doc.ref);
            });
            await transfersBatch.commit();
            deletionResults.pendingTransfers = transfersQuery.size;
            console.log(`✅ Deleted ${transfersQuery.size} pending transfer entries`);

            // 8. Log the deletion action
            await db.collection('admin_actions').add({
                action: 'delete_user_account',
                admin_user: adminUid,
                target_user_id: userId,
                target_user_email: email,
                reason: reason || 'No reason provided',
                user_data_snapshot: userData ? {
                    points_balance: userData.points_balance,
                    available_balance: userData.available_balance,
                    locked_balance: userData.locked_balance,
                    total_earned: userData.total_earned,
                    createdAt: userData.createdAt,
                    walletAddress: userData.walletAddress
                } : null,
                deletion_results: deletionResults,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });

            // 9. Publish to HCS for audit trail
            const hcsMessage = {
                type: 'user_account_deleted',
                admin_uid: adminUid,
                deleted_user_id: userId,
                deleted_user_email: email,
                reason: reason || 'No reason provided',
                deletion_results: deletionResults,
                timestamp: Date.now()
            };
            await publishToHCS(hcsMessage);

            console.log(`✅ Successfully deleted user account: ${email} (${userId})`);

            return {
                success: true,
                message: `User account deleted successfully: ${email}`,
                deleted_user_id: userId,
                deletion_summary: {
                    firebase_auth: deletionResults.auth,
                    user_document: deletionResults.userData,
                    rewards_entries: deletionResults.rewardsLog,
                    social_verifications: deletionResults.socialVerifications,
                    redemptions: deletionResults.redemptions,
                    battle_participations: deletionResults.battles,
                    pending_transfers: deletionResults.pendingTransfers
                }
            };

        } catch (error) {
            console.error(`❌ Error during user deletion: ${error.message}`);
            
            // Log the failed deletion attempt
            await db.collection('admin_actions').add({
                action: 'delete_user_account_failed',
                admin_user: adminUid,
                target_user_id: userId,
                target_user_email: email,
                reason: reason || 'No reason provided',
                error_message: error.message,
                partial_results: deletionResults,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            });

            throw new HttpsError('internal', `Deletion failed: ${error.message}`);
        }

    } catch (error) {
        console.error('Error in deleteUserAccount:', error);
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError('internal', error.message);
    }
});

// ===== ADMIN CONTROLS =====

// Cloud Function: Override Reward Amount (Admin Only)
exports.overrideRewardAmount = onCall({ cors: true }, async (request) => {
    try {
        const { eventType, newAmount, durationHours, reason } = request.data;
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists) {
            throw new Error('Admin access required');
        }

        const expiresAt = new Date(Date.now() + (durationHours * 60 * 60 * 1000));

        await admin.firestore().doc('config/reward_overrides').set({
            [eventType]: {
                override_amount: newAmount,
                expires_at: expiresAt,
                reason,
                admin_user: adminUid,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            }
        }, { merge: true });

        // Log the override action
        await admin.firestore().collection('admin_actions').add({
            action: 'reward_override',
            admin_user: adminUid,
            event_type: eventType,
            new_amount: newAmount,
            duration_hours: durationHours,
            reason,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            message: `Reward override set for ${eventType}`,
            expires_at: expiresAt.toISOString()
        };

    } catch (error) {
        console.error('Error setting reward override:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Pause/Resume Rewards (Super Admin Only)
exports.pauseRewards = onCall({ cors: true }, async (request) => {
    try {
        const { reason } = request.data;
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify super admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists || !adminDoc.data().isSuperAdmin) {
            throw new Error('Super admin permissions required');
        }

        await admin.firestore().doc('config/system').update({
            rewards_paused: true,
            pause_reason: reason,
            paused_by: adminUid,
            paused_at: admin.firestore.FieldValue.serverTimestamp()
        });

        // Log the pause action
        await admin.firestore().collection('admin_actions').add({
            action: 'pause_rewards',
            admin_user: adminUid,
            reason,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            message: 'All rewards paused successfully'
        };

    } catch (error) {
        console.error('Error pausing rewards:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Resume Rewards (Super Admin Only)
exports.resumeRewards = onCall({ cors: true }, async (request) => {
    try {
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify super admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists || !adminDoc.data().isSuperAdmin) {
            throw new Error('Super admin permissions required');
        }

        await admin.firestore().doc('config/system').update({
            rewards_paused: false,
            pause_reason: admin.firestore.FieldValue.delete(),
            resumed_by: adminUid,
            resumed_at: admin.firestore.FieldValue.serverTimestamp()
        });

        // Log the resume action
        await admin.firestore().collection('admin_actions').add({
            action: 'resume_rewards',
            admin_user: adminUid,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            message: 'Rewards resumed successfully'
        };

    } catch (error) {
        console.error('Error resuming rewards:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Get System Health (Admin Dashboard)
exports.getSystemHealth = onCall({ cors: true }, async (request) => {
    try {
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists) {
            throw new Error('Admin access required');
        }

        const [metricsDoc, systemDoc, overridesDoc] = await Promise.all([
            admin.firestore().doc('metrics/totals').get(),
            admin.firestore().doc('config/system').get(),
            admin.firestore().doc('config/reward_overrides').get()
        ]);

        const metrics = metricsDoc.data() || {};
        const system = systemDoc.data() || {};
        const overrides = overridesDoc.data() || {};

        // Calculate distribution rate (last 24 hours)
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const recentRewards = await admin.firestore()
            .collection('rewards_log')
            .where('created_at', '>=', yesterday)
            .get();

        const last24hDistribution = recentRewards.docs.reduce((sum, doc) => 
            sum + (doc.data().amount || 0), 0);

        // Check pending transfers
        const pendingTransfers = await admin.firestore()
            .collection('pending_transfers')
            .where('status', '==', 'PENDING')
            .get();

        return {
            success: true,
            system_health: {
                system_status: {
                    rewards_active: !system.rewards_paused,
                    network: system.network || 'testnet',
                    migration_in_progress: system.migration_in_progress || false
                },
                metrics: {
                    total_users: metrics.user_count || 0,
                    current_tier: getHalvingTier(metrics.user_count || 0),
                    total_distributed: metrics.total_distributed || 0,
                    total_locked: metrics.total_locked || 0,
                    last_24h_distribution: last24hDistribution
                },
                operations: {
                    pending_transfers: pendingTransfers.size,
                    active_overrides: Object.keys(overrides).filter(key => key !== 'created_at').length,
                    last_unlock_run: metrics.last_unlock_run
                },
                event_stats: metrics.event_stats || {}
            }
        };

    } catch (error) {
        console.error('Error getting system health:', error);
        throw new Error(error.message);
    }
});

// ===== HEDERA TRANSFER QUEUE SYSTEM =====

// Scheduled function to process pending transfers (runs every 10 minutes)
exports.processPendingTransfers = onSchedule({
    schedule: '*/10 * * * *', // Every 10 minutes
    timeZone: 'UTC'
}, async (context) => {
    try {
        console.log('🕐 Starting scheduled transfer processing...');
        const result = await processPendingTransfers();
        console.log('✅ Scheduled transfer processing completed:', result);
        return result;
    } catch (error) {
        console.error('❌ Scheduled transfer processing failed:', error);
        throw error;
    }
});

// Cloud Function: Get Transfer Queue Statistics (Admin Only)
exports.getTransferQueueStats = onCall({ cors: true }, async (request) => {
    try {
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists) {
            throw new Error('Admin access required');
        }

        const stats = await getTransferQueueStats();

        return {
            success: true,
            transfer_stats: stats
        };

    } catch (error) {
        console.error('Error getting transfer queue stats:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Retry Failed Transfers (Admin Only)
exports.retryFailedTransfers = onCall({ cors: true }, async (request) => {
    try {
        const adminUid = request.auth?.uid;

        if (!adminUid) {
            throw new Error('Authentication required');
        }

        // Verify admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists) {
            throw new Error('Admin access required');
        }

        const result = await retryFailedTransfers();

        // Log admin action
        await admin.firestore().collection('admin_actions').add({
            action: 'retry_failed_transfers',
            admin_user: adminUid,
            transfers_retried: result.retried,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        return {
            success: true,
            result,
            message: `${result.retried} failed transfers queued for retry`
        };

    } catch (error) {
        console.error('Error retrying failed transfers:', error);
        throw new Error(error.message);
    }
});

// Scheduled function to cleanup old transfers (runs daily)
exports.cleanupOldTransfers = onSchedule({
    schedule: '0 2 * * *', // Daily at 2 AM UTC
    timeZone: 'UTC'
}, async (context) => {
    try {
        console.log('🕐 Starting scheduled transfer cleanup...');
        const result = await cleanupOldTransfers();
        console.log('✅ Scheduled transfer cleanup completed:', result);
        return result;
    } catch (error) {
        console.error('❌ Scheduled transfer cleanup failed:', error);
        throw error;
    }
});

// Manual transfer processing (for testing or emergency)
exports.processTransfersNow = onRequest({ cors: true }, async (req, res) => {
    try {
        console.log('🚀 Manual transfer processing requested...');
        const result = await processPendingTransfers();
        
        res.json({
            success: true,
            message: 'Transfer processing completed',
            result
        });
    } catch (error) {
        console.error('❌ Manual transfer processing failed:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Health check endpoint
exports.health = onRequest((req, res) => {
    res.json({
        status: "healthy",
        timestamp: new Date().toISOString(),
        environment: "firebase-functions",
        hederaConnected: !!hederaClient,
        tokenId: CNE_TOKEN_ID,
        topicId: HCS_TOPIC_ID
    });
});

// Get server time for client synchronization
exports.getServerTime = onCall({ cors: true }, async (request) => {
    try {
        const serverTime = Date.now();
        console.log('⏰ getServerTime called, returning:', serverTime);
        
        return {
            success: true,
            serverTime: serverTime,
            serverTimeIso: new Date(serverTime).toISOString(),
            timezone: 'UTC'
        };
    } catch (error) {
        console.error('Error in getServerTime:', error);
        return {
            success: false,
            error: error.message || 'Failed to get server time'
        };
    }
});

// Cleanup expired waiting rounds
exports.cleanupExpiredRounds = onRequest({ cors: true }, async (req, res) => {
    try {
        console.log('🧹 Cleaning up expired waiting rounds...');
        
        const nowTs = admin.firestore.Timestamp.fromMillis(Date.now());
        const expiredQuery = db.collection('timedRounds')
            .where('status', '==', 'waiting')
            .where('roundEndTime', '<', nowTs)
            .limit(500);
            
        const expiredSnaps = await expiredQuery.get();
        
        const batch = db.batch();
        let deleteCount = 0;
        
        expiredSnaps.forEach(doc => {
            batch.delete(doc.ref);
            deleteCount++;
            console.log(`🗑️ Marking for deletion: ${doc.id} (${doc.data().roomId})`);
        });
        
        if (deleteCount > 0) {
            await batch.commit();
            console.log(`✅ Deleted ${deleteCount} expired rounds`);
        } else {
            console.log('✅ No expired rounds found');
        }
        
        res.json({
            success: true,
            message: `Cleaned up ${deleteCount} expired rounds`,
            deletedCount: deleteCount
        });
        
    } catch (error) {
        console.error('❌ Error cleaning up expired rounds:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Create test rounds for all rooms (for testing purposes)
exports.createTestRounds = onRequest({ cors: true }, async (req, res) => {
    try {
        console.log('🔄 Creating test timed rounds...');
        
        const rooms = ['rookie', 'pro', 'elite'];
        const now = new Date();
        const createdRounds = [];
        
        for (const roomId of rooms) {
            // Server-authoritative time calculation
            const serverNowMs = Date.now(); // Server time as single source of truth
            const roundDurationMs = 2 * 60 * 1000; // 2 minutes duration
            const roundStartTime = new Date(serverNowMs);
            const roundEndTime = new Date(serverNowMs + roundDurationMs);
            
            const roundData = {
                roomId: roomId,
                status: 'waiting',
                roundStartTime: admin.firestore.Timestamp.fromMillis(serverNowMs),
                roundEndTime: admin.firestore.Timestamp.fromMillis(serverNowMs + roundDurationMs),
                endsAt: admin.firestore.Timestamp.fromMillis(serverNowMs + roundDurationMs), // Legacy compatibility
                expireAt: admin.firestore.Timestamp.fromMillis(serverNowMs + roundDurationMs + (60 * 1000)), // TTL field (1 min after end)
                players: [],
                maxPlayers: roomId === 'rookie' ? 4 : roomId === 'pro' ? 6 : 8,
                totalStakes: 0,
                createdAt: admin.firestore.Timestamp.fromMillis(serverNowMs),
                updatedAt: admin.firestore.Timestamp.fromMillis(serverNowMs),
                serverCreatedMs: serverNowMs, // Store raw milliseconds for precise client comparison
                winnerId: null,
                resultColor: null
            };
            
            const docRef = await db.collection('timedRounds').add(roundData);
            console.log(`✅ Created round for ${roomId}: ${docRef.id}`);
            
            createdRounds.push({
                roomId,
                roundId: docRef.id,
                serverCreatedMs: serverNowMs,
                roundStartTime: roundStartTime.toISOString(),
                roundEndTime: roundEndTime.toISOString(),
                durationMinutes: Math.floor(roundDurationMs / (60 * 1000))
            });
        }
        
        console.log('🎉 All test rounds created successfully!');
        
        res.json({
            success: true,
            message: 'Test rounds created successfully',
            rounds: createdRounds,
            totalRounds: createdRounds.length
        });
        
    } catch (error) {
        console.error('❌ Error creating test rounds:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Check active rounds status
exports.checkActiveRounds = onRequest({ cors: true }, async (req, res) => {
    try {
        console.log('🔍 Checking active rounds...');
        
        const activeRoundsSnapshot = await db.collection('timedRounds')
            .where('status', '==', 'active')
            .orderBy('endsAt', 'asc')
            .get();
            
        const activeRounds = [];
        const now = new Date();
        
        activeRoundsSnapshot.forEach(doc => {
            const data = doc.data();
            const endsAt = data.endsAt.toDate();
            const secondsRemaining = Math.max(0, Math.floor((endsAt - now) / 1000));
            const minutesRemaining = Math.floor(secondsRemaining / 60);
            
            activeRounds.push({
                id: doc.id,
                roomId: data.roomId,
                status: data.status,
                endsAt: endsAt.toISOString(),
                secondsRemaining,
                minutesRemaining,
                formattedTime: `${Math.floor(minutesRemaining)}:${String(secondsRemaining % 60).padStart(2, '0')}`,
                playersCount: data.players ? data.players.length : 0,
                maxPlayers: data.maxPlayers || 0
            });
        });
        
        console.log(`✅ Found ${activeRounds.length} active rounds`);
        
        res.json({
            success: true,
            totalActiveRounds: activeRounds.length,
            rounds: activeRounds,
            timestamp: now.toISOString()
        });
        
    } catch (error) {
        console.error('❌ Error checking active rounds:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Cloud Function: Create New Round
exports.createNewRound = onCall({ cors: true }, async (request) => {
    try {
        const { roomId } = request.data;

        if (!roomId) {
            throw new Error("Room ID is required");
        }

        // Validate room exists
        const roomDoc = await db.collection("rooms").doc(roomId).get();
        if (!roomDoc.exists) {
            throw new Error("Room not found");
        }

        const now = new Date();
        const roundDuration = 2 * 60 * 1000; // 2 minutes in milliseconds
        const roundEndTime = new Date(now.getTime() + roundDuration);

        // Create new round
        const newRound = {
            roomId,
            status: "waiting",
            roundStartTime: admin.firestore.Timestamp.fromDate(now),
            roundEndTime: admin.firestore.Timestamp.fromDate(roundEndTime),
            players: [],
            winnerId: null,
            resultColor: null,
            totalStake: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        const roundDoc = await db.collection("rounds").add(newRound);
        
        console.log(`✅ Created new round ${roundDoc.id} for room ${roomId}`);

        return {
            success: true,
            roundId: roundDoc.id,
            roundEndTime: roundEndTime.toISOString(),
            message: "New round created successfully"
        };

    } catch (error) {
        console.error("Error creating new round:", error);
        throw new Error(error.message);
    }
});

// Cloud Function: Close Round (triggered by timer or manually)
exports.closeRound = onCall({ cors: true }, async (request) => {
    try {
        const { roundId } = request.data;

        if (!roundId) {
            throw new Error("Round ID is required");
        }

        const roundDoc = await db.collection("rounds").doc(roundId).get();
        if (!roundDoc.exists) {
            throw new Error("Round not found");
        }

        const roundData = roundDoc.data();
        
        // Check if round is in waiting status
        if (roundData.status !== "waiting") {
            throw new Error("Round is not in waiting status");
        }

        const playerCount = roundData.players?.length || 0;

        if (playerCount < 2) {
            // Cancel round - not enough players
            await roundDoc.ref.update({
                status: "cancelled",
                cancelReason: "Not enough players",
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Trigger refunds for all players
            if (playerCount > 0) {
                await refundPlayers(roundId, roundData.players);
            }

            return {
                success: true,
                status: "cancelled",
                reason: "Not enough players",
                playersRefunded: playerCount
            };
        } else {
            // Start the battle - enough players
            await roundDoc.ref.update({
                status: "active",
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Simulate wheel spin
            const result = await spinWheel(roundId, roundData);

            return {
                success: true,
                status: "completed",
                winner: result.winnerId,
                resultColor: result.resultColor,
                totalPayout: result.payout
            };
        }

    } catch (error) {
        console.error("Error closing round:", error);
        throw new Error(error.message);
    }
});

// Helper: Spin wheel and determine winner
async function spinWheel(roundId, roundData) {
    const colors = ["red", "blue", "green", "yellow", "purple", "orange"];
    const winningColor = colors[Math.floor(Math.random() * colors.length)];
    
    // Find players with matching color, or pick random if no match
    let winner = null;
    const matchingPlayers = roundData.players.filter(p => p.avatarColor === winningColor);
    
    if (matchingPlayers.length > 0) {
        winner = matchingPlayers[Math.floor(Math.random() * matchingPlayers.length)];
    } else {
        winner = roundData.players[Math.floor(Math.random() * roundData.players.length)];
    }

    const totalStake = roundData.totalStake || 0;
    const payout = Math.floor(totalStake * 0.9); // 90% payout, 10% house edge

    // Update round with results
    await db.collection("rounds").doc(roundId).update({
        status: "completed",
        winnerId: winner.uid,
        resultColor: winningColor,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Award winnings to winner (would transfer tokens via Hedera)
    console.log(`🏆 Round ${roundId} winner: ${winner.uid}, payout: ${payout} CNE`);

    // Publish result to HCS for transparency
    const hcsMessage = {
        type: "timed_battle_result",
        roundId,
        winnerId: winner.uid,
        resultColor: winningColor,
        totalStake,
        payout,
        playerCount: roundData.players.length,
        timestamp: new Date().toISOString()
    };
    
    await publishToHCS(hcsMessage);

    return {
        winnerId: winner.uid,
        resultColor: winningColor,
        payout
    };
}

// Helper: Refund players when round is cancelled
async function refundPlayers(roundId, players) {
    if (!players || players.length === 0) return;

    console.log(`💰 Refunding ${players.length} players for cancelled round ${roundId}`);
    
    // In a real implementation, this would trigger Hedera token transfers
    for (const player of players) {
        console.log(`Refunding ${player.stakeAmount} CNE to ${player.uid}`);
        // await transferTokens(HOUSE_ACCOUNT, player.hederaAccountId, player.stakeAmount);
    }

    // Log refunds
    const refundBatch = db.batch();
    players.forEach(player => {
        const refundRef = db.collection("refunds").doc();
        refundBatch.set(refundRef, {
            roundId,
            playerId: player.uid,
            amount: player.stakeAmount,
            reason: "Round cancelled - insufficient players",
            processedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });
    
    await refundBatch.commit();
}

// Populate Firestore with initial data
// Clean up old rounds (removes non-waiting rounds)
exports.cleanupRounds = onRequest({ cors: true }, async (req, res) => {
    try {
        console.log('🧹 Cleaning up old rounds...');
        
        // Get all rounds that are not waiting status
        const oldRoundsSnapshot = await db.collection('timedRounds')
            .where('status', '!=', 'waiting')
            .get();
        
        console.log(`Found ${oldRoundsSnapshot.size} old rounds to delete`);
        
        // Delete old rounds in batches
        const batch = db.batch();
        oldRoundsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log('✅ Old rounds deleted');
        
        // Show current waiting rounds
        const waitingRounds = await db.collection('timedRounds')
            .where('status', '==', 'waiting')
            .get();
        
        const currentRounds = [];
        for (const doc of waitingRounds.docs) {
            const data = doc.data();
            const endTime = data.roundEndTime?.toDate();
            const now = new Date();
            const timeRemaining = Math.max(0, Math.floor((endTime - now) / 1000));
            const minutes = Math.floor(timeRemaining / 60);
            const seconds = timeRemaining % 60;
            
            currentRounds.push({
                roomId: data.roomId,
                roundId: doc.id,
                timeRemaining: `${minutes}:${seconds.toString().padStart(2, '0')}`
            });
        }
        
        res.json({
            success: true,
            message: `Cleaned up ${oldRoundsSnapshot.size} old rounds`,
            oldRoundsDeleted: oldRoundsSnapshot.size,
            waitingRounds: currentRounds.length,
            rounds: currentRounds
        });
        
    } catch (error) {
        console.error('❌ Error cleaning up rounds:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

exports.populateFirestore = onRequest(async (req, res) => {
    try {
        console.log('🚀 Starting Firestore population...');

        // Create battle rooms
        const battleRooms = [
            {
                id: 'crypto-kings',
                name: 'Crypto Kings Arena',
                description: 'Elite battles for cryptocurrency masters',
                entryFee: 100,
                minStake: 50,
                maxStake: 500,
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
                minStake: 25,
                maxStake: 250,
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
                minStake: 10,
                maxStake: 100,
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
                minStake: 35,
                maxStake: 350,
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
        const batch = admin.firestore().batch();
        
        battleRooms.forEach(room => {
            const roomRef = admin.firestore().collection('rooms').doc(room.id);
            batch.set(roomRef, room);
        });

        await batch.commit();
        console.log('✅ Created battle rooms:', battleRooms.map(r => r.name).join(', '));

        // Create initial rounds for each room
        const roundPromises = battleRooms.map(async (room) => {
            const now = new Date();
            const roundDuration = 2 * 60 * 1000; // 2 minutes
            const roundEndTime = new Date(now.getTime() + roundDuration);

            const newRound = {
                roomId: room.id,
                status: "waiting",
                roundStartTime: admin.firestore.Timestamp.fromDate(now),
                roundEndTime: admin.firestore.Timestamp.fromDate(roundEndTime),
                players: [],
                winnerId: null,
                resultColor: null,
                totalStake: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            return db.collection("rounds").add(newRound);
        });

        await Promise.all(roundPromises);

        res.json({
            success: true,
            message: 'Firestore populated successfully with timed rounds',
            roomsCreated: battleRooms.length,
            initialRoundsCreated: battleRooms.length,
            rooms: battleRooms.map(r => ({ id: r.id, name: r.name }))
        });

    } catch (error) {
        console.error('❌ Error populating Firestore:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ===== CME TOKEN TRANSFER PROCESSING =====

// Cloud Function: Process Pending Token Transfers (Manual trigger)
exports.processTokenTransfers = onRequest({ cors: true }, async (req, res) => {
    try {
        const batchSize = 10; // Process 10 transfers at a time
        
        const pendingTransfers = await db.collection('pending_transfers')
            .where('status', '==', 'PENDING')
            .where('retryCount', '<', 3)
            .limit(batchSize)
            .get();

        let processed = 0;
        let failed = 0;

        for (const transferDoc of pendingTransfers.docs) {
            const transferData = transferDoc.data();
            
            try {
                // Process the transfer
                let transactionId = null;
                
                if (hederaClient && CNE_TOKEN_ID) {
                    // Real Hedera transfer
                    const transferTx = new TransferTransaction()
                        .addTokenTransfer(CNE_TOKEN_ID, process.env.OPERATOR_ACCOUNT_ID, -transferData.amount)
                        .addTokenTransfer(CNE_TOKEN_ID, transferData.hederaAccountId, transferData.amount)
                        .freezeWith(hederaClient);

                    const response = await transferTx.execute(hederaClient);
                    const receipt = await response.getReceipt(hederaClient);
                    transactionId = response.transactionId.toString();
                } else {
                    // Mock transfer for testing
                    transactionId = `mock_tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                }

                // Update transfer status
                await db.collection('pending_transfers').doc(transferDoc.id).update({
                    status: 'COMPLETED',
                    transactionId: transactionId,
                    completedAt: Date.now()
                });

                // Update redemption status
                if (transferData.redemptionId) {
                    await db.collection('redemptions').doc(transferData.redemptionId).update({
                        status: 'COMPLETED',
                        transactionId: transactionId,
                        completedAt: Date.now()
                    });
                }

                // Log success
                await db.collection('transfer_log').add({
                    transferId: transferDoc.id,
                    redemptionId: transferData.redemptionId,
                    uid: transferData.uid,
                    amount: transferData.amount,
                    hederaAccountId: transferData.hederaAccountId,
                    transactionId: transactionId,
                    status: 'SUCCESS',
                    timestamp: Date.now()
                });

                // Publish to HCS
                const hcsMessage = {
                    type: 'token_transfer_completed',
                    uid: transferData.uid,
                    amount: transferData.amount,
                    transactionId: transactionId,
                    timestamp: Date.now()
                };
                await publishToHCS(hcsMessage);

                processed++;

            } catch (error) {
                console.error(`Transfer failed for ${transferDoc.id}:`, error);
                
                // Increment retry count
                await db.collection('pending_transfers').doc(transferDoc.id).update({
                    retryCount: (transferData.retryCount || 0) + 1,
                    lastError: error.message,
                    lastRetryAt: Date.now()
                });

                // If max retries reached, mark as failed
                if ((transferData.retryCount || 0) >= 2) {
                    await db.collection('pending_transfers').doc(transferDoc.id).update({
                        status: 'FAILED'
                    });

                    if (transferData.redemptionId) {
                        await db.collection('redemptions').doc(transferData.redemptionId).update({
                            status: 'FAILED',
                            error: error.message
                        });

                        // Refund user's available balance
                        const userRef = db.collection('users').doc(transferData.uid);
                        await db.runTransaction(async (transaction) => {
                            const userDoc = await transaction.get(userRef);
                            const userData = userDoc.data();
                            
                            transaction.update(userRef, {
                                available_balance: userData.available_balance + transferData.amount
                            });
                        });
                    }
                }

                failed++;
            }
        }

        res.json({
            success: true,
            processed: processed,
            failed: failed,
            total: pendingTransfers.size
        });

    } catch (error) {
        console.error('Error processing transfers:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Cloud Function: Unlock Expired Locks for User
exports.unlockExpiredTokens = onCall({ cors: true }, async (request) => {
    try {
        const { uid } = request.data;
        const authUid = request.auth?.uid;

        if (!authUid || authUid !== uid) {
            throw new Error('Authentication mismatch');
        }

        const userDoc = await db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const userData = userDoc.data();
        const now = Date.now();
        let unlockedAmount = 0;
        const remainingLocks = [];

        if (userData.locks) {
            userData.locks.forEach(lock => {
                if (lock.unlockAt <= now) {
                    unlockedAmount += lock.amount;
                } else {
                    remainingLocks.push(lock);
                }
            });
        }

        if (unlockedAmount > 0) {
            await db.collection('users').doc(uid).update({
                available_balance: userData.available_balance + unlockedAmount,
                locked_balance: userData.locked_balance - unlockedAmount,
                locks: remainingLocks
            });

            // Log unlock event
            await db.collection('rewards_log').add({
                id: `unlock_${uid}_${Date.now()}`,
                uid: uid,
                did: userData.did,
                eventType: 'token_unlock',
                amount: unlockedAmount,
                immediate: unlockedAmount,
                locked: 0,
                status: 'COMPLETED',
                createdAt: Date.now()
            });
        }

        return {
            success: true,
            unlockedAmount: fromCMEUnits(unlockedAmount),
            newAvailableBalance: fromCMEUnits(userData.available_balance + unlockedAmount),
            remainingLocks: remainingLocks.map(lock => ({
                amount: fromCMEUnits(lock.amount),
                unlockDate: new Date(lock.unlockAt).toISOString(),
                source: lock.source
            }))
        };

    } catch (error) {
        console.error('Error unlocking tokens:', error);
        throw new Error(error.message);
    }
});

// ===== ADMIN FUNCTIONS =====

// Cloud Function: Admin - Get System Overview
exports.getSystemOverview = onCall({ cors: true }, async (request) => {
    try {
        const authUid = request.auth?.uid;
        
        // Check admin privileges
        const adminDoc = await db.collection('admins').doc(authUid).get();
        if (!adminDoc.exists) {
            throw new Error('Unauthorized - Admin access required');
        }

        // Get system metrics
        const metricsDoc = await db.collection('config').doc('metrics').get();
        const metrics = metricsDoc.data() || {};

        // Get user count
        const usersSnapshot = await db.collection('users').count().get();
        const userCount = usersSnapshot.data().count;

        // Get pending transfers
        const pendingTransfersSnapshot = await db.collection('pending_transfers')
            .where('status', '==', 'PENDING')
            .count()
            .get();
        const pendingCount = pendingTransfersSnapshot.data().count;

        // Get today's activity
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayStart = today.getTime();

        const todayRewardsSnapshot = await db.collection('rewards_log')
            .where('createdAt', '>=', todayStart)
            .count()
            .get();
        const todayRewardsCount = todayRewardsSnapshot.data().count;

        return {
            success: true,
            overview: {
                totalUsers: userCount,
                totalDistributed: fromCMEUnits(metrics.total_distributed || 0),
                dailyDistribution: fromCMEUnits(metrics.daily_distribution || 0),
                pendingTransfers: pendingCount,
                todayRewards: todayRewardsCount,
                currentTier: Math.min(10, Math.floor(userCount / 10000)),
                eventStats: metrics.event_stats || {},
                lastUpdated: metrics.last_updated
            }
        };

    } catch (error) {
        console.error('Error getting system overview:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Admin - Configure Reward Rates
exports.configureRewardRates = onCall({ cors: true }, async (request) => {
    try {
        const { rewardConfig } = request.data;
        const authUid = request.auth?.uid;
        
        // Check admin privileges
        const adminDoc = await db.collection('admins').doc(authUid).get();
        if (!adminDoc.exists) {
            throw new Error('Unauthorized - Admin access required');
        }

        // Validate reward config structure
        if (!rewardConfig || typeof rewardConfig !== 'object') {
            throw new Error('Invalid reward configuration');
        }

        // Validate each reward type
        const validEventTypes = ['video_watch', 'ad_view', 'daily_airdrop', 'social_follow', 'referral_bonus', 'live_stream', 'quiz_completion'];
        const processedConfig = {};

        for (const [eventType, config] of Object.entries(rewardConfig)) {
            if (!validEventTypes.includes(eventType)) {
                throw new Error(`Invalid event type: ${eventType}`);
            }

            processedConfig[eventType] = {
                base: parseFloat(config.base) || 0,
                enabled: Boolean(config.enabled),
                lastUpdated: Date.now(),
                updatedBy: authUid
            };
        }

        await db.collection('config').doc('reward_rates').set(processedConfig);

        // Log admin action
        await db.collection('admin_log').add({
            adminUid: authUid,
            action: 'configure_reward_rates',
            data: processedConfig,
            timestamp: Date.now()
        });

        return {
            success: true,
            message: 'Reward rates configuration updated successfully',
            config: processedConfig
        };

    } catch (error) {
        console.error('Error configuring reward rates:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Admin - Toggle Reward Type
exports.toggleRewardType = onCall({ cors: true }, async (request) => {
    try {
        const { eventType, enabled } = request.data;
        const authUid = request.auth?.uid;
        
        // Check admin privileges
        const adminDoc = await db.collection('admins').doc(authUid).get();
        if (!adminDoc.exists) {
            throw new Error('Unauthorized - Admin access required');
        }

        // Update specific reward type
        const configRef = db.collection('config').doc('reward_rates');
        await configRef.update({
            [`${eventType}.enabled`]: Boolean(enabled),
            [`${eventType}.lastUpdated`]: Date.now(),
            [`${eventType}.updatedBy`]: authUid
        });

        // Log admin action
        await db.collection('admin_log').add({
            adminUid: authUid,
            action: 'toggle_reward_type',
            data: { eventType, enabled },
            timestamp: Date.now()
        });

        return {
            success: true,
            message: `${eventType} rewards ${enabled ? 'enabled' : 'disabled'} successfully`
        };

    } catch (error) {
        console.error('Error toggling reward type:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Admin - Bulk Airdrop
exports.bulkAirdrop = onCall({ cors: true }, async (request) => {
    try {
        const { targetUsers, amount, reason, immediate, locked } = request.data;
        const authUid = request.auth?.uid;
        
        // Check admin privileges
        const adminDoc = await db.collection('admins').doc(authUid).get();
        if (!adminDoc.exists) {
            throw new Error('Unauthorized - Admin access required');
        }

        // Validate parameters
        if (!Array.isArray(targetUsers) || targetUsers.length === 0) {
            throw new Error('Target users must be a non-empty array');
        }

        if (!amount || amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }

        const totalAmount = toCMEUnits(amount);
        const immediateAmount = immediate ? toCMEUnits(immediate) : Math.floor(totalAmount * 0.5);
        const lockedAmount = locked ? toCMEUnits(locked) : Math.floor(totalAmount * 0.5);

        // Process airdrop for each user
        const results = [];
        const batch = db.batch();

        for (const uid of targetUsers.slice(0, 100)) { // Limit to 100 users per batch
            try {
                const userRef = db.collection('users').doc(uid);
                const userDoc = await userRef.get();

                if (userDoc.exists) {
                    const userData = userDoc.data();
                    
                    // Update user balance
                    const newAvailableBalance = userData.available_balance + immediateAmount;
                    const newLockedBalance = userData.locked_balance + lockedAmount;
                    const newTotalBalance = userData.points_balance + totalAmount;
                    
                    const updates = {
                        points_balance: newTotalBalance,
                        available_balance: newAvailableBalance,
                        locked_balance: newLockedBalance
                    };

                    // Add lock if there's locked amount
                    if (lockedAmount > 0) {
                        const newLock = {
                            lockId: `airdrop_${uid}_${Date.now()}`,
                            amount: lockedAmount,
                            unlockAt: Date.now() + (2 * 365 * 24 * 60 * 60 * 1000), // 2 years
                            source: 'admin_airdrop'
                        };
                        
                        updates.locks = [...(userData.locks || []), newLock];
                    }

                    batch.update(userRef, updates);

                    // Log the airdrop
                    const logRef = db.collection('rewards_log').doc();
                    batch.set(logRef, {
                        id: logRef.id,
                        uid: uid,
                        did: userData.did,
                        eventType: 'admin_airdrop',
                        amount: totalAmount,
                        immediate: immediateAmount,
                        locked: lockedAmount,
                        status: 'COMPLETED',
                        reason: reason || 'Admin airdrop',
                        adminUid: authUid,
                        createdAt: Date.now()
                    });

                    results.push({ uid, status: 'success' });
                } else {
                    results.push({ uid, status: 'user_not_found' });
                }
            } catch (error) {
                results.push({ uid, status: 'error', error: error.message });
            }
        }

        // Commit batch
        await batch.commit();

        // Log admin action
        await db.collection('admin_log').add({
            adminUid: authUid,
            action: 'bulk_airdrop',
            data: { 
                targetUsers: targetUsers.length, 
                amount: fromCMEUnits(totalAmount),
                immediate: fromCMEUnits(immediateAmount),
                locked: fromCMEUnits(lockedAmount),
                reason 
            },
            timestamp: Date.now()
        });

        const successCount = results.filter(r => r.status === 'success').length;

        return {
            success: true,
            message: `Airdrop completed: ${successCount}/${targetUsers.length} users processed successfully`,
            results: results
        };

    } catch (error) {
        console.error('Error processing bulk airdrop:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Admin - Configure Halving Tiers
exports.configureHalvingTiers = onCall({ cors: true }, async (request) => {
    try {
        const { halvingConfig } = request.data;
        const authUid = request.auth?.uid;
        
        // Check admin privileges
        const adminDoc = await db.collection('admins').doc(authUid).get();
        if (!adminDoc.exists) {
            throw new Error('Unauthorized - Admin access required');
        }

        // Validate halving config structure
        if (!halvingConfig || typeof halvingConfig !== 'object') {
            throw new Error('Invalid halving configuration');
        }

        await db.collection('config').doc('halving_config').set({
            ...halvingConfig,
            lastUpdated: Date.now(),
            updatedBy: authUid
        });

        // Log admin action
        await db.collection('admin_log').add({
            adminUid: authUid,
            action: 'configure_halving_tiers',
            data: halvingConfig,
            timestamp: Date.now()
        });

        return {
            success: true,
            message: 'Halving configuration updated successfully',
            config: halvingConfig
        };

    } catch (error) {
        console.error('Error configuring halving tiers:', error);
        throw new Error(error.message);
    }
});

// Cloud Function: Admin - Emergency System Control
exports.emergencySystemControl = onCall({ cors: true }, async (request) => {
    try {
        const { action, reason } = request.data;
        const authUid = request.auth?.uid;
        
        // Check admin privileges
        const adminDoc = await db.collection('admins').doc(authUid).get();
        if (!adminDoc.exists) {
            throw new Error('Unauthorized - Admin access required');
        }

        const validActions = ['pause_all', 'resume_all', 'pause_rewards', 'resume_rewards', 'maintenance_mode'];
        if (!validActions.includes(action)) {
            throw new Error('Invalid action');
        }

        const systemStatus = {
            enabled: !action.includes('pause') && action !== 'maintenance_mode',
            maintenance: action === 'maintenance_mode',
            lastUpdated: Date.now(),
            updatedBy: authUid,
            reason: reason || 'Emergency admin control'
        };

        await db.collection('config').doc('system_status').set(systemStatus);

        // Log admin action
        await db.collection('admin_log').add({
            adminUid: authUid,
            action: 'emergency_system_control',
            data: { action, reason },
            timestamp: Date.now()
        });

        return {
            success: true,
            message: `System ${action.replace('_', ' ')} activated successfully`,
            status: systemStatus
        };

    } catch (error) {
        console.error('Error in emergency system control:', error);
        throw new Error(error.message);
    }
});

// Scheduled Function: Reset Daily Metrics (runs daily at midnight UTC)
exports.resetDailyMetrics = onSchedule({
    schedule: '0 0 * * *', // Daily at midnight UTC
    timeZone: 'UTC'
}, async (context) => {
    try {
        console.log('🔄 Resetting daily metrics...');
        
        const metricsRef = db.collection('config').doc('metrics');
        await metricsRef.update({
            daily_distribution: 0,
            last_daily_reset: Date.now()
        });
        
        console.log('✅ Daily metrics reset completed');
        return { success: true, message: 'Daily metrics reset completed' };
        
    } catch (error) {
        console.error('❌ Error resetting daily metrics:', error);
        throw error;
    }
});

// Scheduled Function: Process Token Transfers (runs every 5 minutes)
exports.scheduledTokenTransfers = onSchedule({
    schedule: 'every 5 minutes',
    timeZone: 'UTC'
}, async (context) => {
    try {
        console.log('🔄 Processing scheduled token transfers...');
        
        const batchSize = 5; // Smaller batch for automated processing
        const pendingTransfers = await db.collection('pending_transfers')
            .where('status', '==', 'PENDING')
            .where('retryCount', '<', 3)
            .limit(batchSize)
            .get();

        let processed = 0;
        
        for (const transferDoc of pendingTransfers.docs) {
            const transferData = transferDoc.data();
            
            try {
                let transactionId = null;
                
                if (hederaClient && CNE_TOKEN_ID) {
                    const transferTx = new TransferTransaction()
                        .addTokenTransfer(CNE_TOKEN_ID, process.env.OPERATOR_ACCOUNT_ID, -transferData.amount)
                        .addTokenTransfer(CNE_TOKEN_ID, transferData.hederaAccountId, transferData.amount)
                        .freezeWith(hederaClient);

                    const response = await transferTx.execute(hederaClient);
                    transactionId = response.transactionId.toString();
                } else {
                    transactionId = `mock_tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                }

                await db.collection('pending_transfers').doc(transferDoc.id).update({
                    status: 'COMPLETED',
                    transactionId: transactionId,
                    completedAt: Date.now()
                });

                if (transferData.redemptionId) {
                    await db.collection('redemptions').doc(transferData.redemptionId).update({
                        status: 'COMPLETED',
                        transactionId: transactionId,
                        completedAt: Date.now()
                    });
                }

                processed++;
                
            } catch (error) {
                console.error(`Transfer failed for ${transferDoc.id}:`, error);
                
                await db.collection('pending_transfers').doc(transferDoc.id).update({
                    retryCount: (transferData.retryCount || 0) + 1,
                    lastError: error.message,
                    lastRetryAt: Date.now()
                });
            }
        }
        
        console.log(`✅ Processed ${processed} token transfers`);
        return { success: true, processed: processed };
        
    } catch (error) {
        console.error('❌ Error in scheduled token transfers:', error);
        throw error;
    }
});


// Security monitoring endpoint
exports.getSecurityMetrics = onRequest(async (req, res) => {
    try {
        // Require admin authentication
        const adminKey = req.headers['x-admin-key'] || req.body.adminKey;
        if (adminKey !== process.env.ADMIN_SECRET_KEY) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        await initializeSecurity();
        
        const metrics = await securitySystem.collectSecurityMetrics();
        res.json({
            success: true,
            metrics,
            timestamp: Date.now()
        });

    } catch (error) {
        console.error('Security metrics error:', error);
        res.status(500).json({ error: 'Failed to collect security metrics' });
    }
});

// Test function for debugging authentication
exports.testAuth = onCall({
    cors: true,
    memory: "128MiB",
    region: "us-central1"
}, async (request) => {
    try {
        const authUid = request.auth?.uid;
        const { testParam } = request.data || {};
        
        console.log('🔍 testAuth - Auth object:', !!request.auth);
        console.log('🔍 testAuth - Auth UID:', authUid);
        console.log('🔍 testAuth - Test param:', testParam);
        
        return {
            success: true,
            authenticated: !!authUid,
            uid: authUid,
            testParam: testParam,
            timestamp: Date.now(),
            message: authUid ? `Successfully authenticated as ${authUid}` : 'Not authenticated'
        };
    } catch (error) {
        console.error('❌ testAuth error:', error);
        return {
            success: false,
            error: error.message,
            timestamp: Date.now()
        };
    }
});

// Security alert endpoint
exports.sendSecurityAlert = onRequest(async (req, res) => {
    try {
        const adminKey = req.headers['x-admin-key'] || req.body.adminKey;
        if (adminKey !== process.env.ADMIN_SECRET_KEY) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        await initializeSecurity();
        
        const { eventType, data, severity } = req.body;
        await securitySystem.logSecurityEvent(eventType, { ...data, manualAlert: true });
        
        res.json({
            success: true,
            message: 'Security alert logged',
            eventType
        });

    } catch (error) {
        console.error('Security alert error:', error);
        res.status(500).json({ error: 'Failed to send security alert' });
    }
});

// ================================
// SIMPLE REWARD SYSTEM - Import from separate file  
// ================================
const { simpleEarnReward, simpleGetBalance } = require('./simple_rewards');
exports.simpleEarnReward = simpleEarnReward;
exports.simpleGetBalance = simpleGetBalance;