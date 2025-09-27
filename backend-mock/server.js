const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory storage for battle data
let rooms = {
  "10-100": { minStake: 10, maxStake: 100, name: "Rookie Room" },
  "100-500": { minStake: 100, maxStake: 500, name: "Pro Room" },
  "500-1000": { minStake: 500, maxStake: 1000, name: "Elite Room" },
  "1000-5000": { minStake: 1000, maxStake: 5000, name: "Champion Room" }
};

let rounds = {};
let activeRounds = {};

// Helper function to generate random winner
function selectWinner(players) {
  if (players.length === 0) return null;
  
  // Create weighted selection based on stake amounts
  let totalStake = players.reduce((sum, player) => sum + player.amount, 0);
  let random = Math.random() * totalStake;
  let currentSum = 0;
  
  for (let player of players) {
    currentSum += player.amount;
    if (random <= currentSum) {
      return player;
    }
  }
  
  // Fallback to last player if something went wrong
  return players[players.length - 1];
}

// Routes

// Get all available rooms
app.get('/api/rooms', (req, res) => {
  res.json({
    success: true,
    rooms: Object.keys(rooms).map(roomId => ({
      roomId,
      ...rooms[roomId],
      activeRound: activeRounds[roomId] || null
    }))
  });
});

// Get specific room info
app.get('/api/rooms/:roomId', (req, res) => {
  const { roomId } = req.params;
  
  if (!rooms[roomId]) {
    return res.status(404).json({
      success: false,
      error: 'Room not found'
    });
  }
  
  res.json({
    success: true,
    room: {
      roomId,
      ...rooms[roomId],
      activeRound: activeRounds[roomId] || null
    }
  });
});

// Create a new battle round (admin function)
app.post('/api/rounds', (req, res) => {
  const { roomId, deadline, minStake, maxStake } = req.body;
  
  if (!rooms[roomId]) {
    return res.status(400).json({
      success: false,
      error: 'Invalid room ID'
    });
  }
  
  if (activeRounds[roomId]) {
    return res.status(400).json({
      success: false,
      error: 'Room already has an active round'
    });
  }
  
  const roundId = uuidv4();
  const round = {
    id: roundId,
    roomId,
    deadline: deadline || Date.now() + 300000, // 5 minutes default
    minStake: minStake || rooms[roomId].minStake,
    maxStake: maxStake || rooms[roomId].maxStake,
    status: 'open', // open, locked, completed
    players: [],
    totalPot: 0,
    winner: null,
    createdAt: Date.now()
  };
  
  rounds[roundId] = round;
  activeRounds[roomId] = roundId;
  
  res.json({
    success: true,
    round: round
  });
});

// Get round details
app.get('/api/rounds/:roundId', (req, res) => {
  const { roundId } = req.params;
  
  if (!rounds[roundId]) {
    return res.status(404).json({
      success: false,
      error: 'Round not found'
    });
  }
  
  res.json({
    success: true,
    round: rounds[roundId]
  });
});

// Join a battle round
app.post('/api/rounds/:roundId/join', (req, res) => {
  const { roundId } = req.params;
  const { userId, amount, joinId } = req.body;
  
  if (!rounds[roundId]) {
    return res.status(404).json({
      success: false,
      error: 'Round not found'
    });
  }
  
  const round = rounds[roundId];
  
  if (round.status !== 'open') {
    return res.status(400).json({
      success: false,
      error: 'Round is not open for joining'
    });
  }
  
  if (Date.now() > round.deadline) {
    return res.status(400).json({
      success: false,
      error: 'Round deadline has passed'
    });
  }
  
  if (amount < round.minStake || amount > round.maxStake) {
    return res.status(400).json({
      success: false,
      error: `Stake must be between ${round.minStake} and ${round.maxStake}`
    });
  }
  
  // Check if user already joined
  if (round.players.find(p => p.userId === userId)) {
    return res.status(400).json({
      success: false,
      error: 'User already joined this round'
    });
  }
  
  // Check for duplicate joinId (prevent double-spending)
  if (round.players.find(p => p.joinId === joinId)) {
    return res.status(400).json({
      success: false,
      error: 'Duplicate join request'
    });
  }
  
  const player = {
    userId,
    amount,
    joinId,
    joinedAt: Date.now()
  };
  
  round.players.push(player);
  round.totalPot += amount;
  
  res.json({
    success: true,
    message: 'Successfully joined the round',
    round: {
      id: round.id,
      totalPot: round.totalPot,
      playerCount: round.players.length,
      timeLeft: Math.max(0, round.deadline - Date.now())
    }
  });
});

