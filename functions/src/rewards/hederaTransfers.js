/**
 * Hedera Transfer Queue System
 * Handles batched CNE_TEST token transfers and queue management
 */

const admin = require('firebase-admin');
const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TokenTransferTransaction,
    TopicMessageSubmitTransaction
} = require("@hashgraph/sdk");

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

/**
 * Process pending transfers in batches
 */
async function processPendingTransfers() {
    try {
        console.log('💳 Starting batch transfer processing...');

        if (!hederaClient) {
            throw new Error('Hedera client not initialized');
        }

        // Get pending transfers (limit to prevent timeout)
        const pendingTransfersQuery = await admin.firestore()
            .collection('pending_transfers')
            .where('status', '==', 'PENDING')
            .where('attempt_count', '<', 3) // Max 3 retry attempts
            .orderBy('created_at', 'asc')
            .limit(50) // Process 50 at a time
            .get();

        if (pendingTransfersQuery.empty) {
            console.log('✅ No pending transfers to process');
            return { success: true, processed: 0 };
        }

        console.log(`Found ${pendingTransfersQuery.size} pending transfers`);

        let successCount = 0;
        let failureCount = 0;
        const batch = admin.firestore().batch();

        // Process each transfer
        for (const transferDoc of pendingTransfersQuery.docs) {
            const transferData = transferDoc.data();
            
            try {
                // Validate transfer data
                if (!transferData.to_wallet || !transferData.amount || transferData.amount <= 0) {
                    throw new Error('Invalid transfer data');
                }

                console.log(`Processing transfer: ${transferData.amount} CNE_TEST to ${transferData.to_wallet}`);

                // Execute Hedera transfer
                const transferResult = await executeHederaTransfer(
                    HEDERA_ACCOUNT_ID,
                    transferData.to_wallet,
                    transferData.amount
                );

                if (transferResult.success) {
                    // Mark transfer as completed
                    batch.update(transferDoc.ref, {
                        status: 'COMPLETED',
                        tx_id: transferResult.transactionId,
                        processed_at: admin.firestore.FieldValue.serverTimestamp(),
                        attempt_count: admin.firestore.FieldValue.increment(1)
                    });

                    // Update reward log if applicable
                    if (transferData.reward_log_id) {
                        const rewardLogRef = admin.firestore().doc(`rewards_log/${transferData.reward_log_id}`);
                        batch.update(rewardLogRef, {
                            tx_id: transferResult.transactionId,
                            updated_at: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }

                    // Publish to HCS for transparency
                    await publishTransferToHCS({
                        type: 'token_transfer',
                        from: HEDERA_ACCOUNT_ID,
                        to: transferData.to_wallet,
                        amount: transferData.amount,
                        token_id: CNE_TOKEN_ID,
                        transaction_id: transferResult.transactionId,
                        transfer_type: transferData.transfer_type || 'reward',
                        uid: transferData.uid,
                        timestamp: new Date().toISOString()
                    });

                    successCount++;
                    console.log(`✅ Transfer successful: ${transferResult.transactionId}`);

                } else {
                    throw new Error(transferResult.error || 'Transfer failed');
                }

            } catch (error) {
                console.error(`❌ Transfer failed for ${transferData.to_wallet}:`, error.message);

                // Mark transfer as failed or retry
                const newAttemptCount = (transferData.attempt_count || 0) + 1;
                
                if (newAttemptCount >= 3) {
                    // Max retries reached, mark as failed
                    batch.update(transferDoc.ref, {
                        status: 'FAILED',
                        error: error.message,
                        attempt_count: newAttemptCount,
                        failed_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                } else {
                    // Retry
                    batch.update(transferDoc.ref, {
                        status: 'PENDING',
                        error: error.message,
                        attempt_count: newAttemptCount,
                        next_retry_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                }

                failureCount++;
            }
        }

        // Commit all updates
        await batch.commit();

        console.log(`✅ Batch transfer processing completed:`);
        console.log(`   - Successful: ${successCount}`);
        console.log(`   - Failed: ${failureCount}`);

        return {
            success: true,
            processed: pendingTransfersQuery.size,
            successful: successCount,
            failed: failureCount
        };

    } catch (error) {
        console.error('❌ Error in batch transfer processing:', error);
        throw error;
    }
}

/**
 * Execute individual Hedera token transfer
 */
async function executeHederaTransfer(fromAccountId, toAccountId, amount) {
    try {
        if (!hederaClient) {
            throw new Error('Hedera client not initialized');
        }

        // Convert amount to token units (CNE_TEST has 8 decimals)
        const tokenAmount = Math.round(amount * 100000000); // Convert to smallest unit

        console.log(`Executing Hedera transfer: ${tokenAmount} token units (${amount} CNE_TEST) from ${fromAccountId} to ${toAccountId}`);

        const transferTx = new TokenTransferTransaction()
            .addTokenTransfer(CNE_TOKEN_ID, AccountId.fromString(fromAccountId), -tokenAmount)
            .addTokenTransfer(CNE_TOKEN_ID, AccountId.fromString(toAccountId), tokenAmount)
            .setTransactionMemo(`CNE reward transfer: ${amount} CNE_TEST`)
            .freezeWith(hederaClient);

        const response = await transferTx.execute(hederaClient);
        const receipt = await response.getReceipt(hederaClient);

        const success = receipt.status.toString() === "SUCCESS";
        const transactionId = response.transactionId.toString();

        console.log(`Hedera transfer result: ${success ? 'SUCCESS' : 'FAILED'} - ${transactionId}`);

        return {
            success,
            transactionId,
            receipt: receipt.status.toString()
        };

    } catch (error) {
        console.error('Hedera transfer execution failed:', error);
        return {
            success: false,
            error: error.message,
            transactionId: null
        };
    }
}

/**
 * Queue a new transfer
 */
async function queueNewTransfer(uid, toWallet, amount, transferType = 'reward', rewardLogId = null) {
    try {
        if (!toWallet || !amount || amount <= 0) {
            throw new Error('Invalid transfer parameters');
        }

        console.log(`Queuing new transfer: ${amount} CNE_TEST to ${toWallet} for user ${uid}`);

        const transferData = {
            uid,
            to_wallet: toWallet,
            amount: Math.round(amount * 100000000) / 100000000, // 8 decimal precision
            status: 'PENDING',
            attempt_count: 0,
            transfer_type: transferType,
            reward_log_id: rewardLogId,
            created_at: admin.firestore.FieldValue.serverTimestamp()
        };

        const transferRef = await admin.firestore().collection('pending_transfers').add(transferData);

        console.log(`✅ Transfer queued with ID: ${transferRef.id}`);

        return {
            success: true,
            transfer_id: transferRef.id,
            queued_amount: amount
        };

    } catch (error) {
        console.error('Error queuing transfer:', error);
        throw error;
    }
}

/**
 * Get transfer queue statistics
 */
async function getTransferQueueStats() {
    try {
        const [pendingQuery, completedQuery, failedQuery] = await Promise.all([
            admin.firestore().collection('pending_transfers').where('status', '==', 'PENDING').get(),
            admin.firestore().collection('pending_transfers').where('status', '==', 'COMPLETED').get(),
            admin.firestore().collection('pending_transfers').where('status', '==', 'FAILED').get()
        ]);

        // Calculate amounts
        let pendingAmount = 0;
        let completedAmount = 0;
        let failedAmount = 0;

        pendingQuery.forEach(doc => {
            pendingAmount += doc.data().amount || 0;
        });

        completedQuery.forEach(doc => {
            completedAmount += doc.data().amount || 0;
        });

        failedQuery.forEach(doc => {
            failedAmount += doc.data().amount || 0;
        });

        return {
            pending: {
                count: pendingQuery.size,
                amount: pendingAmount
            },
            completed: {
                count: completedQuery.size,
                amount: completedAmount
            },
            failed: {
                count: failedQuery.size,
                amount: failedAmount
            },
            total_processed: completedQuery.size + failedQuery.size,
            success_rate: completedQuery.size + failedQuery.size > 0 
                ? (completedQuery.size / (completedQuery.size + failedQuery.size) * 100).toFixed(2) + '%'
                : '0%'
        };

    } catch (error) {
        console.error('Error getting transfer queue stats:', error);
        throw error;
    }
}

/**
 * Publish transfer event to HCS
 */
async function publishTransferToHCS(transferData) {
    try {
        if (!hederaClient || !HCS_TOPIC_ID) {
            console.log('HCS not available, skipping transfer log');
            return;
        }

        const submitTx = new TopicMessageSubmitTransaction()
            .setTopicId(HCS_TOPIC_ID)
            .setMessage(JSON.stringify(transferData));

        const response = await submitTx.execute(hederaClient);
        const receipt = await response.getReceipt(hederaClient);

        console.log(`📝 Transfer logged to HCS: ${response.transactionId.toString()}`);

        return {
            success: receipt.status.toString() === "SUCCESS",
            hcs_transaction_id: response.transactionId.toString()
        };

    } catch (error) {
        console.error('HCS transfer logging failed:', error);
        // Don't throw - transfer should still succeed even if HCS logging fails
        return null;
    }
}

/**
 * Retry failed transfers
 */
async function retryFailedTransfers() {
    try {
        console.log('🔄 Retrying failed transfers...');

        // Get failed transfers that haven't exceeded max retries
        const failedTransfersQuery = await admin.firestore()
            .collection('pending_transfers')
            .where('status', '==', 'FAILED')
            .where('attempt_count', '<', 3)
            .limit(20) // Retry 20 at a time
            .get();

        if (failedTransfersQuery.empty) {
            console.log('✅ No failed transfers to retry');
            return { success: true, retried: 0 };
        }

        const batch = admin.firestore().batch();

        // Reset failed transfers to pending for retry
        failedTransfersQuery.forEach(doc => {
            batch.update(doc.ref, {
                status: 'PENDING',
                retry_requested_at: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();

        console.log(`✅ Reset ${failedTransfersQuery.size} failed transfers for retry`);

        return {
            success: true,
            retried: failedTransfersQuery.size
        };

    } catch (error) {
        console.error('Error retrying failed transfers:', error);
        throw error;
    }
}

/**
 * Clean up old completed transfers (keep for 30 days)
 */
async function cleanupOldTransfers() {
    try {
        console.log('🧹 Cleaning up old transfer records...');

        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        const oldTransfersQuery = await admin.firestore()
            .collection('pending_transfers')
            .where('status', 'in', ['COMPLETED', 'FAILED'])
            .where('created_at', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
            .limit(500)
            .get();

        if (oldTransfersQuery.empty) {
            console.log('✅ No old transfers to clean up');
            return { success: true, deleted: 0 };
        }

        const batch = admin.firestore().batch();

        oldTransfersQuery.forEach(doc => {
            batch.delete(doc.ref);
        });

        await batch.commit();

        console.log(`✅ Cleaned up ${oldTransfersQuery.size} old transfer records`);

        return {
            success: true,
            deleted: oldTransfersQuery.size
        };

    } catch (error) {
        console.error('Error cleaning up old transfers:', error);
        throw error;
    }
}

module.exports = {
    processPendingTransfers,
    executeHederaTransfer,
    queueNewTransfer,
    getTransferQueueStats,
    retryFailedTransfers,
    cleanupOldTransfers,
    publishTransferToHCS
};
