// hederaRoundService.js - Core battle round logic with Hedera integration
const crypto = require('crypto');
const {
    TokenAssociateTransaction,
    TokenTransferTransaction,
    TopicMessageSubmitTransaction,
    TransactionId,
    Hbar,
    AccountId,
    PrivateKey
} = require("@hashgraph/sdk");
const { 
    client, 
    OPERATOR_ID, 
    operatorKey, 
    poolAccountId, 
    poolPrivateKey,
    CNE_DECIMALS 
} = require('./hederaClient');

class HederaRoundService {
    constructor() {
        this.cneTokenId = process.env.CNE_TEST_TOKEN_ID;
        this.hcsTopicId = process.env.HCS_TOPIC_ID;
        this.rounds = new Map(); // In-memory storage for active rounds
        
        if (!this.cneTokenId) {
            console.warn('⚠️ CNE_TEST_TOKEN_ID not configured. Run createToken.js first.');
        }
        
        if (!this.hcsTopicId) {
            console.warn('⚠️ HCS_TOPIC_ID not configured. Run createTopic.js first.');
        }
    }

    /**
     * Initialize the service (validate token and topic exist)
     */
    async initialize() {
        console.log('🔧 Initializing Hedera Round Service...');
        
        if (!this.cneTokenId || this.cneTokenId === '0.0.PLACEHOLDER') {
            throw new Error('CNE_TEST_TOKEN_ID not configured. Please run: npm run setup');
        }
        
        if (!this.hcsTopicId || this.hcsTopicId === '0.0.PLACEHOLDER') {
            throw new Error('HCS_TOPIC_ID not configured. Please run: npm run setup');
        }
        
        console.log(`✅ CNE Token: ${this.cneTokenId}`);
        console.log(`✅ HCS Topic: ${this.hcsTopicId}`);
        console.log('🎮 Hedera Round Service ready!');
        
        return true;
    }

    /**
     * Convert human-readable CNE amount to token units (with decimals)
     */
    cneToTokenUnits(cneAmount) {
        return Math.floor(cneAmount * Math.pow(10, CNE_DECIMALS));
    }

    /**
     * Convert token units back to human-readable CNE amount
     */
    tokenUnitsToCNE(tokenUnits) {
        return tokenUnits / Math.pow(10, CNE_DECIMALS);
    }

    /**
     * Generate server seed and commit hash for provable fairness
     */
    generateCommitReveal(roundId) {
        const serverSeed = crypto.randomBytes(32).toString('hex');
        const combined = serverSeed + roundId;
        const commitHash = crypto.createHash('sha256').update(combined).digest('hex');
        
        return { serverSeed, commitHash };
    }

    /**
     * Verify that a reveal matches the commit
     */
    verifyReveal(serverSeed, roundId, expectedCommitHash) {
        const combined = serverSeed + roundId;
        const computedHash = crypto.createHash('sha256').update(combined).digest('hex');
        return computedHash === expectedCommitHash;
    }

    /**
     * Submit message to HCS topic for transparency
     */
    async submitToHCS(message) {
        if (!this.hcsTopicId) {
            console.warn('⚠️ HCS topic not configured, skipping transparency log');
            return null;
        }

        try {
            const messageJson = JSON.stringify(message);
            const submitTx = new TopicMessageSubmitTransaction()
                .setTopicId(this.hcsTopicId)
                .setMessage(messageJson)
                .setMaxTransactionFee(new Hbar(5));

            const submitFreeze = await submitTx.freezeWith(client);
            const submitSign = await submitFreeze.sign(operatorKey);
            const submitResponse = await submitSign.execute(client);
            const submitReceipt = await submitResponse.getReceipt(client);

            console.log(`📡 HCS message submitted: seq ${submitReceipt.topicSequenceNumber}`);
            return {
                sequenceNumber: submitReceipt.topicSequenceNumber.toString(),
                runningHash: submitReceipt.topicRunningHash.toString('hex'),
                transactionId: submitResponse.transactionId.toString()
            };
        } catch (error) {
            console.error('❌ Failed to submit HCS message:', error.message);
            return null;
        }
    }

    /**
     * Create a new battle round
     */
    async createRound(roomId, minStake, maxStake, deadlineMinutes = 5) {
        const roundId = crypto.randomUUID();
        const deadline = Date.now() + (deadlineMinutes * 60 * 1000);
        
        // Generate commit-reveal for this round
        const { serverSeed, commitHash } = this.generateCommitReveal(roundId);
        
        const round = {
            id: roundId,
            roomId,
            minStake,
            maxStake,
            deadline,
            status: 'open', // open, locked, completed
            players: [],
            totalPot: 0,
            serverSeed, // Keep secret until reveal
            commitHash,
            winner: null,
            createdAt: new Date().toISOString(),
            hcsCommitMessage: null,
            hcsRevealMessage: null
        };

        // Submit commit hash to HCS
        const commitMessage = {
            type: 'ROUND_COMMIT',
            roundId,
            roomId,
            commitHash,
            minStake,
            maxStake,
            deadline,
            timestamp: round.createdAt
        };

        round.hcsCommitMessage = await this.submitToHCS(commitMessage);
        this.rounds.set(roundId, round);

        console.log(`🎮 Created round ${roundId} for ${roomId}`);
        console.log(`🔒 Commit hash: ${commitHash}`);
        
        return round;
    }

