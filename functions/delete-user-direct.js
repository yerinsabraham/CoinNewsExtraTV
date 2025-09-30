// Direct Admin User Deletion Script (Firebase Admin SDK)
// This script runs with admin privileges and doesn't require authentication

const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials (service account)
admin.initializeApp();
const db = admin.firestore();

async function deleteUserDirectly(email, reason = 'Direct admin deletion') {
  try {
    console.log('🔐 Direct Admin User Deletion');
    console.log('============================');
    console.log(`📧 Target email: ${email}`);
    console.log(`📝 Reason: ${reason}`);
    console.log('');

    // Step 1: Find user by email
    console.log('🔍 Looking up user by email...');
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
      console.log(`✅ Found user: ${userRecord.uid}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log(`❌ No user found with email: ${email}`);
        return { success: false, message: 'User not found' };
      }
      throw error;
    }

    const userId = userRecord.uid;
    console.log(`👤 User ID: ${userId}`);
    console.log(`📧 Email: ${userRecord.email}`);
    console.log(`📅 Created: ${userRecord.metadata.creationTime}`);
    console.log('');

    // Step 2: Collect user data before deletion
    console.log('📊 Collecting user data...');
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data() : null;
    
    if (userData) {
      console.log(`💰 Points Balance: ${userData.points_balance || 0}`);
      console.log(`💳 Available Balance: ${userData.available_balance || 0}`);
      console.log(`🔒 Locked Balance: ${userData.locked_balance || 0}`);
      console.log(`📈 Total Earned: ${userData.total_earned || 0}`);
    }
    console.log('');

    // Step 3: Start deletion process
    const deletionResults = {
      auth: false,
      userData: false,
      rewardsLog: 0,
      socialVerifications: 0,
      redemptions: 0,
      battles: 0,
      pendingTransfers: 0
    };

    // Delete Firebase Auth user
    console.log('🗑️ Deleting from Firebase Auth...');
    await admin.auth().deleteUser(userId);
    deletionResults.auth = true;
    console.log('✅ Firebase Auth user deleted');

    // Delete user document
    if (userDoc.exists) {
      console.log('🗑️ Deleting user document...');
      await db.collection('users').doc(userId).delete();
      deletionResults.userData = true;
      console.log('✅ User document deleted');
    }

    // Delete rewards log entries
    console.log('🗑️ Deleting rewards log entries...');
    const rewardsQuery = await db.collection('rewards_log')
      .where('uid', '==', userId)
      .get();
    
    const rewardsBatch = db.batch();
    rewardsQuery.docs.forEach(doc => {
      rewardsBatch.delete(doc.ref);
    });
    await rewardsBatch.commit();
    deletionResults.rewardsLog = rewardsQuery.size;
    console.log(`✅ Deleted ${rewardsQuery.size} rewards log entries`);

    // Delete social verifications
    console.log('🗑️ Deleting social verifications...');
    const socialQuery = await db.collection('users').doc(userId)
      .collection('social_verifications').get();
    
    const socialBatch = db.batch();
    socialQuery.docs.forEach(doc => {
      socialBatch.delete(doc.ref);
    });
    await socialBatch.commit();
    deletionResults.socialVerifications = socialQuery.size;
    console.log(`✅ Deleted ${socialQuery.size} social verification entries`);

    // Delete redemptions
    console.log('🗑️ Deleting redemptions...');
    const redemptionsQuery = await db.collection('redemptions')
      .where('uid', '==', userId)
      .get();
    
    const redemptionsBatch = db.batch();
    redemptionsQuery.docs.forEach(doc => {
      redemptionsBatch.delete(doc.ref);
    });
    await redemptionsBatch.commit();
    deletionResults.redemptions = redemptionsQuery.size;
    console.log(`✅ Deleted ${redemptionsQuery.size} redemption entries`);

    // Remove from battle rounds
    console.log('🗑️ Removing from battle rounds...');
    const battlesQuery = await db.collection('timedRounds')
      .where('players', 'array-contains-any', [{ uid: userId }])
      .get();
    
    const battlesBatch = db.batch();
    battlesQuery.docs.forEach(battleDoc => {
      const battleData = battleDoc.data();
      const updatedPlayers = battleData.players.filter(player => player.uid !== userId);
      battlesBatch.update(battleDoc.ref, { 
        players: updatedPlayers,
        totalStake: updatedPlayers.reduce((sum, p) => sum + (p.stakeAmount || 0), 0)
      });
    });
    await battlesBatch.commit();
    deletionResults.battles = battlesQuery.size;
    console.log(`✅ Removed user from ${battlesQuery.size} battle rounds`);

    // Delete pending transfers
    console.log('🗑️ Deleting pending transfers...');
    const transfersQuery = await db.collection('pending_transfers')
      .where('uid', '==', userId)
      .get();
    
    const transfersBatch = db.batch();
    transfersQuery.docs.forEach(doc => {
      transfersBatch.delete(doc.ref);
    });
    await transfersBatch.commit();
    deletionResults.pendingTransfers = transfersQuery.size;
    console.log(`✅ Deleted ${transfersQuery.size} pending transfer entries`);

    // Log the deletion action
    console.log('📝 Logging deletion action...');
    await db.collection('admin_actions').add({
      action: 'delete_user_account_direct',
      admin_type: 'direct_script',
      target_user_id: userId,
      target_user_email: email,
      reason: reason,
      user_data_snapshot: userData ? {
        points_balance: userData.points_balance,
        available_balance: userData.available_balance,
        locked_balance: userData.locked_balance,
        total_earned: userData.total_earned,
        createdAt: userData.createdAt,
        walletAddress: userData.walletAddress
      } : null,
      deletion_results: deletionResults,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Deletion action logged');

    console.log('');
    console.log('🎉 USER ACCOUNT DELETION COMPLETED SUCCESSFULLY!');
    console.log('==============================================');
    console.log(`📧 Deleted: ${email}`);
    console.log(`👤 User ID: ${userId}`);
    console.log('');
    console.log('📊 Summary:');
    console.log(`   ✅ Firebase Auth: Deleted`);
    console.log(`   ✅ User Document: ${deletionResults.userData ? 'Deleted' : 'Not found'}`);
    console.log(`   ✅ Rewards Entries: ${deletionResults.rewardsLog} deleted`);
    console.log(`   ✅ Social Verifications: ${deletionResults.socialVerifications} deleted`);
    console.log(`   ✅ Redemptions: ${deletionResults.redemptions} deleted`);
    console.log(`   ✅ Battle Participations: ${deletionResults.battles} updated`);
    console.log(`   ✅ Pending Transfers: ${deletionResults.pendingTransfers} deleted`);
    console.log('');
    console.log('⚠️  The account and all associated data have been permanently deleted.');

    return {
      success: true,
      deleted_user_id: userId,
      deletion_summary: deletionResults
    };

  } catch (error) {
    console.error(`❌ Error during deletion: ${error.message}`);
    console.error('Stack trace:', error.stack);
    return {
      success: false,
      error: error.message
    };
  }
}

// Main execution
async function main() {
  const email = process.argv[2];
  const reason = process.argv[3] || 'Direct admin script deletion';

  if (!email) {
    console.log('🔐 Direct Firebase User Deletion Tool');
    console.log('Usage: node delete-user-direct.js <email> [reason]');
    console.log('');
    console.log('Example:');
    console.log('  node delete-user-direct.js yerinsmgmt@gmail.com "Account cleanup"');
    return;
  }

  console.log('⚠️  WARNING: This will permanently delete the user account and all data!');
  console.log('⚠️  This action cannot be undone!');
  console.log('');

  // Simple confirmation
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question(`Type "DELETE ${email}" to confirm: `, async (answer) => {
    rl.close();
    
    if (answer === `DELETE ${email}`) {
      console.log('✅ Confirmation received, proceeding with deletion...');
      console.log('');
      
      const result = await deleteUserDirectly(email, reason);
      
      if (result.success) {
        console.log('🎯 Deletion completed successfully!');
        process.exit(0);
      } else {
        console.log('❌ Deletion failed:', result.error);
        process.exit(1);
      }
    } else {
      console.log('❌ Confirmation failed. Deletion cancelled.');
      process.exit(0);
    }
  });
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { deleteUserDirectly };
