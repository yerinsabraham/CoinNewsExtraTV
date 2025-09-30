# CME Token Custodial Wallet System Integration

## Overview

The CoinNewsExtra TV app now includes a comprehensive custodial Hedera wallet system with CME token rewards. This system provides:

- **Custodial Hedera Wallets**: Automatically created for each user
- **Off-chain CME Points**: Mirror on-chain token distribution  
- **Token Locking System**: 50% immediate, 50% locked for 2 years
- **Halving Tiers**: Rewards decrease as user base grows
- **Redemption System**: Convert points to real blockchain tokens

## Architecture

### Backend (Firebase Cloud Functions)

The Firebase functions in `functions/index.js` provide:

1. **User Onboarding** (`onboardUser`)
   - Creates custodial Hedera account
   - Generates ED25519 keypair
   - Issues 100 CME welcome bonus
   - Creates user DID

2. **Reward Processing** (`earnEvent`)
   - Universal reward handler for all events
   - Supports video watching, ads, daily check-ins, etc.
   - Implements halving tiers based on user count
   - Splits rewards: 50% immediate, 50% locked

3. **Token Management**
   - `getUserBalance`: Get user's CME balance
   - `redeemTokens`: Queue tokens for on-chain transfer
   - `unlockExpiredTokens`: Release locked tokens after 2 years

4. **Transfer Processing**
   - `processTokenTransfers`: Convert points to real tokens
   - `scheduledTokenTransfers`: Automated processing every 5 minutes
   - Integrates with Hedera SDK for real blockchain transfers

5. **Admin Functions**
   - `getSystemOverview`: System metrics and statistics
   - `configureHalvingTiers`: Update reward tiers
   - `resetDailyMetrics`: Daily automated reset

### Frontend (Flutter)

The Flutter app includes:

1. **Enhanced RewardService** (`lib/services/reward_service.dart`)
   - New CME token models (`CMEBalance`, `TokenLock`, `RewardResult`)
   - Integration with Firebase functions
   - Mock implementations for testing
   - Updated legacy methods to use new system

2. **CME Wallet Page** (`lib/screens/cme_wallet_page.dart`)
   - Complete wallet management interface
   - Balance display (available, locked, total)
   - Token lock information with unlock dates
   - Redemption functionality
   - Unlock expired tokens

3. **Updated Daily Check-in**
   - Shows CME token rewards
   - Displays immediate and locked amounts
   - Mandatory 30-second ad viewing

## CME Token Economics

### Reward Structure
- **Video Watching**: 5 CME (2.5 immediate, 2.5 locked)
- **Ad Viewing**: 2 CME (1.0 immediate, 1.0 locked)
- **Daily Check-in**: 10 CME (5.0 immediate, 5.0 locked)
- **Quiz Completion**: 15 CME (7.5 immediate, 7.5 locked)
- **Social Follow**: 3 CME (1.5 immediate, 1.5 locked)
- **Referral Bonus**: 25 CME (12.5 immediate, 12.5 locked)
- **Live Stream**: 8 CME (4.0 immediate, 4.0 locked)

### Halving Tiers
Rewards decrease as the user base grows:
- **Tier 0**: 0-9,999 users (full rewards)
- **Tier 1**: 10,000-19,999 users (50% rewards)
- **Tier 2**: 20,000-29,999 users (25% rewards)
- ...continuing to Tier 10 (maximum)

### Token Locking
- **Lock Duration**: 2 years from earning date
- **Lock Purpose**: Prevents immediate dumps, encourages long-term holding
- **Unlock Mechanism**: Users can manually unlock expired locks
- **Lock Types**: Signup bonus, daily rewards, video rewards, etc.

## Hedera Integration

### Custodial Wallet System
- **Account Creation**: Automatic ED25519 keypair generation
- **Private Key Management**: Encrypted storage in Firebase
- **DID Generation**: `did:hedera:0.0.{accountId}` format
- **Initial Funding**: 0 HBAR (gas-free for token transfers)

