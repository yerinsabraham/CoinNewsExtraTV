# CME Token System - Complete Implementation Guide

## 🎯 **System Overview & Terminology**

### **Clear Terminology**
- **CME Points**: In-app off-chain points earned through activities
- **CME Tokens**: Real blockchain tokens (HTS on Hedera)
- **Conversion**: Points → Tokens happens ONLY during redemption via custodial wallet
- **1:1 Ratio**: 1 CME Point = 1 CME Token when redeemed

### **User Journey**
1. **Earn CME Points**: Watch videos, view ads, daily check-ins
2. **Points Split**: 50% Available immediately, 50% Locked (2-year vesting)
3. **Redeem Points**: Convert available points to real CME tokens on Hedera
4. **Self-Custody Option**: Future feature to export private keys

---

## ⚙️ **Redemption Flow & Requirements**

### **Redemption Thresholds**
- **Minimum Redemption**: 10 CME points
- **Maximum Per Day**: 1,000 CME points (anti-abuse measure)
- **Processing Time**: Every 5 minutes via scheduled function
- **Gas Fees**: Platform pays all Hedera transaction fees

### **Redemption Process**
1. User requests redemption from available balance
2. Points locked in "pending" state
3. Scheduled function processes queue
4. Real CME tokens transferred to user's custodial Hedera account
5. User can view transaction on Hedera explorer

### **Gas Fee Strategy**
- **Platform Responsibility**: All HBAR fees paid by system operator account
- **User Experience**: Zero-fee redemptions for users
- **Cost Management**: Batch processing to minimize transaction costs

---

## 🔒 **Locked Balance & Vesting System**

### **Vesting Schedule**
- **Lock Duration**: Exactly 2 years from earning date
- **Release Events**: Daily automated unlock check at midnight UTC
- **Notification**: Push notification when tokens become available
- **Manual Unlock**: Users can manually check and unlock expired locks

### **Vesting Logic**
```typescript
// Example vesting calculation
const lockPeriod = 2 * 365 * 24 * 60 * 60 * 1000; // 2 years in milliseconds
const unlockDate = earnDate + lockPeriod;
const isUnlockable = Date.now() >= unlockDate;
```

### **Wallet Display Requirements**
- **Available CME**: Ready for redemption
- **Locked CME**: Shows total locked balance
- **Vesting Schedule**: List of locks with countdown timers
- **Next Unlock**: Countdown to next vesting event
- **Unlock History**: Log of previously unlocked amounts

---

## 📊 **Halving System Implementation**

### **Halving Triggers**
- **Check Point**: Every reward calculation (backend only)
- **Tier Calculation**: Based on total registered users
- **Application**: Both immediate AND locked rewards halve together
- **Update Frequency**: Real-time tier checking on each reward event

### **Halving Schedule**
```
Tier 0: 0-9,999 users     → 100% rewards
Tier 1: 10,000-19,999     → 50% rewards  
Tier 2: 20,000-29,999     → 25% rewards
Tier 3: 30,000-39,999     → 12.5% rewards
...continuing to Tier 10   → 0.1% rewards (minimum)
```

### **Implementation Details**
- **Real-time**: Tier calculated on every reward request
- **Fair Distribution**: All users get same tier rate simultaneously
- **Transparency**: Current tier displayed in app UI
- **Notification**: Users notified when tier changes

---

## 🏦 **Custodial Wallet Lifecycle**

### **Wallet Creation (Automatic)**
```typescript
// Triggered during user onboarding
const wallet = {
  hederaAccountId: "0.0.1234567",
  privateKey: encrypt(generatedPrivateKey),
  publicKey: "302a300506032b657003210000...",
  did: "did:hedera:0.0.1234567",
  createdAt: Date.now(),
  status: "active"
};
```

### **Wallet Mapping**
- **Firebase UID** ↔ **Hedera Account ID** ↔ **DID**
- **Authentication**: Firebase Auth controls access
- **Authorization**: Only authenticated user can access their wallet
- **Audit Trail**: All operations logged to HCS with DID

### **Future Self-Custody Migration**
- **Export Private Key**: Encrypted download option
- **Withdraw All**: Move all tokens to external wallet
- **Account Closure**: Secure deletion of custodial data
- **Migration Incentive**: Bonus CME for users who self-custody

---

## 🆔 **DID Integration & Usage**

### **DID Structure**
```
did:hedera:0.0.{accountId}
Example: did:hedera:0.0.1234567
```

### **DID Applications**
- **User Identity**: Unique identifier across platforms
- **Cross-Platform Login**: Same DID on web, mobile, TV
- **Audit Logging**: All HCS messages tagged with user DID
- **Future Features**: NFT ownership, governance voting, reputation

### **DID-to-Profile Mapping**
```typescript
const userProfile = {
  firebaseUid: "abc123...",
  did: "did:hedera:0.0.1234567",
  hederaAccountId: "0.0.1234567",
  email: "user@example.com",
  displayName: "John Doe",
  createdAt: Date.now()
};
```

---

## 🛡️ **Admin Controls & Configuration**

### **Dynamic Reward Configuration**
```typescript
// Firebase Remote Config
const rewardConfig = {
  video_watch: { base: 5.0, enabled: true },
  ad_view: { base: 2.0, enabled: true },
  daily_airdrop: { base: 10.0, enabled: true },
  quiz_completion: { base: 15.0, enabled: false }, // Can disable
  social_follow: { base: 3.0, enabled: true },
  referral_bonus: { base: 25.0, enabled: true }
};
```

### **Admin Dashboard Features**
- **Reward Toggle**: Enable/disable specific reward types
- **Rate Adjustment**: Modify base reward amounts without redeploy
- **User Management**: View user balances and transaction history
- **Bulk Operations**: Airdrop tokens to selected users
- **System Monitoring**: Real-time metrics and alerts

