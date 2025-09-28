const { onRequest, onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
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

// Cloud Function: Join Battle
exports.joinBattle = onCall({ cors: true }, async (request) => {
    try {
        const { roomId, stake, color } = request.data;
        const uid = request.auth?.uid;

        if (!uid) {
            throw new Error("Authentication required");
        }

        if (!roomId || !stake || !color) {
            throw new Error("Missing required parameters: roomId, stake, color");
        }

        // Validate room exists and stake is within range
        const roomDoc = await db.collection("rooms").doc(roomId).get();
        if (!roomDoc.exists) {
            throw new Error("Room not found");
        }

        const room = roomDoc.data();
        if (stake < room.minStake || stake > room.maxStake) {
            throw new Error(`Stake must be between ${room.minStake} and ${room.maxStake}`);
        }

        // Check if user has sufficient balance (would check Hedera here)
        // For now, we'll assume they have enough

        // Find or create an active round for this room
        const activeRoundsQuery = await db.collection("rounds")
            .where("roomId", "==", roomId)
            .where("status", "==", "waiting")
            .limit(1)
            .get();

        let roundDoc;
        let roundId;

        if (activeRoundsQuery.empty) {
            // Create new round
            const newRound = {
                roomId,
                status: "waiting",
                players: [],
                winner: null,
                resultColor: null,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };
            
            roundDoc = await db.collection("rounds").add(newRound);
            roundId = roundDoc.id;
        } else {
            roundDoc = activeRoundsQuery.docs[0].ref;
            roundId = activeRoundsQuery.docs[0].id;
        }

        // Add player to round
        await roundDoc.update({
            players: admin.firestore.FieldValue.arrayUnion({
                uid,
                stake,
                color,
                joinedAt: admin.firestore.FieldValue.serverTimestamp()
            }),
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

        return {
            success: true,
            roundId,
            message: "Successfully joined battle"
        };

    } catch (error) {
        console.error("Error in joinBattle:", error);
        throw new Error(error.message);
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

// Firestore Trigger: Auto-start battle when enough players join
exports.startBattle = onDocumentUpdated("rounds/{roundId}", async (event) => {
    const roundId = event.params.roundId;
    const roundData = event.data.after.data();
    
    // Only process if round is waiting and has enough players
    if (roundData.status !== "waiting" || !roundData.players || roundData.players.length < 2) {
        return null;
    }

    try {
        // Update status to active
        await db.collection("rounds").doc(roundId).update({
            status: "active",
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Simulate wheel spin (server-side randomness)
        const colors = ["red", "blue", "green", "yellow", "purple", "orange"];
        const winningColor = colors[Math.floor(Math.random() * colors.length)];
        
        // Find winner (first player with matching color, or random if no match)
        let winner = null;
        const matchingPlayers = roundData.players.filter(p => p.color === winningColor);
        
        if (matchingPlayers.length > 0) {
            winner = matchingPlayers[0].uid;
        } else {
            // No exact match, pick random player
            winner = roundData.players[Math.floor(Math.random() * roundData.players.length)].uid;
        }

        // Calculate total stake pool
        const totalStake = roundData.players.reduce((sum, player) => sum + player.stake, 0);

        // Update round with results
        await db.collection("rounds").doc(roundId).update({
            status: "completed",
            winner,
            resultColor: winningColor,
            totalStake,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Publish result to HCS for transparency
        const hcsMessage = {
            type: "battle_result",
            roundId,
            winner,
            resultColor: winningColor,
            totalStake,
            players: roundData.players.length,
            timestamp: new Date().toISOString()
        };
        
        await publishToHCS(hcsMessage);

        console.log(`Battle ${roundId} completed. Winner: ${winner}, Color: ${winningColor}`);
        
        return null;
    } catch (error) {
        console.error(`Error processing battle ${roundId}:`, error);
        return null;
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