### Blockchain Operations
- **Token Transfers**: HTS (Hedera Token Service) transfers
- **Consensus Service**: HCS messages for audit trail
- **Account Management**: Automated account creation and funding
- **Transaction Queuing**: Reliable transfer processing with retries

### CME Token Details
- **Token Standard**: HTS (Hedera Token Service)
- **Decimals**: 8 (100,000,000 units = 1 CME)
- **Supply Management**: Controlled by smart contract
- **Transfer Fees**: Minimal HBAR fees paid by system

## Usage Flow

### New User Onboarding
1. User creates account in app
2. `onboardUser` function creates Hedera wallet
3. User receives 100 CME welcome bonus (50 available, 50 locked)
4. Wallet address and DID stored in user profile

### Earning Rewards
1. User performs activity (watch video, view ad, etc.)
2. App calls `earnEvent` with activity details
3. System calculates reward based on current tier
4. Reward split: 50% available immediately, 50% locked for 2 years
5. User balance updated in real-time

### Redeeming Tokens
1. User navigates to CME Wallet page
2. Enters amount to redeem from available balance
3. System queues redemption for processing
4. Scheduled function processes queue every 5 minutes
5. Real CME tokens transferred to user's Hedera account

### Unlocking Tokens
1. System tracks all locked tokens with unlock dates
2. User can check for expired locks in wallet
3. Manual unlock process releases tokens to available balance
4. Tokens then eligible for redemption to blockchain

## Admin Dashboard

Administrators can:
- View system overview (total users, distributed tokens, metrics)
- Configure halving tiers and reward amounts
- Monitor pending transfers and failed transactions
- Access detailed reward logs and user analytics
- Manually process transfers in emergency situations

## Testing & Development

### Mock Implementation
- All Firebase functions have fallback mock responses
- Allows development without Firebase backend
- Maintains consistent API interface
- Useful for UI testing and demonstrations

### Environment Configuration
- Development: Mock Hedera client and transfers
- Production: Real Hedera mainnet integration
- Staging: Hedera testnet for safe testing
- Local: Full mock implementation

## Security Considerations

### Private Key Management
- Keys encrypted before Firebase storage
- Production requires proper encryption service
- Keys never transmitted to client
- Regular security audits recommended

### Transfer Security
- All transfers require authentication
- Idempotency keys prevent duplicate rewards
- Rate limiting on reward claims
- Admin controls for emergency stops

### Audit Trail
- All operations logged to HCS
- Immutable blockchain record
- Full transaction traceability
- Compliance with regulations

## Future Enhancements

### Planned Features
- **Staking System**: Lock tokens for additional rewards
- **Governance Voting**: Use tokens for platform decisions
- **NFT Integration**: Reward special achievements with NFTs
- **Cross-chain Bridge**: Support other blockchain networks
- **DeFi Integration**: Yield farming and liquidity provision

### Technical Improvements
- **Batch Processing**: More efficient transfer batching
- **Mobile Wallet**: Non-custodial option for advanced users
- **Multi-sig Support**: Enhanced security for large amounts
- **Hardware Security**: Integration with hardware wallets
- **Lightning Network**: Instant micro-rewards

## Integration Checklist

For developers implementing this system:

- [ ] Deploy Firebase Cloud Functions
- [ ] Configure Hedera client with proper credentials
- [ ] Set up CME token on Hedera Token Service
- [ ] Configure HCS topic for audit logging
- [ ] Update Flutter app with new reward service
- [ ] Test complete user flow end-to-end
- [ ] Set up monitoring and alerting
- [ ] Implement proper key encryption
- [ ] Configure admin access controls
- [ ] Plan backup and recovery procedures

## Support

For questions or issues:
- Check Firebase Functions logs for backend errors
- Use Flutter debug console for client-side issues
- Monitor Hedera network status for blockchain problems
- Review HCS messages for audit trail verification
- Contact admin for system configuration changes

This integration provides a complete foundation for a token-based reward economy in the CoinNewsExtra TV app, with the flexibility to expand and enhance features as needed.