### **Emergency Controls**
- **Pause System**: Stop all reward processing
- **Rollback**: Reverse specific transactions
- **Ban Users**: Prevent specific accounts from earning
- **Audit Mode**: Enhanced logging for investigation

### **Airdrop Functionality**
```typescript
// Admin can airdrop tokens
const airdrop = {
  targetUsers: ["uid1", "uid2", "uid3"],
  amount: 100, // CME points
  reason: "Community reward",
  immediate: 50, // Available immediately
  locked: 50,   // Locked for 2 years
  adminUid: "admin123"
};
```

---

## 🚨 **Fraud Prevention & Security**

### **Rate Limiting**
- **Device Fingerprinting**: Prevent multiple accounts per device
- **IP Tracking**: Limit rewards per IP address
- **Time-based Limits**: Cooldown periods between claims
- **Velocity Checks**: Flag unusually high reward frequency

### **Anomaly Detection**
```typescript
const fraudChecks = {
  videoWatchAnomaly: {
    maxVideosPerHour: 10,
    minWatchPercentage: 0.7,
    deviceReuse: 3 // Max accounts per device
  },
  adViewAnomaly: {
    maxAdsPerDay: 50,
    minViewDuration: 25, // seconds
    repeatClickThreshold: 5
  },
  behaviorPattern: {
    humanLikeDelay: true,
    mouseMovementTracking: true,
    suspiciousVelocity: true
  }
};
```

### **Anti-Abuse Measures**
- **Captcha Integration**: Random human verification
- **Machine Learning**: Behavioral pattern analysis
- **Manual Review**: Flagged accounts require admin approval
- **Account Suspension**: Temporary or permanent bans

### **Watchdog Implementations**
- **Real-time Monitoring**: Live dashboard of suspicious activity
- **Automated Responses**: Temporary rate limiting for flagged accounts
- **Alert System**: Notify admins of potential abuse
- **Forensic Logging**: Detailed logs for investigation

---

## 💻 **Developer Implementation Notes**

### **Mock vs Production Parity**
```typescript
// Mock implementation must mirror production exactly
const mockRewardService = {
  calculateReward: (eventType, userTier) => {
    // SAME logic as production, just no Hedera calls
    return productionRewardCalculation(eventType, userTier);
  },
  processRedemption: async (amount) => {
    // Mock the transfer, but same validation logic
    validateRedemption(amount);
    return mockTransactionId();
  }
};
```

### **Configuration Management**
- **Firebase Remote Config**: All reward rates configurable
- **Environment Variables**: Hedera credentials and network settings
- **Feature Flags**: Enable/disable features without redeploy
- **A/B Testing**: Test different reward rates with user segments

### **Configurable Reward Constants**
```typescript
// NO hard-coded values - all configurable
const rewardRates = await getRemoteConfig('reward_rates');
const videoReward = rewardRates.video_watch.base * getTierMultiplier(userTier);
```

### **Error Handling Strategy**
- **Graceful Degradation**: Fall back to mock when Firebase unavailable
- **Retry Logic**: Exponential backoff for failed operations
- **Circuit Breaker**: Stop calling failing services temporarily
- **User Communication**: Clear error messages with action steps

---

## 📈 **Scalability Considerations**

### **Database Design**
- **Sharding**: Partition users across multiple Firestore collections
- **Indexing**: Optimize queries for reward history and balances
- **Caching**: Redis cache for frequently accessed data
- **Batch Operations**: Process multiple operations together

### **Performance Optimization**
- **Lazy Loading**: Load wallet data only when needed
- **Background Sync**: Update balances in background
- **Compression**: Compress large data payloads
- **CDN**: Cache static assets globally

### **Monitoring & Alerting**
- **Real-time Metrics**: Track system performance
- **Error Tracking**: Monitor error rates and types
- **Business Metrics**: Track user engagement and token distribution
- **Cost Monitoring**: Track Hedera transaction costs

---

## 🔮 **Future Roadmap**

### **Phase 2 Features**
- **Staking System**: Lock tokens for additional rewards
- **Governance Voting**: Use tokens for platform decisions
- **NFT Rewards**: Special achievements unlock unique NFTs
- **Cross-platform Integration**: Use same wallet across all apps

### **Phase 3 Enhancements**
- **DeFi Integration**: Yield farming and liquidity provision
- **Cross-chain Bridge**: Support Ethereum, Polygon, etc.
- **Advanced Analytics**: AI-powered user insights
- **Social Features**: Token-gated communities and features

### **Technical Evolution**
- **Non-custodial Option**: Advanced users can self-manage keys
- **Hardware Wallet**: Integration with Ledger, Trezor
- **Multi-signature**: Enhanced security for large amounts
- **Layer 2 Solutions**: Faster, cheaper transactions

---

## 🎯 **Success Metrics**

### **User Engagement**
- **Daily Active Users**: Track engagement with token features
- **Reward Claim Rate**: Percentage of earned rewards actually claimed
- **Redemption Rate**: How many users convert points to tokens
- **Retention**: Long-term user engagement with token system

### **Economic Health**
- **Token Distribution**: Balanced distribution across user base
- **Vesting Compliance**: Track locked token release patterns
- **Platform Costs**: Hedera transaction fees and operational costs
- **Revenue Impact**: Token system effect on overall app revenue

### **Security Metrics**
- **Fraud Detection**: False positive/negative rates
- **Account Security**: Number of compromised accounts
- **System Uptime**: Availability of token services
- **Audit Compliance**: Regular security assessment results

This comprehensive system provides a robust foundation for the CME token economy while addressing all the crucial implementation details and future scalability needs.
