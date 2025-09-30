# CoinNewsExtra TV - Reward Logic Framework Architecture
## Testnet → Mainnet Migration Strategy

*Production-ready reward engine with halving mechanics and 2-year token locking*

---

## 🎯 Executive Summary

**Phase 1 (Current)**: Implement complete reward engine on **CNE_MAINNET mainnet** (Token ID: `0.0.9764298`)
- Safe testing environment with infinite supply
- Full halving tier simulation
- 50% token locking mechanism (2-year vesting)
- Comprehensive anti-abuse controls

**Phase 2 (Future)**: Migrate to **mainnet CNE** after thorough testing
- Token ID swap to mainnet CNE
- Treasury account migration
- User balance preservation
- Full audit and pilot testing

---

## 🏗️ System Architecture

### Core Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Event         │    │   Reward         │    │   Hedera        │
│   Producers     ├────┤   Engine         ├────┤   Integration   │
│   (App/Web)     │    │   (Firebase)     │    │   (Testnet)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                         │                        │
         │              ┌──────────────────┐               │
         └──────────────┤   HCS Logger     ├───────────────┘
                        │   (Transparency) │
                        └──────────────────┘
```

#### 1. Event Producers
- **Flutter App**: Video watch events, ad interactions, user actions
- **Web Interface**: Social media integrations, referral tracking
- **Admin Panel**: Manual reward overrides, testing triggers

#### 2. API / Event Ingest
- **Firebase Cloud Functions**: Idempotent event processing
- **Authentication**: Firebase Auth + JWT validation
- **Rate Limiting**: Per-user and per-IP abuse prevention
- **Validation**: Event authenticity and anti-spoofing

#### 3. Reward Engine Core
- **Halving Calculator**: Dynamic reward amounts based on user count
- **Lock Manager**: 50% immediate, 50% locked for 2 years
- **Idempotency**: Prevents duplicate rewards
- **Precision**: 8-decimal CNE_MAINNET token handling

#### 4. Ledger System
- **Firestore Database**: Internal balance tracking
- **Transaction Queue**: Batched Hedera transfers
- **Reconciliation**: Balance verification and audit trails

#### 5. Hedera Integration
- **Current**: CNE_MAINNET (0.0.9764298) on mainnet
- **Future**: Mainnet CNE token integration
- **HCS Topic**: 0.0.6917128 for transparency logging

---

## 📊 Data Model (Firestore Schema)

### Collection: `users`
```javascript
{
  uid: "firebase_user_id",
  wallet_address: "0.0.1234567", // Hedera account (nullable)
  available_balance: 1250.75,    // Unlocked CNE_MAINNET ready to transfer
  locked_balance: 2480.25,       // Total locked tokens
  locks: [                       // Array of lock objects
    {
      lockId: "lock_uuid_1",
      amount: 350.0,
      unlockAt: "2027-09-29T12:00:00Z", // 2 years from creation
      source: "signup_bonus",
      createdAt: "2025-09-29T12:00:00Z"
    },
    {
      lockId: "lock_uuid_2", 
      amount: 175.5,
      unlockAt: "2027-10-15T15:30:00Z",
      source: "referral_bonus",
      createdAt: "2025-10-15T15:30:00Z"
    }
  ],
  total_earned: 5730.0,          // Lifetime earnings
  daily_claimed_at: "2025-09-29", // Last daily airdrop claim (UTC date)
  created_at: "2025-01-15T10:00:00Z",
  updated_at: "2025-09-29T12:00:00Z"
}
```

### Collection: `rewards_log` (Audit Trail)
```javascript
{
  id: "reward_uuid",
  uid: "firebase_user_id",
  event_type: "live_10min",       // Event that triggered reward
  amount: 7.0,                    // Total reward amount
  immediate_amount: 3.5,          // 50% available immediately
  locked_amount: 3.5,             // 50% locked for 2 years
  halving_tier: 10000,            // User count tier when rewarded
  tx_id: "hedera_tx_hash",        // Hedera transaction ID (nullable)
  status: "COMPLETED",            // PENDING, COMPLETED, FAILED
  idempotency_key: "unique_key_123", // Prevents duplicate processing
  event_metadata: {               // Additional event context
    video_id: "video_123",
    watch_duration: 600,
    session_id: "session_456"
  },
  created_at: "2025-09-29T12:00:00Z"
}
```

### Collection: `pending_transfers` (Transfer Queue)
```javascript
{
  id: "transfer_uuid",
  to_wallet: "0.0.1234567",      // Recipient Hedera account
  amount: 125.75,                // CNE_MAINNET amount to transfer
  status: "PENDING",             // PENDING, PROCESSING, COMPLETED, FAILED
  attempt_count: 0,              // Retry attempts for failed transfers
  batch_id: "batch_20250929_001", // For batched transfers
  reward_log_id: "reward_uuid",  // Reference to originating reward
  created_at: "2025-09-29T12:00:00Z",
  processed_at: null             // Timestamp when transfer executed
}
```

### Document: `config/halving` (Reward Configuration)
```javascript
{
  thresholds: [10000, 100000, 500000, 1000000, 5000000, 10000000],
  mapping: {
    "10000": {
      daily_airdrop: 28,
      signup_bonus: 700,
      referral_bonus: 700,
      ad_view: 2.8,
      live_10min: 7,
      other_25pct: 7,
      social_follow: 100
    },
    "100000": {
      daily_airdrop: 14,
      signup_bonus: 350,
      referral_bonus: 350,
      ad_view: 1.4,
      live_10min: 3.5,
      other_25pct: 3.5,
      social_follow: 50
    },
    "500000": {
      daily_airdrop: 7,
      signup_bonus: 175,
      referral_bonus: 175,
      ad_view: 0.7,
      live_10min: 1.75,
      other_25pct: 1.75,
      social_follow: 25
    },
    "1000000": {
      daily_airdrop: 3.5,
      signup_bonus: 87.5,
      referral_bonus: 87.5,
      ad_view: 0.35,
      live_10min: 0.875,
      other_25pct: 0.875,
      social_follow: 12.5
    },
    "5000000": {
      daily_airdrop: 1.75,
      signup_bonus: 43.75,
      referral_bonus: 43.75,
      ad_view: 0.175,
      live_10min: 0.4375,
      other_25pct: 0.4375,
      social_follow: 6.25
    },
    "10000000": {
      daily_airdrop: 0.875,
      signup_bonus: 21.875,
      referral_bonus: 21.875,
      ad_view: 0.0875,
      live_10min: 0.21875,
      other_25pct: 0.21875,
      social_follow: 3.125
    }
  },
  lock_duration_years: 2,
  lock_percentage: 0.5,          // 50% locked
  updated_at: "2025-09-29T12:00:00Z"
}
```

### Document: `metrics/totals` (System Metrics)
```javascript
{
  user_count: 45750,             // Current total users (for halving calculation)
  total_distributed: 2450000.75, // All-time CNE_MAINNET distributed
  total_locked: 1225000.375,     // Currently locked tokens
  total_unlocked: 1225000.375,   // Unlocked and available
  daily_distribution: 15750.5,   // Today's distribution
  last_updated: "2025-09-29T12:00:00Z",
  
  // Per-event statistics
  event_stats: {
    signup_bonus: { count: 45750, total: 890625.0 },
    daily_airdrop: { count: 325250, total: 1625000.5 },
    ad_view: { count: 892340, total: 178468.0 },
    live_10min: { count: 234567, total: 467134.0 },
    other_25pct: { count: 156789, total: 313578.0 },
    referral_bonus: { count: 12450, total: 248750.0 },
    social_follow: { count: 89456, total: 894560.0 }
  }
}
```

---

## ⚡ Reward Engine Algorithm

### Core Functions

```javascript
// Halving tier calculation
const THRESHOLDS = [10000000, 5000000, 1000000, 500000, 100000, 10000]; // Descending order

