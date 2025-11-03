/**
 * Token Locking System
 * Handles 2-year token locks, unlock processing, and admin overrides
 */

const admin = require('firebase-admin');

/**
 * Scheduled function to unlock tokens (runs daily)
 */
async function processTokenUnlocks() {
    try {
        console.log('🔓 Starting daily token unlock process...');
        
        const now = new Date();
        const batch = admin.firestore().batch();
        let processedUsers = 0;
        let totalUnlockedAmount = 0;

        // Query users with locks that should be unlocked
        const usersSnapshot = await admin.firestore()
            .collection('users')
            .where('locked_balance', '>', 0)
            .limit(500) // Process in batches to avoid timeouts
            .get();

        console.log(`Found ${usersSnapshot.size} users with locked tokens to check`);

        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            let userUnlockedAmount = 0;
            const updatedLocks = [];

            // Check each lock
            for (const lock of userData.locks || []) {
                const unlockDate = new Date(lock.unlockAt);

                if (unlockDate <= now) {
                    // This lock should be unlocked
                    userUnlockedAmount += lock.amount;
                    console.log(`Unlocking ${lock.amount} CNE_TEST for user ${userDoc.id} (lock from ${lock.source})`);

                    // Create unlock log entry
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
                            unlock_reason: 'scheduled_unlock',
                            unlock_date: now.toISOString()
                        },
                        created_at: admin.firestore.FieldValue.serverTimestamp()
                    });

                    // Queue transfer for unlocked tokens
                    await queueUnlockTransfer(userDoc.id, lock.amount, unlockLogRef.id);

                } else {
                    // Keep this lock (not yet due for unlock)
                    updatedLocks.push(lock);
                }
            }

            if (userUnlockedAmount > 0) {
                // Update user balances
                const newAvailableBalance = (userData.available_balance || 0) + userUnlockedAmount;
                const newLockedBalance = (userData.locked_balance || 0) - userUnlockedAmount;

                batch.update(userDoc.ref, {
                    available_balance: Math.round(newAvailableBalance * 100000000) / 100000000, // 8 decimal precision
                    locked_balance: Math.round(newLockedBalance * 100000000) / 100000000,
                    locks: updatedLocks,
                    updated_at: admin.firestore.FieldValue.serverTimestamp()
                });

                processedUsers++;
                totalUnlockedAmount += userUnlockedAmount;
            }
        }

        // Update system metrics
        if (totalUnlockedAmount > 0) {
            batch.update(admin.firestore().doc('metrics/totals'), {
                total_locked: admin.firestore.FieldValue.increment(-totalUnlockedAmount),
                last_unlock_run: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        await batch.commit();

        console.log(`✅ Token unlock process completed:`);
        console.log(`   - Users processed: ${processedUsers}`);
        console.log(`   - Total unlocked: ${totalUnlockedAmount} CNE_TEST`);

        return {
            success: true,
            users_processed: processedUsers,
            total_unlocked: totalUnlockedAmount,
            processed_at: now.toISOString()
        };

    } catch (error) {
        console.error('❌ Error in token unlock process:', error);
        throw error;
    }
}

/**
 * Manual unlock function (admin emergency use)
 */
async function forceUnlockTokens(adminUid, targetUserId, lockId, reason) {
    try {
        console.log(`🔧 Admin force unlock: ${adminUid} unlocking lock ${lockId} for user ${targetUserId}`);

        // Verify admin permissions
        const adminDoc = await admin.firestore().doc(`admins/${adminUid}`).get();
        if (!adminDoc.exists || !adminDoc.data().isSuperAdmin) {
            throw new Error('Super admin permissions required for force unlock');
        }

        return await admin.firestore().runTransaction(async (transaction) => {
            const userRef = admin.firestore().doc(`users/${targetUserId}`);
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) {
                throw new Error('User not found');
            }

            const userData = userDoc.data();

            // Find the specific lock
            const lockIndex = userData.locks.findIndex(lock => lock.lockId === lockId);
            if (lockIndex === -1) {
                throw new Error('Lock not found');
            }

            const lock = userData.locks[lockIndex];
            userData.locks.splice(lockIndex, 1); // Remove the lock

            // Update balances
            const newAvailableBalance = (userData.available_balance || 0) + lock.amount;
            const newLockedBalance = (userData.locked_balance || 0) - lock.amount;

            userData.available_balance = Math.round(newAvailableBalance * 100000000) / 100000000;
            userData.locked_balance = Math.round(newLockedBalance * 100000000) / 100000000;
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
                    admin_user: adminUid,
                    force_unlock_date: new Date().toISOString()
                },
                created_at: admin.firestore.FieldValue.serverTimestamp()
            };

            // Create admin action log
            const adminActionRef = admin.firestore().collection('admin_actions').doc();
            const adminAction = {
                id: adminActionRef.id,
                action: 'force_unlock_tokens',
                admin_user: adminUid,
                target_user: targetUserId,
                lock_id: lockId,
                unlock_amount: lock.amount,
                reason: reason,
                created_at: admin.firestore.FieldValue.serverTimestamp()
            };

            // Write all updates
            transaction.update(userRef, userData);
            transaction.set(unlockLogRef, unlockLog);
            transaction.set(adminActionRef, adminAction);

            console.log(`✅ Force unlocked ${lock.amount} CNE_TEST for user ${targetUserId}`);

            return {
                success: true,
                unlocked_amount: lock.amount,
                lock_details: lock,
                unlock_log_id: unlockLogRef.id
            };
        });

    } catch (error) {
        console.error('❌ Error in force unlock:', error);
        throw error;
    }
}

