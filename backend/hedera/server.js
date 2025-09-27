// server.js - Hedera-powered backend for Play Extra
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const HederaRoundService = require('./src/hederaRoundService');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Initialize Hedera round service
let hederaService;

async function initializeServices() {
    try {
        console.log('🎮 Initializing Play Extra Hedera Backend...');
        
        hederaService = new HederaRoundService();
        await hederaService.initialize();
        
        console.log('✅ Hedera services initialized successfully');
        console.log(`🪙 CNE Test Token: ${process.env.CNE_TEST_TOKEN_ID}`);
        console.log(`📡 HCS Topic: ${process.env.HCS_TOPIC_ID}`);
        
    } catch (error) {
        console.error('❌ Failed to initialize Hedera services:', error.message);
        console.error('🔧 Please run: npm run setup');
        process.exit(1);
    }
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: 'testnet',
        tokenId: process.env.CNE_TEST_TOKEN_ID,
        topicId: process.env.HCS_TOPIC_ID
    });
});

// Get user stats and balance
app.get('/api/user/:userId/stats', async (req, res) => {
    try {
        const { userId } = req.params;
        
        if (!hederaService) {
            return res.status(503).json({ error: 'Service not initialized' });
        }
        
        const stats = await hederaService.getUserStats(userId);
        res.json(stats);
        
    } catch (error) {
        console.error('Error getting user stats:', error);
        res.status(500).json({ error: error.message });
    }
});

// Start battle round
app.post('/api/battle/start', async (req, res) => {
    try {
        const { playerId, opponentId, wager } = req.body;
        
        if (!hederaService) {
            return res.status(503).json({ error: 'Service not initialized' });
        }
        
        // Validate inputs
        if (!playerId || !opponentId || !wager) {
            return res.status(400).json({ 
                error: 'Missing required fields: playerId, opponentId, wager' 
            });
        }
        
        if (wager < 10 || wager > 1000) {
            return res.status(400).json({ 
                error: 'Wager must be between 10 and 1000 CNE_TEST' 
            });
        }
        
        console.log(`🎮 Starting battle: ${playerId} vs ${opponentId} (${wager} CNE_TEST)`);
        
        const battleResult = await hederaService.startBattle(playerId, opponentId, wager);
        
        console.log(`✅ Battle completed: ${battleResult.winner} wins!`);
        
        res.json(battleResult);
        
    } catch (error) {
        console.error('Error starting battle:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get battle history
app.get('/api/user/:userId/battles', async (req, res) => {
    try {
        const { userId } = req.params;
        const { limit = 10 } = req.query;
        
        if (!hederaService) {
            return res.status(503).json({ error: 'Service not initialized' });
        }
        
        const battles = await hederaService.getBattleHistory(userId, parseInt(limit));
        res.json(battles);
        
    } catch (error) {
        console.error('Error getting battle history:', error);
        res.status(500).json({ error: error.message });
    }
});

// Spin wheel endpoint
app.post('/api/wheel/spin', async (req, res) => {
    try {
        const { playerId } = req.body;
        
        if (!hederaService) {
            return res.status(503).json({ error: 'Service not initialized' });
        }
        
        if (!playerId) {
            return res.status(400).json({ error: 'Missing playerId' });
        }
        
        console.log(`🎰 Wheel spin for player: ${playerId}`);
        
        const spinResult = await hederaService.spinWheel(playerId);
        
        console.log(`✅ Wheel result: ${spinResult.reward} ${spinResult.type}`);
        
        res.json(spinResult);
        
    } catch (error) {
        console.error('Error spinning wheel:', error);
        res.status(500).json({ error: error.message });
    }
});

// Airdrop test tokens (for development)
app.post('/api/user/:userId/airdrop', async (req, res) => {
    try {
        const { userId } = req.params;
        const { amount = 100 } = req.body;
        
        if (!hederaService) {
            return res.status(503).json({ error: 'Service not initialized' });
        }
        
        console.log(`💰 Airdropping ${amount} CNE_TEST to ${userId}`);
        
        const result = await hederaService.airdropTokens(userId, amount);
        
        console.log(`✅ Airdrop completed: ${result.transactionId}`);
        
        res.json(result);
        
    } catch (error) {
        console.error('Error airdropping tokens:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get HCS messages (battle transparency)
app.get('/api/hcs/messages', async (req, res) => {
    try {
        const { limit = 20 } = req.query;
        
        if (!hederaService) {
            return res.status(503).json({ error: 'Service not initialized' });
        }
        
        const messages = await hederaService.getHCSMessages(parseInt(limit));
        res.json(messages);
        
    } catch (error) {
        console.error('Error getting HCS messages:', error);
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ 
        error: 'Internal server error',
        message: err.message,
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Endpoint not found',
        path: req.path,
        method: req.method
    });
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down gracefully...');
    
    if (hederaService) {
        await hederaService.cleanup();
    }
    
    console.log('✅ Cleanup completed');
    process.exit(0);
});

// Start server
async function startServer() {
    try {
        await initializeServices();
        
        app.listen(PORT, () => {
            console.log('\n🚀 Play Extra Hedera Backend');
            console.log('============================');
            console.log(`🌐 Server: http://localhost:${PORT}`);
            console.log(`📊 Health: http://localhost:${PORT}/health`);
            console.log(`🔗 Network: Hedera Testnet`);
            console.log(`⚡ Status: Ready for battle!`);
            console.log('\n📋 Available endpoints:');
            console.log('- GET  /api/user/:userId/stats');
            console.log('- POST /api/battle/start');
            console.log('- GET  /api/user/:userId/battles'); 
            console.log('- POST /api/wheel/spin');
            console.log('- POST /api/user/:userId/airdrop');
            console.log('- GET  /api/hcs/messages');
            console.log('\n💡 Monitor transactions: https://hashscan.io/testnet');
        });
        
    } catch (error) {
        console.error('💥 Failed to start server:', error.message);
        process.exit(1);
    }
}

startServer();