function getHalvingTier(totalUsers) {
    for (const threshold of THRESHOLDS) {
        if (totalUsers >= threshold) {
            return threshold;
        }
    }
    return 10000; // Default to smallest tier
}

// Reward amount calculation
async function getRewardAmount(eventType, totalUsers) {
    const tier = getHalvingTier(totalUsers);
    const config = await admin.firestore().doc('config/halving').get();
    const mapping = config.data().mapping;
    
    const amount = mapping[tier.toString()][eventType];
    if (amount === undefined) {
        throw new Error(`Unknown event type: ${eventType}`);
    }
    
    return { amount, tier };
}

// Main reward processing function
async function applyReward(uid, eventType, eventMetadata, idempotencyKey) {
    // 1. Idempotency check
    const existingLog = await admin.firestore()
        .collection('rewards_log')
        .where('idempotency_key', '==', idempotencyKey)
        .limit(1)
        .get();
    
    if (!existingLog.empty) {
        return existingLog.docs[0].data(); // Return existing reward
    }
    
    // 2. Get current user count and calculate reward
    const metricsDoc = await admin.firestore().doc('metrics/totals').get();
    const totalUsers = metricsDoc.data().user_count;
    const { amount, tier } = await getRewardAmount(eventType, totalUsers);
    
    // 3. Calculate immediate and locked portions
    const immediate = Math.round(amount * 0.5 * 100000000) / 100000000; // 50% immediate (8 decimals)
    const locked = Math.round((amount - immediate) * 100000000) / 100000000; // 50% locked
    
    // 4. Create reward log entry
    const rewardLogRef = admin.firestore().collection('rewards_log').doc();
    const lockId = `lock_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const unlockAt = new Date(Date.now() + (2 * 365 * 24 * 60 * 60 * 1000)); // 2 years
    
    const rewardLog = {
        id: rewardLogRef.id,
        uid,
        event_type: eventType,
        amount,
        immediate_amount: immediate,
        locked_amount: locked,
        halving_tier: tier,
        tx_id: null,
        status: 'PENDING',
        idempotency_key: idempotencyKey,
        event_metadata: eventMetadata,
        created_at: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // 5. Update user balances and create lock (atomic transaction)
    await admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().doc(`users/${uid}`);
        const userDoc = await transaction.get(userRef);
        
        const userData = userDoc.exists ? userDoc.data() : {
            available_balance: 0,
            locked_balance: 0,
            locks: [],
            total_earned: 0
        };
        
        // Update balances
        userData.available_balance += immediate;
        userData.locked_balance += locked;
        userData.total_earned += amount;
        
        // Add new lock
        userData.locks.push({
            lockId,
            amount: locked,
            unlockAt: unlockAt.toISOString(),
            source: eventType,
            createdAt: new Date().toISOString()
        });
        
        userData.updated_at = admin.firestore.FieldValue.serverTimestamp();
        
        // Write updates
        transaction.set(userRef, userData, { merge: true });
        transaction.set(rewardLogRef, rewardLog);
        
        // Update system metrics
        const metricsRef = admin.firestore().doc('metrics/totals');
        transaction.update(metricsRef, {
            total_distributed: admin.firestore.FieldValue.increment(amount),
            total_locked: admin.firestore.FieldValue.increment(locked),
            [`event_stats.${eventType}.count`]: admin.firestore.FieldValue.increment(1),
            [`event_stats.${eventType}.total`]: admin.firestore.FieldValue.increment(amount),
            last_updated: admin.firestore.FieldValue.serverTimestamp()
        });
    });
    
    // 6. Queue immediate transfer to Hedera
    if (immediate > 0) {
        await queueTransfer(uid, immediate, rewardLogRef.id);
    }
    
    // 7. Log to HCS for transparency
    await publishToHCS({
        type: 'reward_granted',
        uid,
        event_type: eventType,
        amount,
        immediate_amount: immediate,
        locked_amount: locked,
        halving_tier: tier,
        timestamp: new Date().toISOString()
    });
    
    // 8. Mark reward as completed
    await rewardLogRef.update({ status: 'COMPLETED' });
    
    return { ...rewardLog, status: 'COMPLETED' };
}
```

---

## 🎮 Event Flow Implementation

### 1. Video Watch Events

```javascript
// Live video: reward every 10 minutes of continuous watching
exports.processLiveWatch = onCall(async (request) => {
    const { videoId, sessionId, watchDuration } = request.data;
    const uid = request.auth.uid;
    
    // Validate minimum watch duration (10 minutes = 600 seconds)
    if (watchDuration < 600) {
        throw new functions.https.HttpsError('invalid-argument', 'Insufficient watch time');
    }
    
    // Anti-abuse: check for continuous watching (no excessive skipping)
    const sessionData = await validateWatchSession(sessionId, watchDuration);
    if (!sessionData.isValid) {
        throw new functions.https.HttpsError('failed-precondition', 'Invalid watch session');
    }
    
    const idempotencyKey = `live_${uid}_${videoId}_${Math.floor(watchDuration / 600)}`;
    
    return await applyReward(uid, 'live_10min', {
        video_id: videoId,
        session_id: sessionId,
        watch_duration: watchDuration
    }, idempotencyKey);
});

// Other videos: reward when 25% watched
exports.processVideoWatch = onCall(async (request) => {
    const { videoId, watchedPercentage, totalDuration } = request.data;
    const uid = request.auth.uid;
    
    if (watchedPercentage < 0.25) {
        throw new functions.https.HttpsError('invalid-argument', 'Insufficient watch percentage');
    }
    
    const idempotencyKey = `video_${uid}_${videoId}_25pct`;
    
    return await applyReward(uid, 'other_25pct', {
        video_id: videoId,
        watched_percentage: watchedPercentage,
        total_duration: totalDuration
    }, idempotencyKey);
});
```

### 2. Advertisement Rewards

```javascript
exports.processAdView = onCall(async (request) => {
    const { adId, adProvider, completionToken } = request.data;
    const uid = request.auth.uid;
    
    // Verify ad completion with 3rd party provider
    const isValidCompletion = await verifyAdCompletion(adProvider, completionToken);
    if (!isValidCompletion) {
        throw new functions.https.HttpsError('failed-precondition', 'Invalid ad completion');
    }
    
    const idempotencyKey = `ad_${uid}_${adId}_${completionToken}`;
    
    return await applyReward(uid, 'ad_view', {
        ad_id: adId,
        ad_provider: adProvider,
        completion_token: completionToken
    }, idempotencyKey);
});
```

### 3. User Lifecycle Events

```javascript
// Signup bonus (triggered on account creation)
exports.processSignupBonus = onCall(async (request) => {
    const uid = request.auth.uid;
    
    // Verify this is a new user (check creation timestamp)
    const userRecord = await admin.auth().getUser(uid);
    const accountAge = Date.now() - new Date(userRecord.metadata.creationTime).getTime();
    
    if (accountAge > 24 * 60 * 60 * 1000) { // More than 24 hours old
        throw new functions.https.HttpsError('failed-precondition', 'Signup bonus expired');
    }
    
    const idempotencyKey = `signup_${uid}`;
    
    return await applyReward(uid, 'signup_bonus', {
        account_created: userRecord.metadata.creationTime
    }, idempotencyKey);
});

// Referral bonus (when referred user signs up)
exports.processReferralBonus = onCall(async (request) => {
    const { referredUserId } = request.data;
    const referrerUid = request.auth.uid;
    
    // Validate referral relationship and referred user activity
    const isValidReferral = await validateReferral(referrerUid, referredUserId);
    if (!isValidReferral) {
        throw new functions.https.HttpsError('failed-precondition', 'Invalid referral');
    }
    
    const idempotencyKey = `referral_${referrerUid}_${referredUserId}`;
    
    return await applyReward(referrerUid, 'referral_bonus', {
        referred_user: referredUserId
    }, idempotencyKey);
});

// Daily airdrop claim
exports.claimDailyAirdrop = onCall(async (request) => {
    const uid = request.auth.uid;
    const today = new Date().toISOString().split('T')[0]; // UTC date
    
    // Check if already claimed today
    const userDoc = await admin.firestore().doc(`users/${uid}`).get();
    const userData = userDoc.data();
    
    if (userData?.daily_claimed_at === today) {
        throw new functions.https.HttpsError('already-exists', 'Daily airdrop already claimed today');
    }
    
    const idempotencyKey = `daily_${uid}_${today}`;
    
    // Update claim date
    await admin.firestore().doc(`users/${uid}`).update({
        daily_claimed_at: today
    });
    
    return await applyReward(uid, 'daily_airdrop', {
        claim_date: today
    }, idempotencyKey);
});
```

---

## 🔒 Token Locking & Vesting System

### Lock Management

```javascript
// Scheduled function to unlock tokens (runs daily)
exports.processTokenUnlocks = onSchedule('0 0 * * *', async (context) => {
    const now = new Date();
    const batch = admin.firestore().batch();
    
    // Query users with locks that should be unlocked
    const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('locked_balance', '>', 0)
        .get();
    
    for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        let unlockedAmount = 0;
        const updatedLocks = [];
        
        // Check each lock
        for (const lock of userData.locks || []) {
            const unlockDate = new Date(lock.unlockAt);
            
            if (unlockDate <= now) {
                // This lock should be unlocked
                unlockedAmount += lock.amount;
                
                // Log the unlock event
                const unlockLogRef = admin.firestore().collection('rewards_log').doc();
                batch.set(unlockLogRef, {
                    id: unlockLogRef.id,
                    uid: userDoc.id,
                    event_type: 'token_unlock',
                    amount: lock.amount,
                    immediate_amount: lock.amount,
                    locked_amount: 0,
                    halving_tier: null,
                    tx_id: null,
                    status: 'COMPLETED',
                    idempotency_key: `unlock_${lock.lockId}`,
                    event_metadata: {
                        original_lock: lock,
                        unlock_reason: 'schedule_unlock'
                    },
                    created_at: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // Keep this lock
                updatedLocks.push(lock);
            }
        }
        
        if (unlockedAmount > 0) {
            // Update user balances
            batch.update(userDoc.ref, {
                available_balance: userData.available_balance + unlockedAmount,
                locked_balance: userData.locked_balance - unlockedAmount,
                locks: updatedLocks,
                updated_at: admin.firestore.FieldValue.serverTimestamp()
            });
            
            // Queue transfer for unlocked tokens
            await queueTransfer(userDoc.id, unlockedAmount, `unlock_${userDoc.id}_${now.getTime()}`);
        }
    }
    
    await batch.commit();
    console.log(`Processed token unlocks for ${usersSnapshot.docs.length} users`);
});

// Manual unlock function (admin emergency use)
exports.forceUnlockTokens = onCall({ cors: true }, async (request) => {
    // Verify admin permissions
    const adminProvider = await admin.firestore().doc(`admins/${request.auth.uid}`).get();
    if (!adminProvider.exists || !adminProvider.data().isSuperAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Super admin required');
    }
    
    const { targetUserId, lockId, reason } = request.data;
    
    return await admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().doc(`users/${targetUserId}`);
        const userDoc = await transaction.get(userRef);
        const userData = userDoc.data();
        
        // Find the specific lock
        const lockIndex = userData.locks.findIndex(lock => lock.lockId === lockId);
        if (lockIndex === -1) {
            throw new functions.https.HttpsError('not-found', 'Lock not found');
        }
        
        const lock = userData.locks[lockIndex];
        userData.locks.splice(lockIndex, 1); // Remove the lock
        
        // Update balances
        userData.available_balance += lock.amount;
        userData.locked_balance -= lock.amount;
        userData.updated_at = admin.firestore.FieldValue.serverTimestamp();
        
        // Create audit log
        const unlockLogRef = admin.firestore().collection('rewards_log').doc();
        const unlockLog = {
            id: unlockLogRef.id,
            uid: targetUserId,
            event_type: 'admin_force_unlock',
            amount: lock.amount,
            immediate_amount: lock.amount,
            locked_amount: 0,
            halving_tier: null,
            tx_id: null,
            status: 'COMPLETED',
            idempotency_key: `force_unlock_${lockId}`,
            event_metadata: {
                original_lock: lock,
                unlock_reason: reason,
                admin_user: request.auth.uid
            },
            created_at: admin.firestore.FieldValue.serverTimestamp()
        };
        
        transaction.update(userRef, userData);
        transaction.set(unlockLogRef, unlockLog);
        
        return unlockLog;
    });
});
```

---

## 🛡️ Anti-Abuse & Security Controls

### Fraud Prevention System

```javascript
// Rate limiting and abuse detection
class AntiAbuseSystem {
    static async validateUser(uid, eventType) {
        const today = new Date().toISOString().split('T')[0];
        
        // Check daily caps per user
        const dailyRewards = await admin.firestore()
            .collection('rewards_log')
            .where('uid', '==', uid)
            .where('created_at', '>=', new Date(today))
            .get();
        
        const dailyCaps = {
            ad_view: 50,        // Max 50 ads per day
            live_10min: 144,    // Max 24 hours of live watching
            other_25pct: 20,    // Max 20 videos per day
            daily_airdrop: 1,   // Once per day
            social_follow: 10   // Max 10 follows per day
        };
        
        const currentCount = dailyRewards.docs.filter(doc => 
            doc.data().event_type === eventType
        ).length;
        
        if (currentCount >= (dailyCaps[eventType] || 100)) {
            throw new functions.https.HttpsError('resource-exhausted', 
                `Daily limit exceeded for ${eventType}`);
        }
        
        return true;
    }
    
    static async validateWatchSession(sessionId, watchDuration) {
        // Check for suspicious watch patterns
        const sessionDoc = await admin.firestore()
            .doc(`watch_sessions/${sessionId}`)
            .get();
        
        if (!sessionDoc.exists) {
            return { isValid: false, reason: 'Session not found' };
        }
        
        const sessionData = sessionDoc.data();
        
        // Check for excessive skipping (more than 30% skip rate)
        const skipRate = sessionData.totalSkips / watchDuration;
        if (skipRate > 0.3) {
            return { isValid: false, reason: 'Excessive skipping detected' };
        }
        
        // Check for minimum continuous watch (at least 80% continuous)
        const continuousRate = sessionData.continuousTime / watchDuration;
        if (continuousRate < 0.8) {
            return { isValid: false, reason: 'Insufficient continuous watch' };
        }
        
        return { isValid: true };
    }
    
    static async validateReferral(referrerUid, referredUserId) {
        // Prevent self-referral
        if (referrerUid === referredUserId) {
            return false;
        }
        
        // Check if referred user has minimum activity (7 days)
        const referredUser = await admin.auth().getUser(referredUserId);
        const accountAge = Date.now() - new Date(referredUser.metadata.creationTime).getTime();
        const sevenDays = 7 * 24 * 60 * 60 * 1000;
        
        if (accountAge < sevenDays) {
            return false; // Too new, wait for activity
        }
        
        // Check for existing referral relationship
        const existingReferral = await admin.firestore()
            .collection('rewards_log')
            .where('uid', '==', referrerUid)
            .where('event_type', '==', 'referral_bonus')
            .where('event_metadata.referred_user', '==', referredUserId)
            .limit(1)
            .get();
        
        return existingReferral.empty; // Only if no existing referral
    }
}

// Device/IP tracking for abuse prevention
exports.trackDeviceActivity = onCall(async (request) => {
    const { deviceId, ipAddress } = request.data;
    const uid = request.auth.uid;
    
    // Track device-user associations
    await admin.firestore().doc(`device_tracking/${deviceId}`).set({
        users: admin.firestore.FieldValue.arrayUnion(uid),
        ip_addresses: admin.firestore.FieldValue.arrayUnion(ipAddress),
        last_seen: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    // Alert if too many accounts from same device/IP
    const deviceDoc = await admin.firestore().doc(`device_tracking/${deviceId}`).get();
    const deviceData = deviceDoc.data();
    
    if (deviceData.users.length > 5) { // Max 5 accounts per device
        console.warn(`Suspicious device activity: ${deviceId} has ${deviceData.users.length} users`);
        
        // Could trigger manual review or temporary restrictions
        await admin.firestore().collection('abuse_alerts').add({
            type: 'multiple_accounts_device',
            device_id: deviceId,
            user_count: deviceData.users.length,
            users: deviceData.users,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });
    }
});
```

---

## 📈 Exact Reward Calculations

### Halving Tier Examples

```javascript
// Example calculations using exact values from your tokenomics

// Example A: Live watch 10 minutes at 10,000 users
const userCount = 10000;
const tier = getHalvingTier(userCount); // Returns 10000
const rewardAmount = 7; // CNE_MAINNET from mapping[10000][live_10min]

const immediate = 3.5;  // 50% available immediately
const locked = 3.5;     // 50% locked for 2 years

// Example B: User signup at 100,000 users  
const userCount = 100000;
const tier = getHalvingTier(userCount); // Returns 100000
const rewardAmount = 350; // CNE_MAINNET from mapping[100000][signup_bonus]

const immediate = 175;  // 50% available immediately
const locked = 175;     // 50% locked for 2 years

// Example C: Ad viewed at 1,000,000 users
const userCount = 1000000;
const tier = getHalvingTier(userCount); // Returns 1000000  
const rewardAmount = 0.35; // CNE_MAINNET from mapping[1000000][ad_view]

const immediate = 0.175;  // 50% available immediately
const locked = 0.175;     // 50% locked for 2 years

// Precision handling for small amounts
function roundToCNEPrecision(amount) {
    return Math.round(amount * 100000000) / 100000000; // 8 decimal places
}
```

---

## 🧪 Testing Strategy (CNE_MAINNET Phase)

### Test Suite Implementation

```javascript
// Halving tier simulation test
describe('Halving Tier System', () => {
    test('should return correct tier for user counts', () => {
        expect(getHalvingTier(5000)).toBe(10000);      // Below threshold
        expect(getHalvingTier(15000)).toBe(10000);     // First tier
        expect(getHalvingTier(150000)).toBe(100000);   // Second tier
        expect(getHalvingTier(750000)).toBe(500000);   // Third tier
        expect(getHalvingTier(2000000)).toBe(1000000); // Fourth tier
        expect(getHalvingTier(7500000)).toBe(5000000); // Fifth tier
        expect(getHalvingTier(15000000)).toBe(10000000); // Final tier
    });
    
    test('should calculate correct reward amounts per tier', async () => {
        // Mock user counts for each tier
        const testCases = [
            { users: 10000, eventType: 'signup_bonus', expected: 700 },
            { users: 100000, eventType: 'signup_bonus', expected: 350 },
            { users: 500000, eventType: 'ad_view', expected: 0.7 },
            { users: 1000000, eventType: 'live_10min', expected: 0.875 },
            { users: 5000000, eventType: 'daily_airdrop', expected: 1.75 },
            { users: 10000000, eventType: 'referral_bonus', expected: 21.875 }
        ];
        
        for (const testCase of testCases) {
            const { amount } = await getRewardAmount(testCase.eventType, testCase.users);
            expect(amount).toBe(testCase.expected);
        }
    });
});

// Idempotency testing
describe('Idempotency System', () => {
    test('should not create duplicate rewards', async () => {
        const uid = 'test_user_123';
        const eventType = 'ad_view';
        const idempotencyKey = 'test_key_456';
        
        // First call should create reward
        const reward1 = await applyReward(uid, eventType, {}, idempotencyKey);
        expect(reward1.status).toBe('COMPLETED');
        
        // Second call with same key should return existing reward
        const reward2 = await applyReward(uid, eventType, {}, idempotencyKey);
        expect(reward2.id).toBe(reward1.id);
        
        // Verify only one reward log exists
        const logs = await admin.firestore()
            .collection('rewards_log')
            .where('idempotency_key', '==', idempotencyKey)
            .get();
        expect(logs.size).toBe(1);
    });
});

// Lock and unlock testing
describe('Token Locking System', () => {
    test('should create 2-year locks correctly', async () => {
        const uid = 'test_user_789';
        const reward = await applyReward(uid, 'signup_bonus', {}, 'test_lock_key');
        
        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        const userData = userDoc.data();
        
        expect(userData.locks.length).toBe(1);
        
        const lock = userData.locks[0];
        const unlockDate = new Date(lock.unlockAt);
        const createdDate = new Date(lock.createdAt);
        const yearsDiff = (unlockDate - createdDate) / (1000 * 60 * 60 * 24 * 365);
        
        expect(Math.abs(yearsDiff - 2)).toBeLessThan(0.01); // Within 1% of 2 years
    });
    
    test('should unlock tokens after 2 years', async () => {
        // Create a lock with past unlock date
        const uid = 'test_user_unlock';
        const pastDate = new Date(Date.now() - 1000); // 1 second ago
        
        await admin.firestore().doc(`users/${uid}`).set({
            available_balance: 100,
            locked_balance: 200,
            locks: [{
                lockId: 'test_lock',
                amount: 200,
                unlockAt: pastDate.toISOString(),
                source: 'test_reward',
                createdAt: new Date(Date.now() - 1000000).toISOString()
            }]
        });
        
        // Run unlock process
        await processTokenUnlocks();
        
        // Verify tokens were unlocked
        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        const userData = userDoc.data();
        
        expect(userData.available_balance).toBe(300);
        expect(userData.locked_balance).toBe(0);
        expect(userData.locks.length).toBe(0);
    });
});

// Anti-abuse testing
describe('Anti-Abuse System', () => {
    test('should enforce daily caps', async () => {
        const uid = 'test_spam_user';
        
        // Create 50 ad view rewards (daily cap)
        for (let i = 0; i < 50; i++) {
            await applyReward(uid, 'ad_view', {}, `ad_key_${i}`);
        }
        
        // 51st attempt should fail
        await expect(
            applyReward(uid, 'ad_view', {}, 'ad_key_51')
        ).rejects.toThrow('Daily limit exceeded');
    });
    
    test('should detect invalid watch sessions', async () => {
        const sessionId = 'invalid_session';
        
        // Create session with excessive skipping
        await admin.firestore().doc(`watch_sessions/${sessionId}`).set({
            totalSkips: 300,    // 300 skips
            continuousTime: 400, // 400 seconds continuous
            totalDuration: 600   // 600 seconds total
        });
        
        const validation = await AntiAbuseSystem.validateWatchSession(sessionId, 600);
        expect(validation.isValid).toBe(false);
        expect(validation.reason).toContain('skipping');
    });
});
```

---

## 🚀 Mainnet Migration Checklist

### Pre-Migration Requirements

```javascript
// Migration configuration
const MIGRATION_CONFIG = {
    mainnet: {
        tokenId: '0.0.9764298',
        treasury: '0.0.6917102',
        hcsTopic: '0.0.6917128',
        network: 'mainnet'
    },
    mainnet: {
        tokenId: 'TBD', // Real CNE token ID
        treasury: 'TBD', // Mainnet treasury account  
        hcsTopic: 'TBD', // Mainnet HCS topic
        network: 'mainnet'
    }
};

// Pre-migration validation
exports.validateMigrationReadiness = onCall(async (request) => {
    const checks = [];
    
    // 1. Code audit completion
    checks.push({
        name: 'Security Audit',
        status: await checkSecurityAudit(),
        required: true
    });
    
    // 2. Test coverage verification
    checks.push({
        name: 'Test Coverage',
        status: await checkTestCoverage(),
        required: true,
        target: '95%'
    });
    
    // 3. Mainnet credentials setup
    checks.push({
        name: 'Mainnet Credentials',
        status: await checkMainnetCredentials(),
        required: true
    });
    
    // 4. User balance reconciliation
    checks.push({
        name: 'Balance Reconciliation',
        status: await reconcileAllBalances(),
        required: true
    });
    
    // 5. Pilot group selection
    checks.push({
        name: 'Pilot Group Ready',
        status: await checkPilotGroup(),
        required: true,
        details: 'Select 100 active users for pilot'
    });
    
    const allRequired = checks.filter(c => c.required).every(c => c.status === 'PASSED');
    
    return {
        ready: allRequired,
        checks,
        estimated_migration_time: '2-4 hours',
        rollback_plan: 'Available within 30 minutes'
    };
});

// Pilot migration function
exports.runPilotMigration = onCall(async (request) => {
    const { pilotUserIds } = request.data;
    
    if (pilotUserIds.length > 100) {
        throw new functions.https.HttpsError('invalid-argument', 'Pilot limited to 100 users');
    }
    
    const results = [];
    
    for (const uid of pilotUserIds) {
        try {
            // Migrate user to mainnet
            const migrationResult = await migrateUserToMainnet(uid);
            results.push({
                uid,
                status: 'SUCCESS',
                details: migrationResult
            });
        } catch (error) {
            results.push({
                uid,
                status: 'FAILED',
                error: error.message
            });
        }
    }
    
    return {
        pilot_complete: true,
        success_count: results.filter(r => r.status === 'SUCCESS').length,
        failure_count: results.filter(r => r.status === 'FAILED').length,
        results
    };
});

// Full migration execution
exports.executeMainnetMigration = onCall(async (request) => {
    // Verify super admin permissions
    const adminDoc = await admin.firestore().doc(`admins/${request.auth.uid}`).get();
    if (!adminDoc.exists || !adminDoc.data().isSuperAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Super admin required');
    }
    
    // Pause all reward processing
    await admin.firestore().doc('config/system').update({
        rewards_paused: true,
        migration_in_progress: true,
        migration_started_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    try {
        // 1. Update configuration to mainnet
        await admin.firestore().doc('config/hedera').update(MIGRATION_CONFIG.mainnet);
        
        // 2. Migrate all user balances
        const migrationStats = await migrateAllUsersToMainnet();
        
        // 3. Verify migration integrity
        const verificationResult = await verifyMigrationIntegrity();
        
        // 4. Resume reward processing
        await admin.firestore().doc('config/system').update({
            rewards_paused: false,
            migration_in_progress: false,
            migration_completed_at: admin.firestore.FieldValue.serverTimestamp(),
            network: 'mainnet'
        });
        
        return {
            migration_successful: true,
            users_migrated: migrationStats.total_users,
            tokens_migrated: migrationStats.total_tokens,
            verification: verificationResult
        };
        
    } catch (error) {
        // Rollback on failure
        await admin.firestore().doc('config/hedera').update(MIGRATION_CONFIG.mainnet);
        await admin.firestore().doc('config/system').update({
            rewards_paused: false,
            migration_in_progress: false,
            migration_failed_at: admin.firestore.FieldValue.serverTimestamp(),
            network: 'mainnet'
        });
        
        throw new functions.https.HttpsError('internal', `Migration failed: ${error.message}`);
    }
});
```

---

## 📊 Admin Controls & Monitoring

### Administrative Functions

```javascript
// Override reward amounts (temporary)
exports.overrideRewardAmount = onCall(async (request) => {
    const { eventType, newAmount, durationHours, reason } = request.data;
    
    // Verify admin permissions
    const adminDoc = await admin.firestore().doc(`admins/${request.auth.uid}`).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
    
    const expiresAt = new Date(Date.now() + (durationHours * 60 * 60 * 1000));
    
    await admin.firestore().doc('config/reward_overrides').set({
        [eventType]: {
            original_amount: null, // Will be set when first override is applied
            override_amount: newAmount,
            expires_at: expiresAt,
            reason,
            admin_user: request.auth.uid,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        }
    }, { merge: true });
    
    // Log the override action
    await admin.firestore().collection('admin_actions').add({
        action: 'reward_override',
        admin_user: request.auth.uid,
        event_type: eventType,
        new_amount: newAmount,
        duration_hours: durationHours,
        reason,
        created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true, expires_at: expiresAt };
});

// Emergency pause all rewards
exports.pauseRewards = onCall(async (request) => {
    const { reason } = request.data;
    
    // Verify super admin permissions
    const adminDoc = await admin.firestore().doc(`admins/${request.auth.uid}`).get();
    if (!adminDoc.exists || !adminDoc.data().isSuperAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Super admin required');
    }
    
    await admin.firestore().doc('config/system').update({
        rewards_paused: true,
        pause_reason: reason,
        paused_by: request.auth.uid,
        paused_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Log the pause action
    await admin.firestore().collection('admin_actions').add({
        action: 'pause_rewards',
        admin_user: request.auth.uid,
        reason,
        created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true, message: 'All rewards paused' };
});

// Resume rewards
exports.resumeRewards = onCall(async (request) => {
    // Verify super admin permissions
    const adminDoc = await admin.firestore().doc(`admins/${request.auth.uid}`).get();
    if (!adminDoc.exists || !adminDoc.data().isSuperAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Super admin required');
    }
    
    await admin.firestore().doc('config/system').update({
        rewards_paused: false,
        pause_reason: admin.firestore.FieldValue.delete(),
        resumed_by: request.auth.uid,
        resumed_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true, message: 'Rewards resumed' };
});

// System health dashboard
exports.getSystemHealth = onCall(async (request) => {
    const [metricsDoc, systemDoc, overridesDoc] = await Promise.all([
        admin.firestore().doc('metrics/totals').get(),
        admin.firestore().doc('config/system').get(),
        admin.firestore().doc('config/reward_overrides').get()
    ]);
    
    const metrics = metricsDoc.data();
    const system = systemDoc.data();
    const overrides = overridesDoc.data();
    
    // Calculate distribution rate (last 24 hours)
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentRewards = await admin.firestore()
        .collection('rewards_log')
        .where('created_at', '>=', yesterday)
        .get();
    
    const last24hDistribution = recentRewards.docs.reduce((sum, doc) => 
        sum + doc.data().amount, 0);
    
    // Check pending transfers
    const pendingTransfers = await admin.firestore()
        .collection('pending_transfers')
        .where('status', '==', 'PENDING')
        .get();
    
    return {
        system_status: {
            rewards_active: !system?.rewards_paused,
            network: system?.network || 'mainnet',
            migration_in_progress: system?.migration_in_progress || false
        },
        metrics: {
            total_users: metrics?.user_count || 0,
            current_tier: getHalvingTier(metrics?.user_count || 0),
            total_distributed: metrics?.total_distributed || 0,
            total_locked: metrics?.total_locked || 0,
            last_24h_distribution: last24hDistribution
        },
        operations: {
            pending_transfers: pendingTransfers.size,
            active_overrides: Object.keys(overrides || {}).length,
            last_unlock_run: system?.last_unlock_run || null
        },
        event_stats: metrics?.event_stats || {}
    };
});
```

---

## 📋 Implementation Deliverables

### Development Checklist

#### Phase 1: Core Infrastructure ✅
- [x] Firebase project setup with CNE_MAINNET integration
- [x] Firestore collections schema (users, rewards_log, etc.)
- [x] Halving tier configuration document
- [x] Basic reward calculation functions
- [x] HCS transparency logging

#### Phase 2: Reward Engine Implementation 🚧
- [ ] `applyReward()` function with idempotency
- [ ] Event-specific reward endpoints (video, ad, signup, etc.)
- [ ] Token locking system with 2-year vesting
- [ ] Anti-abuse controls and daily caps
- [ ] Batch transfer queue system

#### Phase 3: Admin Controls 📋
- [ ] Admin override system for reward amounts
- [ ] Emergency pause/resume functionality
- [ ] System health dashboard
- [ ] Force unlock capabilities (super admin)
- [ ] Audit logging for all admin actions

#### Phase 4: Testing & Validation 🧪
- [ ] Unit tests for halving calculations
- [ ] Integration tests for full reward flow
- [ ] Anti-abuse scenario testing
- [ ] Load testing with high user counts
- [ ] Balance reconciliation verification

#### Phase 5: Mainnet Preparation 🚀
- [ ] Security audit completion
- [ ] Mainnet credentials setup
- [ ] Migration scripts and rollback procedures
- [ ] Pilot user group testing
- [ ] Full system migration execution

### Code Templates Ready for Implementation

```javascript
// 1. functions/src/rewards/rewardEngine.js
// 2. functions/src/rewards/antiAbuse.js  
// 3. functions/src/rewards/lockManager.js
// 4. functions/src/rewards/hederaTransfers.js
// 5. functions/src/admin/rewardOverrides.js
// 6. functions/src/admin/systemControls.js
// 7. functions/src/migrations/mainnetMigration.js
// 8. functions/src/utils/precision.js
// 9. functions/src/monitoring/systemHealth.js
// 10. functions/src/testing/rewardSimulation.js
```

---

## 🎉 Success Criteria

### Testnet Phase Success Metrics
- ✅ All halving tiers calculate correct reward amounts
- ✅ 100% idempotency (no duplicate rewards)
- ✅ Token locks create and unlock properly after 2 years
- ✅ Anti-abuse system blocks malicious activity
- ✅ 99.9% uptime for reward processing
- ✅ Complete audit trail via HCS logging

### Mainnet Migration Success Criteria
- ✅ Zero balance discrepancies after migration  
- ✅ All locked tokens preserve unlock dates
- ✅ <30 second downtime during switch
- ✅ Pilot group validates mainnet functionality
- ✅ Full security audit clearance
- ✅ Emergency rollback capability tested

This comprehensive reward framework provides a production-ready foundation for your tokenomics implementation, ensuring fair distribution, proper security, and seamless scaling from mainnet to mainnet operations! 🚀
