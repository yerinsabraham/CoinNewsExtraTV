/**
 * Core Reward Engine
 * Handles halving calculations, reward processing, and token locking
 */

const admin = require('firebase-admin');

// Precision utilities for CNE_TEST tokens (8 decimals)
const PRECISION_MULTIPLIER = 100000000; // 10^8

function roundToCNEPrecision(amount) {
  return Math.round(amount * PRECISION_MULTIPLIER) / PRECISION_MULTIPLIER;
}

/**
 * Calculate halving tier based on total user count
 * @param {number} totalUsers - Current total users
 * @returns {number} - Tier threshold
 */
function getHalvingTier(totalUsers) {
  const THRESHOLDS = [10000000, 5000000, 1000000, 500000, 100000, 10000]; // Descending order
  
  for (const threshold of THRESHOLDS) {
    if (totalUsers >= threshold) {
      return threshold;
    }
  }
  return 10000; // Default to smallest tier
}

/**
 * Get reward amount for specific event type and user count
 * @param {string} eventType - Type of event (ad_view, signup_bonus, etc.)
 * @param {number} totalUsers - Current total users
 * @returns {Promise<{amount: number, tier: number}>}
 */
async function getRewardAmount(eventType, totalUsers) {
  try {
    const tier = getHalvingTier(totalUsers);
    
    // Get halving configuration
    const configDoc = await admin.firestore().doc('config/halving').get();
    if (!configDoc.exists) {
      throw new Error('Halving configuration not found');
    }
    
    const config = configDoc.data();
    const mapping = config.mapping;
    
    if (!mapping[tier.toString()] || mapping[tier.toString()][eventType] === undefined) {
      throw new Error(`Unknown event type: ${eventType} for tier: ${tier}`);
    }
    
    const amount = mapping[tier.toString()][eventType];
    
    // Check for admin overrides
    const overridesDoc = await admin.firestore().doc('config/reward_overrides').get();
    if (overridesDoc.exists) {
      const overrides = overridesDoc.data();
      const override = overrides[eventType];
      
      if (override && new Date(override.expires_at.toDate()) > new Date()) {
        console.log(`Using override amount for ${eventType}: ${override.override_amount} (expires: ${override.expires_at.toDate()})`);
        return { amount: override.override_amount, tier, isOverride: true };
      }
    }
    
    return { amount, tier, isOverride: false };
  } catch (error) {
    console.error('Error getting reward amount:', error);
    throw error;
  }
}

/**
 * Main reward processing function with idempotency and locking
 * @param {string} uid - User ID
 * @param {string} eventType - Event type that triggered reward
 * @param {Object} eventMetadata - Additional event context
 * @param {string} idempotencyKey - Unique key to prevent duplicate processing
 * @returns {Promise<Object>} - Reward log entry
 */