    /**
     * Join a battle round by verifying token transfer
     */
    async joinRound(roundId, userAccountId, stakeAmount, transferTransactionId) {
        const round = this.rounds.get(roundId);
        if (!round) {
            throw new Error('Round not found');
        }

        if (round.status !== 'open') {
            throw new Error('Round is not open for joining');
        }

        if (Date.now() > round.deadline) {
            throw new Error('Round deadline has passed');
        }

        if (stakeAmount < round.minStake || stakeAmount > round.maxStake) {
            throw new Error(`Stake must be between ${round.minStake} and ${round.maxStake} CNE`);
        }

        // Check if user already joined
        if (round.players.find(p => p.accountId === userAccountId)) {
            throw new Error('User already joined this round');
        }

        // Verify the token transfer transaction
        const transferVerified = await this.verifyTokenTransfer(
            transferTransactionId,
            userAccountId,
            poolAccountId.toString(),
            this.cneToTokenUnits(stakeAmount)
        );

        if (!transferVerified) {
            throw new Error('Token transfer verification failed');
        }

        // Add player to round
        const player = {
            accountId: userAccountId,
            stakeAmount,
            transferTxId: transferTransactionId,
            joinedAt: new Date().toISOString()
        };

        round.players.push(player);
        round.totalPot += stakeAmount;

        console.log(`👥 Player ${userAccountId} joined round ${roundId} with ${stakeAmount} CNE`);
        return { round, player };
    }

    /**
     * Verify a token transfer transaction occurred
     */
    async verifyTokenTransfer(transactionId, fromAccount, toAccount, expectedAmount) {
        try {
            // For testnet, we can verify via transaction receipt
            const txId = TransactionId.fromString(transactionId);
            const receipt = await txId.getReceipt(client);
            
            if (receipt.status.toString() !== 'SUCCESS') {
                console.error(`❌ Transaction ${transactionId} was not successful`);
                return false;
            }

            // In production, you'd also verify the transfer details via mirror node
            // For now, we trust that the transaction exists and was successful
            console.log(`✅ Verified token transfer: ${transactionId}`);
            return true;

        } catch (error) {
            console.error(`❌ Failed to verify transfer ${transactionId}:`, error.message);
            return false;
        }
    }

    /**
     * Lock a round (prevent new joins)
     */
    async lockRound(roundId) {
        const round = this.rounds.get(roundId);
        if (!round) {
            throw new Error('Round not found');
        }

        if (round.status !== 'open') {
            throw new Error('Round is not open');
        }

        if (round.players.length < 2) {
            throw new Error('Need at least 2 players to lock the round');
        }

        round.status = 'locked';
        round.lockedAt = new Date().toISOString();

        console.log(`🔒 Locked round ${roundId} with ${round.players.length} players`);
        return round;
    }

    /**
     * Reveal winner and execute payout
     */
    async revealWinner(roundId) {
        const round = this.rounds.get(roundId);
        if (!round) {
            throw new Error('Round not found');
        }

        if (round.status !== 'locked') {
            throw new Error('Round must be locked before revealing winner');
        }

        // Submit server seed to HCS for transparency
        const revealMessage = {
            type: 'ROUND_REVEAL',
            roundId,
            serverSeed: round.serverSeed,
            commitHash: round.commitHash,
            playerCount: round.players.length,
            totalPot: round.totalPot,
            timestamp: new Date().toISOString()
        };

        round.hcsRevealMessage = await this.submitToHCS(revealMessage);

        // Deterministically select winner
        const winner = this.selectWinner(round.players, round.serverSeed, roundId);
        const houseEdge = 0.05; // 5% house edge
        const winnings = Math.floor(round.totalPot * (1 - houseEdge));

        round.winner = {
            accountId: winner.accountId,
            stakeAmount: winner.stakeAmount,
            winnings,
            selectionProof: this.generateSelectionProof(round.players, round.serverSeed, roundId)
        };

        // Execute payout
        try {
            const payoutTxId = await this.executePayout(winner.accountId, winnings);
            round.winner.payoutTxId = payoutTxId;
            console.log(`💰 Payout executed: ${winnings} CNE to ${winner.accountId}`);
        } catch (error) {
            console.error('❌ Payout failed:', error.message);
            round.winner.payoutError = error.message;
        }

        round.status = 'completed';
        round.completedAt = new Date().toISOString();

        // Submit final result to HCS
        const resultMessage = {
            type: 'ROUND_COMPLETED',
            roundId,
            winner: round.winner,
            timestamp: round.completedAt
        };
        await this.submitToHCS(resultMessage);

        console.log(`🏆 Round ${roundId} completed. Winner: ${winner.accountId}`);
        return round;
    }

