const { onRequest, onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TokenTransferTransaction, 
    TopicMessageSubmitTransaction,
    AccountBalanceQuery,
    Hbar 
} = require("@hashgraph/sdk");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Hedera Configuration
const HEDERA_ACCOUNT_ID = process.env.HEDERA_ACCOUNT_ID || "0.0.6917102";
const HEDERA_PRIVATE_KEY = process.env.HEDERA_PRIVATE_KEY;
const CNE_TOKEN_ID = process.env.CNE_TEST_TOKEN_ID || "0.0.6917127";
const HCS_TOPIC_ID = process.env.HCS_TOPIC_ID || "0.0.6917128";

// Initialize Hedera Client
let hederaClient;
try {
    if (HEDERA_PRIVATE_KEY) {
        hederaClient = Client.forTestnet();
        hederaClient.setOperator(
            AccountId.fromString(HEDERA_ACCOUNT_ID),
            PrivateKey.fromStringECDSA(HEDERA_PRIVATE_KEY)
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
