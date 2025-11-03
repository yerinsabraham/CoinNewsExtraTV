// Direct Admin User Deletion Script - Auto Execute
// This script runs automatically without confirmation prompts

const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials (service account)
admin.initializeApp();
const db = admin.firestore();

async function deleteUserDirectly(email, reason = 'Auto admin deletion') {
  try {
    console.log('🔐 EXECUTING DIRECT ADMIN USER DELETION');
    console.log('======================================');
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
    console.log(`📅 Last Sign In: ${userRecord.metadata.lastSignInTime || 'Never'}`);
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
      console.log(`🏆 Level: ${userData.level || 1}`);
      console.log(`💎 Rank: ${userData.rank || 'Bronze'}`);
    } else {
      console.log('ℹ️  No user document found in Firestore');
    }
    console.log('');

    // Step 3: Start deletion process
    console.log('🗑️ STARTING DELETION PROCESS...');
    console.log('================================');
    
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
    console.log('🔥 Deleting from Firebase Authentication...');
    await admin.auth().deleteUser(userId);
    deletionResults.auth = true;
    console.log('✅ Firebase Auth user deleted');

    // Delete user document
    if (userDoc.exists) {
      console.log('📄 Deleting user document from Firestore...');
      await db.collection('users').doc(userId).delete();
      deletionResults.userData = true;
      console.log('✅ User document deleted');
    } else {
      console.log('ℹ️  No user document to delete');
    }

    // Delete rewards log entries
    console.log('🎁 Deleting rewards log entries...');
    const rewardsQuery = await db.collection('rewards_log')
      .where('uid', '==', userId)
      .get();
    
    if (!rewardsQuery.empty) {
      const rewardsBatch = db.batch();
      rewardsQuery.docs.forEach(doc => {
        rewardsBatch.delete(doc.ref);
      });
      await rewardsBatch.commit();
    }
    deletionResults.rewardsLog = rewardsQuery.size;
    console.log(`✅ Deleted ${rewardsQuery.size} rewards log entries`);

    // Delete social verifications
    console.log('📱 Deleting social verifications...');
    const socialQuery = await db.collection('users').doc(userId)
      .collection('social_verifications').get();
    
    if (!socialQuery.empty) {
      const socialBatch = db.batch();
      socialQuery.docs.forEach(doc => {
        socialBatch.delete(doc.ref);
      });
      await socialBatch.commit();
    }
    deletionResults.socialVerifications = socialQuery.size;
    console.log(`✅ Deleted ${socialQuery.size} social verification entries`);

    // Delete redemptions
    console.log('💸 Deleting redemptions...');
    const redemptionsQuery = await db.collection('redemptions')
      .where('uid', '==', userId)
      .get();
    
    if (!redemptionsQuery.empty) {
      const redemptionsBatch = db.batch();
      redemptionsQuery.docs.forEach(doc => {
        redemptionsBatch.delete(doc.ref);
      });
      await redemptionsBatch.commit();
    }
    deletionResults.redemptions = redemptionsQuery.size;
    console.log(`✅ Deleted ${redemptionsQuery.size} redemption entries`);

    // Remove from battle rounds
    console.log('⚔️ Removing from battle rounds...');
    const battlesQuery = await db.collection('timedRounds')
      .where('players', 'array-contains-any', [{ uid: userId }])
      .get();
    
    if (!battlesQuery.empty) {
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
    }
    deletionResults.battles = battlesQuery.size;
    console.log(`✅ Removed user from ${battlesQuery.size} battle rounds`);

    // Delete pending transfers
    console.log('💳 Deleting pending transfers...');
    const transfersQuery = await db.collection('pending_transfers')
      .where('uid', '==', userId)
      .get();
    
    if (!transfersQuery.empty) {
      const transfersBatch = db.batch();
      transfersQuery.docs.forEach(doc => {
        transfersBatch.delete(doc.ref);
      });
      await transfersBatch.commit();
    }
    deletionResults.pendingTransfers = transfersQuery.size;
    console.log(`✅ Deleted ${transfersQuery.size} pending transfer entries`);

    // Log the deletion action
    console.log('📝 Creating audit log entry...');
    await db.collection('admin_actions').add({
      action: 'delete_user_account_auto',
      admin_type: 'direct_script',
      target_user_id: userId,
      target_user_email: email,
      reason: reason,
      user_data_snapshot: userData ? {
        points_balance: userData.points_balance || 0,
        available_balance: userData.available_balance || 0,
        locked_balance: userData.locked_balance || 0,
        total_earned: userData.total_earned || 0,
        level: userData.level || 1,
        rank: userData.rank || 'Bronze',
        createdAt: userData.createdAt,
        walletAddress: userData.walletAddress
      } : null,
      deletion_results: deletionResults,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      execution_timestamp: new Date().toISOString()
    });
    console.log('✅ Audit log entry created');

    console.log('');
    console.log('🎉 USER ACCOUNT DELETION COMPLETED SUCCESSFULLY!');
    console.log('==============================================');
    console.log(`📧 Deleted Account: ${email}`);
    console.log(`👤 User ID: ${userId}`);
    console.log(`🕒 Execution Time: ${new Date().toLocaleString()}`);
    console.log('');
    console.log('📊 DELETION SUMMARY:');
    console.log(`   🔥 Firebase Auth: ✅ Deleted`);
    console.log(`   📄 User Document: ${deletionResults.userData ? '✅ Deleted' : 'ℹ️ Not found'}`);
    console.log(`   🎁 Rewards Entries: ✅ ${deletionResults.rewardsLog} deleted`);
    console.log(`   📱 Social Verifications: ✅ ${deletionResults.socialVerifications} deleted`);
    console.log(`   💸 Redemptions: ✅ ${deletionResults.redemptions} deleted`);
    console.log(`   ⚔️ Battle Participations: ✅ ${deletionResults.battles} updated`);
    console.log(`   💳 Pending Transfers: ✅ ${deletionResults.pendingTransfers} deleted`);
    console.log('');
    console.log('⚠️  The account and all associated data have been permanently deleted.');
    console.log('📝 Action logged in admin_actions collection for audit trail.');

    return {
      success: true,
      deleted_user_id: userId,
      deletion_summary: deletionResults,
      execution_time: new Date().toISOString()
    };

  } catch (error) {
    console.error('');
    console.error('❌ ERROR DURING DELETION:');
    console.error('========================');
    console.error(`Message: ${error.message}`);
    console.error(`Code: ${error.code || 'N/A'}`);
    console.error('');
    console.error('Stack trace:');
    console.error(error.stack);
    console.error('');
    
    return {
      success: false,
      error: error.message,
      error_code: error.code
    };
  }
}

// Auto-execute deletion for yerinsmgmt@gmail.com
async function main() {
  console.log('🚀 AUTO-EXECUTING USER DELETION');
  console.log('===============================');
  console.log('Target: yerinsmgmt@gmail.com');
  console.log('Reason: Account cleanup - user requested deletion');
  console.log('');
  
  const result = await deleteUserDirectly(
    'yerinsmgmt@gmail.com', 
    'Account cleanup - user requested deletion after account mixing issues'
  );
  
  if (result.success) {
    console.log('');
    console.log('🎯 MISSION ACCOMPLISHED!');
    console.log('User yerinsmgmt@gmail.com has been completely removed from the system.');
    process.exit(0);
  } else {
    console.log('');
    console.log('💥 DELETION FAILED!');
    console.log('Error:', result.error);
    process.exit(1);
  }
}

// Execute immediately
main().catch(error => {
  console.error('💥 Unhandled error:', error);
  process.exit(1);
});