async function applyReward(uid, eventType, eventMetadata, idempotencyKey) {
  try {
    console.log(`Processing reward: ${eventType} for user: ${uid}`);
    
    // 1. Check system status
    const systemDoc = await admin.firestore().doc('config/system').get();
    const systemConfig = systemDoc.data();
    
    if (systemConfig?.rewards_paused) {
      throw new Error(`Rewards are currently paused: ${systemConfig.pause_reason || 'No reason provided'}`);
    }
    
    // 2. Idempotency check
    const existingLog = await admin.firestore()
      .collection('rewards_log')
      .where('idempotency_key', '==', idempotencyKey)
      .limit(1)
      .get();
    
    if (!existingLog.empty) {
      console.log(`Idempotent reward found for key: ${idempotencyKey}`);
      return existingLog.docs[0].data();
    }
    
    // 3. Anti-abuse validation
    await validateAntiAbuse(uid, eventType);
    
    // 4. Get current user count and calculate reward
    const metricsDoc = await admin.firestore().doc('metrics/totals').get();
    const totalUsers = metricsDoc.data()?.user_count || 1000;
    const { amount, tier, isOverride } = await getRewardAmount(eventType, totalUsers);
    
    // 5. Calculate immediate and locked portions (50/50 split)
    const immediate = roundToCNEPrecision(amount * 0.5);
    const locked = roundToCNEPrecision(amount - immediate);
    
    console.log(`Reward calculation - Total: ${amount}, Immediate: ${immediate}, Locked: ${locked}, Tier: ${tier}`);
    
    // 6. Create reward log entry
    const rewardLogRef = admin.firestore().collection('rewards_log').doc();
    const lockId = `lock_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const unlockAt = new Date(Date.now() + (2 * 365 * 24 * 60 * 60 * 1000)); // 2 years from now
    
    const rewardLog = {
      id: rewardLogRef.id,
      uid,
      event_type: eventType,
      amount: roundToCNEPrecision(amount),
      immediate_amount: immediate,
      locked_amount: locked,
      halving_tier: tier,
      tx_id: null, // Will be set when Hedera transfer completes
      status: 'PENDING',
      idempotency_key: idempotencyKey,
      event_metadata: eventMetadata || {},
      is_override: isOverride || false,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // 7. Update user balances and create lock (atomic transaction)
    await admin.firestore().runTransaction(async (transaction) => {
      const userRef = admin.firestore().doc(`users/${uid}`);
      const userDoc = await transaction.get(userRef);
      
      let userData = userDoc.exists ? userDoc.data() : {
        uid,
        wallet_address: null,
        available_balance: 0,
        locked_balance: 0,
        locks: [],
        total_earned: 0,
        daily_claimed_at: null,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      };
      
      // Update balances
      userData.available_balance = roundToCNEPrecision(userData.available_balance + immediate);
      userData.locked_balance = roundToCNEPrecision(userData.locked_balance + locked);
      userData.total_earned = roundToCNEPrecision(userData.total_earned + amount);
      
      // Add new lock if there's a locked portion
      if (locked > 0) {
        userData.locks = userData.locks || [];
        userData.locks.push({
          lockId,
          amount: locked,
          unlockAt: unlockAt.toISOString(),
          source: eventType,
          createdAt: new Date().toISOString()
        });
      }
      
      userData.updated_at = admin.firestore.FieldValue.serverTimestamp();
      
      // Write user updates
      transaction.set(userRef, userData, { merge: true });
      
      // Write reward log
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
    
    console.log(`✅ Reward processed successfully: ${rewardLogRef.id}`);
    
    // 8. Queue immediate transfer to Hedera (if user has wallet)
    if (immediate > 0) {
      await queueTransfer(uid, immediate, rewardLogRef.id);
    }
    
    // 9. Log to HCS for transparency
    await publishToHCS({
      type: 'reward_granted',
      uid,
      event_type: eventType,
      amount,
      immediate_amount: immediate,
      locked_amount: locked,
      halving_tier: tier,
      timestamp: new Date().toISOString(),
      tx_ref: rewardLogRef.id
    });
    
    // 10. Mark reward as completed
    await rewardLogRef.update({ 
      status: 'COMPLETED',
      completed_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { ...rewardLog, status: 'COMPLETED' };
    
  } catch (error) {
    console.error('Error applying reward:', error);
    
    // Log failed reward attempt
    await admin.firestore().collection('rewards_log').add({
      uid,
      event_type: eventType,
      status: 'FAILED',
      error: error.message,
      idempotency_key: idempotencyKey,
      event_metadata: eventMetadata || {},
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    throw error;
  }
}

/**
 * Anti-abuse validation
 * @param {string} uid - User ID
 * @param {string} eventType - Event type
 */
async function validateAntiAbuse(uid, eventType) {
  const today = new Date().toISOString().split('T')[0]; // UTC date
  
  // Get system configuration for daily caps
  const systemDoc = await admin.firestore().doc('config/system').get();
  const dailyCaps = systemDoc.data()?.daily_caps || {};
  
  // Check daily caps per user
  const dailyRewards = await admin.firestore()
    .collection('rewards_log')
    .where('uid', '==', uid)
    .where('status', '==', 'COMPLETED')
    .orderBy('created_at', 'desc')
    .limit(100) // Check recent rewards
    .get();
  
  // Count rewards for today
  const todayCount = dailyRewards.docs.filter(doc => {
    const createdAt = doc.data().created_at.toDate();
    const rewardDate = createdAt.toISOString().split('T')[0];
    return rewardDate === today && doc.data().event_type === eventType;
  }).length;
  
  const dailyLimit = dailyCaps[eventType] || 100;
  
  if (todayCount >= dailyLimit) {
    throw new Error(`Daily limit exceeded for ${eventType}. Limit: ${dailyLimit}, Current: ${todayCount}`);
  }
  
  console.log(`Anti-abuse check passed for ${eventType}: ${todayCount}/${dailyLimit} daily rewards`);
}

/**
 * Queue transfer for Hedera processing
 * @param {string} uid - User ID
 * @param {number} amount - Amount to transfer
 * @param {string} rewardLogId - Reference to reward log
 */
async function queueTransfer(uid, amount, rewardLogId) {
  try {
    // Get user's wallet address
    const userDoc = await admin.firestore().doc(`users/${uid}`).get();
    const userData = userDoc.data();
    
    if (!userData?.wallet_address) {
      console.log(`No wallet address for user ${uid}, skipping immediate transfer`);
      return;
    }
    
    // Create transfer queue entry
    await admin.firestore().collection('pending_transfers').add({
      to_wallet: userData.wallet_address,
      amount: roundToCNEPrecision(amount),
      status: 'PENDING',
      attempt_count: 0,
      reward_log_id: rewardLogId,
      uid: uid,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`✅ Queued transfer: ${amount} CNE_TEST to ${userData.wallet_address}`);
  } catch (error) {
    console.error('Error queuing transfer:', error);
    // Don't throw - reward should still be processed even if transfer queuing fails
  }
}

/**
 * Publish event to HCS for transparency
 * @param {Object} eventData - Event data to publish
 */
async function publishToHCS(eventData) {
  try {
    // This will integrate with existing HCS functionality
    // For now, just log the event
    console.log('📝 HCS Event:', JSON.stringify(eventData, null, 2));
    
    // TODO: Integrate with existing HCS client from backend/hedera
    // await hcsClient.submitMessage(topicId, JSON.stringify(eventData));
  } catch (error) {
    console.error('Error publishing to HCS:', error);
    // Don't throw - reward should still be processed even if HCS logging fails
  }
}

module.exports = {
  getHalvingTier,
  getRewardAmount,
  applyReward,
  validateAntiAbuse,
  queueTransfer,
  publishToHCS,
  roundToCNEPrecision
};
