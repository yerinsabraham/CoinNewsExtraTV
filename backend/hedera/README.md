# Play Extra - Hedera Testnet Integration

🎮 **Blockchain-powered gaming backend for Play Extra**

This backend integrates with Hedera Testnet to provide real blockchain functionality for the Play Extra game, including token transfers, HCS transparency, and verifiable randomness.

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ 
- Hedera testnet account with HBAR balance
- CNEtv Flutter app configured

### 1. Get Hedera Testnet Credentials
1. Visit [Hedera Portal](https://portal.hedera.com)
2. Create testnet account
3. Fund with HBAR from faucet
4. Note your Account ID and Private Key

### 2. Environment Setup
```bash
# Copy template and configure
cp .env.template .env

# Edit .env with your credentials
# HEDERA_OPERATOR_ID=0.0.YOUR_ACCOUNT_ID  
# HEDERA_OPERATOR_KEY=your_private_key
```

### 3. Automated Setup
```bash
# Install dependencies and run complete setup
npm install
npm run setup
```

This will:
- ✅ Test Hedera connection
- 🪙 Create CNE_TEST token (1M supply)
- 📡 Create HCS topic for transparency
- 📝 Update .env with IDs

### 4. Start Backend
```bash
npm start
# Server runs on http://localhost:3001
```

## 📋 Manual Setup (Alternative)

If automated setup fails, run individually:

```bash
# Test connection
npm run test-connection

# Create token
npm run create-token

# Create HCS topic  
npm run create-topic
```

## 🎮 Game Features

### Battle System
- **Real Token Wagers**: Players wager CNE_TEST tokens
- **Commit-Reveal**: Fair randomness using Hedera HCS
- **Instant Settlement**: Winner gets 1.8x wager (10% house edge)
- **Full Transparency**: All rounds logged to HCS

### Wheel System
- **Daily Spins**: Free spin every 24 hours
- **Token Rewards**: 10-100 CNE_TEST prizes
- **Verifiable Randomness**: HCS-backed entropy

### Token Economics
- **Symbol**: CNE_TEST
- **Supply**: 1,000,000 tokens
- **Decimals**: 2 (like cents)
- **Distribution**: Treasury-controlled airdrops

## 🔧 API Endpoints

### Health Check
```
GET /health
```

### User Stats
```
GET /api/user/:userId/stats
```

### Start Battle
```
POST /api/battle/start
{
    "playerId": "player1",
    "opponentId": "player2", 
    "wager": 50
}
```

### Battle History
```
GET /api/user/:userId/battles?limit=10
```

### Spin Wheel
```
POST /api/wheel/spin
{
    "playerId": "player1"
}
```

### Airdrop Tokens (Dev)
```
POST /api/user/:userId/airdrop
{
    "amount": 100
}
```

### HCS Messages
```
GET /api/hcs/messages?limit=20
```

## 🏗️ Architecture

### Backend Structure
```
backend/hedera/
├── src/
│   ├── hederaClient.js      # Hedera SDK setup
│   └── hederaRoundService.js # Battle logic
├── scripts/
│   ├── setup.js             # Complete setup
│   ├── testConnection.js    # Connection test
│   ├── createToken.js       # Token creation
│   └── createTopic.js       # HCS topic setup
├── server.js                # Express server
├── .env.template           # Environment template
└── package.json
```

### Battle Flow
1. **Commit Phase**: Both players submit masked moves to HCS  
2. **Reveal Phase**: Players reveal moves + random nonces
3. **Settlement**: Winner determined, tokens transferred
4. **Transparency**: Full round data published to HCS

### HCS Integration
- **Topic ID**: Stored in .env after setup
- **Message Format**: JSON with battle data
- **Transparency**: All rounds viewable on HashScan
- **Consensus**: Hedera's consensus timestamps prevent manipulation

## 🔍 Monitoring

### Transaction Tracking
- **HashScan**: https://hashscan.io/testnet
- **Search**: Use token/topic IDs from setup
- **Real-time**: Monitor HCS messages

### Logs
```bash
# Backend logs
npm start

# Setup logs  
npm run setup

# Connection test
npm run test-connection
```

## 🛠️ Troubleshooting

### Common Issues

**"Connection failed"**
- Check HBAR balance (need ~5 HBAR)
- Verify account ID format: `0.0.123456`
- Confirm private key is correct

**"Token creation failed"**
- Insufficient HBAR for transaction fees
- Invalid private key permissions
- Network connectivity issues

**"Service not initialized"**
- Run `npm run setup` first
- Check .env configuration
- Verify token/topic IDs exist

### Debug Commands
```bash
# Test everything
npm run test-connection

# Check balance
node -e "require('./src/hederaClient').testConnection()"

# Validate .env
cat .env | grep -v "PLACEHOLDER"
```

## 🔒 Security

### Environment Variables
- **Never commit .env** (in .gitignore)
- **Use testnet only** for development  
- **Rotate keys** regularly
- **Monitor usage** via HashScan

### Battle Security  
- **Commit-reveal** prevents front-running
- **HCS timestamps** provide verifiable ordering
- **House edge** prevents long-term losses
- **Rate limiting** prevents spam

## 🚀 Production Deployment

### Mainnet Migration
1. Update .env with mainnet credentials
2. Change network in hederaClient.js
3. Fund production treasury account  
4. Re-run setup for mainnet resources

### Scaling Considerations
- **Connection pooling** for high throughput
- **Batch transactions** for efficiency  
- **Redis caching** for user balances
- **Load balancing** for multiple servers

## 📊 Token Distribution

### Initial Allocation
- **Treasury**: 1,000,000 CNE_TEST (100%)
- **Airdrops**: Controlled distribution
- **Battle Rewards**: From treasury
- **Wheel Prizes**: From treasury

### Economics
- **Battle Fee**: 10% to treasury
- **Wheel Cost**: Free daily spin
- **Airdrop**: 100 tokens per user
- **Max Wager**: 1,000 CNE_TEST

## 🎯 Integration with Flutter App

### Backend URL
Update Flutter app to use:
```dart
// Change from mock backend
const String baseUrl = 'http://localhost:3001';
```

### Wallet Integration (Future)
- HashPack wallet connect
- User-controlled token accounts
- Direct transactions from mobile

## 📈 Metrics & Analytics

### Key Metrics
- Daily active players
- Battle volume (CNE_TEST)
- Token distribution
- HCS message volume
- Server performance

### Monitoring Tools
- HashScan transaction explorer
- Server logs and metrics
- User engagement analytics
- Token economics dashboard

---

## 🆘 Support

Need help? Check:
1. This README
2. Hedera documentation: https://docs.hedera.com
3. CNEtv development team
4. Hedera Discord community

**Happy gaming on Hedera! 🎮⚡**