/**
 * Get locks summary for a user
 */
async function getUserLocksSummary(uid) {
    try {
        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        
        if (!userDoc.exists) {
            return {
                total_locked: 0,
                active_locks: [],
                unlockable_amount: 0
            };
        }

        const userData = userDoc.data();
        const now = new Date();
        let unlockableAmount = 0;
        const activeLocks = [];

        if (userData.locks) {
            userData.locks.forEach(lock => {
                const unlockDate = new Date(lock.unlockAt);
                const daysRemaining = Math.ceil((unlockDate - now) / (24 * 60 * 60 * 1000));

                if (unlockDate <= now) {
                    unlockableAmount += lock.amount;
                }

                activeLocks.push({
                    lockId: lock.lockId,
                    amount: lock.amount,
                    source: lock.source,
                    unlockAt: lock.unlockAt,
                    createdAt: lock.createdAt,
                    daysRemaining: Math.max(0, daysRemaining),
                    isUnlockable: unlockDate <= now
                });
            });
        }

        return {
            total_locked: userData.locked_balance || 0,
            active_locks: activeLocks,
            unlockable_amount: unlockableAmount,
            locks_count: activeLocks.length
        };

    } catch (error) {
        console.error('Error getting user locks summary:', error);
        throw error;
    }
}

/**
 * Queue transfer for unlocked tokens
 */
async function queueUnlockTransfer(uid, amount, unlockLogId) {
    try {
        // Get user's wallet address
        const userDoc = await admin.firestore().doc(`users/${uid}`).get();
        const userData = userDoc.data();

        if (!userData?.wallet_address) {
            console.log(`No wallet address for user ${uid}, skipping unlock transfer`);
            return;
        }

        // Create transfer queue entry
        await admin.firestore().collection('pending_transfers').add({
            to_wallet: userData.wallet_address,
            amount: Math.round(amount * 100000000) / 100000000, // 8 decimal precision
            status: 'PENDING',
            attempt_count: 0,
            reward_log_id: unlockLogId,
            uid: uid,
            transfer_type: 'unlock',
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ Queued unlock transfer: ${amount} CNE_TEST to ${userData.wallet_address}`);
    } catch (error) {
        console.error('Error queuing unlock transfer:', error);
        // Don't throw - unlock should still be processed even if transfer queuing fails
    }
}

/**
 * Get system-wide locks statistics
 */
async function getSystemLocksStats() {
    try {
        // Get metrics
        const metricsDoc = await admin.firestore().doc('metrics/totals').get();
        const metrics = metricsDoc.data() || {};

        // Get users with locks
        const usersWithLocksQuery = await admin.firestore()
            .collection('users')
            .where('locked_balance', '>', 0)
            .get();

        let totalLocks = 0;
        let upcomingUnlocks = [];
        const now = new Date();

        // Analyze all locks
        usersWithLocksQuery.forEach(doc => {
            const userData = doc.data();
            if (userData.locks) {
                userData.locks.forEach(lock => {
                    totalLocks++;
                    const unlockDate = new Date(lock.unlockAt);
                    const daysUntilUnlock = Math.ceil((unlockDate - now) / (24 * 60 * 60 * 1000));
                    
                    if (daysUntilUnlock >= 0 && daysUntilUnlock <= 30) {
                        upcomingUnlocks.push({
                            amount: lock.amount,
                            daysUntilUnlock,
                            source: lock.source
                        });
                    }
                });
            }
        });

        return {
            total_locked_amount: metrics.total_locked || 0,
            total_locks_count: totalLocks,
            users_with_locks: usersWithLocksQuery.size,
            upcoming_unlocks_30_days: upcomingUnlocks.length,
            upcoming_unlock_amount_30_days: upcomingUnlocks.reduce((sum, unlock) => sum + unlock.amount, 0),
            last_unlock_run: metrics.last_unlock_run
        };

    } catch (error) {
        console.error('Error getting system locks stats:', error);
        throw error;
    }
}

module.exports = {
    processTokenUnlocks,
    forceUnlockTokens,
    getUserLocksSummary,
    queueUnlockTransfer,
    getSystemLocksStats
};