// Lock the round (prevent new joins)
app.post('/api/rounds/:roundId/lock', (req, res) => {
  const { roundId } = req.params;
  
  if (!rounds[roundId]) {
    return res.status(404).json({
      success: false,
      error: 'Round not found'
    });
  }
  
  const round = rounds[roundId];
  
  if (round.status !== 'open') {
    return res.status(400).json({
      success: false,
      error: 'Round is not open'
    });
  }
  
  if (round.players.length < 2) {
    return res.status(400).json({
      success: false,
      error: 'Need at least 2 players to lock the round'
    });
  }
  
  round.status = 'locked';
  round.lockedAt = Date.now();
  
  res.json({
    success: true,
    message: 'Round locked successfully',
    round: {
      id: round.id,
      status: round.status,
      playerCount: round.players.length,
      totalPot: round.totalPot
    }
  });
});

// Reveal the winner
app.post('/api/rounds/:roundId/reveal', (req, res) => {
  const { roundId } = req.params;
  
  if (!rounds[roundId]) {
    return res.status(404).json({
      success: false,
      error: 'Round not found'
    });
  }
  
  const round = rounds[roundId];
  
  if (round.status !== 'locked') {
    return res.status(400).json({
      success: false,
      error: 'Round must be locked before revealing winner'
    });
  }
  
  if (round.players.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'No players in this round'
    });
  }
  
  // Select winner
  const winner = selectWinner(round.players);
  const winnings = Math.floor(round.totalPot * 0.95); // 5% house edge
  
  round.winner = {
    userId: winner.userId,
    winnings: winnings,
    originalStake: winner.amount
  };
  round.status = 'completed';
  round.completedAt = Date.now();
  
  // Remove from active rounds
  delete activeRounds[round.roomId];
  
  res.json({
    success: true,
    message: 'Winner revealed!',
    result: {
      roundId: round.id,
      winner: round.winner,
      totalPot: round.totalPot,
      playerCount: round.players.length,
      allPlayers: round.players.map(p => ({
        userId: p.userId,
        amount: p.amount,
        isWinner: p.userId === winner.userId
      }))
    }
  });
});

// Get round history for a user
app.get('/api/users/:userId/rounds', (req, res) => {
  const { userId } = req.params;
  
  const userRounds = Object.values(rounds).filter(round => 
    round.players.some(player => player.userId === userId)
  );
  
  const roundHistory = userRounds.map(round => ({
    id: round.id,
    roomId: round.roomId,
    status: round.status,
    playerStake: round.players.find(p => p.userId === userId).amount,
    totalPot: round.totalPot,
    playerCount: round.players.length,
    isWinner: round.winner && round.winner.userId === userId,
    winnings: round.winner && round.winner.userId === userId ? round.winner.winnings : 0,
    completedAt: round.completedAt,
    createdAt: round.createdAt
  }));
  
  res.json({
    success: true,
    rounds: roundHistory
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Play Extra Battle Mock Server is running',
    timestamp: Date.now(),
    activeRounds: Object.keys(activeRounds).length,
    totalRounds: Object.keys(rounds).length
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🎮 Play Extra Battle Mock Server running on port ${PORT}`);
  console.log(`📡 API Base URL: http://localhost:${PORT}/api`);
  console.log(`🏠 Available rooms: ${Object.keys(rooms).join(', ')}`);
  console.log(`🔧 Environment: ${process.env.APP_MODE || 'MOCK'}`);
});

module.exports = app;