    /**
     * Deterministically select winner based on stakes and server seed
     */
    selectWinner(players, serverSeed, roundId) {
        const combined = serverSeed + roundId;
        const hash = crypto.createHash('sha256').update(combined).digest('hex');
        const randomBigInt = BigInt('0x' + hash);
        
        const totalPot = players.reduce((sum, player) => sum + player.stakeAmount, 0);
        const randomValue = Number(randomBigInt % BigInt(Math.floor(totalPot * 1000))) / 1000;
        
        let currentSum = 0;
        for (const player of players) {
            currentSum += player.stakeAmount;
            if (randomValue <= currentSum) {
                return player;
            }
        }
        
        // Fallback to last player
        return players[players.length - 1];
    }

    /**
     * Generate proof that winner selection was fair
     */
    generateSelectionProof(players, serverSeed, roundId) {
        return {
            serverSeed,
            roundId,
            combinedString: serverSeed + roundId,
            hash: crypto.createHash('sha256').update(serverSeed + roundId).digest('hex'),
            totalPot: players.reduce((sum, p) => sum + p.stakeAmount, 0),
            playerStakes: players.map(p => ({ accountId: p.accountId, stake: p.stakeAmount }))
        };
    }

    /**
     * Execute token payout to winner
     */
    async executePayout(winnerAccountId, winningsAmount) {
        if (!poolAccountId || !poolPrivateKey) {
            throw new Error('Pool account not configured');
        }

        const tokenUnits = this.cneToTokenUnits(winningsAmount);
        
        const transferTx = new TokenTransferTransaction()
            .addTokenTransfer(this.cneTokenId, poolAccountId, -tokenUnits)
            .addTokenTransfer(this.cneTokenId, winnerAccountId, tokenUnits)
            .setMaxTransactionFee(new Hbar(10));

        const transferFreeze = await transferTx.freezeWith(client);
        const transferSign = await transferFreeze.sign(poolPrivateKey);
        const transferResponse = await transferSign.execute(client);
        const transferReceipt = await transferResponse.getReceipt(client);

        if (transferReceipt.status.toString() !== 'SUCCESS') {
            throw new Error('Payout transfer failed');
        }

        return transferResponse.transactionId.toString();
    }

    /**
     * Get round details
     */
    getRound(roundId) {
        return this.rounds.get(roundId);
    }

    /**
     * Get all rounds
     */
    getAllRounds() {
        return Array.from(this.rounds.values());
    }

    /**
     * Clean up completed rounds (for memory management)
     */
    cleanupCompletedRounds(olderThanHours = 24) {
        const cutoff = Date.now() - (olderThanHours * 60 * 60 * 1000);
        
        for (const [roundId, round] of this.rounds.entries()) {
            if (round.status === 'completed' && 
                new Date(round.completedAt).getTime() < cutoff) {
                this.rounds.delete(roundId);
                console.log(`🧹 Cleaned up old round: ${roundId}`);
            }
        }
    }

    /**
     * Get user stats and balance (placeholder implementation)
     */
    async getUserStats(userId) {
        // TODO: Implement real balance checking from Hedera
        return {
            userId,
            balance: 1000, // Mock balance for now
            battlesWon: 0,
            battlesLost: 0,
            totalWagered: 0,
            lastSpin: null
        };
    }

    /**
     * Start a battle between two players
     */
    async startBattle(playerId, opponentId, wager) {
        console.log(`🎮 Starting battle: ${playerId} vs ${opponentId} (${wager} CNE_TEST)`);
        
        // Simple mock battle logic - random winner
        const winner = Math.random() < 0.5 ? playerId : opponentId;
        const loser = winner === playerId ? opponentId : playerId;
        
        const battleResult = {
            battleId: crypto.randomUUID(),
            players: [playerId, opponentId],
            wager,
            winner,
            loser,
            winnerPayout: Math.floor(wager * 1.8), // 10% house edge
            timestamp: new Date().toISOString(),
            transactionId: 'mock-tx-' + Date.now()
        };
        
        return battleResult;
    }

    /**
     * Get battle history for a user
     */
    async getBattleHistory(userId, limit = 10) {
        // Mock data for now
        return [];
    }

    /**
     * Spin the wheel for rewards
     */
    async spinWheel(playerId) {
        const rewards = [10, 25, 50, 100];
        const reward = rewards[Math.floor(Math.random() * rewards.length)];
        
        return {
            playerId,
            reward,
            type: 'CNE_TEST',
            timestamp: new Date().toISOString(),
            transactionId: 'mock-wheel-' + Date.now()
        };
    }

    /**
     * Airdrop tokens to a user (for development)
     */
    async airdropTokens(userId, amount) {
        console.log(`💰 Mock airdrop: ${amount} CNE_TEST to ${userId}`);
        
        return {
            userId,
            amount,
            transactionId: 'mock-airdrop-' + Date.now(),
            timestamp: new Date().toISOString()
        };
    }

    /**
     * Get HCS messages for transparency
     */
    async getHCSMessages(limit = 20) {
        // Mock HCS messages
        return [];
    }

    /**
     * Cleanup resources
     */
    async cleanup() {
        console.log('🧹 Cleaning up Hedera service...');
        this.cleanupCompletedRounds();
    }
}

module.exports = HederaRoundService;
